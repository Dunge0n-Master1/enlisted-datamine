from "%enlSqGlob/ui_library.nut" import *

let {
  upgrade_items_count, equip_item, swap_items, equip_by_list, dispose_items_count
} = require("%enlist/meta/clientApi.nut")

let isItemActionInProgress = Watched(false)

let mkActionCb = @(cb) function(res) {
  isItemActionInProgress(false)
  cb?(res)
}

let function upgradeItem(guidsTbl, spendItemGuids, cb = null) {
  if (isItemActionInProgress.value)
    return
  isItemActionInProgress(true)
  upgrade_items_count(guidsTbl, spendItemGuids, mkActionCb(cb))
}

let function equipItem(itemGuid, slotType, slotId, targetGuid) {
  if (isItemActionInProgress.value)
    return
  isItemActionInProgress(true)
  equip_item(targetGuid, itemGuid, slotType, slotId, mkActionCb(null))
}

let function swapItems(soldierGuid1, slotType1, slotId1, soldierGuid2, slotType2, slotId2){
  if (isItemActionInProgress.value)
    return
  isItemActionInProgress(true)
  swap_items(soldierGuid1, slotType1, slotId1, soldierGuid2, slotType2, slotId2, mkActionCb(null))
}

let function equipByList(sGuid, equipList, cb = null) {
  if (isItemActionInProgress.value)
    return
  isItemActionInProgress(true)
  equip_by_list(sGuid, equipList, mkActionCb(cb))
}

let function disposeItem(guidsTbl, cb = null) {
  if (isItemActionInProgress.value)
    return

  isItemActionInProgress(true)
  dispose_items_count(guidsTbl, mkActionCb(cb))
}

return {
  isItemActionInProgress
  upgradeItem
  equipItem
  swapItems
  equipByList
  disposeItem
}
