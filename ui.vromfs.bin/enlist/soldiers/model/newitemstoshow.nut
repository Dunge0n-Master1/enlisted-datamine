from "%enlSqGlob/ui_library.nut" import *

let { mark_as_seen } = require("%enlist/meta/clientApi.nut")
let { configs } = require("%enlist/meta/configs.nut")
let { prepareItems, preferenceSort } = require("items_list_lib.nut")
let { curCampItems, objInfoByGuid } = require("state.nut")
let { profile, curCampSoldiers } = require("%enlist/meta/profile.nut")
let { collectSoldierData } = require("%enlist/soldiers/model/curSoldiersState.nut")
let { hasModalWindows } = require("%ui/components/modalWindows.nut")

let justPurchasedItems = mkWatched(persist, "justPurchasedItems", [])

let newItemsToShow = Computed(function() {
  if ("items_templates" not in configs.value)
    return null

  let itemsGuids = []
  foreach (guid, item in curCampItems.value)
    if (!(item?.wasSeen ?? true))
      itemsGuids.append(guid)

  let soldiersGuids = []
  foreach (guid, soldier in curCampSoldiers.value)
    if (!(soldier?.wasSeen ?? true))
      soldiersGuids.append(guid)

  let unseenGuids = [].extend(itemsGuids).extend(soldiersGuids)
  return unseenGuids.len() > 0
    ? {
        header = loc("battleRewardTitle")
        allItems = prepareItems(unseenGuids, objInfoByGuid.value)
          .sort(preferenceSort)
          .map(@(item) item?.itemtype == "soldier" ? collectSoldierData(item) : item)
        itemsGuids
        soldiersGuids
      }
    : null
})

let function markSeenGuids(objs, guids) {
  let res = clone objs
  foreach (guid in guids)
    if (guid in objs)
      res[guid] <- objs[guid].__merge({ wasSeen = true })
  return res
}

let isMarkSeenInProgress = Watched(false) //to ignore duplicate changes
let function markNewItemsSeen() {
  if (isMarkSeenInProgress.value || newItemsToShow.value == null)
    return

  let { itemsGuids, soldiersGuids } = newItemsToShow.value
  isMarkSeenInProgress(true)
  mark_as_seen(itemsGuids, soldiersGuids, @(_) isMarkSeenInProgress(false))

  //no need to wait for server answer to close this window
  profile.mutate(function(p) {
    p.soldiers <- markSeenGuids(p?.soldiers, soldiersGuids)
    p.items <- markSeenGuids(p?.items, itemsGuids)
  })
}

return {
  needNewItemsWindow = Computed(@() newItemsToShow.value != null && !hasModalWindows.value)
  newItemsToShow
  markNewItemsSeen
  justPurchasedItems
}
