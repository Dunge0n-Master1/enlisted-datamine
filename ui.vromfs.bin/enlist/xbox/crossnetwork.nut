let cn = require("%xboxLib/impl/crossnetwork.nut")
let logX = require("%sqstd/log.nut")().with_prefix("[CROSSNET] ")
let {voiceChatRestricted} = require("%enlSqGlob/voiceChatGlobalState.nut")

let { xboxCrossplayAvailable, xboxCrosschatAvailable, xboxMultiplayerAvailable,
  xboxCrossChatWithFriendsAllowed, xboxCrossChatWithAllAllowed,
  xboxCrossVoiceWithFriendsAllowed, xboxCrossVoiceWithAllAllowed
} = require("%enlSqGlob/crossnetwork_state.nut")


let function on_text_chat_permission_result(success, state) {
  logX($"on_text_chat_permission_result: {success}, {state}")
  xboxCrossChatWithFriendsAllowed(success && (state == cn.CommunicationState.FriendsOnly
    || state == cn.CommunicationState.Allowed))
  xboxCrossChatWithAllAllowed(success && state == cn.CommunicationState.Allowed)
}


let function on_voice_chat_permission_result(success, state) {
  logX($"on_voice_chat_permission_result: {success}, {state}")
  xboxCrossVoiceWithFriendsAllowed(success && (state == cn.CommunicationState.FriendsOnly
    || state == cn.CommunicationState.Allowed))
  xboxCrossVoiceWithAllAllowed(success && state == cn.CommunicationState.Allowed)
}


let function on_crossnetwork_change(success) {
  logX($"on_crossnetwork_change: {success}")
  let communicationsAvailable = success && cn.has_communications_privilege()
  xboxCrossplayAvailable(success && cn.has_crossnetwork_privilege())
  xboxCrosschatAvailable(communicationsAvailable)
  voiceChatRestricted(!communicationsAvailable)
  xboxMultiplayerAvailable(success && cn.has_multiplayer_sessions_privilege())
  cn.retrieve_text_chat_permissions(0, on_text_chat_permission_result) //xuid 0 - external player
  cn.retrieve_voice_chat_permissions(0, on_voice_chat_permission_result) //xuid 0 - external player
}

cn.register_state_change_callback(on_crossnetwork_change)