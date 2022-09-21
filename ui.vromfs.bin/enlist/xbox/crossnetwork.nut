let {voiceChatRestrictedUpdate} = require("%enlSqGlob/voiceChatGlobalState.nut")

let { xboxCrossplayAvailableUpdate, xboxCrosschatAvailableUpdate, xboxMultiplayerAvailableUpdate,
  xboxCrossChatWithFriendsAllowedUpdate, xboxCrossChatWithAllAllowedUpdate,
  xboxCrossVoiceWithFriendsAllowedUpdate, xboxCrossVoiceWithAllAllowedUpdate
} = require("%enlSqGlob/crossnetwork_state.nut")

let { CommunicationState } = require("%xboxLib/impl/crossnetwork.nut")
let { multiplayerPrivilege, communicationsPrivilege, crossnetworkPrivilege,
  textWithAnonUser, voiceWithAnonUser } = require("%xboxLib/crossnetwork.nut")


multiplayerPrivilege.subscribe(function(v) {
  xboxMultiplayerAvailableUpdate(v)
})


communicationsPrivilege.subscribe(function(v) {
  xboxCrosschatAvailableUpdate(v)
  voiceChatRestrictedUpdate(!v)
})


crossnetworkPrivilege.subscribe(function(v) {
  xboxCrossplayAvailableUpdate(v)
})


textWithAnonUser.subscribe(function(v) {
  xboxCrossChatWithFriendsAllowedUpdate(
    v == CommunicationState.FriendsOnly || v == CommunicationState.Allowed
  )
  xboxCrossChatWithAllAllowedUpdate(v == CommunicationState.Allowed)
})


voiceWithAnonUser.subscribe(function(v) {
  xboxCrossVoiceWithFriendsAllowedUpdate(
    v == CommunicationState.FriendsOnly || v == CommunicationState.Allowed
  )
  xboxCrossVoiceWithAllAllowedUpdate(v == CommunicationState.Allowed)
})
