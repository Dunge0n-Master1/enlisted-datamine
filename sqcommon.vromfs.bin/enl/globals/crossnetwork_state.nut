from "frp" import Computed, Watched

let { is_xbox, is_sony } = require("%dngscripts/platform.nut")
let { globalWatched } = require("%dngscripts/globalState.nut")
let { get_setting_by_blk_path } = require("settings")

let isCrossnetworkChatAvailable = true
let isCrossnetworkChatOptionNeeded = !is_xbox //No option on xbox platform. setting is from system
let isDebugCrossplay = false

enum CrossplayState {
  OFF = "off"
  CONSOLES = "consoles"
  ALL = "all"
}

let CrossPlayStateWeight = {
  [CrossplayState.OFF] = 0,
  [CrossplayState.CONSOLES] = 1,
  [CrossplayState.ALL] = 2
}

const savedCrossnetworkPlayId = "gameplay/crossnetworkPlay"
let {savedCrossnetworkState, savedCrossnetworkStateUpdate} = globalWatched("savedCrossnetworkState", @() get_setting_by_blk_path(savedCrossnetworkPlayId) ?? CrossplayState.ALL)

const savedCrossnetworkChatId = "gameplay/crossnetworkChat"
let {savedCrossnetworkChatState, savedCrossnetworkChatStateUpdate}  = globalWatched("savedCrossnetworkChatState", @() get_setting_by_blk_path(savedCrossnetworkChatId) ?? true)

let {xboxCrossplayAvailable, xboxCrossplayAvailableUpdate} = globalWatched("xboxCrossplayAvailable", @() false)
let {xboxCrosschatAvailable, xboxCrosschatAvailableUpdate} = globalWatched("xboxCrosschatAvailable", @() false)
let {xboxMultiplayerAvailable, xboxMultiplayerAvailableUpdate} = globalWatched("xboxMultiplayerAvailable", @() true)

let {xboxCrossChatWithFriendsAllowed, xboxCrossChatWithFriendsAllowedUpdate} = globalWatched("xboxCrossChatWithFriendsAllowed", @() true)
let {xboxCrossChatWithAllAllowed, xboxCrossChatWithAllAllowedUpdate} = globalWatched("xboxCrossChatWithAllAllowed", @() true)
let {xboxCrossVoiceWithFriendsAllowed, xboxCrossVoiceWithFriendsAllowedUpdate} = globalWatched("xboxCrossVoiceWithFriendsAllowed", @() true)
let {xboxCrossVoiceWithAllAllowed, xboxCrossVoiceWithAllAllowedUpdate} = globalWatched("xboxCrossVoiceWithAllAllowed", @() true)

let crossplayOptionNeededByProject = is_xbox || is_sony
let isCrossplayOptConsolesOnlyRequired = Watched(true)
let isCrossplayOptionNeeded = Watched(crossplayOptionNeededByProject || isDebugCrossplay)

let availableCrossplayOptions = Computed(function() {
  if (is_xbox) //We are displaying limited options list on xbox
    return !xboxCrossplayAvailable.value ? [ CrossplayState.OFF ]
      : isCrossplayOptConsolesOnlyRequired.value ? [ CrossplayState.CONSOLES, CrossplayState.ALL ]
      : [ CrossplayState.ALL ]

  if (!isCrossplayOptionNeeded.value) //Just in case, so option could be readed correctly on PC for example
    return [ CrossplayState.ALL ]

  if (!isCrossplayOptConsolesOnlyRequired.value) //Not all projects have all platforms of players
    return [ CrossplayState.OFF, CrossplayState.ALL ]

  return [ CrossplayState.OFF, CrossplayState.CONSOLES, CrossplayState.ALL ]
})

let validateCsState = @(state, available) available.contains(state) ? state : available?.top() ?? CrossplayState.ALL

let multiplayerAvailable = Computed(@() xboxMultiplayerAvailable.value)
local crossnetworkPlay = null
local crossnetworkChat = null

if (is_xbox) {
  crossnetworkPlay = Computed(@() xboxCrossplayAvailable.value
    ? validateCsState(savedCrossnetworkState.value, availableCrossplayOptions.value)
    : CrossplayState.OFF)

  crossnetworkChat = Computed(@() xboxCrosschatAvailable.value)
}
else if (is_sony || isDebugCrossplay) {
  crossnetworkPlay = Computed(@() validateCsState(savedCrossnetworkState.value, availableCrossplayOptions.value))
  crossnetworkChat = Computed(@() savedCrossnetworkChatState.value ?? false)
}
else {
  crossnetworkPlay = Computed(@() CrossplayState.ALL)
  crossnetworkChat = Computed(@() isCrossnetworkChatAvailable)
}

let isCrossnetworkIntercationAvailable = Computed(@()
  isCrossnetworkChatAvailable
  && multiplayerAvailable.value
  && crossnetworkChat.value)

let canCrossnetworkChatWithAll = Computed(@()
  isCrossnetworkIntercationAvailable.value
  && xboxCrossChatWithAllAllowed.value)

let canCrossnetworkChatWithFriends = Computed(@()
  isCrossnetworkIntercationAvailable.value
  && xboxCrossChatWithFriendsAllowed.value)

let canCrossnetworkVoiceWithAll = Computed(@()
  isCrossnetworkIntercationAvailable.value
  && xboxCrossVoiceWithAllAllowed.value)

let canCrossnetworkVoiceWithFriends = Computed(@()
  isCrossnetworkIntercationAvailable.value
  && xboxCrossVoiceWithFriendsAllowed.value)

return {
  savedCrossnetworkPlayId
  savedCrossnetworkState, savedCrossnetworkStateUpdate
  xboxCrossplayAvailable, xboxCrossplayAvailableUpdate
  crossnetworkPlay
  needShowCrossnetworkPlayIcon = is_xbox
  CrossplayState
  xboxCrosschatAvailable, xboxCrosschatAvailableUpdate
  crossnetworkChat
  savedCrossnetworkChatId
  savedCrossnetworkChatState, savedCrossnetworkChatStateUpdate
  CrossPlayStateWeight
  isCrossnetworkChatAvailable
  availableCrossplayOptions
  isCrossplayOptionNeeded
  isCrossnetworkChatOptionNeeded
  xboxMultiplayerAvailable, xboxMultiplayerAvailableUpdate
  multiplayerAvailable
  xboxCrossChatWithFriendsAllowed, xboxCrossChatWithFriendsAllowedUpdate,
  xboxCrossChatWithAllAllowed, xboxCrossChatWithAllAllowedUpdate,
  xboxCrossVoiceWithFriendsAllowed, xboxCrossVoiceWithFriendsAllowedUpdate,
  xboxCrossVoiceWithAllAllowed, xboxCrossVoiceWithAllAllowedUpdate,
  canCrossnetworkChatWithAll
  canCrossnetworkChatWithFriends
  canCrossnetworkVoiceWithAll
  canCrossnetworkVoiceWithFriends
}