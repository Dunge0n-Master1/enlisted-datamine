from "%enlSqGlob/ui_library.nut" import *

let { itemsByArmies, commonArmy, activeBoosters, campaignsByArmy
} = require("%enlist/meta/profile.nut")
let { curArmy } = require("state.nut")
let serverTime = require("%enlSqGlob/userstats/serverTime.nut")

let isBooster = @(item) item?.itemtype == "booster"

let boosterItems = Computed(function() {
  let res = {}
  let curArmyId = curArmy.value
  let commonArmyId = commonArmy.value
  let armyItems = itemsByArmies.value

  foreach (armyId in [curArmyId, commonArmyId])
    foreach (item in (armyItems?[armyId] ?? {}))
      if (isBooster(item))
        res[item.guid] <- item
  return res
})

let allBoostersBase = Computed(function() {
  let aBoosters = activeBoosters.value
  let campByArmy = campaignsByArmy.value
  return boosterItems.value.values().map(function(item) {
    let { guid, ctime, expMul = 0.0, battles = 0, lifeTime = 0, armyLimit = [] } = item
    let leftBattles = battles - (aBoosters?[guid].battles ?? 0)
    let expireTime = lifeTime > 0 ? ctime + lifeTime : 0
    let campaignLimit = armyLimit.map(@(armyId) campByArmy?[armyId]).filter(@(s) s != null)

    return {
      guid, expMul, armyLimit, leftBattles, expireTime, battles, lifeTime, ctime, campaignLimit
    }
  })
})

let allBoosters = Watched([])
let nextExpireTime = Watched(0)

let countNextExpire = @(boosters) boosters
  .reduce(@(res, b) b.expireTime <= 0 || (res > 0 && b.expireTime > res) ? res : b.expireTime, 0)

let function recalcActiveBosters(_ = null) {
  let time = serverTime.value
  let boosters = allBoostersBase.value.filter(@(b) b.expireTime <= 0 || b.expireTime > time)
  let nextExpire = countNextExpire(boosters)
  let timeLeft = nextExpire - time
  if (timeLeft > 0)
    gui_scene.resetTimeout(timeLeft, recalcActiveBosters)
  allBoosters(boosters)
  nextExpireTime(nextExpire)
}
allBoosters.whiteListMutatorClosure(recalcActiveBosters)
nextExpireTime.whiteListMutatorClosure(recalcActiveBosters)

recalcActiveBosters()
allBoostersBase.subscribe(recalcActiveBosters)

let curArmyBoosters = Computed(function() {
  let curArmyId = curArmy.value
  return allBoosters.value.filter(function(booster) {
    let { armyLimit } = booster
    return armyLimit.len() == 0 || armyLimit.contains(curArmyId)
  })
})

return {
  boosterItems
  allBoostersBase
  curArmyBoosters
  allBoosters
  nextExpireTime
  isBooster
}
