let {get_setting_by_blk_path} = require("settings")
let platform = require("%dngscripts/platform.nut")
let sharedWatched = require("%dngscripts/sharedWatched.nut")

let modes = {
  on = "on"
  off = "off"
  micOff = "micOff"
}

let activation_modes = {
  toggle = "toggle"
  pushToTalk = "pushToTalk"
  always = "always"
}

let validateMode = @(mode, list, defValue) mode in list ? mode : defValue

let settings = {
  recordVolume = clamp(get_setting_by_blk_path("voice/record_volume") ?? 1.0, 0.0, 1.0)
  playbackVolume = clamp(get_setting_by_blk_path("voice/playback_volume") ?? 1.0, 0.0, 1.0)
  recordingEnable = false
  recordingEnabledGeneration = 0
  chatMode = validateMode(get_setting_by_blk_path("voice/mode"), modes, platform.is_nswitch ? modes.off : modes.on)
  activationMode = validateMode(get_setting_by_blk_path("voice/activation_mode"),
    activation_modes,
    platform.is_pc ? activation_modes.toggle : activation_modes.always)
}.map(@(value, name) sharedWatched($"voiceState.{name}", @() value))

let function setRecordingEnabled(val){
  settings.recordingEnable(val)
  settings.recordingEnabledGeneration(settings.recordingEnabledGeneration.value+1)
}
return {
  settings
  setRecordingEnabled
  modes
  activation_modes
}
