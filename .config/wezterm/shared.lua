local wezterm = require 'wezterm'
local keys = require('/keys')

function split(str, ts)
  -- 引数がないときは空tableを返す
  if ts == nil then return {} end

  local t = {} ;
  i=1
  for s in string.gmatch(str, "([^"..ts.."]+)") do
    t[i] = s
    i = i + 1
  end

  return t
end

-- 各タブの「ディレクトリ名」を記憶しておくテーブル
local title_cache = {}

-- タブの形をカスタマイズ
-- タブの左側の装飾
local SOLID_LEFT_ARROW = wezterm.nerdfonts.ple_lower_right_triangle
-- タブの右側の装飾
local SOLID_RIGHT_ARROW = wezterm.nerdfonts.ple_upper_left_triangle

return {
  font = wezterm.font_with_fallback {
    'HackGen',
    'Cica',
    'JetBrains Mono',
    'Noto Sans Mono CJK JP',
  },
  font_size = 13.0,
  color_scheme = 'Tokyo Night',
  use_ime = true,
  -- enable_tab_bar = false,
  window_background_opacity = 0.95,
  window_padding = {
    left = 8,
    right = 8,
    top = 8,
    bottom = 8,
  },
  adjust_window_size_when_changing_font_size = false,
  initial_cols = 250,
  initial_rows = 60,
  
  -- 非アクティブなpaneの明度を下げて、アクティブなpaneとの差をつける
  inactive_pane_hsb = {
    hue = 1.0,
    saturation = 1.0,
    brightness = 0.3,  -- 明度を70%に下げる
  },

  wezterm.on('update-status', function(window, pane)
    -- カレントディレクトリをキャッシュする
    local pane_id = pane:pane_id()
    title_cache[pane_id] = "-"
    local process_info = pane:get_foreground_process_info()
    if process_info then
      local cwd = process_info.cwd
      local dirs = split(cwd, '/')
      local current_dir = dirs[#dirs]
      title_cache[pane_id] = current_dir
    end
  end),
  
  wezterm.on("format-tab-title", function(tab, tabs, panes, config, hover, max_width)
    local background = "#5c6d74"
    local foreground = "#FFFFFF"
    local edge_background = "none"
    if tab.is_active then
      background = "#ae8b2d"
      foreground = "#FFFFFF"
    end
    local edge_foreground = background

    local pane_id = tab.active_pane.pane_id
    local cwd = "none"
    if title_cache[pane_id] then
      cwd = title_cache[pane_id]
    else
      cwd = "-"
    end

    local title = "  " .. cwd .. "  [ " .. wezterm.truncate_right(tab.active_pane.title, max_width - 1) .. " ]"

    return {
      { Background = { Color = edge_background } },
      { Foreground = { Color = edge_foreground } },
      { Text = SOLID_LEFT_ARROW },
      { Background = { Color = background } },
      { Foreground = { Color = foreground } },
      { Text = title },
      { Background = { Color = edge_background } },
      { Foreground = { Color = edge_foreground } },
      { Text = SOLID_RIGHT_ARROW },
    }
  end),

  keys = keys,
} 