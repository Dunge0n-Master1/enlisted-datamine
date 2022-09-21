from "%enlSqGlob/ui_library.nut" import *

let eventbus = require("eventbus")
let voiceApi = require_optional("voiceApi")
let {voiceChatRestricted} = require("%enlSqGlob/voiceChatGlobalState.nut")
let {on_room_disconnect} = require("voiceState.nut")
let {soundRecordDevice} = require("%enlSqGlob/sound_state.nut")
let platform = require("%dngscripts/platform.nut")
let {voiceRecordingEnable, voiceRecordingEnabledGeneration,
  voiceRecordVolume, voiceActivationMode, voicePlaybackVolume, voiceChatMode,
  voice_modes, voice_activation_modes, setRecordingEnabled} = require("%enlSqGlob/voice_settings.nut")

if (voiceApi == null)
  return null

let {levelIsLoading, levelLoaded} = require("%enlSqGlob/levelState.nut")
let tempDisableVoice = platform.is_sony ? Computed(@() levelIsLoading.value || !levelLoaded.value) : Watched(false)

local function onVoiceChat(new_value) {
  if (voiceChatRestricted.value) {
    new_value = voice_modes.off
    log("Voice chat restriction is in effect")
  }

  log($"Voice chat mode changed to '{new_value}'")
  if (new_value == voice_modes.off) {
    voiceApi.enable_mic(false)
    voiceApi.enable_voice(false)
    eventbus.send("voice.reset_speaking", null)
  } else if (new_value == voice_modes.micOff) {
    voiceApi.enable_mic(false)
    voiceApi.enable_voice(true)
  } else if (new_value == voice_modes.on) {
    voiceApi.enable_mic(true)
    voiceApi.enable_voice(true)
  } else {
    log("Wrong value set for voiceChatMode: ", new_value)
  }
}

voiceChatRestricted.subscribe(@(_val) onVoiceChat(voiceChatMode.value))

tempDisableVoice.subscribe(function(val) {
  if (val) {
    onVoiceChat(voice_modes.off)
  }
  else {
    onVoiceChat(voiceChatMode.value)
  }
})

let voiceSettingsDescr = {
  [voiceRecordVolume] = @(val) voiceApi.set_record_volume(val),
  [voicePlaybackVolume] = @(val) voiceApi.set_playback_volume(val),
  [voiceRecordingEnable] = @(val) voiceApi.set_recording(val),
  [voiceChatMode] = onVoiceChat
}
// separate loops is essential. do not merge them into one
foreach (watched, handler in voiceSettingsDescr)
  handler(watched.value)
foreach (watched, handler in voiceSettingsDescr)
  watched.subscribe(handler)

let function recordDeviceHandler(...){
  let dev = soundRecordDevice.value
  voiceApi.set_record_device(dev?.id ?? -1)
  setRecordingEnabled(voiceRecordingEnable.value)
}
soundRecordDevice.subscribe(recordDeviceHandler)
recordDeviceHandler()


voiceRecordingEnabledGeneration.subscribe(@(...) voiceApi.set_recording(voiceRecordingEnable.value) )


eventbus.subscribe("voice.on_peer_stop_speaking", @(data) eventbus.send("voice.hide_speaking", data.name))
eventbus.subscribe("voice.on_peer_start_speaking",
  function(data) {
    if (voiceChatMode.value != voice_modes.off && !tempDisableVoice.value &&
      !voiceChatRestricted.value) {
      eventbus.send("voice.show_speaking", data.name)
    }
  })

eventbus.subscribe("voice.on_peer_left", @(data) eventbus.send("voice.hide_speaking", data.name))
eventbus.subscribe("voice.on_room_disconnect",
  function(data) {
    on_room_disconnect(data.uri)
    eventbus.send("voice.reset_speaking", null)
  })
eventbus.subscribe("voice.on_room_connect",
  function(data) {
    if (!data.success)
      return
    onVoiceChat(voiceChatMode.value)
    if (voiceActivationMode.value == voice_activation_modes.always)
      setRecordingEnabled(true)
    else
      setRecordingEnabled(voiceRecordingEnable.value)
  })

voiceActivationMode.subscribe(function(value) {
  if (value == voice_activation_modes.always)
    setRecordingEnabled(true)
})

let function voice_start_test() {
  voiceApi.join_echo_room()
  setRecordingEnabled(true)
}

let function voice_stop_test() {
  voiceApi.leave_echo_room()
  setRecordingEnabled(false)
}

let function mute_player(player_name) {
  voiceApi.mute_player_by_name(player_name)
}

let function unmute_player(player_name) {
  voiceApi.unmute_player_by_name(player_name)
}

console_register_command(voice_start_test, "voice.start_test")
console_register_command(voice_stop_test, "voice.stop_test")
console_register_command(mute_player, "voice.mute_player")
console_register_command(unmute_player, "voice.unmute_player")
