from "%enlSqGlob/ui_library.nut" import *

let { settings } = require("%enlist/options/onlineSettings.nut")

const SEEN_ID = "seen/currencies"

let seenShopItems = Computed(@() settings.value?[SEEN_ID])

let function markShopItemSeen(armyId, shopItem) {
  if (!(seenShopItems.value?[shopItem] ?? false))
    settings.mutate(function(set) {
      let saved = clone (set?[SEEN_ID] ?? {})
      let armySaved = clone (saved?[armyId] ?? {})
      armySaved[shopItem] <- true
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
  excludeShopItemSeen
}
