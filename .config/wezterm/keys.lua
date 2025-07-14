local wezterm = require 'wezterm'

return {
  {
    key = 't',
    mods = 'CMD',
    action = wezterm.action_callback(function(window, pane)
      -- 新しいタブを作成
      window:perform_action(wezterm.action.SpawnTab('CurrentPaneDomain'), pane)
      -- タブタイトルの更新を強制
      window:perform_action(wezterm.action.EmitEvent('update-status'), pane)
    end),
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
  {
    key = 'Enter',
    mods = 'ALT',
    action = wezterm.action.DisableDefaultAssignment,
  },
  
} 