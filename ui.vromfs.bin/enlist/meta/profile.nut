from "%enlSqGlob/ui_library.nut" import *

let servProfile = require("servProfile.nut")
let { items, soldiers, squads } = servProfile
let { getLinkedArmyName } = require("%enlSqGlob/ui/metalink.nut")
let { curCampaign } = require("curCampaign.nut")
let { gameProfile } = require("%enlist/soldiers/model/config/gameProfile.nut")
let { allItemTemplates } = require("%enlist/soldiers/model/all_items_templates.nut")

const NO_ARMY = "__no_army__"

let divideByArmies = @(objList) objList.reduce(function(res, obj, guid) {
  let armyId = getLinkedArmyName(obj) ?? NO_ARMY
  if (armyId not in res)
    res[armyId] <- {}
  res[armyId][guid] <- obj
  return res
}, {})

let applyTemplatesByArmies = @(objByArmies, templates) objByArmies.map(@(list, armyId)
  list.map(@(obj) (templates?[armyId][obj?.basetpl] ?? {}).__merge(obj)))

let verify = @(list) list.filter(@(obj) obj?.hasVerified ?? true)

let itemsByArmies = Computed(@()
  applyTemplatesByArmies(divideByArmies(items.value), allItemTemplates.value))

let soldiersByArmies = Computed(@()
  applyTemplatesByArmies(divideByArmies(verify(soldiers.value)), allItemTemplates.value))

let squadsByArmies = Computed(@() divideByArmies(verify(squads.value)))

let commonArmy = Computed(@() gameProfile.value?.commonArmy)

let curArmiesList = Computed(@()
  (gameProfile.value?.campaigns[curCampaign.value].armies ?? []).map(@(a) a.id))

let curArmiesListExt = Computed(function() {
  let armiesList = clone curArmiesList.value
  let commonArmyId = commonArmy.value
  if (commonArmyId != null)
    armiesList.append(commonArmyId)
  return armiesList
})

let campaignsByArmy = Computed(function() {
  let res = {}
  foreach (campaign in gameProfile.value?.campaigns ?? {})
    foreach (army in campaign?.armies ?? [])
      res[army.id] <- campaign
  return res
})

let function mergeArmiesObjs(objsByArmies, armiesList) {
  let res = {}
  foreach (armyId in armiesList)
    res.__update(objsByArmies?[armyId] ?? {})
  return res
}

let curCampItems = Computed(@() mergeArmiesObjs(itemsByArmies.value, curArmiesListExt.value))
let curCampSoldiers = Computed(@() mergeArmiesObjs(soldiersByArmies.value, curArmiesList.value))
let curCampSquads = Computed(@() mergeArmiesObjs(squadsByArmies.value, curArmiesList.value))

let linkIgnore = { army = true, index = true }
let function remapByLink(objList) {
  let res = {}
  foreach (obj in objList)
    foreach (to, linkType in obj.links)
      if (linkType not in linkIgnore) {
        if (to not in res)
          res[to] <- {}
        if (linkType not in res[to])
          res[to][linkType] <- []
        res[to][linkType].append(obj)
      }
  return res
}

let campItemsByLink = Computed(@() remapByLink(curCampItems.value))
let campSoldiersByLink = Computed(@() remapByLink(curCampSoldiers.value))

return servProfile.__merge({
  curArmiesList
  curArmiesListExt
  commonArmy
  itemsByArmies
  soldiersByArmies
  squadsByArmies
  curCampItems
  curCampSoldiers
  curCampSquads
  campItemsByLink
  campSoldiersByLink
  campaignsByArmy
})
