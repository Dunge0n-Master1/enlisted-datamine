from "%enlSqGlob/ui_library.nut" import *

let eventbus = require("eventbus")
let voiceApi = require_optional("voiceApi")
let voiceState = require("voiceState.nut")
let soundState = require("%enlSqGlob/sound_state.nut")
let platform = require("%dngscripts/platform.nut")
let sharedWatched = require("%dngscripts/sharedWatched.nut")
let {settings, modes, activation_modes, setRecordingEnabled} = require("%enlSqGlob/voice_settings.nut")

if (voiceApi == null)
  return null

let levelIsLoading = sharedWatched("levelIsLoading", @() false)
let levelLoaded = sharedWatched("levelLoaded", @() false)
let tempDisableVoice = platform.is_sony ? Computed(@() levelIsLoading.value || !levelLoaded.value) : Watched(false)

local function onVoiceChat(new_value) {
  if (voiceState.voiceChatRestricted.value) {
    new_value = modes.off
    log("Voice chat restriction is in effect")
  }

  log($"Voice chat mode changed to '{new_value}'")
  if (new_value == modes.off) {
    voiceApi.enable_mic(false)
    voiceApi.enable_voice(false)
    eventbus.send("voice.reset_speaking", null)
  } else if (new_value == modes.micOff) {
    voiceApi.enable_mic(false)
    voiceApi.enable_voice(true)
  } else if (new_value == modes.on) {
    voiceApi.enable_mic(true)
    voiceApi.enable_voice(true)
  } else {
    log("Wrong value set for voiceChatMode: ", new_value)
  }
}

voiceState.voiceChatRestricted.subscribe(@(_val) onVoiceChat(settings.chatMode.value))

tempDisableVoice.subscribe(function(val) {
  if (val) {
    onVoiceChat(modes.off)
  }
  else {
    onVoiceChat(settings.chatMode.value)
  }
})

let voiceSettingsDescr = {
  recordVolume = {handler = @(val) voiceApi.set_record_volume(val)}
  playbackVolume = {handler = @(val) voiceApi.set_playback_volume(val) }
  recordingEnable = {handler = @(val) voiceApi.set_recording(val) }
  chatMode = {handler=onVoiceChat}
}

let function recordDeviceHandler(...){
  let dev = soundState.recordDevice.value
  voiceApi.set_record_device(dev?.id ?? -1)
  setRecordingEnabled(settings.recordingEnable.value)
}
soundState.recordDevice.subscribe(recordDeviceHandler)
recordDeviceHandler()

foreach (k,v in voiceSettingsDescr)
  settings[k].subscribe(v.handler)

settings.recordingEnabledGeneration.subscribe(@(...) voiceApi.set_recording(settings.recordingEnable.value) )

// separate loops is essential. do not merge them into one
foreach (k,v in voiceSettingsDescr)
  v.handler(settings[k].value)

eventbus.subscribe("voice.on_peer_stop_speaking", @(data) eventbus.send("voice.hide_speaking", data.name))
eventbus.subscribe("voice.on_peer_start_speaking",
  function(data) {
    if (settings.chatMode.value != modes.off && !tempDisableVoice.value &&
      !voiceState.voiceChatRestricted.value) {
      eventbus.send("voice.show_speaking", data.name)
    }
  })

eventbus.subscribe("voice.on_peer_left", @(data) eventbus.send("voice.hide_speaking", data.name))
eventbus.subscribe("voice.on_room_disconnect",
  function(data) {
    voiceState.on_room_disconnect(data.uri)
    eventbus.send("voice.reset_speaking", null)
  })
eventbus.subscribe("voice.on_room_connect",
  function(data) {
    if (!data.success)
      return
    onVoiceChat(settings.chatMode.value)
    if (settings.activationMode.value == activation_modes.always)
      setRecordingEnabled(true)
    else
      setRecordingEnabled(settings.recordingEnable.value)
  })

settings.activationMode.subscribe(function(value) {
  if (value == activation_modes.always)
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
