let { get_setting_by_blk_path=null } = require_optional("settings")
let { app_is_offline_mode } = require("app")

const SETTING_EDITOR_PLAYCONFIG = "daEditor4/sandboxPlayConfig_"

let isSandboxContext = @() app_is_offline_mode()

let function getSandboxConfigValue(name, defval) {
  if (!isSandboxContext())
    return defval
  let val = get_setting_by_blk_path?($"{SETTING_EDITOR_PLAYCONFIG}{name}")
  if (val==null || val=="" || val==-1)
    return defval
  return val
}

return { isSandboxContext, getSandboxConfigValue }
