from "%enlSqGlob/ui_library.nut" import *

let { getLinkedArmyName } = require("%enlSqGlob/ui/metalink.nut")
let { unlock_squad, buy_army_exp } = require("%enlist/meta/clientApi.nut")
let { receivedUnlocks } = require("%enlist/meta/profile.nut")
let { disabledSectionsData } = require("%enlist/mainMenu/disabledSections.nut")
let { armies, curCampSquads, curArmy, curArmyData, curUnlockedSquads, squadsByArmy
} = require("state.nut")
let { armyLevelsData, armiesUnlocks, hasLevelDiscount, curLevelDiscount
} = require("%enlist/campaigns/armiesConfig.nut")
let { curArmyShowcase } = require("%enlist/shop/armyShopState.nut")
let { shopItems } = require("%enlist/shop/shopItems.nut")
let { CAMPAIGN_NONE, isPurchaseableCampaign, isCampaignBought, needFreemiumStatus
} = require("%enlist/campaigns/campaignConfig.nut")
let { isSquadRented } = require("%enlist/soldiers/model/squadInfoState.nut")


let curUnlockedSquadId = Watched(null)
let isBuyLevelInProgress = Watched(false)
let needUpdateCampaignScroll = Watched(false)
let isArmyUnlocksStateVisible = Watched(false)
let squadUnlockInProgress = Watched(null)
let idxToForceScroll = Watched(null)

let uType = freeze({
  EMPTY = 0
  SQUAD = 1
  ITEM = 2
  SHOP = 3
})

let hasCampaignSection = Computed(@() !(disabledSectionsData.value?.CAMPAIGN ?? false))

let curUnlockedSquadsIds = Computed(@()
  curUnlockedSquads.value
    .filter(@(s) !isSquadRented (s))
    .reduce(@(res, s) res.rawset(s.squadId, true), {}))

let LEVEL_WIDTH = fsh(70)
let SHOWCASE_ITEM_WIDTH = LEVEL_WIDTH
let squadGap = hdpx(20)

let curArmyLevels = Computed(function() {
  let showcaseByLevel = curArmyShowcase.value
  local expTo = 0
  local posTo = 0.0
  local showcasePosTo = 0.0
  return armyLevelsData.value
    .map(function(levelData, idx) {
      let { exp = 0, levelCost = 0 } = levelData
      let expFrom = expTo
      expTo += exp
      let posFrom = posTo
      let showcaseAmount = (showcaseByLevel?[idx] ?? []).len()
      let showcasePosFrom = showcasePosTo
      showcasePosTo += showcaseAmount * SHOWCASE_ITEM_WIDTH
      if (exp > 0)
        posTo += 1.0
      return {
        level = idx
        posFrom = max(posFrom - 0.5, 0.0)
        posTo = max(posTo - 0.5, 0.0)
        expFrom = expFrom
        expTo = expTo
        expSize = exp
        levelCost
        showcase = {
          posFrom = showcasePosFrom
          posTo = showcasePosTo
        }
      }
    })
})

let curArmyLevelsSize = Computed(@()
  curArmyLevels.value.len() ? curArmyLevels.value.top().posTo + 0.5 : 0.0)

let curArmyShowcasesSize = Computed(@()
  curArmyLevels.value.len() ? curArmyLevels.value.top().showcase.posTo : 0.0)

let function getLevelDataByExp(exp, expGrid) {
  let res = {
    level = 1
    expToLevelRest = 0
    expToLevelTotal = 0
    exp = 0
  }
  local expTotal = 0
  foreach (lvl, levelData in expGrid) {
    expTotal += levelData.exp
    if (exp < expTotal) {
      res.expToLevelRest = expTotal - exp
      res.expToLevelTotal = levelData.exp
      res.exp = levelData.exp - expTotal + exp
      break
    }
    res.level = max(res.level, lvl + 1)
  }
  return res
}

let curArmyExp = Computed(@() curArmyData.value?.exp ?? 0)
let curArmyLevel = Computed(@() curArmyData.value?.level ?? 0)
let curBuyLevelData = Computed(function() {
  let levelData = armyLevelsData.value?[curArmyLevel.value]
  let levelExp = levelData?.exp ?? 0
  let levelCost = levelData?.levelCost ?? 0
  if (levelExp <= 0 || levelCost <= 0)
    return null

  let needExp = levelExp - curArmyExp.value
  if (needExp <= 0)
    return null

  let hasDiscount = hasLevelDiscount.value
  let discount = curLevelDiscount.value
  let cost = levelCost * needExp / levelExp
  return {
    needExp
    cost = max(cost - cost * discount / 100, 1)
    costFull = hasDiscount ? max(cost, 1) : null
    discount = hasDiscount ? discount : null
    hasDiscount
  }
})

let curArmyUnlocks = Computed(@() armiesUnlocks.value
  .filter(@(u) u.armyId == curArmy.value)
  .sort(@(a, b) a.level <=> b.level || (a?.exp ?? 0) <=> (b?.exp ?? 0)))

let hasArmyUnlocks = Computed(@() curArmyUnlocks.value.len() > 0)

let curArmySquadsUnlocks = Computed(@() curArmyUnlocks.value
  .filter(@(u) u.unlockType == "squad"))

let curArmyLevelRewardsUnlocks = Computed(@() curArmyUnlocks.value
  .filter(@(u) u.unlockType == "level_reward"))

let function getSquadByUnlock(allSquads, unlock) {
  let unlockSquad = allSquads
    .findvalue(@(squad) squad.squadId == unlock.unlockId &&
      (getLinkedArmyName(squad) ?? "") == unlock.armyId)

  return unlockSquad == null || isSquadRented(unlockSquad) ? null
    : unlockSquad
}

let findMax = @(arr) arr.reduce(@(res, val) max(val, res), 0)

let curArmyNextUnlockLevel = Computed(function() {
  let allSquads = curCampSquads.value
  let uReceived = receivedUnlocks.value
  let squadUnlocks = {}
  foreach (unlock in curArmySquadsUnlocks.value)
    squadUnlocks[unlock.level] <- unlock
  let rewardUnlocks = {}
  foreach (unlock in curArmyLevelRewardsUnlocks.value)
    rewardUnlocks[unlock.level] <- unlock

  let maxLevel = max(findMax(squadUnlocks.keys()), findMax(rewardUnlocks.keys()))
  let haveFreemium = isPurchaseableCampaign.value && isCampaignBought.value
  local nextLevel = 0
  for (local lvl = 1; lvl <= maxLevel; lvl++) {
    nextLevel = lvl
    let unlock = squadUnlocks?[lvl] ?? rewardUnlocks?[lvl]
    let { campaignGroup = CAMPAIGN_NONE } = unlock
    if (unlock != null && (campaignGroup == CAMPAIGN_NONE || haveFreemium)) {
      let isNewSquad = unlock.unlockType == "squad" && getSquadByUnlock(allSquads, unlock) == null
      let isNewReward = unlock.unlockType == "level_reward" && !(unlock.unlockGuid in uReceived)
      if (isNewSquad || isNewReward)
        break
    }
  }
  return nextLevel
})

let readyToUnlockSquadId = Computed(function() {
  let level = curArmyNextUnlockLevel.value
  if (level > curArmyLevel.value)
    return null
  let unlock = curArmySquadsUnlocks.value.findvalue(@(u) u.level == level)
  return unlock?.unlockType != "squad" || getSquadByUnlock(curCampSquads.value, unlock) ? null
    : unlock.unlockId
})

let curArmyRewardsUnlocks = Computed(@()
  curArmyUnlocks.value.filter(@(u) u.unlockType != "squad" && u.unlockType != "level_reward")
    .map(@(u) u.__update({
      isMultiple = (u?.multipleUnlock.periods ?? 0) > 0
        && (u.multipleUnlock.expEnd ?? 0) > (u.multipleUnlock.expBegin ?? 0)
    })))

let function getUnlockProgress(armyExp, unlockExp, expGrid) {
  local progress = 0
  if (armyExp >= unlockExp)
    progress = 100
  else {
    let lvlData = getLevelDataByExp(armyExp, expGrid)
    let cutExp = armyExp - lvlData.exp
    progress = 100 * lvlData.exp / (unlockExp - cutExp)
  }
  return {
    progress = min(progress, 100)
    isReached = armyExp >= unlockExp
  }
}

let researchSquads = Computed(function() {
  let allSquads = curCampSquads.value
  let lockedSquads = {}
  foreach (squad in allSquads) {
    let armyId = getLinkedArmyName(squad) ?? ""
    if (squad.locked)
      lockedSquads[armyId] <- (lockedSquads?[armyId] ?? {})
        .__update({ [squad.squadId] = squad.guid })
  }

  let expGrid = armyLevelsData.value
  let res = {}
  foreach (army in armies.value) {
    let armyId = army.guid
    let lockedByArmy = lockedSquads?[armyId] ?? {}
    let armyResearchSquads = curArmySquadsUnlocks.value
      .filter(@(u) u.unlockId in lockedByArmy)

    if (armyResearchSquads.len() > 0) {
      let u = armyResearchSquads[0]
      let squadGuid = lockedByArmy?[u.unlockId]
      let squad = allSquads?[squadGuid]
      if (squad != null)
        res[armyId] <- squad
          .__merge(getUnlockProgress(army.exp, u.exp, expGrid))
    }
  }

  return res
})

let reachedArmyUnlocks = Computed(function() {
  let needFreemium = needFreemiumStatus.value
  let received = receivedUnlocks.value
  let lvls = armies.value.map(@(a) a.level)
  let exps = armies.value.map(@(a) a.exp)
  let squads = squadsByArmy.value.map(function(squads) {
    let res = {}
    foreach (s in squads)
      res[s.squadId] <- true
    return res
  })

  let res = {}
  foreach(u in armiesUnlocks.value) {
    let { campaignGroup = CAMPAIGN_NONE } = u
    if (campaignGroup != CAMPAIGN_NONE && needFreemium)
      continue

    if (u.unlockType == "level_reward" && u.unlockGuid in received)
      continue

    let armyId = u.armyId
    if (u.unlockType == "squad" && u.unlockId in squads?[armyId])
      continue

    let lvl = lvls?[armyId] ?? 0
    let exp = exps?[armyId] ?? 0
    if (lvl < u.level || (lvl == u.level && exp < (u?.exp ?? 0)))
      continue

    res[armyId] <- max((res?[armyId] ?? 0), u.level)
  }

  return res
})

let function unlockSquad(squadId) {
  if (squadId in curUnlockedSquadsIds.value || squadUnlockInProgress.value != null)
    return

  squadUnlockInProgress(squadId)
  unlock_squad(curArmy.value, squadId, function(res) {
    squadUnlockInProgress(null)
    let unlockedSquadId = res?.squads.values()[0].squadId
    if (unlockedSquadId != null)
      curUnlockedSquadId(unlockedSquadId)
  })
}

let function buyArmyLevel(cb = null) {
  if (isBuyLevelInProgress.value)
    return
  let { needExp = 0, cost = 0 } = curBuyLevelData.value
  if (needExp <=0 || cost <= 0)
    return

  isBuyLevelInProgress(true)
  buy_army_exp(curArmy.value, needExp, cost,
    function(res){
       isBuyLevelInProgress(false)
       cb?(res?.error == null)
    })
}

let viewSquadId = mkWatched(persist, "viewSquadId")

let allArmyUnlocks = Computed(function() {
  let allUnlocks = curArmySquadsUnlocks.value.map(@(v) v.__merge({
    unlockType = uType.SQUAD,
    uid = $"squad_{v.unlockId}_{v.level}"
  }))
    .extend(curArmyLevelRewardsUnlocks.value.map(@(v) v.__merge({
      unlockType = uType.ITEM,
      uid = $"item_{v.unlockId}_{v.level}" })))
    .filter(@(u) "level" in u)

  let curArmyLvl = curArmyData.value?.level ?? 0
  if (curArmyLvl > 1){
    foreach (level, guidsList in curArmyShowcase.value)
      foreach (guid in guidsList)
        if (guid in shopItems.value)
          allUnlocks.append(shopItems.value[guid].__merge({
            level, unlockType = uType.SHOP, uid = guid }))
  }

  allUnlocks.sort(@(a, b) a.level <=> b.level || a.unlockType <=> b.unlockType)

  let emptyCount = armyLevelsData.value.len() - (allUnlocks?[allUnlocks.len() - 1].level ?? 0)
  if (emptyCount > 0)
    allUnlocks.resize(allUnlocks.len() + emptyCount, { unlockType = uType.EMPTY })

  return allUnlocks
})

let function scrollToCampaignLvl(level){
  let indexToScroll = allArmyUnlocks.value.findindex(@(reward) reward?.level == level)
  idxToForceScroll(indexToScroll)
}

return {
  hasCampaignSection
  curArmyLevels
  curArmyLevelsSize
  curArmyShowcasesSize
  curArmyExp
  curArmyLevel
  curBuyLevelData
  unlockSquad
  hasArmyUnlocks
  buyArmyLevel
  curArmySquadsUnlocks
  curArmyRewardsUnlocks
  curArmyLevelRewardsUnlocks
  curArmyNextUnlockLevel
  curUnlockedSquadId
  squadUnlockInProgress
  researchSquads
  reachedArmyUnlocks
  viewSquadId
  receivedUnlocks
  needUpdateCampaignScroll
  isArmyUnlocksStateVisible
  readyToUnlockSquadId
  isBuyLevelInProgress
  allArmyUnlocks
  uType
  scrollToCampaignLvl
  idxToForceScroll

  squadGap
  levelWidth = LEVEL_WIDTH
  showcaseItemWidth = SHOWCASE_ITEM_WIDTH
}

