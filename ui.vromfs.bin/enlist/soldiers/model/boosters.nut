from "%enlSqGlob/ui_library.nut" import *

let {
  itemsByArmies, commonArmy, activeBoosters, campaignsByArmy
} = require("%enlist/meta/profile.nut")
let { curArmy } = require("state.nut")
let serverTime = require("%enlSqGlob/userstats/serverTime.nut")


let globalBoost = "global"
let boostsTypes = ["army", "squad", "soldier"]

let isBooster = @(item) "bType" in item

let boosterItems = Computed(function() {
  let res = {}
  let curArmyId = curArmy.value
  foreach (armyId in [curArmyId, commonArmy.value])
    foreach (item in itemsByArmies.value?[armyId] ?? {})
      if (isBooster(item))
        res[item.guid] <- item
  return res
})

let allBoostersBase = Computed(function() {
  let aBoosters = activeBoosters.value
  let campByArmy = campaignsByArmy.value
  return boosterItems.value.values().map(function(item) {
    let { guid, bType, ctime, expMul = 0.0, battles = 0, lifeTime = 0, armyLimit = [] } = item
    let leftBattles = battles - (aBoosters?[item.guid].battles ?? 0)
    let expireTime = lifeTime > 0 ? ctime + lifeTime : 0
    let campaignLimit = {}
    foreach (armyId in armyLimit)
      if (armyId in campByArmy) {
        let army = campByArmy[armyId]
        campaignLimit[army.id] <- army
      }

    return {
      guid, bType, expMul, armyLimit, leftBattles, expireTime, battles, lifeTime, ctime,
      campaignLimit = campaignLimit.values()
    }
  })
})

let allBoosters = Watched([])
let nextExpireTime = Computed(@() allBoosters.value
  .reduce(@(res, b) b.expireTime <= 0 || (res > 0 && b.expireTime > res) ? res : b.expireTime, 0))

let function recalcActiveBosters() {
  let time = serverTime.value
  let allBaseBoosters = allBoostersBase.value
  let boosters = allBaseBoosters.filter(@(b) b.expireTime <= 0 || b.expireTime > time)
  allBoosters(boosters)

  // FIXME: This is for debug info. Should be removed
  log($"recalcActiveBosters time: {time}")
  foreach (b in allBaseBoosters) {
    let { guid, ctime, lifeTime, expireTime, battles, leftBattles } = b
    let isHidden = b.expireTime > 0 && b.expireTime < time
    log($"* time: {expireTime} = {ctime} + {lifeTime}, battles: {leftBattles}/{battles}, guid: {guid}{isHidden ? ", HIDDEN" : ""}")
  }
  log($"active {boosters.len()} boosters of {allBaseBoosters.len()}")
}
allBoosters.whiteListMutatorClosure(recalcActiveBosters)

nextExpireTime.subscribe(function(v) {
  let timeLeft = v - serverTime.value
  if (timeLeft > 0)
    gui_scene.resetTimeout(timeLeft, recalcActiveBosters)
})

recalcActiveBosters()
allBoostersBase.subscribe(@(_) recalcActiveBosters())

let curArmyBoosters = Computed(function() {
  let curArmyId = curArmy.value
  return allBoosters.value.filter(function(booster) {
    let { armyLimit } = booster
    return armyLimit.len() == 0 || armyLimit.contains(curArmyId)
  })
})

let curBoosts = Computed(function() {
  local res = {}
  boostsTypes.each(@(t) res[t] <- 0.0)
  foreach (booster in curArmyBoosters.value)
    if (booster.bType == globalBoost)
      res = res.map(@(t) t + booster.expMul)
    else if (booster.bType in res)
      res[booster.bType] += booster.expMul
  return res
})

return {
  boosterItems
  allBoostersBase
  globalBoost
  curArmyBoosters
  allBoosters
  curBoosts
  nextExpireTime
  isBooster
}
