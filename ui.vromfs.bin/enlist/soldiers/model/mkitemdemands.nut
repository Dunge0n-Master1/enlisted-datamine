from "%enlSqGlob/ui_library.nut" import *

let { armies, curArmy } = require("state.nut")

let function getDemandsFromPool(pool, key, value) {
  let byKey = pool?[key] ?? {}
  pool[key] <- byKey
  let byValue = byKey?[value] ?? { [key] = value }
  byKey[value] <- byValue
  return byValue
}

// Caveat: This method will only work correctly for items demands check of the currently selected army
local function mkItemListDemands(items) {
  if (typeof items != "array")
    items = [items]
  let demandsPool = {}
  return Computed(function() {
    let armyId = curArmy.value
    let armyLevel = armies.value?[armyId].level ?? 0
    return items.map(function(item) {
      let { unlocklevel = 0 } = item
      if (!(item?.isShopItem ?? false))
        return { item }
      if (unlocklevel > 0 && unlocklevel > armyLevel)
        return {
          item
          demands = getDemandsFromPool(demandsPool, "levelLimit", unlocklevel)
        }
      return {
        item
        demands = getDemandsFromPool(demandsPool, "canObtainInShop", unlocklevel >= 0)
      }
    })
  })
}

let function mkItemDemands(item) {
  let demands = mkItemListDemands(item)
  return Computed(@() demands.value?[0].demands)
}

return {
  mkItemDemands
  mkItemListDemands
}