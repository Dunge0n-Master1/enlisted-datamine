from "%enlSqGlob/ui_library.nut" import *

let {get_setting_by_blk_path} = require("settings")
let {planeControlModeStateUpdate} = require("%enlSqGlob/planeControlModeState.nut")
let {getOnlineSaveData, optionCtor, optionSpinner } = require("%ui/hud/menus/options/options_lib.nut")

const MOUSE_AIM = "mouse_aim"
const SIMPLE_JOY = "simple_joy"
const DIRECT = "direct"

let mods = freeze([MOUSE_AIM, SIMPLE_JOY, DIRECT])
let modSettings = {
  [MOUSE_AIM]  = { isMouseAimEnabled = true, isSimpleJoyEnabled = false},
  [SIMPLE_JOY] = { isMouseAimEnabled = false, isSimpleJoyEnabled = true},
  [DIRECT]     = { isMouseAimEnabled = false, isSimpleJoyEnabled = false},
}

let blkPath = "gameplay/planeControlMode"

let onlineDataMode = getOnlineSaveData(blkPath,
  @() get_setting_by_blk_path(blkPath) ?? MOUSE_AIM
)

let planeControlMode = optionCtor({
  name = loc("gameplay/planeControlMode")
  widgetCtor = optionSpinner
  tab = "Game"
  var = onlineDataMode.watch
  setValue = onlineDataMode.setValue
  available = mods
  valToString = @(s) loc($"gameplay/plane_control_mode_{s}")
  blkPath
})

let function setPlaneControlMode(mode) {
  if (mode not in modSettings)
    return
  let {isMouseAimEnabled, isSimpleJoyEnabled} = modSettings[mode]
  planeControlModeStateUpdate({isMouseAimEnabled, isSimpleJoyEnabled})
}
onlineDataMode.watch.subscribe(setPlaneControlMode)
setPlaneControlMode(onlineDataMode.watch.value)

return [planeControlMode]