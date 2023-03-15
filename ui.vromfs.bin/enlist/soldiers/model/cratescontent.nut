from "%enlSqGlob/ui_library.nut" import *

let armyEffects = require("armyEffects.nut")
let { curArmy } = require("%enlist/soldiers/model/state.nut")
let { get_crates_content } = require("%enlist/meta/clientApi.nut")
let { metaGen } = require("%enlist/meta/metaConfigUpdater.nut")
let { configs } = require("%enlist/meta/configs.nut")
let { trimUpgradeSuffix, templateLevel } = require("%enlSqGlob/ui/itemsInfo.nut")
let { shopItems } = require("%enlist/shop/shopItems.nut")

let requestedCratesContent = Watched({})
let requested = {}

let getArmiesLevels = @(effects) effects.map(@(a) a.army_level)
local requestedArmyLevels = getArmiesLevels(armyEffects.value)

let function requestCratesContent(armyId, crates) {
  if ((armyId ?? "") == "")
    return
  let armyCrates = requestedCratesContent.value?[armyId]
  if (armyId not in requested)
    requested[armyId] <- {}
  let armyRequested = requested[armyId]
  let toRequest = crates.filter(@(c) c not in armyCrates && c not in armyRequested)
  if (toRequest.len() == 0)
    return
  toRequest.each(@(c) armyRequested[c] <- true)
  get_crates_content(armyId, toRequest, function(res) {
    toRequest.each(function(c) { if (c in armyRequested) delete armyRequested[c] })
    if ("content" in res)
      requestedCratesContent.mutate(@(cc) cc[armyId] <- (cc?[armyId] ?? {}).__merge(res.content))
  })
}

armyEffects.subscribe(function(effects) {
  let levels = getArmiesLevels(effects)
  if (isEqual(levels, requestedArmyLevels))
    return

  let armyId = curArmy.value
  let curCrates = requestedCratesContent.value?[armyId] ?? {}
  requestedArmyLevels = levels
  requestedCratesContent({})

  if (armyId != null && curCrates.len() > 0)
    requestCratesContent(armyId, curCrates.keys())
})
metaGen.subscribe(@(_) requestedCratesContent({}))

let function getCrateContentComp(armyId, crateId) {
  requestCratesContent(armyId, [crateId])
  let res = Computed(@() requestedCratesContent.value?[armyId][crateId])
  res.subscribe(function(r) {
    if (r == null)
      requestCratesContent(armyId, [crateId])
  })
  return res
}


let function removeCrateContent(cratesData) {
  requestedCratesContent.mutate(function(cc) {
    foreach (crateData in cratesData) {
      let { armyId, id } = crateData
      if (id in cc?[armyId])
        delete cc[armyId][id]
    }
  })
}


let function getShopItemsIds(items) {
  let itemsInfo = items.reduce(function(res, s) {
    if (s?.crates != null)
      s.crates.each(function(v) {
        let { armyId, id } = v
        if (armyId not in res)
          res[armyId] <- []
        res[armyId].append(id)
      })
    return res
  }, {})
  return itemsInfo
}

let itemToShopItem = Computed(function(){
  let res = {}
  let allCrates = configs.value?.all_crates
  shopItems.value.each(function(shopItem, shopItemId){
    let crates = shopItem?.crates ?? []
    crates.each(function(crate){
      let {armyId, id} = crate
      local itemsInCrate = allCrates[armyId][id]
      if (armyId not in res)
        res[armyId] <- {}

      local allKeys = {}
      foreach(item in itemsInCrate){
        allKeys[trimUpgradeSuffix(item)] <- true
      }

      itemsInCrate.each(function(item){
        if (item not in res[armyId])
          res[armyId][item] <- {}
        res[armyId][item][shopItemId] <- allKeys.len()
      })
    })
  })

  res.each(function(armyItems, armyId){
    armyItems.each(function(item, itemId){
      res[armyId][itemId] = item.keys().sort(@(a, b) item[a] <=> item[b])
    })
  })

  return res
})


let function getShopListForItem(tpl, armyId, itemsToShopItems, allItemTemplates){
  let res = itemsToShopItems?[armyId][tpl] ?? []
  if (res.len() > 0)
    return res

  for (local i=1; i<4; i++){
    let upgraded = templateLevel(tpl, i)
    if (upgraded not in allItemTemplates?[armyId])
      return []
    let upShopItems = itemsToShopItems?[armyId][upgraded]
    if (upShopItems != null){
      return upShopItems
    }
  }

  return []
}

return {
  getCrateContentComp
  getShopListForItem
  removeCrateContent
  requestCratesContent
  requestedCratesContent
  getShopItemsIds
  itemToShopItem
}
