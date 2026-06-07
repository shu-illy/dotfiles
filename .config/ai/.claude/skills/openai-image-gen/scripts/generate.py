#!/usr/bin/env python3
"""OpenAI Image Generation API (gpt-image-*) client — Python stdlib only.

Saves generated images to a local directory and prints `SAVED:<abs-path>`
lines to stdout so a calling agent can pick them up.
"""

from __future__ import annotations

import argparse
import base64
import json
import os
import re
import sys
import urllib.error
import urllib.request
from datetime import datetime
from pathlib import Path

API_URL = "https://api.openai.com/v1/images/generations"
DEFAULT_MODEL = os.environ.get("OPENAI_IMAGE_MODEL", "gpt-image-2")
DEFAULT_OUTPUT_DIR = Path(
    os.environ.get("OPENAI_IMAGE_OUTPUT_DIR", str(Path.home() / "Pictures" / "claude-gen"))
)
TIMEOUT_SECONDS = 120

EXIT_OK = 0
EXIT_GENERIC = 1
EXIT_AUTH = 2
EXIT_RATE = 3
EXIT_POLICY = 4
EXIT_TIMEOUT = 5
EXIT_ORG_VERIFY = 6

ALLOWED_SIZES = {
    "1024x1024", "1024x1536", "1536x1024",
    "2048x2048", "2048x1152", "3840x2160", "2160x3840",
    "auto",
}
ALLOWED_QUALITIES = {"low", "medium", "high", "auto"}
ALLOWED_OUTPUT_FORMATS = {"png", "jpeg", "webp"}

PRICE_TABLE_USD = {
    ("gpt-image-2", "low"):    (0.005, 0.04),
    ("gpt-image-2", "medium"): (0.02,  0.10),
    ("gpt-image-2", "high"):   (0.05,  0.211),
    ("gpt-image-2", "auto"):   (0.02,  0.211),
    ("gpt-image-1.5", "low"):    (0.009, 0.04),
    ("gpt-image-1.5", "medium"): (0.02,  0.10),
    ("gpt-image-1.5", "high"):   (0.05,  0.20),
    ("gpt-image-1.5", "auto"):   (0.02,  0.20),
    ("gpt-image-1", "low"):    (0.011, 0.04),
    ("gpt-image-1", "medium"): (0.04,  0.16),
    ("gpt-image-1", "high"):   (0.07,  0.25),
    ("gpt-image-1", "auto"):   (0.04,  0.25),
    ("gpt-image-1-mini", "low"):    (0.005, 0.015),
    ("gpt-image-1-mini", "medium"): (0.015, 0.03),
    ("gpt-image-1-mini", "high"):   (0.03,  0.052),
    ("gpt-image-1-mini", "auto"):   (0.015, 0.052),
}


def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(
        prog="openai-image-gen",
        description="Generate images with OpenAI's gpt-image-* models and save locally.",
    )
    p.add_argument("--prompt", required=True, help="Text prompt for the image.")
    p.add_argument("--model", default=DEFAULT_MODEL,
                   help=f"Model ID (default: {DEFAULT_MODEL}). Overridable via $OPENAI_IMAGE_MODEL.")
    p.add_argument("--size", default="auto",
                   help=f"Image size. Allowed: {sorted(ALLOWED_SIZES)} (default: auto).")
    p.add_argument("--quality", default="auto",
                   help=f"Quality tier. Allowed: {sorted(ALLOWED_QUALITIES)} (default: auto).")
    p.add_argument("--n", type=int, default=1, help="Number of images (default: 1).")
    p.add_argument("--output-format", default="png", dest="output_format",
                   help=f"Image file format. Allowed: {sorted(ALLOWED_OUTPUT_FORMATS)} (default: png).")
    p.add_argument("--out", default=None,
                   help="Output path (file for n=1, directory for n>1). Default: auto-named under "
                        f"{DEFAULT_OUTPUT_DIR}/YYYY-MM-DD/.")
    p.add_argument("--cheap", action="store_true",
                   help="Force model=gpt-image-1-mini and quality=low to minimize cost.")
    p.add_argument("--background", default=None,
                   help="opaque | auto (model-dependent). Pass-through to API.")
    p.add_argument("--moderation", default=None,
                   help="auto | low. Pass-through to API.")
    p.add_argument("--dry-run", action="store_true", dest="dry_run",
                   help="Print the request body and intended save path(s) without calling the API.")
    p.add_argument("--yes", action="store_true",
                   help="Skip interactive cost confirmation when n > 4.")
    args = p.parse_args()

    if args.cheap:
        args.model = "gpt-image-1-mini"
        args.quality = "low"

    if args.size not in ALLOWED_SIZES:
        p.error(f"--size must be one of {sorted(ALLOWED_SIZES)}")
    if args.quality not in ALLOWED_QUALITIES:
        p.error(f"--quality must be one of {sorted(ALLOWED_QUALITIES)}")
    if args.output_format not in ALLOWED_OUTPUT_FORMATS:
        p.error(f"--output-format must be one of {sorted(ALLOWED_OUTPUT_FORMATS)}")
    if args.n < 1:
        p.error("--n must be >= 1")

    return args


def slugify(text: str, max_len: int = 40) -> str:
    head = text.strip()[:max_len]
    cleaned = re.sub(
        r"[^0-9A-Za-z\-ぁ-ゖァ-ヺー一-鿿]+",
        "-",
        head,
    )
    cleaned = re.sub(r"-+", "-", cleaned).strip("-").lower()
    return cleaned or "image"


def avoid_collision(path: Path) -> Path:
    if not path.exists():
        return path
    stem, suffix = path.stem, path.suffix
    parent = path.parent
    i = 1
    while True:
        candidate = parent / f"{stem}-{i}{suffix}"
        if not candidate.exists():
            return candidate
        i += 1


def build_save_paths(args: argparse.Namespace, now: datetime) -> list[Path]:
    ext = args.output_format
    slug = slugify(args.prompt)
    timestamp = now.strftime("%H%M%S")

    if args.out:
        out = Path(args.out).expanduser().resolve()
        if args.n == 1:
            out.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
            return [avoid_collision(out)]
        out.mkdir(parents=True, exist_ok=True, mode=0o700)
        return [
            avoid_collision(out / f"{timestamp}-{slug}-{i:03d}.{ext}")
            for i in range(1, args.n + 1)
        ]

    day_dir = DEFAULT_OUTPUT_DIR.expanduser() / now.strftime("%Y-%m-%d")
    day_dir.mkdir(parents=True, exist_ok=True, mode=0o700)
    if args.n == 1:
        return [avoid_collision(day_dir / f"{timestamp}-{slug}.{ext}")]
    return [
        avoid_collision(day_dir / f"{timestamp}-{slug}-{i:03d}.{ext}")
        for i in range(1, args.n + 1)
    ]


def build_request_body(args: argparse.Namespace) -> dict:
    body: dict = {
        "model": args.model,
        "prompt": args.prompt,
        "size": args.size,
        "quality": args.quality,
        "n": args.n,
        "output_format": args.output_format,
    }
    if args.background:
        body["background"] = args.background
    if args.moderation:
        body["moderation"] = args.moderation
    return body


def estimate_cost(args: argparse.Namespace) -> tuple[float, float]:
    key = (args.model, args.quality)
    if key not in PRICE_TABLE_USD:
        return (0.0, 0.0)
    lo, hi = PRICE_TABLE_USD[key]
    return (lo * args.n, hi * args.n)


def call_api(api_key: str, body: dict) -> dict:
    data = json.dumps(body).encode("utf-8")
    req = urllib.request.Request(
        API_URL,
        data=data,
        headers={
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json",
            "User-Agent": "openai-image-gen-skill/1.0 (python-stdlib)",
        },
        method="POST",
    )
    with urllib.request.urlopen(req, timeout=TIMEOUT_SECONDS) as resp:
        return json.loads(resp.read().decode("utf-8"))


def handle_http_error(e: urllib.error.HTTPError) -> int:
    try:
        body_bytes = e.read()
        body_text = body_bytes.decode("utf-8", errors="replace")
    except Exception:
        body_text = ""

    try:
        parsed = json.loads(body_text)
        msg = parsed.get("error", {}).get("message", body_text)
        err_type = parsed.get("error", {}).get("type", "")
        err_code = parsed.get("error", {}).get("code", "")
    except Exception:
        msg = body_text or str(e)
        err_type = ""
        err_code = ""

    status = e.code
    print(f"HTTP {status}: {msg}", file=sys.stderr)

    if status == 401:
        print("対処: $OPENAI_API_KEY が無効です。`echo $OPENAI_API_KEY` で値を確認、または "
              "platform.openai.com で再発行してください。", file=sys.stderr)
        return EXIT_AUTH
    if status == 403:
        print("対処: gpt-image-* 系は組織検証が必要です。"
              "platform.openai.com → Settings → Organization → Verification "
              "で本人確認を完了してください (政府発行 ID 必要、即時〜数日)。", file=sys.stderr)
        return EXIT_ORG_VERIFY
    if status == 429:
        retry_after = e.headers.get("Retry-After") if e.headers else None
        if retry_after:
            print(f"対処: レート制限。{retry_after} 秒待ってから再試行してください。", file=sys.stderr)
        else:
            print("対処: レート制限に到達。1 分後に再試行 or tier を上げてください。", file=sys.stderr)
        return EXIT_RATE
    if status == 400 and ("content_policy" in err_code or "content_policy" in err_type):
        print("対処: プロンプトが OpenAI の利用ポリシーで拒否されました。表現を変えて再試行してください。",
              file=sys.stderr)
        return EXIT_POLICY
    return EXIT_GENERIC


def main() -> int:
    args = parse_args()

    if args.n > 4 and not args.yes and not args.dry_run:
        lo, hi = estimate_cost(args)
        print(f"警告: n={args.n} は推定 ${lo:.3f}〜${hi:.3f} のコストになります。"
              "続行するには --yes を付けて再実行してください。", file=sys.stderr)
        return EXIT_GENERIC

    now = datetime.now()
    save_paths = build_save_paths(args, now)
    body = build_request_body(args)
    lo, hi = estimate_cost(args)

    if args.dry_run:
        redacted = {
            "url": API_URL,
            "headers": {
                "Authorization": "Bearer ***",
                "Content-Type": "application/json",
            },
            "body": body,
        }
        print("=== DRY RUN ===")
        print(json.dumps(redacted, indent=2, ensure_ascii=False))
        print(f"\n推定コスト: ${lo:.3f}〜${hi:.3f} (n={args.n}, model={args.model}, quality={args.quality})")
        print("保存予定パス:")
        for p in save_paths:
            print(f"  {p}")
        for p in save_paths:
            print(f"SAVED:{p}  # (dry-run, not actually written)")
        return EXIT_OK

    api_key = os.environ.get("OPENAI_API_KEY")
    if not api_key:
        print("エラー: 環境変数 OPENAI_API_KEY が未設定です。", file=sys.stderr)
        print("対処: platform.openai.com で API キーを発行し、`~/.zshrc` に以下を追記してください:",
              file=sys.stderr)
        print('  export OPENAI_API_KEY="sk-..."', file=sys.stderr)
        print("その後 `source ~/.zshrc` で読み込み直してください。", file=sys.stderr)
        return EXIT_AUTH

    try:
        response = call_api(api_key, body)
    except urllib.error.HTTPError as e:
        return handle_http_error(e)
    except urllib.error.URLError as e:
        reason = getattr(e, "reason", str(e))
        if "timed out" in str(reason).lower():
            print(f"エラー: 生成が {TIMEOUT_SECONDS} 秒以内に完了しませんでした。", file=sys.stderr)
            print("対処: --quality low または小さい --size で再試行してください。", file=sys.stderr)
            return EXIT_TIMEOUT
        print(f"ネットワークエラー: {reason}", file=sys.stderr)
        return EXIT_GENERIC
    except TimeoutError:
        print(f"エラー: 生成が {TIMEOUT_SECONDS} 秒以内に完了しませんでした。", file=sys.stderr)
        return EXIT_TIMEOUT
    except Exception as e:
        print(f"予期しないエラー: {type(e).__name__}: {e}", file=sys.stderr)
        return EXIT_GENERIC

    data = response.get("data") or []
    if not data:
        print("エラー: API レスポンスに画像データが含まれていません。", file=sys.stderr)
        print(json.dumps(response, indent=2, ensure_ascii=False)[:1000], file=sys.stderr)
        return EXIT_GENERIC

    if len(data) != len(save_paths):
        save_paths = save_paths[:len(data)]

    actual_cost_line = ""
    if "usage" in response:
        actual_cost_line = f"# usage: {json.dumps(response['usage'], ensure_ascii=False)}"

    print(f"推定コスト: ${lo:.3f}〜${hi:.3f} (n={len(data)}, model={args.model}, quality={args.quality})")
    if actual_cost_line:
        print(actual_cost_line)

    written: list[Path] = []
    for item, path in zip(data, save_paths):
        b64 = item.get("b64_json")
        if not b64:
            print(f"警告: 画像データに b64_json がありません: {item.keys()}", file=sys.stderr)
            continue
        try:
            raw = base64.b64decode(b64)
        except Exception as e:
            print(f"エラー: base64 デコード失敗: {e}", file=sys.stderr)
            return EXIT_GENERIC
        path.write_bytes(raw)
        written.append(path)

    if not written:
        return EXIT_GENERIC

    for p in written:
        print(f"SAVED:{p}")
    return EXIT_OK


if __name__ == "__main__":
    sys.exit(main())
