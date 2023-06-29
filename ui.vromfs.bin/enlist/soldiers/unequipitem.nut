from "%enlSqGlob/ui_library.nut" import *

let { getLinksByType, getFirstLinkedObjectGuid, getLinkedSquadGuid
} = require("%enlSqGlob/ui/metalink.nut")
let { getDemandingSlots, getDemandingSlotsInfo, objInfoByGuid, getSoldierItemSlots
} = require("%enlist/soldiers/model/state.nut")
let { equipItem } = require("%enlist/soldiers/model/itemActions.nut")
let popupsState = require("%enlSqGlob/ui/popup/popupsState.nut")
let { campItemsByLink, squads, soldiers } = require("%enlist/meta/profile.nut")
let { isSquadRented } = require("model/squadInfoState.nut")
let { showRentedSquadLimitsBox } = require("%enlist/soldiers/components/squadsComps.nut")
let { curEquippedItem, selectParams } = require("model/selectItemState.nut")


let showUnequipImpossible = @(text) popupsState.addPopup({
  id = "unequip_item_error"
  text
  styleName = "error"
})


let canUnequip = Computed(function() {
  let item = curEquippedItem.value
  if (!item)
    return false

  let params = selectParams.value
  if (!params)
    return false


  let { ownerGuid, slotType } = params
  let owner = objInfoByGuid.value?[ownerGuid]
  let sList = soldiers.value
  let soldier = sList?[ownerGuid] ?? sList?[getFirstLinkedObjectGuid(owner, sList)]
  if (!soldier)
    return false


  let squadGuid = getLinkedSquadGuid(soldier)
  if (squadGuid != null && isSquadRented(squads.value?[squadGuid]))
    return false

  if (item?.isFixed)
    return false

  let demandingSlots = getDemandingSlots(ownerGuid, slotType, owner, campItemsByLink.value)
  if (demandingSlots.len() > 0) {
    let equippedCount = demandingSlots.reduce(@(res, v) v != null ? res + 1 : res, 0)
    if (equippedCount <= 1) {
      let demandingInfo = getDemandingSlotsInfo(ownerGuid, slotType)
      if (demandingInfo != "")
        return false
    }
  }

  return true
})


let function unequip(slotType, slotId, ownerGuid, cb = null) {
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

  let equippedItems = getSoldierItemSlots(ownerGuid, campItemsByLink.value)
  let { item = null } = equippedItems.findvalue(@(d) d.slotType == slotType && d.slotId == slotId)
  if (item?.isFixed ?? false) {
    showUnequipImpossible(loc($"equipDemand/deniedUnequipPremium"))
    return
  }

  let demandingSlots = getDemandingSlots(ownerGuid, slotType, owner, campItemsByLink.value)
  if (demandingSlots.len() > 0) {
    let equippedCount = demandingSlots.filter(@(item_) item_ != null).len()
    if (equippedCount <= 1) {
      let demandingInfo = getDemandingSlotsInfo(ownerGuid, slotType)
      if (demandingInfo != "") {
        showUnequipImpossible(demandingInfo)
        return
      }
    }
  }
  equipItem(null, slotType, slotId, ownerGuid, cb)
}

let function unequipBySlot(slotData, cb = null) {
  let { slotType, slotId, ownerGuid } = slotData
  unequip(slotType, slotId, ownerGuid, cb)
}

let function unequipItem(data, cb = null) {
  let { item = null, slotType = null, slotId = null, soldierGuid = null } = data
  if (item == null || slotType == null || item?.guid == null)
    return
  let ownerGuid = soldierGuid ?? getLinksByType(item, slotType)?[0]
  if (!ownerGuid)
    return
  unequip(slotType, slotId, ownerGuid, cb)
}

return {
  unequip
  unequipBySlot
  unequipItem
  canUnequip
}