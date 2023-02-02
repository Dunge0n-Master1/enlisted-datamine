from "%enlSqGlob/ui_library.nut" import *

let { get_setting_by_blk_path } = require("settings")
let { DBGLEVEL } = require("dagor.system")


let hasProfileCard = mkWatched(persist, "hasProfileCard", true)
let hasMedals = mkWatched(persist, "hasMedals", true)
let isItemTransferEnabled = mkWatched(persist, "isItemTransferEnabled", true)
let hasCustomGames = mkWatched(persist, "hasCustomGames", true)
let showEventsWidget = mkWatched(persist, "showEventsWidget", true)
let hasUserLogs = mkWatched(persist, "hasUserLogs", DBGLEVEL > 0)
let showModsInCustomRoomCreateWnd = mkWatched(persist, "showMods", true)
let hasVehicleCustomization = mkWatched(persist, "hasVehicleCustomization", true)
let isOffersVisible = mkWatched(persist, "isOffersVisible", true)
let hasUsermail = mkWatched(persist, "hasUsermail", DBGLEVEL > 0)
let showReplayTabInProfile = mkWatched(persist, "showReplayTabInProfile", true)
let showUserProfile = mkWatched(persist, "showUserProfile", DBGLEVEL > 0)
let multyPurchaseAllowed = mkWatched(persist, "multyPurchaseAllowed", DBGLEVEL > 0)
let PSNAllowShowQRCodeStore = mkWatched(persist, "PSNAllowShowQRCodeStore", false)
let canRentSquad = mkWatched(persist, "canRentSquad", false)
let hasMassVehDecorPaste = mkWatched(persist, "hasMassVehDecorPaste", false)
let hasCampaignPromo = mkWatched(persist, "hasCampaignPromo", false)
let hasGoToSquadbtn = mkWatched(persist, "hasGoToSquadbtn", false)


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
  hasGoToSquadbtn
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