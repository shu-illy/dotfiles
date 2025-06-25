local wezterm = require 'wezterm'

-- 共有設定を読み込み
local shared_config = dofile(wezterm.config_dir .. '/shared.lua')

-- 端末固有設定を読み込み（ファイルが存在する場合のみ）
local local_config = {}
local local_config_path = wezterm.config_dir .. '/local.lua'
local function file_exists(path)
  local f = io.open(path, "r")
  if f then f:close() return true else return false end
end
if file_exists(local_config_path) then
  local_config = dofile(local_config_path)
end

-- 設定をマージ
local config = {}
for k, v in pairs(shared_config) do
  config[k] = v
end
for k, v in pairs(local_config) do
  config[k] = v
end

return config 