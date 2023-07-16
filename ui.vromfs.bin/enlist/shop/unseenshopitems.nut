from "%enlSqGlob/ui_library.nut" import *

let { settings } = require("%enlist/options/onlineSettings.nut")

const OLD_SEEN_ID = "seen/currencies"
const SEEN_ID = "seen/shopItems"

enum SeenMarks {
  NOT_SEEN = 0
  OPENED = 1
  SEEN = 2
}

let seenData = Computed(@() settings.value?[SEEN_ID] ?? {})

let function applyCompatibility() {
  if (OLD_SEEN_ID not in settings.value)
    return

  let seenOld = settings.value[OLD_SEEN_ID]
  let res = {}
  foreach (armyId, armySeenData in seenOld) {
    if (type(armySeenData) != "table")
      continue

    res[armyId] <- {}
    foreach (itemId, armySaved in armySeenData) {
      let newArmySaved = type(armySaved) == "bool" ? SeenMarks.SEEN
        : type(armySaved) == "integer" ? armySaved
        : null
      if (newArmySaved != null)
        res[armyId][itemId] <- newArmySaved
    }
  }
  settings.mutate(function(set) {
    set[SEEN_ID] <- res
    delete set[OLD_SEEN_ID]
  })
}

// compatibility from 03/08/2022
settings.subscribe(function(v) {
  if (OLD_SEEN_ID in v)
    gui_scene.resetTimeout(0.1, applyCompatibility)
})

let getSeenStatus = @(val) val == null ? SeenMarks.NOT_SEEN : val

let seenShopItems = Computed(function() {
  let opened = {}
  let seen = {}
  foreach(armyId, armySeen in seenData.value)
    foreach(key, status in armySeen) {
      if (status != SeenMarks.NOT_SEEN) {
        if (armyId not in opened)
          opened[armyId] <- {}
        opened[armyId][key] <- true
      }
      if (status == SeenMarks.SEEN) {
        if (armyId not in seen)
          seen[armyId] <- {}
        seen[armyId][key] <- true
      }
    }
  return { opened, seen }
})

let function changeStatus(status, armyId, itemGuids) {
  let update = {}
  foreach (guid in typeof itemGuids == "array" ? itemGuids : [itemGuids])
    if (getSeenStatus(seenData.value?[armyId][guid]) != status)
      update[guid] <- status
  if (update.len() == 0)
    return

  settings.mutate(function(set) {
    let saved = clone set?[SEEN_ID] ?? {}
    let armySaved = clone saved?[armyId] ?? {}
    armySaved.__update(update)
    saved[armyId] <- armySaved
    set[SEEN_ID] <- saved
  })
}

let markShopItemSeen = @(armyId, itemGuids) changeStatus(SeenMarks.SEEN, armyId, itemGuids)

let markShopItemOpened = @(armyId, itemGuids) changeStatus(SeenMarks.OPENED, armyId, itemGuids)

let function excludeShopItemSeen(armyId, excludeList) {
  settings.mutate(function(set) {
    let saved = clone (set?[SEEN_ID] ?? {})
    let armySaved = clone (saved?[armyId] ?? {})
    saved[armyId] <- armySaved.filter(@(_, name) excludeList.findindex(@(v) v == name) == null)
    set[SEEN_ID] <- saved
  })
}

console_register_command(@() settings.mutate(@(s) SEEN_ID in s ? delete s[SEEN_ID] : null), "meta.resetSeenShopItems")

return {
  seenShopItems
  markShopItemSeen
  markShopItemOpened
  excludeShopItemSeen
  getSeenStatus
  SeenMarks
}
