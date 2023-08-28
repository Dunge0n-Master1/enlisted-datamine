from "%enlSqGlob/ui_library.nut" import *

let { sub_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let { doesLocTextExist } = require("dagor.localize")
let { setTooltip } = require("%ui/style/cursors.nut")
let tooltipBox = require("%ui/style/tooltipBox.nut")
let math = require("%sqstd/math.nut")
let {
  smallPadding, bigPadding, defTxtColor, perkIconSize, titleTxtColor,
  activeBgColor, msgHighlightedTxtColor
} = require("%enlSqGlob/ui/viewConst.nut")
let colors = require("%ui/style/colors.nut")
let {
  allItemTemplates, findItemTemplate
} = require("%enlist/soldiers/model/all_items_templates.nut")
let { getItemName } = require("%enlSqGlob/ui/itemsInfo.nut")
let { perksStatsCfg, classesConfig, fallBackImage } = require("%enlist/meta/perks/perksStats.nut")
let perksList = require("%enlist/meta/perks/perksList.nut")
let colorize = require("%ui/components/colorize.nut")
let { perksData, getPerkPointsInfo } = require("%enlist/soldiers/model/soldierPerks.nut")
let { pPointsBaseParams, pPointsList } = require("%enlist/meta/perks/perksPoints.nut")

const MIN_ROLL_PERKS = 10
const NEXT_ROLL_PERKS = 5

let COST_ICON_PAIR_WIDTH = hdpx(50)
let BG_DARKEN = Color(0, 0, 0, 255)
let BG_LIGHTEN = Color(10, 10, 10, 255)
let BG_HOVER = Color(35, 35, 35, 255)
let PERK_UNAVAILABLE_COLOR = Color(120, 120, 120, 255)

let mkText = @(txt) {
  rendObj = ROBJ_TEXT
  text = txt
}.__update(sub_txt)

let flexTextArea = @(params) {
  size = [flex(), SIZE_TO_CONTENT]
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  color = defTxtColor
  vplace = ALIGN_CENTER
  halign = ALIGN_LEFT
}.__update(sub_txt, params)


let perkPointIcon = @(icon, color = defTxtColor, pPointSize = hdpxi(32)) {
  rendObj = ROBJ_IMAGE
  size = [pPointSize, pPointSize]
  image = Picture("{0}:{1}:{1}:K".subst(icon, pPointSize))
  color
}

let perkPointCostText = @(pPointCfg, cost) {
  rendObj = ROBJ_TEXT
  text = cost
  color = pPointCfg.color
}

let iconAnimations = [
  { prop = AnimProp.scale, from = [1,1], to = [1.5,1.5],
    play = true, easing = InOutQuad, duration = 0.4 }
  { prop = AnimProp.scale, from = [1.5,1.5], to = [1,1],
    play = true, easing = InOutQuad, delay = 0.4, duration = 0.5 }
]

let valAnimations = [
  { prop = AnimProp.opacity, from = 0.2, to = 1, duration = 0.2
    play = true, easing = InOutCubic }
  { prop = AnimProp.scale, from = [3.5,3.5], to = [1,1],
    play = true, easing = InOutCubic, duration = 1 }
]

let addAnimations = [
  { prop = AnimProp.opacity, from = 0.2, to = 1, duration = 0.3,
    play = true, easing = InOutCubic }
  { prop = AnimProp.opacity, from = 1, to = 1, duration = 0.4,
    play = true, easing = InOutCubic, delay = 0.3}
  { prop = AnimProp.opacity, from = 1, to = 0, duration = 0.35,
    play = true, easing = InOutCubic, delay = 0.7 }
  { prop = AnimProp.translate, from = [0, hdpx(50)], to = [0, hdpx(20)],
    play = true, easing = OutCubic, duration = 1 }
]

local function usedPerkPoints(pPointCfg, pPointId, usedValue, totalValue, changedValue) {
  local leftValue = totalValue - usedValue
  if (leftValue < 0) {
    // show adequate stat values even for inconsistent data
    totalValue = usedValue
    leftValue = 0
  }

  let { icon, color } = pPointCfg
  return {
    halign = ALIGN_RIGHT
    key = $"{pPointId}-{totalValue}-{changedValue}"
    children = [
      {
        flow = FLOW_HORIZONTAL
        valign = ALIGN_CENTER
        children = [
          perkPointIcon(icon, color).__update({
            transform = {}
            animations = changedValue > 0 ? iconAnimations : null
          })
          mkText($"{leftValue}/")
          perkPointCostText(pPointCfg, $"{totalValue}").__update({
            transform = {}
            animations = changedValue > 0 ? valAnimations : null
          })
        ]
      }
      changedValue == 0 ? null : perkPointCostText(pPointCfg, $" +{changedValue}").__update({
        opacity = 0
        transform = {}
        animations = addAnimations
      })
    ]
  }
}

let perkIcon = @(perk, iconSize, iconColor = Color(220,220,220)) function() {
  let size = iconSize.tointeger()
  let statClassMask = (perk?.stats ?? {}).keys()
    .reduce(@(res, statId) res | (perksStatsCfg.value?[statId]?.stat_class ?? 0), 0)
  return {
    watch = perksStatsCfg
    size = [size, size]
    rendObj = ROBJ_IMAGE
    image = Picture("{0}:{1}:{1}:K"
      .subst(classesConfig?[statClassMask].image ?? fallBackImage, size))
    color = iconColor
  }
}

let function mkPerkCostChildren(perk, isUnavailable = false, showFreePerks = false) {
  let perkCost = perk?.cost
  if ((perkCost?.len() ?? 0) == 0)
    return null

  let pPointType = perkCost.keys()[0]
  let pPointsValue = perkCost?[pPointType]
  if (pPointsValue == null || (pPointsValue == 0 && !showFreePerks))
    return null

  local pPointCfg = pPointsBaseParams[pPointType] ?? {}
  if (isUnavailable)
    pPointCfg = pPointCfg.__merge({color = PERK_UNAVAILABLE_COLOR})
  let { icon, color } = pPointCfg
  return {
    flow = FLOW_HORIZONTAL
    size = [flex(), SIZE_TO_CONTENT]
    halign = ALIGN_LEFT
    valign = ALIGN_CENTER
    children = [
      perkPointIcon(icon, color)
      pPointsValue == 0 ? null : perkPointCostText(pPointCfg, pPointsValue)
    ]
  }
}

let function mkPerkCostShort(perk, isUnavailable, statType, style = {}) {
  let pPointsChildren = mkPerkCostChildren(perk, isUnavailable, true)
  if (pPointsChildren == null)
    return null

  local onhoverTooltip = null
  if (isUnavailable){
    let statName = loc($"stat/{statType}_genitive")
    let tooltipText = loc("notEnoughPerkPointsHint", {statName})
    onhoverTooltip = flexTextArea({text = tooltipText, size = SIZE_TO_CONTENT})
  }
  return {
    flow = FLOW_VERTICAL
    halign = ALIGN_RIGHT
    vplace = ALIGN_CENTER
    behavior = Behaviors.Button
    size = [COST_ICON_PAIR_WIDTH, SIZE_TO_CONTENT]
    onHover = !isUnavailable ? null
      : @(on) setTooltip(!on ? null : tooltipBox({
          flow = FLOW_HORIZONTAL
          gap = bigPadding
          valign = ALIGN_CENTER
          children = onhoverTooltip
        }))
    children = pPointsChildren
  }.__merge(style)
}

let function getStatDescList(perkStatsTable, perk, isUnavailable = false) {
  let res = []
  let stats = perk?.stats ?? {}
  foreach (statId, statValue in stats) {
    let locId = $"stat/{statId}/desc"
    if (!doesLocTextExist(locId))
      continue
    let value = statValue * (perkStatsTable?[statId].base_power ?? 0.0)
    let statValueText = math.round_by_value(value, 0.1)
      + (perkStatsTable?[statId].power_type ?? "")
    res.append(loc(locId, {
      value = isUnavailable ? statValueText : colorize(colors.MsgMarkedText, statValueText)
    }))
  }
  return res
}

let function getPerkItems(armyId, items) {
  let res = []
  foreach (itemTpl in items) {
    let item = findItemTemplate(allItemTemplates, armyId, itemTpl)
    if (item == null)
      continue

    res.append(colorize(colors.MsgMarkedText, getItemName(item)))
  }
  return res
}

let getPerkItemsText = @(armyId, items)
  items.len() == 0 ? ""
    : $" {loc("perks/itemsInfo", { items = ", ".join(getPerkItems(armyId, items)) })}"

let mkPerkDesc = @(perksStatsTable, armyId, perk, separator = ", ") "{0}{1}"
  .subst(separator.join(getStatDescList(perksStatsTable, perk)),
    getPerkItemsText(armyId, perk?.items ?? []))

let defIconCtor = @(iconSettings) perkIcon(iconSettings.perk, iconSettings.iconSize,
                                              iconSettings?.color)
let priceIconCtor = @(iconSettings) mkPerkCostShort(iconSettings.perk,
  iconSettings.isUnavailable, iconSettings.statType, iconSettings?.customStyle)

let thumbIconSize = hdpxi(20)

let recommendedPerkIcon = {
  rendObj = ROBJ_IMAGE
  size =  [thumbIconSize, thumbIconSize]
  image = Picture($"!ui/uiskin/thumb.svg:{thumbIconSize}:{thumbIconSize}:K")
}

let perkUi = @(armyId, perkId, customStyle = {}, params = {}) function() {
  let {
    isRecommended, isUnavailable = false, iconSize = perkIconSize, iconCtor = defIconCtor
  } = params

  let perk = perksList.value?[perkId]
  let textParams = {
    text = perk != null
      ? mkPerkDesc(perksStatsCfg.value, armyId, perk)
      : loc("choose_new_perk")
    color = !perk ? titleTxtColor : isUnavailable ? PERK_UNAVAILABLE_COLOR : defTxtColor
    halign = customStyle?.halign ?? ALIGN_LEFT
  }.__update(customStyle?.font!=null && customStyle?.fontSize!=null
    ? {font=customStyle.font, fontSize=customStyle.fontSize}
    : (customStyle?.fontStyle ?? sub_txt))
  let statType = isUnavailable ? perk?.cost.keys()[0] : ""
  let iconSettings = {perk, iconSize, isUnavailable, statType, customStyle}
  return {
    watch = [perksStatsCfg, perksList]
    key = perk
    size = [flex(), iconSize]
    flow = FLOW_HORIZONTAL
    padding = [smallPadding, bigPadding]
    gap = bigPadding
    valign = ALIGN_CENTER
    animations = perk ? null : [
      { prop = AnimProp.opacity, from = 0.6, to = 1, duration = 1, play = true, loop = true, easing = Blink}
    ]

    children = [
      iconCtor(iconSettings)
      isRecommended ? recommendedPerkIcon : null
      flexTextArea(textParams)
    ]
  }.__update(customStyle)
}

let perkCardBg = @(slotNumber, cb = null, params = {}, children = null) watchElemState(@(sf) {
  rendObj = ROBJ_BOX
  size = [flex(), SIZE_TO_CONTENT]
  behavior = cb ? Behaviors.Button : null
  onClick = cb
  sound = {
    hover = "ui/enlist/button_highlight"
    click = "ui/enlist/button_click"
  }
  fillColor = sf & S_HOVER ? BG_HOVER
    : (slotNumber % 2) ? BG_LIGHTEN
    : BG_DARKEN
  borderColor = activeBgColor
  borderWidth = [0, 0, sf & S_HOVER ? 1 : 0, 0]
  children = children
}.__update(params))

let perkCard = kwarg(@(armyId, perkData, slotNumber = 0, cb = null, customStyle = {}) function() {
  if (perksList.value?[perkData.perkId] == null)
    return { watch = perksList }

  return {
    watch = perksList
    size = customStyle?.size ?? [flex(), SIZE_TO_CONTENT]
    children = perkCardBg(slotNumber, cb, customStyle, perkUi(
      armyId,
      perkData.perkId,
      customStyle,
      {
        isSelected = perkData?.isSelected ?? false
        isUnavailable = !(perkData?.isAvailable ?? true)
        iconCtor = priceIconCtor
        isRecommended = perkData?.recommended ?? false
      }
    ))
  }
})

let function uniteEqualPerks(perks) {
  let perksCount = {}
  foreach (perkId in perks)
    perksCount[perkId] <- (perksCount?[perkId] ?? 0) + 1

  let unitedPerks = []
  foreach (perkId in perks) {
    if (perkId not in perksCount)
      continue
    unitedPerks.append({ perkId, amount = perksCount[perkId] })
    delete perksCount[perkId]
  }
  return unitedPerks
}


let tierTitle = @(tier) tier?.locId
  ? {
      rendObj = ROBJ_TEXTAREA
      margin = smallPadding
      behavior = Behaviors.TextArea
      color = titleTxtColor
      text = loc(tier.locId)
    }.__update(sub_txt)
  : null

let perkPointsInfoTooltip = {
  size = [hdpx(400), SIZE_TO_CONTENT]
  flow = FLOW_VERTICAL
  gap = smallPadding
  children = [
    mkText(loc("perkPointsTitle")).__update({ color = msgHighlightedTxtColor })
    flexTextArea({ text = loc("perkPointsDesc") })
  ]
}


let function mkPerksPointsBlock(soldierGuid) {
  if (soldierGuid == null)
    return null

  let perkPointsInfoWatch = Computed(function() {
    let perks = perksData.value?[soldierGuid]
    return perks == null ? null : getPerkPointsInfo(perksList.value, perks)
  })

  local cachedPerks = clone perkPointsInfoWatch.value?.total ?? {}
  return function() {
    let res = { watch = perkPointsInfoWatch }
    let perkPointsInfo = perkPointsInfoWatch.value
    if (perkPointsInfo == null)
      return res

    let children = []
    foreach (pPointId in pPointsList) {
      let pointsAmount = perkPointsInfo.total?[pPointId] ?? 0
      if (pointsAmount <= 0)
        continue
      let pPointCfg = pPointsBaseParams?[pPointId]
      if (pPointCfg == null)
        continue

      let usedValue = perkPointsInfo.used?[pPointId] ?? 0
      let changed = pointsAmount - (cachedPerks?[pPointId] ?? pointsAmount)
      if (changed != 0)
        cachedPerks[pPointId] <- perkPointsInfo.total[pPointId]
      children.append(usedPerkPoints(pPointCfg, pPointId, usedValue, pointsAmount, changed))
    }

    return res.__update({
      behavior = Behaviors.Button
      size = SIZE_TO_CONTENT
      flow = FLOW_HORIZONTAL
      gap = bigPadding
      onHover = @(on) setTooltip(on ? tooltipBox(perkPointsInfoTooltip) : null)
      skipDirPadNav = true
      children = children
    })
  }
}

let function statsRange(statsTable, stat, isLocked) {
  let { icon, color } = pPointsBaseParams[stat]
  let { minVal, maxVal } = statsTable[stat]
  return {
    flow = FLOW_HORIZONTAL
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    children = [
      perkPointIcon(icon, isLocked ? defTxtColor : color)
      {
        rendObj = ROBJ_TEXT
        color = defTxtColor
        text = minVal == maxVal ? maxVal : $"{minVal}-{maxVal}"
      }
    ]
  }
}


let function mkStatList(content, sClassesCfg, isLocked = false) {
  let { soldierClasses, soldierTierMax, soldierTierMin, soldierRareMax,
    soldierRareMin, soldierHasMaxStats } = content
  let { pointsByTiers = [], perkPointsModifications = []
    } = sClassesCfg?[soldierClasses[0]] ?? {}

  local stats = {}
  let statsMax = pointsByTiers[min(soldierTierMax, pointsByTiers.len() - 1)]
  let maxRareModifications = min(soldierRareMax, perkPointsModifications.len() - 1)
  foreach (statId in pPointsList) {
    let maxVal = statsMax[statId].max
      + (perkPointsModifications[maxRareModifications]?[statId] ?? 0)
    stats[statId] <- {
      maxVal
      minVal = soldierHasMaxStats ? maxVal
        : pointsByTiers[soldierTierMin][statId].min +
          (perkPointsModifications[max(soldierRareMin, 0)]?[statId] ?? 0)
    }
  }
  return {
    flow = FLOW_HORIZONTAL
    halign = ALIGN_LEFT
    size = [hdpx(260), hdpx(32)]
    gap = bigPadding
    children = pPointsList.map(@(x) statsRange(stats, x, isLocked))
  }
}

return {
  mkText
  perkIcon
  flexTextArea
  getStatDescList
  mkPerkCostChildren
  perkCard
  perkCardBg
  tierTitle
  uniteEqualPerks
  perkPointIcon
  perkPointCostText
  usedPerkPoints
  mkPerksPointsBlock
  mkPerkDesc
  thumbIconSize
  perkUi
  priceIconCtor
  mkStatList
}