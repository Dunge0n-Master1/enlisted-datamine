from "%enlSqGlob/ui_library.nut" import *


let perksPoints = require("%enlist/meta/perks/perksPoints.nut")
let tooltipBox = require("%ui/style/tooltipBox.nut")

let { fontMedium } = require("%enlSqGlob/ui/fontsStyle.nut")
let { setTooltip } = require("%ui/style/cursors.nut")
let { mkPerkDesc } = require("perksPackage.nut")
let { mkItemCurrency } = require("%enlist/shop/currencyComp.nut")
let { sound_play } = require("sound")
let {
  colPart, miniPadding, smallPadding, midPadding, defBdColor, defTxtColor, defSlotBgColor,
  defItemBlur, commonBorderRadius, columnGap, accentColor, negativeTxtColor, completedTxtColor,
  hoverSlotBgColor, darkTxtColor, darkPanelBgColor
} = require("%enlSqGlob/ui/designConst.nut")


let defTxtStyle = { color = defTxtColor }.__update(fontMedium)
let hoverTxtStyle = { color = darkTxtColor }.__update(fontMedium)

let PERK_UNAVAILABLE_COLOR = Color(120, 120, 120, 255)


let perkIconSpace = colPart(1.2)
let perkIconSize = colPart(0.8)
let minSlotHeight = colPart(0.9)
let plusIconSize = colPart(0.6)
let defIconSize = colPart(0.5)
let btnSlotHeight = colPart(0.8)


let perkPointIcon = @(pPointCfg, pPointSize = perkIconSize) {
  rendObj = ROBJ_IMAGE
  size = [pPointSize, pPointSize]
  image = Picture("{0}:{1}:{1}:K".subst(pPointCfg.icon, pPointSize))
  color = pPointCfg.color
}

let perkPointCostText = @(pPointCfg, cost) {
  rendObj = ROBJ_TEXT
  text = cost
  color = pPointCfg.color
}

let mkTextArea = @(txt, params = {}) {
  size = [flex(), SIZE_TO_CONTENT]
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  color = defTxtColor
  text = txt
}.__update(params)


let morePerksHint = mkTextArea(loc("perks/getMorePerks"), { halign = ALIGN_CENTER })


let function mkPerkCostChildren(perk, isUnavailable = false, showFreePerks = false) {
  let perkCost = perk?.cost
  if ((perkCost?.len() ?? 0) == 0)
    return null

  let pPointType = perkCost.keys()[0]
  let pPointsValue = perkCost?[pPointType]
  if (pPointsValue == null || (pPointsValue == 0 && !showFreePerks))
    return null

  local pPointCfg = perksPoints.pPointsBaseParams[pPointType] ?? {}
  if (isUnavailable)
    pPointCfg = pPointCfg.__merge({color = PERK_UNAVAILABLE_COLOR})

  return {
    size = flex()
    children = [
      perkPointIcon(pPointCfg).__update({
        hplace = ALIGN_CENTER
        vplace = ALIGN_CENTER
      })
      pPointsValue == 0 ? null
        : perkPointCostText(pPointCfg, pPointsValue).__update({
            margin = [miniPadding, smallPadding]
          })
    ]
  }
}


let function mkPerkCostShort(perk, isUnavailable = false, statType = "") {
  let pPointsChildren = mkPerkCostChildren(perk, isUnavailable, true)
  if (pPointsChildren == null)
    return null

  return {
    flow = FLOW_VERTICAL
    halign = ALIGN_RIGHT
    vplace = ALIGN_CENTER
    behavior = Behaviors.Button
    size = [perkIconSpace, flex()]
    onHover = !isUnavailable ? null
      : @(on) setTooltip(!on ? null : tooltipBox({
          flow = FLOW_HORIZONTAL
          gap = midPadding
          valign = ALIGN_CENTER
          children = mkTextArea(loc("notEnoughPerkPointsHint", {
            statName = loc($"stat/{statType}_genitive")
          }), { size = SIZE_TO_CONTENT })
        }))
    children = pPointsChildren
  }
}


let animXValue = colPart(2)
let function mkPerkCard(armyId, perk, pCfg, trigger, onClick = null) {
  return watchElemState(@(sf) {
    size = [flex(), SIZE_TO_CONTENT]
    valign = ALIGN_CENTER
    rendObj = ROBJ_WORLD_BLUR
    fillColor = sf & S_HOVER ? hoverSlotBgColor : defSlotBgColor
    color = defItemBlur
    behavior = onClick ? Behaviors.Button : null
    onClick = onClick
    flow = FLOW_HORIZONTAL
    children = [
      {
        size = [perkIconSpace, flex()]
        children = [
          mkPerkCostShort(perk)
        ]
      }
      {
        size = [flex(), SIZE_TO_CONTENT]
        minHeight = minSlotHeight
        padding = midPadding
        valign = ALIGN_CENTER
        children = mkTextArea(
          perk != null ? mkPerkDesc(pCfg, armyId, perk, "\n") : loc("choose_new_perk")
        )
      }
    ]
    transform = {}
    animations = [
      { prop = AnimProp.opacity, from = 0, to = 0, duration = 0.1, play = true }
      { prop = AnimProp.translate, from = [animXValue, 0], to = [0,0],
        duration = 0.6, easing = OutCubic, trigger }
      { prop = AnimProp.opacity, from = 1, to = 0.3, duration = 0.2, delay = 0.4,
        trigger }
      { prop = AnimProp.opacity, from = 0.3, to = 1, duration = 0.4, delay = 0.6,
        easing = Blink, trigger, onFinish = @() sound_play("ui/debriefing/squad_star") }
      { prop = AnimProp.opacity, from = 0.3, to = 1, duration = 0.4, delay = 0.9,
        easing = Blink, trigger }
    ]
  })
}


let mkPerkSlotOverride = @(sf, onClick) {
  size = [flex(), minSlotHeight]
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  behavior = onClick ? Behaviors.Button : null
  onClick = onClick
  rendObj = ROBJ_BOX
  borderWidth = 1
  borderRadius = commonBorderRadius
  borderColor = defBdColor
  fillColor = sf & S_ACTIVE ? darkPanelBgColor
    : sf & S_HOVER ? accentColor
    : null
}

let mkChoosePerkCard = @(onClick = null) watchElemState(@(sf) {
  children = {
    rendObj = ROBJ_IMAGE
    size = [plusIconSize, plusIconSize]
    image = Picture("!ui/squads/plus.svg:{0}:{0}:K".subst(plusIconSize))
    color = sf & S_HOVER ? darkTxtColor : defBdColor
  }
}.__update(mkPerkSlotOverride(sf, onClick)))

let mkBuyPerkCard = @(slotText, slotIcon, onClick = null) watchElemState(@(sf) {
  flow = FLOW_HORIZONTAL
  padding = [0, midPadding]
  children = [
    mkTextArea(slotText(sf),
      { halign = ALIGN_CENTER }.__update(sf & S_HOVER ? hoverTxtStyle : defTxtStyle))
    slotIcon(sf)
  ]
}.__update(mkPerkSlotOverride(sf, onClick)))


let mkTrainRankBtn = @(txt, currencyTpl, count, isEnough, onClick) watchElemState(@(sf) {
  size = [colPart(2), SIZE_TO_CONTENT]
  flow = FLOW_HORIZONTAL
  gap = defIconSize
  padding = [0, columnGap]
  children = [
    {
      rendObj = ROBJ_TEXT
      text = txt
    }.__update(sf & S_HOVER ? hoverTxtStyle : defTxtStyle)
    mkItemCurrency({
      currencyTpl
      count
      textStyle = {
        color = !isEnough ? negativeTxtColor
          : sf & S_HOVER ? darkTxtColor : defTxtColor
      }
    })
  ]
}.__update(
  mkPerkSlotOverride(sf, onClick),
  { size = [flex(), btnSlotHeight] }
))


let mkTrainStepBtn = @(currencyTpl, count, isEnough, onClick) watchElemState(@(sf) {
  flow = FLOW_HORIZONTAL
  padding = [0, columnGap]
  gap = defIconSize
  children = [
    {
      rendObj = ROBJ_IMAGE
      size = [defIconSize, defIconSize]
      image = Picture("!ui/uiskin/perk_step_upgrade.svg:{0}:{0}:K".subst(defIconSize))
      color = sf & S_HOVER ? darkTxtColor : defTxtColor
    }
    mkItemCurrency({
      currencyTpl
      count
      textStyle = {
        color = !isEnough ? negativeTxtColor
          : sf & S_HOVER ? darkTxtColor : defTxtColor
      }
    })
  ]
}.__update(
  mkPerkSlotOverride(sf, onClick),
  { size = [SIZE_TO_CONTENT, btnSlotHeight] }
))


let function mkSoldierSteps(perks) {
  let minText = loc("perks/trainStepsBeforeRank", { steps = perks?.stepsLeft ?? 0 })
  let infoText = loc("perks/trainPriceInfo")
  return mkTextArea($"{minText} {infoText}", { halign = ALIGN_CENTER })
}

let soldierMaxRank = mkTextArea(loc("perks/maxRankReached"), {
  halign = ALIGN_CENTER
  color = completedTxtColor
})


return {
  mkPerkCard
  mkChoosePerkCard
  mkBuyPerkCard
  morePerksHint
  mkTrainRankBtn
  mkTrainStepBtn
  mkSoldierSteps
  soldierMaxRank
}
