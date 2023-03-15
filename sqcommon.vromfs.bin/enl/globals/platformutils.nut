from "%enlSqGlob/ui_library.nut" import *
let { is_xbox, is_sony, is_pc } = require("%dngscripts/platform.nut")
let { endsWith, startsWith } = require("%sqstd/string.nut")
let { CrossplayState } = require("%enlSqGlob/crossnetwork_state.nut")

//FIXME: dirty hack, until we will receive platform of player
let consoleCompare = {
  xbox = {
    isFromPlatform = @(name) endsWith(name, "@live") || startsWith(name, "^")
    isPlatform = is_xbox
  }
  psn = {
    isFromPlatform = @(name) endsWith(name, "@psn") || startsWith(name, "*")
    isPlatform = is_sony
  }
}

let function isPlayerSuitableForContactsList(name, crossnetworkChatValue) {
  if (crossnetworkChatValue)
    return true

  foreach (p in consoleCompare)
    if (p.isFromPlatform(name))
      return false
  return true
}

let canInterractCrossPlatform = function(name, crossnetworkChatValue) {
  if (crossnetworkChatValue)
    return true

  foreach (p in consoleCompare)
    if (p.isFromPlatform(name))
      return p.isPlatform

  return is_pc //Everybody else
}

let function canInterractCrossPlatformByCrossplay(name, crossplayValue) {
  if (crossplayValue == CrossplayState.ALL)
    return true

  if (crossplayValue == CrossplayState.OFF)
    return canInterractCrossPlatform(name, false)

  // crossplayValue == CrossplayState.Console
  foreach (p in consoleCompare)
    if (p.isFromPlatform(name))
      return true

  return false
}

return {
  isPlayerSuitableForContactsList
  canInterractCrossPlatform
  consoleCompare
  canInterractCrossPlatformByCrossplay
}
