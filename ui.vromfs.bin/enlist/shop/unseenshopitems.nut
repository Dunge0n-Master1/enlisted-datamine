from "%enlSqGlob/ui_library.nut" import *

let { settings } = require("%enlist/options/onlineSettings.nut")

const OLD_SEEN_ID = "seen/currencies"
const SEEN_ID = "seen/shopItems"

enum SeenMarks {
  NOT_SEEN = 0
  OPENED = 1
  SEEN = 2
}

let function applyCompatibility() {
  if (OLD_SEEN_ID not in settings.value)
    return

  let seenData = settings.value[OLD_SEEN_ID]
  let res = {}
  foreach (armyId, armySeenData in seenData) {
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
  let res = { opened = {}, seen = {} }
  foreach(armyId, armySeen in settings.value?[SEEN_ID] ?? {})
    foreach(key, seenData in armySeen) {
      if (getSeenStatus(seenData) != SeenMarks.NOT_SEEN) {
        if (armyId not in res.opened)
          res.opened[armyId] <- {}
        res.opened[armyId][key] <- true
      }
      if (getSeenStatus(seenData) == SeenMarks.SEEN) {
        if (armyId not in res.seen)
          res.seen[armyId] <- {}
        res.seen[armyId][key] <- true
      }
    }
  return res
})

let function markShopItemSeen(armyId, shopItem) {
  if (getSeenStatus(seenShopItems.value.seen?[armyId][shopItem]) != SeenMarks.SEEN)
    settings.mutate(function(set) {
      let saved = clone (set?[SEEN_ID] ?? {})
      let armySaved = clone (saved?[armyId] ?? {})
      armySaved[shopItem] <- SeenMarks.SEEN
      saved[armyId] <- armySaved
      set[SEEN_ID] <- saved
    })
}

let function markShopItemOpened(armyId, itemGuids) {
  if (itemGuids.len() > 0)
    settings.mutate(function(set) {
      let saved = clone (set?[SEEN_ID] ?? {})
      let armySaved = clone (saved?[armyId] ?? {})
      foreach(guid in itemGuids)
        armySaved[guid] <- SeenMarks.OPENED
      saved[armyId] <- armySaved
      set[SEEN_ID] <- saved
    })
}

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
