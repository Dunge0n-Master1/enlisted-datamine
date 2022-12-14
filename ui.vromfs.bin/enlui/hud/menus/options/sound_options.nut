from "%enlSqGlob/ui_library.nut" import *

let {get_setting_by_blk_path} = require("settings")
let { sound_set_volume } = require("sound")
let {is_pc} = require("%dngscripts/platform.nut")
let {soundOutputDevicesList, soundOutputDevice, soundOutputDeviceUpdate} = require("%enlSqGlob/sound_state.nut")
let {
  getOnlineSaveData, optionSpinner, optionCtor, optionPercentTextSliderCtor
} = require("options_lib.nut")
let { headshotSoundOption, battleMusicOption } = require("%ui/hud/menus/options/sound_gameplay_options.nut")

local function optionVolSliderCtor(opt, group, xmbNode) {
  let optSetValue = opt.setValue // saved original reference to avoid recursive call of opt.setValue
  let function setValue(val) {
    optSetValue(val)
    sound_set_volume(opt.busName, val)
  }

  opt = opt.__merge({min = 0 max = 1 unit = 0.05 mult = 100 pageScroll = 0.05 setValue = setValue })

  return optionPercentTextSliderCtor(opt, group, xmbNode)
}

let function soundOption(title, field) {
  let blkPath = $"sound/volume/{field}"
  let { watch, setValue } = getOnlineSaveData(blkPath,
    @() get_setting_by_blk_path(blkPath) ?? 1.0)
  return optionCtor({
    name = title
    tab = "Sound"
    widgetCtor = optionVolSliderCtor
    var = watch
    setValue
    defVal = 1.0
    blkPath
    busName = field
  })
}
let optVolumeMaster = soundOption(loc("options/volume_master"), "MASTER")
let optVolumeAmbient = soundOption(loc("options/volume_ambient"), "ambient")
let optVolumeSfx = soundOption(loc("options/volume_sfx"), "effects")
let optVolumeInterface = soundOption(loc("options/volume_interface"), "interface")
let optVolumeMusic = soundOption(loc("options/volume_music"), "music")
let optVolumeDialogs = soundOption(loc("options/volume_dialogs"), "voices")
let optVolumeGuns = soundOption(loc("options/volume_guns"), "weapon")

let optOutputDevice = optionCtor({
  name = loc("options/sound_device_out")
  tab = "Sound"
  widgetCtor = optionSpinner
  blkPath = "sound/output_device"
  isAvailableWatched = Computed(@() is_pc && soundOutputDevicesList.value.len() > 0)
  changeVarOnListUpdate = false
  var = soundOutputDevice
  setValue = soundOutputDeviceUpdate
  available = soundOutputDevicesList
  valToString = @(v) v?.name ?? ""
  isEqual = @(a,b) (a?.name ?? "")==(b?.name ?? "")
})

return {
  optVolumeMaster
  optVolumeAmbient
  optVolumeSfx
  optVolumeInterface
  optVolumeMusic
  optVolumeDialogs
  optVolumeGuns
  soundOptions = [
    optOutputDevice,
    optVolumeMaster, optVolumeAmbient, optVolumeSfx,
    optVolumeInterface, optVolumeMusic, optVolumeDialogs, optVolumeGuns,
    headshotSoundOption, battleMusicOption
  ]
}
