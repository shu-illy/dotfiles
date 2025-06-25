local wezterm = require 'wezterm'

return {
  font = wezterm.font_with_fallback {
    'HackGenNerd',
    'Cica',
    'JetBrains Mono',
    'Noto Sans Mono CJK JP',
  },
  font_size = 13.0,
  color_scheme = 'Tokyo Night',
  use_ime = true,
  enable_tab_bar = false,
  window_background_opacity = 0.95,
  window_padding = {
    left = 8,
    right = 8,
    top = 8,
    bottom = 8,
  },
  adjust_window_size_when_changing_font_size = false,
} 