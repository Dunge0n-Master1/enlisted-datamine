from "%enlSqGlob/ui_library.nut" import *

let parseDargHotkeys = require("parseDargHotkeys.nut")

local function gamepadHotkeys(hotkeys, skipDescription = null){
  if (hotkeys == null || typeof(hotkeys) != "array" || hotkeys.len()==0)
    return ""

  if (skipDescription != null)
    hotkeys = hotkeys.filter(@(v) (v?[1]?.description?.skip ?? false) == skipDescription)
  hotkeys = hotkeys.map(@(v) typeof v =="string" ? v : v[0])
  hotkeys = hotkeys.filter(@(v) typeof v =="string")
  hotkeys = hotkeys.map(@(v) parseDargHotkeys(v))
  hotkeys = hotkeys.reduce(@(a,b) a.extend(b?.gamepad ?? []), [])
  return hotkeys?[0] ?? ""
}

return gamepadHotkeys
