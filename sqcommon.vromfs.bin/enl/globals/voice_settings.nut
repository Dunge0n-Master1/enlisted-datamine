let {get_setting_by_blk_path} = require("settings")
let platform = require("%dngscripts/platform.nut")
let {globalWatched} = require("%dngscripts/globalState.nut")

let voice_modes = {
  on = "on"
  off = "off"
  micOff = "micOff"
}

let voice_activation_modes = {
  toggle = "toggle"
  pushToTalk = "pushToTalk"
  always = "always"
}

let validateMode = @(mode, list, defValue) mode in list ? mode : defValue

let {voiceRecordVolume, voiceRecordVolumeUpdate} = globalWatched("voiceRecordVolume", @() clamp(get_setting_by_blk_path("voice/record_volume") ?? 1.0, 0.0, 1.0))
let {voicePlaybackVolume, voicePlaybackVolumeUpdate} = globalWatched("voicePlaybackVolume", @() clamp(get_setting_by_blk_path("voice/playback_volume") ?? 1.0, 0.0, 1.0))
let {voiceRecordingEnable, voiceRecordingEnableUpdate} = globalWatched("voiceRecordingEnable", @() false)
let {voiceRecordingEnabledGeneration, voiceRecordingEnabledGenerationUpdate} = globalWatched("voiceRecordingEnabledGeneration", @() 0)
let {voiceChatMode, voiceChatModeUpdate} = globalWatched("voiceChatMode", @() validateMode(get_setting_by_blk_path("voice/mode"), voice_modes, platform.is_nswitch ? voice_modes.off : voice_modes.on))
let {voiceActivationMode, voiceActivationModeUpdate} = globalWatched("voiceActivationMode", @() validateMode(get_setting_by_blk_path("voice/activation_mode"),
    voice_activation_modes,
    platform.is_pc ? voice_activation_modes.toggle : voice_activation_modes.always)
)

let function setRecordingEnabled(val) {
  voiceRecordingEnableUpdate(val)
  voiceRecordingEnabledGenerationUpdate(voiceRecordingEnabledGeneration.value+1)
}

return {
  voiceRecordVolume, voiceRecordVolumeUpdate,
  voicePlaybackVolume, voicePlaybackVolumeUpdate,
  voiceRecordingEnable, voiceRecordingEnableUpdate,
  voiceRecordingEnabledGeneration, voiceRecordingEnabledGenerationUpdate,
  voiceChatMode, voiceChatModeUpdate,
  voiceActivationMode, voiceActivationModeUpdate
  setRecordingEnabled
  voice_modes
  voice_activation_modes
}
