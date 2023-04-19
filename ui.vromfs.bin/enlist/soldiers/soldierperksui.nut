from "%enlSqGlob/ui_library.nut" import *

let { fontMedium } = require("%enlSqGlob/ui/fontsStyle.nut")
let perksList = require("%enlist/meta/perks/perksList.nut")
let getPayItemsData = require("model/getPayItemsData.nut")
let mkSpinner = require("%ui/components/mkSpinner.nut")

let { ceil } = require("math")
let { getRomanNumeral } = require("%sqstd/math.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { Bordered } = require("%ui/components/txtButton.nut")
let { mkItemCurrency } = require("%enlist/shop/currencyComp.nut")
let { mkCurrency } = require("%enlist/currency/currenciesComp.nut")
let { enlistedGold } = require("%enlist/currency/currenciesList.nut")
let { openAvailablePerks } = require("availablePerksWnd.nut")
let { curArmy, curCampItems, curCampItemsCount } = require("model/state.nut")
let { perksData, getTierAvailableData } = require("model/soldierPerks.nut")
let { isCurCampaignProgressUnlocked } = require("%enlist/meta/curCampaign.nut")
let { mkPerksPointsBlock } = require("components/perksPackage.nut")
let { getLinkedArmyName } = require("%enlSqGlob/ui/metalink.nut")
let { perksStatsCfg } = require("%enlist/meta/perks/perksStats.nut")
let { curUpgradeDiscount, disablePerkReroll } = require("%enlist/campaigns/campaignConfig.nut")
let {
  midPadding, columnGap, colPart, leftAppearanceAnim, darkTxtColor, titleTxtColor, defTxtColor
} = require("%enlSqGlob/ui/designConst.nut")
let {
  mkPerkCard, mkChoosePerkCard, mkBuyPerkCard, morePerksHint, mkTrainRankBtn,
  mkTrainStepBtn, mkSoldierSteps, soldierMaxRank
} = require("components/perksPkg.nut")
let {
  perkLevelsGrid, getOrdersToNextLevel, getNextLevelData, getExpToNextLevel
} = require("%enlist/meta/perks/perksExp.nut")
let {
  TRAINING_ORDER, trainingPrices, maxTrainByClass, getTrainingPrice
} = require("model/config/soldierTrainingConfig.nut")
let {
  mkRetrainingPoints, onPerksChoice, onBuyLevel, showNotEnoughOrdersMsg,
  showTrainResearchMsg
} = require("soldierPerksPkg.nut")
let {
  soldierTrainingInProgress, trainSoldier
} = require("%enlist/soldiers/model/trainState.nut")
let colorize = require("%ui/components/colorize.nut")


let defTxtStyle = { color = defTxtColor }.__update(fontMedium)
let hoverTxtStyle = { color = darkTxtColor }.__update(fontMedium)

local animIdx = 0
let spinner = mkSpinner(colPart(0.7))

let mkLevelCurrency = @(perks, sf) function() {
  let res = { watch = perkLevelsGrid }
  let nextLevelData = getNextLevelData({
    level = perks.level
    maxLevel = perks.maxLevel
    exp = perks.exp
    lvlsCfg = perkLevelsGrid.value
  })
  if (nextLevelData == null)
    return res

  return res.__update({
    children = mkCurrency({
      currency = enlistedGold
      price = nextLevelData.cost
      txtStyle = sf & S_HOVER ? hoverTxtStyle : defTxtStyle
    })
  })
}


let getNoAvailPerksText = @(soldier, sf)
  loc("get_more_exp_to_add_perk", {
    value = colorize(sf & S_HOVER ? darkTxtColor : titleTxtColor,
      getExpToNextLevel(soldier.level, soldier.maxLevel, perkLevelsGrid.value.expToLevel) - soldier.exp)
  })


let mkNextLevelBlock = @(perks, tier, tierAvailableData, onSlotClick)
  function() {
    let { isSuccess, errorText = "" } = tierAvailableData
    let { orderTpl = null, ordersRequire = 0 } = getOrdersToNextLevel({
      level = perks.level
      maxLvl = perks.maxLevel
      cfg = perkLevelsGrid.value
    })
    let barterData = orderTpl != null
      ? getPayItemsData({ [orderTpl] = ordersRequire }, curCampItems.value)
      : null
    let isUnavailable = !isSuccess || (!barterData && disablePerkReroll.value)
    let onClick = isUnavailable ? null : @() onBuyLevel(perks, tier, onSlotClick)
    let slotText = isSuccess ? @(sf) getNoAvailPerksText(perks, sf) : errorText
    let slotIcon = @(sf) isUnavailable ? null
      : barterData || !isCurCampaignProgressUnlocked.value ? mkItemCurrency({
          currencyTpl = orderTpl
          count = ordersRequire
          textStyle = sf & S_HOVER ? hoverTxtStyle : defTxtStyle
        })
      : mkLevelCurrency(perks, sf)

    return {
      watch = [isCurCampaignProgressUnlocked, perkLevelsGrid, curCampItems, disablePerkReroll]
      size = [flex(), SIZE_TO_CONTENT]
      children = mkBuyPerkCard(slotText, slotIcon, onClick)
    }
  }


let function mkTierContent(armyId, tierIdx, tier, perks, pList, pCfg, onClick) {
  let tierAvailableData = getTierAvailableData(perks, tier)
  let { isSuccess } = tierAvailableData
  let { availPerks, tiers, guid, prevTier = -1 } = perks
  let { choiceAmount = 0 } = tier

  local needShowEmpty = isSuccess && (availPerks > 0 || prevTier == tiers.indexof(tier))
  local hasPurchasePerkInfoSlot = availPerks <= 0 || !isSuccess

  let children = []
  foreach (i, pId in tier.slots) {
    let perkId = pId ?? ""
    if (perkId == "" && !needShowEmpty)
      continue

    let slotIdx = i
    if (perkId != "" && perkId in pList) {
      let trigger = $"tier{tierIdx}slot{slotIdx}"
      let cb = choiceAmount <= 0 ? null : @() onClick(slotIdx)
      children.append({
        key = $"{guid}_{slotIdx}"
        size = [flex(), SIZE_TO_CONTENT]
        children = mkPerkCard(armyId, pList?[perkId], pCfg, trigger, cb)
      }.__update(leftAppearanceAnim(0.05 * animIdx)))
      animIdx++
      continue
    }

    if (onClick) {
      children.append({
        key = $"{guid}_{slotIdx}"
        size = [flex(), SIZE_TO_CONTENT]
        children = mkChoosePerkCard(@() onClick(slotIdx))
      }.__update(leftAppearanceAnim(0.05 * animIdx)))
      hasPurchasePerkInfoSlot = false
    }
    needShowEmpty = false
    animIdx++
  }

  if (hasPurchasePerkInfoSlot && children.len() < tier.slots.len())
    children.append(mkNextLevelBlock(perks, tier, tierAvailableData, onClick))

  return {
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    gap = midPadding
    children
  }
}


let mkTierBlock = @(armyId, tierIdx, tier, perks, pList, pCfg, onClick) {
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_VERTICAL
  gap = midPadding
  children = mkTierContent(armyId, tierIdx, tier, perks, pList, pCfg, onClick)
}


let function mkPerksList(guid, armyId, perks, pList, pCfg, cb) {
  let children = (perks?.tiers ?? []).map(function(tier, tierIdx) {
    let onClick = cb == null ? null : @(slotIdx) cb(guid, perks, tierIdx, slotIdx)
    return mkTierBlock(armyId, tierIdx, tier, perks, pList, pCfg, onClick)
  })
  return {
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    gap = midPadding
    children
  }
}


let mkPerksListBtn = @(sGuid) @() {
  watch = [curArmy, perksList, perksData]
  size = [flex(), SIZE_TO_CONTENT]
  children = Bordered(utf8ToUpper(loc("possible_perks_list")),
    @() openAvailablePerks(perksList.value, curArmy.value, perksData.value?[sGuid]),
    { btnWidth = flex() })
}

let mkManageBlock = @(guid) {
  key = $"perks_points_{guid}"
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_VERTICAL
  gap = columnGap
  halign = ALIGN_CENTER
  children = [
    mkPerksPointsBlock(guid)
    mkPerksListBtn(guid)
  ]
}


let function mkSoldierTrainBtn(soldier, perks) {
  let { guid = null, sClass = "", tier = 0 } = soldier
  if (guid == null)
    return null

  let orderTpl = TRAINING_ORDER
  return function() {
    let res = {
      watch = [ curCampItems, curCampItemsCount, trainingPrices,
        maxTrainByClass, soldierTrainingInProgress, curUpgradeDiscount ]
    }
    if (soldierTrainingInProgress.value)
      return res.__update({
        hplace = ALIGN_CENTER
        children = spinner
      })

    let campItems = curCampItemsCount.value
    let stepOrders = getTrainingPrice(sClass, tier, trainingPrices.value)
    let isTrainingLimited = (maxTrainByClass.value?[sClass] ?? 0) < tier

    let { stepsLeft = 0 } = perks
    let freemiumDiscount = 1.0 - curUpgradeDiscount.value
    let stepPrice = ceil(stepOrders * freemiumDiscount).tointeger()
    let rankPrice = stepPrice * stepsLeft

    let rankPay = getPayItemsData({ [orderTpl] = rankPrice }, curCampItems.value)
    let rankCb = rankPay == null ? @() showNotEnoughOrdersMsg()
      : isTrainingLimited ? @() showTrainResearchMsg(soldier)
      : @() trainSoldier(guid, rankPay, stepsLeft)

    let children = []
    let isEnoughForTrain = (campItems?[orderTpl] ?? 0) >= rankPrice
    let rankText = loc("perks/trainSoldierNextRank", { tier = getRomanNumeral(tier + 1) })
    children.append(mkTrainRankBtn(utf8ToUpper(rankText), orderTpl, rankPrice, isEnoughForTrain, rankCb))

    let stepPay = getPayItemsData({ [orderTpl] = stepPrice }, curCampItems.value)
    let stepCb = stepPay == null ? @() showNotEnoughOrdersMsg()
      : isTrainingLimited ? @() showTrainResearchMsg(soldier)
      : @() trainSoldier(guid, stepPay, 1)

    if (stepsLeft > 1) {
      let isEnoughForStep = (campItems?[orderTpl] ?? 0) >= (stepPrice ?? 0)
      children.append(mkTrainStepBtn(orderTpl, stepPrice, isEnoughForStep, stepCb))
    }

    return res.__update({
      size = [flex(), SIZE_TO_CONTENT]
      flow = FLOW_HORIZONTAL
      gap = columnGap
      children
    })
  }
}


let perksListUi = @(soldier, canManage) function() {
  let { tier, guid, sClass } = soldier.value
  let armyId = getLinkedArmyName(soldier.value)
  let perks = perksData.value?[guid]
  let pList = perksList.value
  let pCfg = perksStatsCfg.value
  let hasMaxRank = tier >= (trainingPrices.value?[sClass].len() ?? 0)
  let canExpandPerks = !hasMaxRank && (perks?.canChangePerk ?? false)
  animIdx = 0
  return {
    watch = [perksData, perksList, perksStatsCfg, trainingPrices, soldier]
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    gap = columnGap
    children = [
      mkPerksList(guid, armyId, perks, pList, pCfg, canManage ? onPerksChoice : null)
      {
        key = $"{guid}_btns"
        size = [flex(), SIZE_TO_CONTENT]
        flow = FLOW_VERTICAL
        gap = columnGap
        children = [
          canExpandPerks ? morePerksHint : null
          hasMaxRank ? null : mkSoldierTrainBtn(soldier.value, perks)
          hasMaxRank ? soldierMaxRank : mkSoldierSteps(perks)
        ]
      }.__update(leftAppearanceAnim(0.05 * animIdx))
    ]
  }
}


return kwarg(function(soldier, canManage = true) {
  let soldierGuid = Computed(@() soldier.value?.guid)
  return function() {
    let res = { watch = soldierGuid }
    let guid = soldierGuid.value
    if (guid == null)
      return null

    return res.__update({
      flow = FLOW_VERTICAL
      size = flex()
      gap = columnGap
      children = [
        canManage
          ? mkManageBlock(guid).__update(leftAppearanceAnim(0))
          : null
        perksListUi(soldier, canManage)
        canManage
          ? {
              size = [flex(), SIZE_TO_CONTENT]
              children = mkRetrainingPoints(guid)
            }.__update(leftAppearanceAnim(0.05 * animIdx))
          : null
      ]
    })
  }
})
