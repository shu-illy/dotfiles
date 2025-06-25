local wezterm = require 'wezterm'

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
  enable_tab_bar = false,
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
  keys = {
    {
      key = 't',
      mods = 'CMD',
      action = wezterm.action.SpawnTab 'CurrentPaneDomain',
    },
    {
      key = 'd',
      mods = 'CMD',
      action = wezterm.action.SplitHorizontal({})
    },
    {
      key = 'd',
      mods = 'CMD|SHIFT',
      action = wezterm.action.SplitVertical,
    },
    {
      key = 'LeftArrow',
      mods = 'CMD',
      action = wezterm.action.SendKey{ key = 'Home' },
    },
    {
      key = 'w',
      mods = 'CMD',
      action = wezterm.action.CloseCurrentPane{ confirm = true },
    },
    {
      key = '[',
      mods = 'CMD',
      action = wezterm.action.ActivatePaneDirection('Prev'),
    },
    {
      key = ']',
      mods = 'CMD',
      action = wezterm.action.ActivatePaneDirection('Next'),
    },
  },
} 