local wezterm = require 'wezterm'

return {
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
} 