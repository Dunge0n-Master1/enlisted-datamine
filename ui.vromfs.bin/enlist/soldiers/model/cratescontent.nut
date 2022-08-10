from "%enlSqGlob/ui_library.nut" import *

let armyEffects = require("armyEffects.nut")
let { curArmy } = require("%enlist/soldiers/model/state.nut")
let { get_crates_content } = require("%enlist/meta/clientApi.nut")
let { metaGen } = require("%enlist/meta/metaConfigUpdater.nut")

let cratesContent = Watched({})
let requested = {}

let getArmiesLevels = @(effects) effects.map(@(a) a.army_level)
local requestedArmyLevels = getArmiesLevels(armyEffects.value)

let function requestCratesContent(armyId, crates) {
  if ((armyId ?? "") == "")
    return
  let armyCrates = cratesContent.value?[armyId]
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
      cratesContent.mutate(@(cc) cc[armyId] <- (cc?[armyId] ?? {}).__merge(res.content))
  })
}

armyEffects.subscribe(function(effects) {
  let levels = getArmiesLevels(effects)
  if (isEqual(levels, requestedArmyLevels))
    return

  let armyId = curArmy.value
  let curCrates = cratesContent.value?[armyId] ?? {}
  requestedArmyLevels = levels
  cratesContent({})

  if (armyId != null && curCrates.len() > 0)
    requestCratesContent(armyId, curCrates.keys())
})
metaGen.subscribe(@(_) cratesContent({}))

let function getCrateContentComp(armyId, crateId) {
  requestCratesContent(armyId, [crateId])
  let res = Computed(@() cratesContent.value?[armyId][crateId])
  res.subscribe(function(r) {
    if (r == null)
      requestCratesContent(armyId, [crateId])
  })
  return res
}

//crateList = [{ armyId, id }] - same format as in the shop item.
//result computed = { <crateId> = { <armyId> = <content> } }
let function getCratesListComp(cratesListWatch) {
  let cratesByArmies = {}
  foreach (cfg in cratesListWatch.value) {
    let { id, armyId } = cfg
    if (armyId not in cratesByArmies)
      cratesByArmies[armyId] <- {}
    cratesByArmies[armyId][id] <- true
  }

  foreach (armyId, crates in cratesByArmies)
    requestCratesContent(armyId, crates.keys())

  return Computed(function() {
    let crates = {}
    foreach (cfg in cratesListWatch.value) {
      let { id, armyId } = cfg
      if (id not in crates)
        crates[id] <- {}
      crates[id][armyId] <- cratesContent.value?[armyId][id]
    }
    return crates
  })
}

return {
  getCrateContentComp
  getCratesListComp
}