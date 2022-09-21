let {voiceActivationMode, voiceRecordingEnable, voice_activation_modes, setRecordingEnabled} = require("%enlSqGlob/voice_settings.nut")

return {
  eventHandlers = {
    ["VoiceChat.Record"] = function(_event) {
      if (voiceActivationMode.value == voice_activation_modes.pushToTalk)
        setRecordingEnabled(true)
      else if (voiceActivationMode.value == voice_activation_modes.toggle)
        setRecordingEnabled(!voiceRecordingEnable.value)
    },
    ["VoiceChat.Record:end"] = function(_event) {
      if (voiceActivationMode.value == voice_activation_modes.pushToTalk)
        setRecordingEnabled(false)
    }
  }
}
