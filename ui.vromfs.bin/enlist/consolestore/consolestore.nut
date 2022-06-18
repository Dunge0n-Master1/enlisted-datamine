from "%enlSqGlob/ui_library.nut" import *

let {
  is_sony,
  is_xbox
} = require("%dngscripts/platform.nut")

let { logerr } = require("dagor.debug")

local openConsumable = @() logerr("[Console Store][Consumable] Not supported platform")
local openBundles = @() logerr("[Console Store][Bundles] Not supported platform")
local openBundle = @(id) logerr($"[Console Store][Bundle] Not supported platform {id}")

if (is_xbox) {
  let store = require("%enlist/consoleStore/consoleStoreXbox.nut")
  openConsumable = @() store.show_marketplace(store.PKConsumable)
  openBundles = @() store.show_marketplace(store.PKDurable)
  openBundle = @(id) store.show_details(id)
}
else if (is_sony) {
  let store = require("%enlist/consoleStore/consoleStorePsn.nut")
  openConsumable = @() store.show_category("ENLISTEDGOLD")
  openBundles = @() store.show_category("ENLISTEDSQUADS")
  openBundle = @(id) store.show_pack_by_id(id)
}

return {
  openConsumable
  openBundles
  openBundle
}