from "frp" import Computed

let { is_xbox, is_sony } = require("%dngscripts/platform.nut")
let sharedWatched = require("%dngscripts/sharedWatched.nut")
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
let savedCrossnetworkState  = sharedWatched("crossnetworkState", @() get_setting_by_blk_path(savedCrossnetworkPlayId) ?? CrossplayState.ALL)

const savedCrossnetworkChatId = "gameplay/crossnetworkChat"
let savedCrossnetworkChatState  = sharedWatched("savedCrossnetworkChatState", @() get_setting_by_blk_path(savedCrossnetworkChatId) ?? true)

let xboxCrossplayAvailable = sharedWatched("xboxCrossplayAvailable", @() false)
let xboxCrosschatAvailable = sharedWatched("xboxCrosschatAvailable", @() false)
let xboxMultiplayerAvailable = sharedWatched("xboxMultiplayerAvailable", @() true)

let xboxCrossChatWithFriendsAllowed = sharedWatched("xboxCrossChatWithFriendsAllowed", @() true)
let xboxCrossChatWithAllAllowed = sharedWatched("xboxCrossChatWithAllAllowed", @() true)
let xboxCrossVoiceWithFriendsAllowed = sharedWatched("xboxCrossVoiceWithFriendsAllowed", @() true)
let xboxCrossVoiceWithAllAllowed = sharedWatched("xboxCrossVoiceWithAllAllowed", @() true)

let crossplayOptionNeededByProject = sharedWatched("crossplayOptionNeededByProject", @() is_xbox || is_sony)
let isCrossplayOptConsolesOnlyRequired = sharedWatched("isCrossplayOptConsolesOnlyRequired", @() true)
let isCrossplayOptionNeeded = Computed(@() crossplayOptionNeededByProject.value || isDebugCrossplay)

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
  && crossnetworkPlay.value != CrossplayState.OFF
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
  savedCrossnetworkState
  xboxCrossplayAvailable
  crossnetworkPlay
  needShowCrossnetworkPlayIcon = is_xbox
  CrossplayState
  xboxCrosschatAvailable
  crossnetworkChat
  savedCrossnetworkChatId
  savedCrossnetworkChatState
  CrossPlayStateWeight
  isCrossnetworkChatAvailable
  availableCrossplayOptions
  isCrossplayOptionNeeded
  isCrossnetworkChatOptionNeeded
  xboxMultiplayerAvailable
  multiplayerAvailable
  xboxCrossChatWithFriendsAllowed
  xboxCrossChatWithAllAllowed
  xboxCrossVoiceWithFriendsAllowed
  xboxCrossVoiceWithAllAllowed
  canCrossnetworkChatWithAll
  canCrossnetworkChatWithFriends
  canCrossnetworkVoiceWithAll
  canCrossnetworkVoiceWithFriends
  isCrossplayOptConsolesOnlyRequired
  crossplayOptionNeededByProject
}