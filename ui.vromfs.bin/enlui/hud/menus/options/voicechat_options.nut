from "%enlSqGlob/ui_library.nut" import *

let {
  optionSpinner, optionCtor, optionPercentTextSliderCtor, mkDisableableCtor
} = require("options_lib.nut")
let platform = require("%dngscripts/platform.nut")
let voice = require("%enlSqGlob/voice_settings.nut")
let soundState = require("%enlSqGlob/sound_state.nut")
let voiceSettings = voice.settings
let voiceModes = voice.modes
let voiceActivationModes = voice.activation_modes
let {voiceChatEnabled, voiceChatRestricted} = require("%enlSqGlob/voiceChatGlobalState.nut")

let optPlaybackVolume = optionCtor({
  name = loc("voicechat/playback_volume")
  tab = "VoiceChat"
  widgetCtor = optionPercentTextSliderCtor
  blkPath = "voice/playback_volume"
  defVal = 1.0
  min = 0 max = 1 unit = 0.05 pageScroll = 0.05 mult = 100
  var = voiceSettings.playbackVolume
  originalVal = voiceSettings.playbackVolume.value
  restart = false
  isAvailable = @() voiceChatEnabled.value
})

let optMicVolume = optionCtor({
  name = loc("voicechat/mic_volume")
  tab = "VoiceChat"
  widgetCtor = optionPercentTextSliderCtor
  blkPath = "voice/record_volume"
  defVal = 1.0
  min = 0 max = 1 unit = 0.05 pageScroll = 0.05 mult = 100
  var = voiceSettings.recordVolume
  originalVal = voiceSettings.recordVolume.value
  restart = false
  isAvailable = @() voiceChatEnabled.value
})

let optMode = optionCtor({
  name = loc("voicechat/mode")
  tab = "VoiceChat"
  widgetCtor = mkDisableableCtor(
    Computed(@() voiceChatRestricted.value ? loc("voicechat/parental") : null),
    optionSpinner)
  blkPath = "voice/mode"
  defVal = voiceSettings.chatMode.value
  var = voiceSettings.chatMode
  originalVal = voiceSettings.chatMode.value
  restart = false
  available = voiceModes.keys()
  valToString = @(v) loc($"voicechat/{v}")
  isEqual = @(a,b) a==b
  isAvailable = @() voiceChatEnabled.value
})

let optActivationMode = optionCtor({
  name = loc("voicechat/activation_mode")
  tab = "VoiceChat"
  widgetCtor = optionSpinner
  blkPath = "voice/activation_mode"
  defVal = voiceSettings.activationMode.value
  var = voiceSettings.activationMode
  originalVal = voiceSettings.activationMode.value
  restart = false
  available = voiceActivationModes.keys()
  valToString = @(v) loc($"voicechat/{v}")
  isEqual = @(a,b) a==b
  isAvailable = @() voiceChatEnabled.value && platform.is_pc
})

let optRecordDevice = optionCtor({
  name = loc("voicechat/record_device")
  tab = "VoiceChat"
  widgetCtor = optionSpinner
  blkPath = "sound/record_device"
  isAvailableWatched = Computed(@() platform.is_pc && voiceChatEnabled.value &&
                    soundState.recordDevicesList.value.len() > 0)
  var = soundState.recordDevice
  available = soundState.recordDevicesList
  valToString = @(v) v?.name ?? ""
  isEqual = @(a,b) (a?.name ?? "")==(b?.name ?? "")
  changeVarOnListUpdate = false
})

return {
  optPlaybackVolume
  optRecordDevice
  optActivationMode
  optMode
  optMicVolume

  voiceChatOptions = [
    optPlaybackVolume, optRecordDevice, optActivationMode, optMode, optMicVolume
  ]
}
