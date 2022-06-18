let {settings, activation_modes, setRecordingEnabled} = require("%enlSqGlob/voice_settings.nut")
let {activationMode, recordingEnable} = settings

return {
  eventHandlers = {
    ["VoiceChat.Record"] = function(_event) {
      if (activationMode.value == activation_modes.pushToTalk)
        setRecordingEnabled(true)
      else if (activationMode.value == activation_modes.toggle)
        setRecordingEnabled(!recordingEnable.value)
    },
    ["VoiceChat.Record:end"] = function(_event) {
      if (activationMode.value == activation_modes.pushToTalk)
        setRecordingEnabled(false)
    }
  }
}
