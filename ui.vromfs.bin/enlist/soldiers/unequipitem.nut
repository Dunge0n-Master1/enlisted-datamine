from "%enlSqGlob/ui_library.nut" import *

let { getLinksByType } = require("%enlSqGlob/ui/metalink.nut")
let {
  getDemandingSlots, getDemandingSlotsInfo, objInfoByGuid
} = require("%enlist/soldiers/model/state.nut")
let { equipItem } = require("%enlist/soldiers/model/itemActions.nut")
let popupsState = require("%enlist/popup/popupsState.nut")
let { campItemsByLink } = require("%enlist/meta/profile.nut")


let function unequip(slotType, slotId, ownerGuid) {
  let listByDemands = getDemandingSlots(ownerGuid, slotType,
    objInfoByGuid.value?[ownerGuid], campItemsByLink.value)
  if (listByDemands.len() > 0) {
    let equippedCount = listByDemands.filter(@(item) item != null).len()
    if (equippedCount <= 1) {
      let demandingInfo = getDemandingSlotsInfo(ownerGuid, slotType)
      if ((demandingInfo ?? "").len() > 0)
        return popupsState.addPopup({
          id = "unequip_item_error"
          text = demandingInfo
          styleName = "error"
        })
    }
  }
  equipItem(null, slotType, slotId, ownerGuid)
}

let function unequipBySlot(slotData) {
  let { slotType, slotId, ownerGuid } = slotData
  unequip(slotType, slotId, ownerGuid)
}

let function unequipItem(data) {
  let { item = null, slotType = null, slotId = null, soldierGuid = null } = data
  if (item == null || slotType == null)
    return
  let ownerGuid = soldierGuid ?? getLinksByType(item, slotType)?[0]
  if (!ownerGuid)
    return
  unequip(slotType, slotId, ownerGuid)
}

return {
  unequip
  unequipBySlot
  unequipItem
}