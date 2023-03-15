from "%enlSqGlob/ui_library.nut" import *

let { get_setting_by_blk_path } = require("settings")
let { DBGLEVEL } = require("dagor.system")
let {nestWatched} = require("%dngscripts/globalState.nut")


let hasProfileCard = nestWatched("hasProfileCard", true)
let hasMedals = nestWatched("hasMedals", true)
let isItemTransferEnabled = nestWatched("isItemTransferEnabled", true)
let hasCustomGames = nestWatched("hasCustomGames", true)
let showEventsWidget = nestWatched("showEventsWidget", true)
let hasUserLogs = nestWatched("hasUserLogs", DBGLEVEL > 0)
let showModsInCustomRoomCreateWnd = nestWatched("showMods", true)
let hasVehicleCustomization = nestWatched( "hasVehicleCustomization", true)
let isOffersVisible = nestWatched("isOffersVisible", true)
let hasUsermail = nestWatched("hasUsermail", DBGLEVEL > 0)
let showReplayTabInProfile = nestWatched("showReplayTabInProfile", true)
let showUserProfile = nestWatched("showUserProfile", DBGLEVEL > 0)
let multyPurchaseAllowed = nestWatched("multyPurchaseAllowed", DBGLEVEL > 0)
let PSNAllowShowQRCodeStore = nestWatched("PSNAllowShowQRCodeStore", false)
let canRentSquad = nestWatched("canRentSquad", false)
let hasMassVehDecorPaste = nestWatched("hasMassVehDecorPaste", true)
let hasCampaignPromo = nestWatched("hasCampaignPromo", false)
let allowReconnect = nestWatched("allowReconnect", true)


let features = {
  hasProfileCard
  hasMedals
  hasUserLogs
  isItemTransferEnabled
  hasCustomGames
  showEventsWidget
  showModsInCustomRoomCreateWnd
  hasVehicleCustomization
  isOffersVisible
  hasUsermail
  showReplayTabInProfile
  showUserProfile
  multyPurchaseAllowed
  PSNAllowShowQRCodeStore
  canRentSquad
  hasMassVehDecorPaste
  hasCampaignPromo
  allowReconnect
}

foreach (featureId, featureFlag in features)
  featureFlag(get_setting_by_blk_path($"features/{featureId}") ?? featureFlag.value)

console_register_command(
  @(name) name in features ? console_print($"{name} = {features[name].value}") : console_print($"FEATURE NOT EXIST {name}"),
  "feature.has")

console_register_command(
  function(name) {
    if (name not in features)
      return console_print($"FEATURE NOT EXIST {name}")
    let feature = features[name]
    feature(!feature.value)
    console_print($"Feature {name} changed to {feature.value}")
  }
  "feature.toggle")

return freeze(features)