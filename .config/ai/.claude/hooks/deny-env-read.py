#!/usr/bin/env python3
"""PreToolUse hook: .env / .envrc 系ファイルの「中身の読み取り」を拒否する。

方針:
- 対象: basename が .env / .envrc / .env.<任意> / .envrc.<任意>（大文字小文字無視）
  ただし .example / .sample / .template で終わるテンプレートは対象外
- Read / Edit / NotebookEdit: 対象パスを直接指定したら拒否
- Grep: path / glob が対象を指したら拒否。ディレクトリ検索（glob・type 指定なし）は
  rg が隠しファイルも見るため、除外 glob を updatedInput で注入する
- Bash: コマンドを字句解析し、対象パス（またはそれにマッチしうる glob）を引数に取る
  単純コマンドが「中身を出力しないコマンド」(cp / mv / ls / test 等) 以外なら拒否。
  `< .env` の入力リダイレクト、シェル / インタプリタに渡すコード文字列・heredoc 内の
  参照、コマンド置換内での参照も拒否
- 対象外の呼び出しでは何も出力せず exit 0（allow を返さない。通常の
  permission 判定・auto mode をそのまま通すため）

これは文字列ベースの防御（うっかり読むことを防ぐガードレール）であり、
変数展開・動的なパス組み立て・スクリプト内部での読み込み・cp 後の別名ファイル
読み取り・ディレクトリ単位の再帰読み取り等は塞げない（ベストエフォート）。
"""
import codecs
import fnmatch
import json
import os
import re
import shlex
import sys

TEMPLATE_SUFFIXES = (".example", ".sample", ".template")
ENV_BASENAME_RE = re.compile(r"^\.env(rc)?(\.[^\s/]+)?$", re.I)

# 引数に対象ファイルを取っても中身を出力しないコマンド
SAFE_COMMANDS = {
    "cp", "mv", "rm", "ls", "test", "[", "[[", "stat", "touch", "chmod",
    "mkdir", "echo", "printf", "tee",
}
# 中身を出さないサブコマンド
SAFE_SUBCOMMANDS = {
    "git": {"check-ignore", "rm", "ls-files", "status"},
    "direnv": {"allow", "permit", "deny", "block", "revoke", "status"},
}
# サブコマンドより前に値を取るグローバルオプション
SUBCOMMAND_VALUE_OPTS = {"git": {"-C", "-c", "--git-dir", "--work-tree", "--namespace"}}

# 引数の順に「パターン → ファイル」を取る検索コマンド（最初の位置引数はパターン）
GREP_COMMANDS = {"grep", "egrep", "fgrep", "rg"}
GREP_VALUE_OPTS = {
    "-A", "-B", "-C", "-m", "--max-count", "-g", "--glob", "-t", "--type", "-T",
    "--type-not", "-M", "--max-columns", "-j", "--threads", "--color", "--colors",
}

# 引数のコード文字列内でファイルを開きうるもの
SHELLS = {"sh", "bash", "zsh", "dash", "ksh", "fish", "csh", "tcsh", "eval", "watch"}
INTERPRETERS = {
    "python", "ruby", "node", "perl", "php", "deno", "bun", "osascript",
    "awk", "gawk", "sed", "lua", "Rscript", "irb", "tsx", "ts-node",
}
# 次の語を本体コマンドとして扱うラッパー（値を取るオプションは読み飛ばす）
WRAPPERS = {
    "sudo": {"-u", "-g", "-C", "-h", "-p", "-U", "-r", "-t"},
    "env": {"-u", "-C", "-S", "-P"},
    "timeout": {"-s", "-k", "--signal", "--kill-after"},
    "nice": {"-n"},
    "exec": {"-a"},
    "xargs": {"-I", "-n", "-P", "-L", "-d", "-E", "-s"},
    "command": set(), "builtin": set(), "nohup": set(), "time": set(),
    "rtk": set(), "npx": set(), "bunx": set(),
}
# 「<ランチャー> <サブコマンド> <本体>」形式
LAUNCHERS = {"uv": {"run"}, "poetry": {"run"}, "bundle": {"exec"}, "pnpm": {"exec", "dlx"}, "yarn": {"dlx", "exec"}}

GREP_EXCLUDE_GLOB = "!{.env,.envrc,.env.*,.envrc.*}"

SEPARATORS = {";", "&&", "||", "|", "&", "(", ")", "|&", ";;"}
INPUT_REDIRECTS = {"<", "<>", "<&"}
OUTPUT_REDIRECTS = {">", ">>", ">|", "&>", "&>>", ">&", "<<<"}


def expand_braces(word: str, limit: int = 64):
    """簡易ブレース展開（a{b,c}d → abd, acd / a{d..f} → ad, ae, af）。"""
    m = re.search(r"\{([^{}]*,[^{}]*|[A-Za-z0-9]\.\.[A-Za-z0-9])\}", word)
    if not m or limit <= 0:
        return [word]
    inner = m.group(1)
    rng = re.fullmatch(r"([A-Za-z0-9])\.\.([A-Za-z0-9])", inner)
    if rng:
        a, b = sorted((ord(rng.group(1)), ord(rng.group(2))))
        alts = [chr(c) for c in range(a, min(b, a + 40) + 1)]
    else:
        alts = inner.split(",")
    out = []
    for alt in alts:
        out.extend(expand_braces(word[:m.start()] + alt + word[m.end():], limit - 1))
        if len(out) > limit:
            break
    return out


def is_env_basename(base: str) -> bool:
    return bool(ENV_BASENAME_RE.match(base)) and not base.lower().endswith(TEMPLATE_SUFFIXES)


def is_env_path(word: str) -> bool:
    word = word.strip().rstrip("/")
    return bool(word) and is_env_basename(os.path.basename(word))


def may_glob_env(word: str) -> bool:
    # shell の glob は先頭が . でないパターンでドットファイルにマッチしないので、. 始まりのみ見る
    base = os.path.basename(word.rstrip("/"))
    if not base.startswith(".") or not any(c in base for c in "*?["):
        return False
    probes = [".env", ".envrc", ".env.local", ".env.production", ".env.development"]
    return any(fnmatch.fnmatchcase(p, base.lower()) for p in probes)


def candidate_parts(word: str):
    """語そのものに加え、埋め込まれたパス（HEAD:.env / --env-file=.env / @.env / -f.env）も返す。"""
    parts = {word, re.split(r"[:=]", word)[-1]}
    for p in list(parts):
        q = re.sub(r"^-[A-Za-z]", "", p) if re.match(r"^-[A-Za-z].", p) else p
        parts.add(q)
        parts.add(q.lstrip("@<"))
    return parts


def mentions_env(word: str, globs: bool = True) -> bool:
    if not isinstance(word, str) or not word:
        return False
    for w in expand_braces(word):
        for p in candidate_parts(w):
            if is_env_path(p) or (globs and may_glob_env(p)):
                return True
    return False


HEREDOC_START_RE = re.compile(r"(?<!<)<<(?!<)(-?)[ \t]*(['\"]?)\\?([^\s'\"<>|&;()]+)\2")


def _unquoted_positions(line: str):
    """引用符・コメントの外にある文字位置の集合と、コメント開始位置を返す（簡易）。"""
    pos, q, i = set(), None, 0
    while i < len(line):
        c = line[i]
        if q:
            if c == q:
                q = None
            elif q == '"' and line.startswith("$(", i):
                q = None  # "$(...)" の中はコマンドとして扱う（"$(cat <<'EOF' ..." 対策）
            elif c == "\\" and q == '"':
                i += 1
        elif c in "'\"":
            q = c
        elif c == "\\":
            i += 1
        elif c == "#" and (i == 0 or line[i - 1] in " \t;&|("):
            return pos, i
        else:
            pos.add(i)
        i += 1
    return pos, None


def strip_comment(line: str) -> str:
    _, comment_at = _unquoted_positions(line)
    return line if comment_at is None else line[:comment_at]


def split_heredocs(cmd: str):
    """(heredoc 本文とコメントを除いたコマンド, [(開始行, 本文, 終端が引用符なしか), ...]) を返す。"""
    lines = cmd.split("\n")
    kept, bodies, i = [], [], 0
    while i < len(lines):
        line = strip_comment(lines[i])
        kept.append(line)
        i += 1
        unq, _ = _unquoted_positions(line)
        for m in HEREDOC_START_RE.finditer(line):
            if m.start() not in unq:
                continue
            before = line[:m.start()]
            if before.count("$((") > before.count("))"):
                continue  # 算術式のシフト演算
            strip_tabs, delim = m.group(1) == "-", m.group(3)
            unquoted = not m.group(2) and "\\" not in m.group(0)
            body = []
            while i < len(lines):
                cand = lines[i].lstrip("\t") if strip_tabs else lines[i]
                i += 1
                if cand == delim:
                    break
                body.append(lines[i - 1])
            bodies.append((line, "\n".join(body), unquoted))
    return "\n".join(kept), bodies


def find_substitutions(text: str):
    """$(...) / <(...) / `...` の中身を返す（括弧の入れ子に対応）。"""
    i = 0
    while i < len(text):
        if text.startswith("$((", i):
            i += 3
            continue
        if text.startswith("$(", i) or text.startswith("<(", i):
            depth, j = 1, i + 2
            while j < len(text) and depth:
                if text[j] == "(":
                    depth += 1
                elif text[j] == ")":
                    depth -= 1
                j += 1
            yield text[i + 2:j - 1]
            i = j
            continue
        if text[i] == "`":
            j = text.find("`", i + 1)
            if j == -1:
                break
            yield text[i + 1:j]
            i = j + 1
            continue
        i += 1


def base_name(word: str) -> str:
    return os.path.basename(word.lstrip("`$("))


def is_interpreter(name: str) -> bool:
    return re.sub(r"[0-9.]+$", "", name or "") in INTERPRETERS


def fallback_check(cmd: str):
    # 保守的判定: 対象パスそのものが含まれていれば拒否（glob は見ない。正規表現等の誤検知を避ける）
    # 字句解析に失敗したとき・インタプリタのコード文字列に使う
    flat = re.sub(r"['\"\\]", "", cmd)
    for w in re.split(r"[\s`;|&()<>]+", flat):
        if mentions_env(w, globs=False):
            return f"{w} を参照している"
    for w in re.split(r"[\s`;|&()<>,'\"]+", cmd):
        if mentions_env(w, globs=False):
            return f"{w} を参照している"
    return None


def _decode_ansi_c(s: str) -> str:
    try:
        return codecs.decode(s, "unicode_escape")
    except Exception:
        return s


def tokenize(cmd: str):
    # $'..' は ANSI-C エスケープ（\x2e 等）を解いてから通常の引用符として扱う
    cmd = re.sub(r"\$'((?:[^'\\]|\\.)*)'",
                 lambda m: "'" + _decode_ansi_c(m.group(1)).replace("'", "") + "'", cmd)
    cmd = re.sub(r"\$\"", '"', cmd)
    cmd = re.sub(r"(?<![\w/.\-])\d+(?=[<>])", " ", cmd)  # 2>/dev/null の fd 番号を落とす
    lexer = shlex.shlex(cmd.replace("\n", " ; "), posix=True, punctuation_chars=";&|()<>")
    lexer.whitespace_split = True
    lexer.commenters = ""
    return list(lexer)


def resolve_command(words):
    """ラッパー・ランチャー・代入を読み飛ばし、(本体コマンド名, 本体の位置) を返す。"""
    i = 0
    while i < len(words):
        w = words[i]
        if re.match(r"^[A-Za-z_][A-Za-z0-9_]*=", w):
            i += 1
            continue
        n = base_name(w)
        if n in WRAPPERS:
            i += 1
            value_opts = WRAPPERS[n]
            while i < len(words) and words[i].startswith("-"):
                i += 2 if words[i] in value_opts else 1
            if n == "timeout" and i < len(words):
                i += 1  # 時間指定
            continue
        if n in LAUNCHERS:
            i += 1
            if i < len(words) and words[i] in LAUNCHERS[n]:
                i += 1
            while i < len(words) and words[i].startswith("-"):
                i += 1
            continue
        return n, i
    return None, i


def check_segment(seg, depth, strict=False):
    """1 つの単純コマンドを検査する。strict はコマンド置換内（安全コマンドの例外を無効化）。"""
    words = list(seg)
    name, start = resolve_command(words)

    # シェル / インタプリタに渡すコード文字列を検査
    if name in SHELLS:
        for w in words[start + 1:]:
            if not w.startswith("-"):
                reason = check_bash(w, depth + 1)
                if reason:
                    return reason
    if is_interpreter(name):
        reason = fallback_check(" ".join(words[start + 1:]))
        if reason:
            return f"インタプリタのコード内で {reason}"
        # 引数はコード・正規表現なので glob 判定はしない（s/.*// 等の誤検知を避ける）
        return None

    prev, env_args, args, positional = None, [], [], 0
    grep_explicit_pattern, skip_next, sub = False, False, None
    # 本体より前の代入・ラッパー引数（F=.env cmd / F=.env）も対象パスの受け渡しとみなす
    for w in words[:start]:
        if mentions_env(w.split("=", 1)[-1]):
            env_args.append(w)
    for w in words[start + 1:]:
        if prev in INPUT_REDIRECTS:
            if mentions_env(w):
                return f"入力リダイレクトで {w} を読もうとしている"
            prev = w
            continue
        if prev in OUTPUT_REDIRECTS:
            prev = w
            continue  # 書き込み先・here-string は読み取りではない
        if w in INPUT_REDIRECTS or w in OUTPUT_REDIRECTS:
            prev = w
            continue
        if skip_next:
            skip_next = False
            prev = w
            continue
        args.append(w)
        if name in SAFE_SUBCOMMANDS and sub is None:
            if w in SUBCOMMAND_VALUE_OPTS.get(name, ()):
                skip_next = True
                prev = w
                continue
            if not w.startswith("-"):
                sub = w
                prev = w
                continue
        if name in GREP_COMMANDS:
            if prev in ("-e", "--regexp"):
                prev = w
                continue
            if w in GREP_VALUE_OPTS:
                skip_next = True
                prev = w
                continue
            if re.match(r"^-[A-Za-z]*[ef]", w) or w.startswith(("--regexp", "--file")):
                grep_explicit_pattern = True
            if not w.startswith("-"):
                positional += 1
                if positional == 1 and not grep_explicit_pattern:
                    prev = w
                    continue  # 最初の位置引数は検索パターン
        if mentions_env(w):
            env_args.append(w)
        prev = w

    if not env_args:
        return None
    if not strict:
        if name in SAFE_SUBCOMMANDS and sub in SAFE_SUBCOMMANDS[name]:
            return None
        if name in ("cp", "mv"):
            dests = [a for a in args if not a.startswith("-")]
            dest = os.path.normpath(dests[-1]) if dests else ""
            if dest.startswith(("/dev/", "//dev/")) or dest.lower().endswith(TEMPLATE_SUFFIXES):
                return f"`{name}` で {env_args[0]} を {dest} に出そうとしている"
            return None
        if name in SAFE_COMMANDS:
            return None
    elif name in ("echo", "printf") and not any(is_env_path(a) for a in args):
        return None
    return f"`{name or '(代入)'}` に {env_args[0]} を渡している"


def check_bash(cmd: str, depth: int = 0, strict: bool = False):
    """拒否理由を返す。問題なければ None。"""
    if depth > 8:
        return None
    cmd = cmd.replace("\\\n", "")  # 行継続
    cmd, heredocs = split_heredocs(cmd)

    for start_line, body, unquoted in heredocs:
        names = {base_name(t) for t in re.split(r"[\s;&|()]+", start_line) if t}
        # シェル / インタプリタに heredoc で渡すコードは中身を検査
        if names & SHELLS:
            reason = check_bash(body, depth + 1)
            if reason:
                return reason
        if any(is_interpreter(n) for n in names):
            reason = fallback_check(body)
            if reason:
                return f"heredoc で渡すコード内で {reason}"
        if "xargs" in names and fallback_check(body):
            return "heredoc 経由で xargs に対象ファイルを渡している"
        # 引用符なし終端の heredoc では本文中のコマンド置換が実行される
        if unquoted:
            for inner in find_substitutions(body):
                reason = check_bash(inner, depth + 1, strict=True)
                if reason:
                    return f"heredoc 内のコマンド置換で {reason}"

    # コマンド置換の中で対象を引数に取れば、安全なコマンドでも拒否（cat $(ls .env) 対策）
    for inner in find_substitutions(cmd):
        reason = check_bash(inner, depth + 1, strict=True)
        if reason:
            return f"コマンド置換内で {reason}"

    tokens = tokenize(cmd)

    segments, cur = [], []
    for t in tokens:
        if t in SEPARATORS:
            if cur:
                segments.append(cur)
            cur = []
        else:
            cur.append(t)
    if cur:
        segments.append(cur)

    # xargs / while read にパイプで渡す場合、前段の対象パスは後段で読まれうる（ls .env | xargs cat）
    if any(base_name(t) in ("xargs", "read") for t in tokens) and any(mentions_env(t) for t in tokens):
        return "パイプ経由で対象ファイルを後段のコマンドに渡している"

    for seg in segments:
        reason = check_segment(seg, depth, strict)
        if reason:
            return reason
    return None


def deny(reason: str):
    out = {
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "deny",
            "permissionDecisionReason": (
                f".env / .envrc 系ファイルの読み取りは禁止されている（{reason}）。"
                "秘匿情報を含むためブラックボックスとして扱い、cp でのコピーや "
                "test -f / ls での存在確認のみ行うこと。中身の構成を知りたい場合は "
                ".env.example 等のテンプレートを参照すること。"
            ),
        }
    }
    print(json.dumps(out, ensure_ascii=False))
    sys.exit(0)


def handle(data):
    tool = data.get("tool_name", "")
    ti = data.get("tool_input")
    if not isinstance(ti, dict):
        return

    if tool in ("Read", "Edit", "NotebookEdit", "MultiEdit"):
        p = ti.get("file_path") or ti.get("notebook_path") or ""
        if isinstance(p, str) and is_env_path(p):
            deny(f"{tool} で {p} を指定している")
    elif tool == "Grep":
        for key in ("path", "glob"):
            v = ti.get(key) or ""
            if not isinstance(v, str):
                continue
            hit = mentions_env(v) or (
                key == "glob" and any(
                    e.lower().lstrip("*/").startswith(".env") and not e.lower().endswith(TEMPLATE_SUFFIXES)
                    for e in expand_braces(v)
                )
            )
            if key == "glob" and not v.startswith("!"):
                # rg の glob はドットファイルにも * がマッチする
                probes = (".env", ".envrc", ".env.local")
                hit = hit or any(
                    fnmatch.fnmatchcase(p, os.path.basename(e.lower()))
                    for e in expand_braces(v) for p in probes
                )
            if hit:
                deny(f"Grep の {key} に {v} を指定している")
        # ディレクトリ検索では rg が隠しファイルも見るため、.env 系を除外する glob を注入する
        path = ti.get("path") or ""
        cwd = data.get("cwd")
        cwd = cwd if isinstance(cwd, str) and cwd else "."
        target = os.path.join(cwd, path) if isinstance(path, str) and path else cwd
        if not ti.get("glob") and not ti.get("type") and os.path.isdir(target):
            updated = dict(ti)
            updated["glob"] = GREP_EXCLUDE_GLOB
            print(json.dumps({"hookSpecificOutput": {
                "hookEventName": "PreToolUse",
                "updatedInput": updated,
            }}, ensure_ascii=False))
    elif tool == "Bash":
        cmd = ti.get("command") or ""
        if not isinstance(cmd, str):
            return
        flat = re.sub(r"['\"\\\n]", "", cmd).lower()
        if ".env" not in flat and not re.search(r"\.[^\s/]*[*?\[{]|\\x|\\[0-7]", cmd):
            return
        try:
            reason = check_bash(cmd)
        except ValueError:
            reason = fallback_check(cmd)
        if reason:
            deny(reason)


def main():
    try:
        data = json.load(sys.stdin)
        if isinstance(data, dict):
            handle(data)
    except SystemExit:
        raise
    except Exception as e:  # hook が落ちると fail-open になるのでログだけ残す
        print(f"deny-env-read: internal error: {e!r}", file=sys.stderr)


if __name__ == "__main__":
    main()
