from "%enlSqGlob/ui_library.nut" import *

let u = require("%sqstd/underscore.nut")
let { logerr } = require("dagor.debug")
let { curArmiesList, getSoldiersByArmy, curCampSquads, chosenSquadsByArmy, curCampaign
} = require("state.nut")
let { getLinkedSquadGuid } = require("%enlSqGlob/ui/metalink.nut")
let {
  getExpToNextLevel, perkLevelsGrid, getNextLevelData
} = require("%enlist/meta/perks/perksExp.nut")
let { titleTxtColor } = require("%enlSqGlob/ui/viewConst.nut")
let colorize = require("%ui/components/colorize.nut")
let {
  get_perks_choice, choose_perk, change_perk_choice, buy_soldier_exp,
  use_soldier_levelup_orders, buy_soldier_max_level, drop_perk
} = require("%enlist/meta/clientApi.nut")
let serverPerks = require("%enlist/meta/servProfile.nut").soldierPerks
let { configs } = require("%enlist/meta/configs.nut")
let popupsState = require("%enlist/popup/popupsState.nut")
let { gameProfile } = require("%enlist/soldiers/model/config/gameProfile.nut")

let perkActionsInProgress = Watched({})
let perkChoiceWndParams = mkWatched(persist, "perkChoiceWndParams")

let getNoAvailPerksText = @(soldier)
  loc("get_more_exp_to_add_perk", {
    value = colorize(titleTxtColor,
      getExpToNextLevel(soldier.level, soldier.maxLevel, perkLevelsGrid.value.expToLevel) - soldier.exp)
  })

let perksData = Computed(function() {
  let { perkSlotsByTiers = [], perkSchemes = {} } = configs.value
  let maxLevelByTier = perkSlotsByTiers.map(@(levels) levels.reduce(@(res, l) res + l, 0))
  return serverPerks.value.map(function(p) {
    let { slots = [],  sTier = 1, perkSchemeId = "" } = p //compatibility with enlisted_0_1_17_X
    let scheme = perkSchemes?[perkSchemeId] ?? []
    return p.__merge({
      maxLevel = maxLevelByTier?[sTier] ?? 1
      tiers = scheme.map(@(tierCfg, idx) tierCfg.__merge({
        slots = (clone (slots?[idx] ?? []))
          .resize(perkSlotsByTiers?[sTier][idx] ?? 0, "")
      }))
    })
  })
})

let function obtainPerksChoice(soldierGuid, tierIdx, slotIdx, cb) {
  if (soldierGuid in perkActionsInProgress.value)
    return

  let callCb = function(res) {
    if (cb)
      cb(res)
  }

  let soldierPerks = perksData.value?[soldierGuid]
  if ((soldierPerks?.availPerks ?? 0) <= 0 && (soldierPerks?.prevTier ?? -1) < 0)
    return callCb({ errorText = getNoAvailPerksText(soldierPerks) })

  let tierData = perksData.value?[soldierGuid].tiers[tierIdx]
  if ((tierData?.choiceAmount ?? 0) <= 0)
    return callCb({ errorText = loc("perk/no_perks_to_select") })

  perkActionsInProgress.mutate(@(v) v[soldierGuid] <- true)
  let handleResult = function(res) {
    perkActionsInProgress.mutate(@(v) delete v[soldierGuid])
    if ((res?.error ?? "") != "") {
      cb({ errorText = loc(res.error) })
      return
    }

    cb(res?.choiceData ?? {})
  }

  get_perks_choice(soldierGuid, tierIdx, slotIdx, handleResult)
}


let resData = @(errorText) { isSuccess = !errorText, errorText = errorText }

let function getTierAvailableData(soldier, tierData) {
  foreach (tData in soldier?.tiers ?? [])
    if (tData == tierData)
      return resData(null)
    else if (tData.slots.indexof(null) != null)
      return resData(loc("special_perks_unlock_condition",
        { value = colorize(titleTxtColor, tData.slots.len()) }))
  return resData(loc("perks_not_available"))
}

let function choosePerk(soldierGuid, tierIdx, slotIdx, perkId, cb = @(_) null) {
  if (soldierGuid in perkActionsInProgress.value)
    return cb(resData(null))

  let soldier = perksData.value[soldierGuid]
  let tierData = soldier.tiers[tierIdx]
  let slots = tierData.slots
  if (!soldier?.canChangePerk && (slots[slotIdx] ?? "") != "")
    return cb(resData(loc("Earn soldier max level to change perks")))

  if (!(slotIdx in slots))
    return cb(resData(loc("Not exist slot index")))

  let processChoiceData = function(choiceData) {
    if (choiceData?.errorText)
      return cb(resData(choiceData?.errorText))

    if (choiceData.soldierGuid != soldierGuid ||
        choiceData.tierIdx != tierIdx ||
        choiceData.slotIdx != slotIdx)
      return cb(resData(loc("Perk choice data mismatch")))

    let choice = choiceData.choice
    if (choice.indexof(perkId) == null && slots[slotIdx] != perkId)
      return cb(resData(loc("Perk not available")))

    perkActionsInProgress.mutate(@(v) v[soldierGuid] <- true)
    choose_perk(soldierGuid, tierIdx, slotIdx, perkId,
      function(res) {
        perkActionsInProgress.mutate(@(v) delete v[soldierGuid])
        cb(resData(res?.error))
      })
  }

  obtainPerksChoice(soldierGuid, tierIdx, slotIdx, processChoiceData)
}

let changePerkCost = Computed(@() gameProfile.value?.perkChoiceChangeCost ?? 0)
let function changePerks(soldierGuid, tierIdx, slotIdx, cb) {
  if (soldierGuid in perkActionsInProgress.value)
    return
  let cost = changePerkCost.value
  if (cost <= 0) {
    logerr($"Try to change perk when invalid cost {cost}")
    return
  }
  perkActionsInProgress.mutate(@(v) v[soldierGuid] <- true)
  change_perk_choice(soldierGuid, tierIdx, slotIdx, cost,
    function(res) {
      perkActionsInProgress.mutate(@(v) delete v[soldierGuid])
      cb((res?.error ?? "") != "" ? { errorText = loc(res.error) } : res?.choiceData)
    })
}


let function getTotalPerkValue(perksListTable, perksStatsTable, perks, perkName) {
  local sum = 0.0
  foreach (tier in perks?.tiers ?? [])
    foreach (perkId in tier?.slots ?? [])
      if (tier?.perks?.indexof?(perkId) != null) {
        let stats = perksListTable?[perkId].stats ?? {}
        sum += stats?[perkName]
          ? stats[perkName] * perksStatsTable[perkName].base_power
          : 0.0
      }
  return sum
}

let function getPerksCount(perks) {
  local count = 0
  foreach (tier in perks?.tiers ?? [])
    foreach (perkId in tier?.slots ?? [])
      count += (perkId ?? "") == "" ? 0 : 1
  return count
}

let notChoosenPerkSoldiers = Watched({})
let notChoosenPerkSquads = Watched({})
let notChoosenPerkArmies = Watched({})

let function updateNotChosenPerks(...) {
  let soldiersList = {}
  let squadsList = {}
  let armiesList = {}

  foreach (armyId in curArmiesList.value) {
    armiesList[armyId] <- 0
    squadsList[armyId] <- {}
    let chosenSquads = chosenSquadsByArmy.value?[armyId]
    if (chosenSquads == null)
      continue

    foreach (soldier in getSoldiersByArmy(armyId)) {
      let guid = soldier.guid
      let perks = perksData.value?[guid]
      if (perks?.canChangePerk)
        continue

      local availPerks = (perks?.availPerks ?? 0)
      if ((perks?.prevTier ?? -1) >= 0)
        availPerks++
      if (availPerks == 0)
        continue
      soldiersList[guid] <- availPerks

      let squadId = curCampSquads.value?[getLinkedSquadGuid(soldier)].squadId
      if (squadId == null)
        continue
      squadsList[armyId][squadId] <- (squadsList[armyId]?[squadId] ?? 0) + 1

      if (chosenSquads.findindex(@(s) s?.squadId == squadId) != null)
        armiesList[armyId]++
    }
  }

  if (!u.isEqual(armiesList, notChoosenPerkArmies.value))
    notChoosenPerkArmies(armiesList)
  if (!u.isEqual(soldiersList, notChoosenPerkSoldiers.value))
    notChoosenPerkSoldiers(soldiersList)
  if (!u.isEqual(squadsList, notChoosenPerkSquads.value))
    notChoosenPerkSquads(squadsList)
}
updateNotChosenPerks()

//no need to subscribe on armies, soldier can not change army
foreach (w in [perksData, curCampaign, chosenSquadsByArmy])
  w.subscribe(updateNotChosenPerks)

let function getPerkPointsInfo(perksListTable, sPerksData, exclude = {}) {
  let res = {
    used = {}
    total = clone (sPerksData?.points ?? {})
    bonus = {}
  }

  foreach (pTier in sPerksData.tiers)
    foreach (pSlot in pTier.slots)
      if (pSlot != null && !exclude?[pSlot]) {
        let perkCfg = perksListTable?[pSlot] ?? {}
        foreach (pPointId, pPointCost in perkCfg?.cost ?? {})
          res.used[pPointId] <- (res.used?[pPointId] ?? 0) + pPointCost
        foreach (pPointId, pPointBonus in perkCfg?.bonus ?? {}) {
          res.bonus[pPointId] <- (res.bonus?[pPointId] ?? 0) + pPointBonus
          res.total[pPointId] <- (res.total?[pPointId] ?? 0) + pPointBonus
        }
      }

  return res
}

let function useSoldierLevelupOrders(guid, barterData, cb) {
  use_soldier_levelup_orders(guid, barterData, cb)
}

let function buySoldierLevel(perks, cb) {
  let nextLevelData = getNextLevelData({
    level = perks.level
    maxLevel = perks.maxLevel
    exp = perks.exp
    lvlsCfg = perkLevelsGrid.value
  })
  if (nextLevelData == null)
    return

  buy_soldier_exp(perks.guid, nextLevelData.exp, nextLevelData.cost, cb)
}


let function buySoldierMaxLevel(guid, cost, cb = @(_) null) {
  buy_soldier_max_level(guid, cost, cb)
}

let showActionError = @(text)
  popupsState.addPopup({ id = "perk_assign_msg", text = text, styleName = "error" })

let function showPerksChoice(soldierGuid, tierIdx, slotIdx) {
  obtainPerksChoice(soldierGuid, tierIdx, slotIdx,
    @(choiceData) "errorText" in choiceData ? showActionError(choiceData.errorText)
      : perkChoiceWndParams(choiceData))
}

let dropPerk = @(soldierGuid, tierIdx, slotIdx) drop_perk(soldierGuid, tierIdx, slotIdx)

console_register_command(@(soldierGuid, tierIdx, slotIdx) dropPerk(soldierGuid, tierIdx, slotIdx),
  "meta.dropPerk")

return {
  perksData
  notChoosenPerkArmies
  notChoosenPerkSquads
  notChoosenPerkSoldiers
  perkActionsInProgress
  perkChoiceWndParams
  changePerkCost

  obtainPerksChoice
  choosePerk
  changePerks
  getTierAvailableData
  getNoAvailPerksText
  getTotalPerkValue
  getPerksCount

  getPerkPointsInfo
  buySoldierLevel
  useSoldierLevelupOrders
  buySoldierMaxLevel
  showActionError
  showPerksChoice
  dropPerk
}
