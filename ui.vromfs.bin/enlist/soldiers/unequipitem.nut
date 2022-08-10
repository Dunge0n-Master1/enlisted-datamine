from "%enlSqGlob/ui_library.nut" import *

let {
  getLinksByType, getFirstLinkedObjectGuid, getLinkedSquadGuid
} = require("%enlSqGlob/ui/metalink.nut")
let {
  getDemandingSlots, getDemandingSlotsInfo, objInfoByGuid
} = require("%enlist/soldiers/model/state.nut")
let { equipItem } = require("%enlist/soldiers/model/itemActions.nut")
let popupsState = require("%enlist/popup/popupsState.nut")
let { campItemsByLink, squads, soldiers } = require("%enlist/meta/profile.nut")
let { isSquadRented } = require("model/squadInfoState.nut")
let { showRentedSquadLimitsBox } = require("%enlist/soldiers/components/squadsComps.nut")


let function unequip(slotType, slotId, ownerGuid) {
  let owner = objInfoByGuid.value?[ownerGuid]
  let sList = soldiers.value
  let soldier = sList?[ownerGuid] ?? sList?[getFirstLinkedObjectGuid(owner, sList)]
  if (soldier != null) {
    let squadGuid = getLinkedSquadGuid(soldier)
    if (squadGuid != null && isSquadRented(squads.value?[squadGuid])) {
      showRentedSquadLimitsBox()
      return
    }
  }

  let listByDemands = getDemandingSlots(ownerGuid, slotType, owner, campItemsByLink.value)
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