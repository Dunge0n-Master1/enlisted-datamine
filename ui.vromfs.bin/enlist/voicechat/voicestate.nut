from "%enlSqGlob/ui_library.nut" import *

let localSettings = require("%enlist/options/localSettings.nut")("voice/", false)
let {nestWatched} = require("%dngscripts/globalState.nut")
let {voiceChatEnabled} = require("%enlSqGlob/voiceChatGlobalState.nut")
let voiceApi = require_optional("voiceApi")
let {voiceRecordVolume, voiceRecordVolumeUpdate,
  voiceChatMode, voiceChatModeUpdate,
  voicePlaybackVolume, voicePlaybackVolumeUpdate,
  voiceActivationMode, voiceActivationModeUpdate,
  voice_modes, voice_activation_modes} = require("%enlSqGlob/voice_settings.nut")
let { matchingCall } = require("%enlist/matchingClient.nut")

let initialized = nestWatched("initialized", false)
let joinedVoiceRooms = persist("joinedVoiceRooms", @() {})

let validation_tbl = {
  voiceChatMode = @(v) voice_modes?[v] ?? voiceChatMode.value
  voiceActivationMode = @(v) voice_activation_modes?[v] ?? voiceActivationMode.value
}

let validate_setting = @(key, val) validation_tbl?[key](val) ?? val

let function loadVoiceSettings() {
  log("loadVoiceSettings")
  let noop = { // warning disable: -declared-never-used
    voiceRecordVolume = [localSettings(voiceRecordVolume.value, "record_volume"), voiceRecordVolumeUpdate]
    voicePlaybackVolume = [localSettings(voicePlaybackVolume.value, "playback_volume"), voicePlaybackVolumeUpdate]
    voiceChatMode = [voiceChatEnabled.value ? localSettings(voiceChatMode.value, "mode") : Watched(voice_modes.off), voiceChatModeUpdate]
    voiceActivationMode = [localSettings(voiceActivationMode.value, "activation_mode"), voiceActivationModeUpdate]
  }.each(function(v, key) {
    let [watched, update] = v
    update(validate_setting(key, watched.value))
  })
}


if (!initialized.value && voiceApi != null) {
  loadVoiceSettings()
  initialized(true)
}

let function leave_voice_chat(voice_chat_id, cb = null) {
  if (voiceApi && voiceChatEnabled.value && voice_chat_id in joinedVoiceRooms) {
    matchingCall("mproxy.voice_leave_channel", function(_) { cb?() }, { channel = voice_chat_id })
    voiceApi.leave_room(joinedVoiceRooms[voice_chat_id]?.chanUri ?? "")
    delete joinedVoiceRooms[voice_chat_id]
  }
}

let function join_voice_chat(voice_chat_id) {
  log($"joining voice {voice_chat_id}")
  if (voiceApi && voiceChatEnabled.value && !(voice_chat_id in joinedVoiceRooms)) {
    matchingCall("mproxy.voice_join_channel",
                      function(response) {
                        debugTableData(response)
                        if (response.error == 0) {
                          if (!(voice_chat_id in joinedVoiceRooms))
                            return
                          let voiceToken = response?.token
                          let voiceChan = response?.channel
                          let voiceName = response?.name
                          if (voiceToken != null && voiceChan != null && voiceName != null) {
                            log($"join into voice chat as {voiceName} channel: {voiceChan} token: {voiceToken}")
                            voiceApi.join_room(voiceName, voiceToken, voiceChan)
                            joinedVoiceRooms[voice_chat_id].chanUri <- voiceChan
                            return
                          }
                        }
                        log($"failed to join voice channel {voice_chat_id}")
                      },
                      { channel = voice_chat_id })
    joinedVoiceRooms[voice_chat_id] <- {}
  }
}

// Reconnect on connection lost
let function on_room_disconnect(voice_chat_id) {
  if (voice_chat_id in joinedVoiceRooms) {
    log($"reconnect to voice room {voice_chat_id}")
    delete joinedVoiceRooms[voice_chat_id]
    join_voice_chat(voice_chat_id)
  }
}

return {
  leave_voice_chat
  join_voice_chat
  on_room_disconnect
}
