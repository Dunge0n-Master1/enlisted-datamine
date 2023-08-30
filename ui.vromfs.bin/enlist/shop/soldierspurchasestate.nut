from "%enlSqGlob/ui_library.nut" import *

let { curArmyShopItems, curUnseenAvailShopGuids } = require("%enlist/shop/armyShopState.nut")
let { getClassCfg, soldierClasses } = require("%enlSqGlob/ui/soldierClasses.nut")


const SOLDIER_GROUP = "soldier_silver_group"
const BATTLE_PASS_SOLDIER_GROUP = "soldier_battlepass_group"
let isSoldiersPurchasing = Watched(false)


let soldierShopItems = Computed(@() curArmyShopItems.value.filter(@(s)
  (s?.offerGroup == SOLDIER_GROUP || s?.offerGroup == BATTLE_PASS_SOLDIER_GROUP)))

let unseenSoldierShopItems = Computed(function() {
  let guids = {}
  foreach (shopItem in soldierShopItems.value)
    if (shopItem.guid in curUnseenAvailShopGuids.value)
      guids[shopItem.guid] <- true
  return guids
})

let function extractKinds(crateContent) {
  let classesList = crateContent?.content.soldierClasses ?? {}
  return classesList.len() == 0 ? null : classesList
    .map(@(sClass) getClassCfg(sClass).kind)
    .reduce(@(res, sKind) res.rawset(sKind, true), {})
    .keys()
}

let function getKindsList(itemsContent) {
  let res = []
  let kinds = {}
  foreach (content in itemsContent) {
    let sKindList = extractKinds(content) ?? []
    if (sKindList.len() != 1)
      continue

    let [ soldierKind ] = sKindList
    let { reqLevel } = content
    if (soldierKind in kinds)
      kinds[soldierKind].reqLvl = min(kinds[soldierKind].reqLvl, reqLevel)
    else {
      let sKindData = { soldierKind, reqLvl = reqLevel }
      kinds[soldierKind] <- sKindData
      res.append(sKindData)
    }
  }
  return res
}

let function getSoldiersList(cratesContent, sShopItems) {
  let classesArr = clone cratesContent
  let classes = classesArr
  let kindsToShow = getKindsList(classes)

  let soldiersToShow = sShopItems.reduce(function(res, content) {
    let soldierSpec = cratesContent.findvalue(@(crate)
      crate.shopItemId == content.id)?.content.soldierClasses[0]
    let soldierKind = soldierClasses?[soldierSpec].kind ?? ""
    res.append(content.__merge({ soldierSpec, soldierKind }))
    return res
  }, [])
    .sort(@(a, b) (b?.limit == 1) <=> (a?.limit == 1)
      || (soldierClasses?[a.soldierSpec].rank ?? 0) <=> (soldierClasses?[b.soldierSpec].rank ?? 0))

  return { kindsToShow, soldiersToShow }
}


return {
  soldierShopItems
  unseenSoldierShopItems
  getSoldiersList
  isSoldiersPurchasing
}
