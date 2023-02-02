from "%enlSqGlob/ui_library.nut" import *

let { body_txt, sub_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let { ceil } = require("math")
let { getRomanNumeral } = require("%sqstd/math.nut")
let msgbox = require("%enlist/components/msgbox.nut")
let { sound_play } = require("sound")
let { smallPadding, bigPadding, perkIconSize, defTxtColor, titleTxtColor,
  soldierWndWidth, commonBtnHeight
} = require("%enlSqGlob/ui/viewConst.nut")
let perksList = require("%enlist/meta/perks/perksList.nut")
let { perksData, getPerkPointsInfo, getTierAvailableData,
  getNoAvailPerksText, showPerksChoice, buySoldierLevel, useSoldierLevelupOrders, dropPerk
} = require("model/soldierPerks.nut")
let { getLinkedArmyName } = require("%enlSqGlob/ui/metalink.nut")
let { isCurCampaignProgressUnlocked } = require("%enlist/meta/curCampaign.nut")
let getPayItemsData = require("model/getPayItemsData.nut")
let confirmBarterMsgBox = require("%enlist/shop/confirmBarterMsgBox.nut")
let { perkLevelsGrid, getNextLevelData, getOrdersToNextLevel
} = require("%enlist/meta/perks/perksExp.nut")
let { openAvailablePerks } = require("availablePerksWnd.nut")
let { curArmy, curCampItems, curCampItemsCount } = require("model/state.nut")
let { perkCardBg, perkCard, tierTitle, mkPerksPointsBlock
} = require("components/perksPackage.nut")
let textButton = require("%ui/components/textButton.nut")
let unseenSignal = require("%ui/components/unseenSignal.nut")
let { purchaseMsgBox } = require("%enlist/currency/purchaseMsgBox.nut")
let { enlistedGold } = require("%enlist/currency/currenciesList.nut")
let { mkCurrency } = require("%enlist/currency/currenciesComp.nut")
let { mkItemCurrency } = require("%enlist/shop/currencyComp.nut")
let { soldierTrainingInProgress, trainSoldier
} = require("%enlist/soldiers/model/trainState.nut")
let spinner = require("%ui/components/spinner.nut")({ height = hdpx(40) })
let { TRAINING_ORDER, trainingPrices, getTrainingPrice, maxTrainByClass
} = require("%enlist/soldiers/model/config/soldierTrainingConfig.nut")
let { mkCurrencyButton } = require("%enlist/soldiers/components/currencyButton.nut")
let { focusResearch, findResearchTrainClass, hasResearchSquad
} = require("%enlist/researches/researchesFocus.nut")
let { soldierClasses } = require("%enlSqGlob/ui/soldierClasses.nut")
let { curUpgradeDiscount, disablePerkReroll } = require("%enlist/campaigns/campaignConfig.nut")

local slotNumber = 0

let choosePerkIcon = unseenSignal()
  .__update({ hplace = ALIGN_CENTER, vplace = ALIGN_CENTER, animations = null })

let mkText = @(txt) {
  rendObj = ROBJ_TEXT
  color = defTxtColor
  text = txt
}.__update(sub_txt)

let mkTextArea = @(txt) {
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  size = [flex(), SIZE_TO_CONTENT]
  color = defTxtColor
  text = txt
}.__update(sub_txt)

let choosePerkRow  = @(slotIdx, icon, locId, onClick = null) perkCardBg(slotIdx, onClick, {
  size = [flex(), SIZE_TO_CONTENT]
  valign = ALIGN_CENTER
  flow = FLOW_HORIZONTAL
  gap = smallPadding
  padding = smallPadding
}, [
  {
    size = [perkIconSize, perkIconSize]
    children = icon
  }
  mkTextArea(loc(locId)).__update({
    color = titleTxtColor
  })
])

let useSoldierLevelOrdersMsg = @(perks, tier, ordersToNextLevel, barterData, onSlotClick)
  confirmBarterMsgBox({
    purchase = @() useSoldierLevelupOrders(perks.guid, barterData,
      function(res) {
        if (onSlotClick == null || (res?.error ?? "").len() > 0)
          return

        let chooseIdx = tier.slots.findindex(@(perkId) (perkId ?? "") == "")
        if (chooseIdx != null)
          onSlotClick(chooseIdx)
      })
    priceView = mkItemCurrency({
      currencyTpl = ordersToNextLevel.orderTpl
      count = ordersToNextLevel.ordersRequire
    })
    title = loc("soldierLevel", { level = perks.level })
    productView = mkTextArea(loc("buy/soldierLevelConfirmOrder")).__update({
      halign = ALIGN_CENTER
      color = titleTxtColor
    }.__update(body_txt)),
    currenciesAmount = mkItemCurrency({
      currencyTpl = ordersToNextLevel.orderTpl
      count = curCampItemsCount.value?[ordersToNextLevel.orderTpl] ?? 0
    })
  })

let function buySoldierLevelMsg(perks, cb, ordersToNextLevel) {
  let nextLevelData = getNextLevelData({
    level = perks.level
    maxLevel = perks.maxLevel
    exp = perks.exp
    lvlsCfg = perkLevelsGrid.value
  })
  if (nextLevelData == null)
    return null

  purchaseMsgBox({
    price = nextLevelData.cost
    currencyId = "EnlistedGold"
    title = loc("soldierLevel", { level = perks.level })
    description = loc("buy/soldierLevelConfirm")
    purchase = @() buySoldierLevel(perks, cb)
    srcComponent = "buy_soldier_level"
    additionalButtons = [{
      text = ""
      action = @() null,
      customStyle = {
        isEnabled = false
        children = {
          flow = FLOW_HORIZONTAL
          size = [SIZE_TO_CONTENT, commonBtnHeight]
          gap = bigPadding
          valign = ALIGN_CENTER
          halign = ALIGN_CENTER
          padding = bigPadding
          children = [
            mkText(loc("notEnoughOrders")).__update(body_txt)
            mkItemCurrency({
              currencyTpl = ordersToNextLevel.orderTpl,
              count = ordersToNextLevel.ordersRequire
            })
          ]
        }
      }
    }]
  })
}

let slotBgStyle = {
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_HORIZONTAL
  gap = bigPadding
  minHeight = perkIconSize + 2 * smallPadding
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  padding = smallPadding
}

let mkLevelCurrency = @(perks)
  function() {
    let res = { watch = perkLevelsGrid }
    let nextLevelData = getNextLevelData({
      level = perks.level
      maxLevel = perks.maxLevel
      exp = perks.exp
      lvlsCfg = perkLevelsGrid.value
    })
    return res.__update(nextLevelData != null
      ? {
          children = mkCurrency({
            currency = enlistedGold
            price = nextLevelData.cost
          })
        }
      : {})
  }

let function onBuyLevel(perks, tier = null, onSlotClick = null) {
  let ordersToNextLevel = getOrdersToNextLevel({
    level = perks.level
    maxLvl = perks.maxLevel
    cfg = perkLevelsGrid.value
  })
  let barterData = ordersToNextLevel != null
    ? getPayItemsData({ [ordersToNextLevel.orderTpl] = ordersToNextLevel.ordersRequire },
        curCampItems.value)
    : null
  if (barterData != null)
    return useSoldierLevelOrdersMsg(perks, tier, ordersToNextLevel, barterData, onSlotClick)
  else if (!isCurCampaignProgressUnlocked.value)
    return msgbox.show({ text = loc("shop/noItemsToPay") })

  buySoldierLevelMsg(perks, function(res) {
    if (onSlotClick == null || (res?.error ?? "").len() > 0)
      return

    let chooseIdx = tier.slots.findindex(@(perkId) (perkId ?? "") == "")
    if (chooseIdx != null)
      onSlotClick(chooseIdx)
  }, ordersToNextLevel)
}

let mkNextLevelBlock = kwarg(@(perks, tier, tierAvailableData, onSlotClick) function() {
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
  let onPressCb = isUnavailable ? null : @() onBuyLevel(perks, tier, onSlotClick)
  return {
    watch = [isCurCampaignProgressUnlocked, perkLevelsGrid, curCampItems, disablePerkReroll]
    size = [flex(), SIZE_TO_CONTENT]
    children = perkCardBg(slotNumber++, onPressCb, slotBgStyle, [
      mkTextArea(isSuccess ? getNoAvailPerksText(perks) : errorText).__update({
        size = [pw(80), SIZE_TO_CONTENT]
        halign = ALIGN_CENTER
      })
      isUnavailable ? null
        : barterData || !isCurCampaignProgressUnlocked.value ? mkItemCurrency({
            currencyTpl = orderTpl
            count = ordersRequire
          })
        : mkLevelCurrency(perks)
    ])
  }
})

let function tierContentUi(armyId, tierIdx, tier, perks, onSlotClick) {
  let { choiceAmount = 0 } = tier
  let children = []
  let tierAvailableData = getTierAvailableData(perks, tier)
  local needShowEmpty = tierAvailableData.isSuccess
    && (perks.availPerks > 0 || (perks?.prevTier ?? -1) == perks.tiers.indexof(tier))
  local hasPurchasePerkInfoSlot = perks.availPerks <= 0 || !tierAvailableData.isSuccess

  foreach (i, p in tier.slots) {
    let perkId = p ?? ""
    if (perkId == "" && !needShowEmpty)
      continue

    let slotIdx = i
    if (perkId != "") {
      let trigger = $"tier{tierIdx}slot{slotIdx}"
      children.append(perkCard({
        armyId
        perkData = { perkId = perkId }
        slotNumber = slotNumber++
        cb = choiceAmount <= 0 ? null
          : @() onSlotClick(slotIdx)
        customStyle = {
          transform = {}
          animations = [
            { prop = AnimProp.opacity, from = 0, to = 0, duration = 0.1, play = true }
            { prop = AnimProp.translate, from = [soldierWndWidth, 0], to = [0,0],
              duration = 0.6, easing = OutCubic, trigger }
            { prop = AnimProp.opacity, from = 1, to = 0.3, duration = 0.2, delay = 0.4,
              trigger }
            { prop = AnimProp.opacity, from = 0.3, to = 1, duration = 0.4, delay = 0.6,
              easing = Blink, trigger, onFinish = @() sound_play("ui/debriefing/squad_star") }
            { prop = AnimProp.opacity, from = 0.3, to = 1, duration = 0.4, delay = 0.9,
              easing = Blink, trigger }
          ]
        }
      }))
      continue
    }

    if (onSlotClick) {
      children.append(choosePerkRow(slotNumber++, choosePerkIcon, "choose_new_perk",
        @() onSlotClick(slotIdx)))
      hasPurchasePerkInfoSlot = false
    }
    needShowEmpty = false
  }

  if (hasPurchasePerkInfoSlot && children.len() < tier.slots.len())
    children.append(mkNextLevelBlock({ perks, tier, tierAvailableData, onSlotClick }))

  return {
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    children = children
  }
}

let tierUi = @(armyId, tierIdx, tier, perks, onSlotClick) {
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_VERTICAL
  gap = smallPadding
  children = [
    tierTitle(tier)
    {
      size = [flex(), SIZE_TO_CONTENT]
      flow = FLOW_VERTICAL
      gap = smallPadding
      children = tierContentUi(armyId, tierIdx, tier, perks, onSlotClick)
    }
  ]
}

let mkPerksListBtn = @(soldier) @() {
  watch = [curArmy, perksList, perksData]
  hplace = ALIGN_RIGHT
  children = textButton.SmallFlat(loc("possible_perks_list"),
    @() openAvailablePerks(perksList.value, curArmy.value, perksData.value?[soldier?.guid]),
    { margin = 0, padding = [bigPadding, 2 * bigPadding] })
  }

let function onPerksChoice(soldierGuid, perks, tierIdx, slotIdx) {
  if ((perks?.tiers[tierIdx].slots[slotIdx] ?? "") == "")
    return showPerksChoice(soldierGuid, tierIdx, slotIdx)

  let isDrop = perks.availPerks == 0
  msgbox.showMessageWithContent({
    uid = "change_perk_confirm"
    content = {
      flow = FLOW_VERTICAL
      size = [sw(50), SIZE_TO_CONTENT]
      margin = [fsh(5), 0]
      gap = fsh(3)
      halign = ALIGN_CENTER
      children = [
        mkTextArea(loc(isDrop ? "msg/dropPerk" : "msg/useRetrainingPoint")).__update({
          halign = ALIGN_CENTER
          color = titleTxtColor
        }.__update(body_txt))
      ]
    }
    buttons = [
      { text = loc("Yes"),
        action = @() isDrop ? dropPerk(soldierGuid, tierIdx, slotIdx)
          : showPerksChoice(soldierGuid, tierIdx, slotIdx)
        isCurrent = !isDrop
      }
      { text = loc("Cancel")
        isCurrent = isDrop
        isCancel = true
      }
    ]
  })
}

let morePerksHint = mkTextArea(loc("perks/getMorePerks"))

let soldierMaxRank = mkTextArea(loc("perks/maxRankReached"))

let function mkSoldierSteps(perks) {
  let minText = loc("perks/trainStepsBeforeRank", { steps = perks?.stepsLeft ?? 0 })
  let infoText = loc("perks/trainPriceInfo")
  return mkTextArea($"{minText} {infoText}")
}

let function showNotEnoughOrdersMsg() {
  msgbox.show({ text = loc("soldier/noOrdersToTrain") })
}

let function showTrainResearchMsg(soldier) {
  let { sClass = "unknown" } = soldier
  let armyId = getLinkedArmyName(soldier)
  let research = findResearchTrainClass(soldier)
  if (research == null)
    msgbox.show({ text = loc("msg/cantTrainClassHigher") })
  else if (!hasResearchSquad(armyId, research))
    msgbox.show({ text = loc("msg/needUnlockSquadToTrain",
      { sClass = loc(soldierClasses?[sClass].locId ?? "unknown") }) })
  else
    msgbox.show({
      text = loc("msg/needResearchToTrainHigher")
      buttons = [
        { text = loc("Ok"), isCurrent = true }
        { text = loc("GoToResearch"), action = @() focusResearch(research) }
      ]
    })
}

let function mkSoldierTrainBtn(soldier, perks) {
  let { guid = null, sClass = "", tier = 0 } = soldier
  if (guid == null)
    return null

  let orderTpl = TRAINING_ORDER
  return function() {
    let res = { watch = [
      curCampItems, curCampItemsCount, trainingPrices, maxTrainByClass, soldierTrainingInProgress,
      curUpgradeDiscount
    ] }
    let campItems = curCampItemsCount.value
    let stepOrders = getTrainingPrice(sClass, tier, trainingPrices.value)
    let isTrainingLimited = (maxTrainByClass.value?[sClass] ?? 0) < tier
    let isAvailable = !soldierTrainingInProgress.value

    let children = []
    if (!isAvailable)
      children.append(spinner)

    let { stepsLeft = 0 } = perks
    let freemiumDiscount = 1.0 - curUpgradeDiscount.value
    let stepPrice = ceil(stepOrders * freemiumDiscount).tointeger()
    let rankPrice = stepPrice * stepsLeft

    let rankPay = getPayItemsData({ [orderTpl] = rankPrice }, curCampItems.value)
    let rankCb = rankPay == null ? @() showNotEnoughOrdersMsg()
      : isTrainingLimited ? @() showTrainResearchMsg(soldier)
      : @() trainSoldier(guid, rankPay, stepsLeft)
    if (isAvailable)
      children.append(mkCurrencyButton({
        text = loc("perks/trainSoldierNextRank", { tier = getRomanNumeral(tier + 1) })
        cb = rankCb
        orderTpl
        orderCount = rankPrice
        campItems
        isEnabled = true
        override = { hplace = ALIGN_LEFT }
      }))

    let stepPay = getPayItemsData({ [orderTpl] = stepPrice }, curCampItems.value)
    let stepCb = stepPay == null ? @() showNotEnoughOrdersMsg()
      : isTrainingLimited ? @() showTrainResearchMsg(soldier)
      : @() trainSoldier(guid, stepPay, 1)
    if (stepsLeft > 1 && isAvailable)
      children.append(mkCurrencyButton({
        text = loc("perks/trainSoldierOneStep")
        cb = stepCb
        orderTpl
        orderCount = stepPrice
        campItems
        isEnabled = true
        override = { hplace = ALIGN_RIGHT }
      }))

    return res.__update({
      size = [flex(), SIZE_TO_CONTENT]
      halign = ALIGN_CENTER
      children
    })
  }
}

let function mkPerksList(guid, armyId, perks, canManage) {
  slotNumber = 0
  let children = (perks?.tiers ?? [])
    .map(@(tier, tierIdx) tierUi(armyId, tierIdx, tier, perks,
      (canManage ? @(slotIdx) onPerksChoice(guid, perks, tierIdx, slotIdx) : null)))
  return {
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    children
  }
}

let perksUi = @(soldier, canManage) function() {
  let { guid = null, sClass = null } = soldier
  let armyId = soldier == null ? null : getLinkedArmyName(soldier)
  let perks = perksData.value?[guid]
  let hasMaxRank = soldier.tier >= (trainingPrices.value?[sClass].len() ?? 0)
  let canExpandPerks = !hasMaxRank && (perks?.canChangePerk ?? false)
  return {
    watch = [perksData, trainingPrices]
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    margin = [bigPadding, 0]
    gap = bigPadding
    children = [
      mkPerksList(guid, armyId, perks, canManage)
      canExpandPerks ? morePerksHint : null
      hasMaxRank ? null : mkSoldierTrainBtn(soldier, perks)
      hasMaxRank ? soldierMaxRank : mkSoldierSteps(perks)
    ]
  }
}

let mkRetrainingPoints = @(soldierGuid) function() {
  let { availPerks = 0, canChangePerk = false } = perksData.value?[soldierGuid]
  return {
    watch = perksData
    size = [flex(), SIZE_TO_CONTENT]
    children = availPerks <= 0 || !canChangePerk ? null
      : {
          size = [flex(), SIZE_TO_CONTENT]
          flow = FLOW_VERTICAL
          gap = bigPadding
          children = [
            {
              size = [flex(), SIZE_TO_CONTENT]
              flow = FLOW_HORIZONTAL
              halign = ALIGN_CENTER
              valign = ALIGN_CENTER
              children = [
                mkText("{0}: ".subst(loc("perk/retraining_points")))
                mkText(availPerks).__update({
                  key = availPerks
                  color = titleTxtColor
                }.__update(body_txt))
              ]
            }
          ]
        }
  }
}

local prevPerkPointsData = null;

let function mkPerksPoints(soldierGuid) {
  let perkPointsInfoWatch = Computed(function() {
    let perks = perksData.value?[soldierGuid]
    return perks == null ? null : getPerkPointsInfo(perksList.value, perks)
  })
  local prev = {}
  if (prevPerkPointsData?.guid != soldierGuid){
    prevPerkPointsData = { guid = soldierGuid }.__update(perkPointsInfoWatch.value?.total)
    prev = prevPerkPointsData
  } else {
    prev = prevPerkPointsData
    prevPerkPointsData = { guid = soldierGuid }.__update(perkPointsInfoWatch.value?.total)
  }
  return {
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_HORIZONTAL
    gap = bigPadding
    margin = [0, 0, smallPadding, 0]
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    children = mkPerksPointsBlock(perkPointsInfoWatch, prev)
  }
}

return {
  mkPerksPoints
  mkPerksListBtn
  mkRetrainingPoints
  perksUi
}
