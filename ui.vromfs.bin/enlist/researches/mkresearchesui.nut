from "%enlSqGlob/ui_library.nut" import *

let cursors = require("%ui/style/cursors.nut")
let colorize = require("%ui/components/colorize.nut")
let mkCurSquadsList = require("%enlSqGlob/ui/mkSquadsList.nut")
let hoverImage = require("%enlist/components/hoverImage.nut")
let faComp = require("%ui/components/faComp.nut")
let researchStatusesCfg = require("researchStatuses.nut")
let armySelectUi = require("%enlist/soldiers/army_select.ui.nut")

let { isGamepad } = require("%ui/control/active_controls.nut")
let { mkHotkey } = require("%ui/components/uiHotkeysHint.nut")
let { sound_play } = require("%dngscripts/sound_system.nut")
let { safeAreaBorders } = require("%enlist/options/safeAreaState.nut")
let { Bordered } = require("%ui/components/txtButton.nut")
let { PrimaryFlat, Purchase } = require("%ui/components/textButton.nut")
let { mkGlyphsStyle } = require("%enlSqGlob/ui/soldierClasses.nut")
let { makeHorizScroll } = require("%ui/components/scrollbar.nut")
let { fontSmall, fontMedium, fontLarge } = require("%enlSqGlob/ui/fontsStyle.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { blinkUnseenIcon } = require("%ui/components/unseenSignal.nut")
let { mkLockByCampaignProgress } = require("%enlist/soldiers/lockCampaignPkg.nut")
let { mkDisabledSectionBlock } = require("%enlist/mainMenu/disabledSections.nut")
let { mkCurUnseenResearchesBySquads } = require("unseenResearches.nut")
let { isSquadPremium, mkCardText, mkActiveBlock } = require("%enlSqGlob/ui/squadsUiComps.nut")
let { iconByGameTemplate, getItemName } = require("%enlSqGlob/ui/itemsInfo.nut")
let { curArmy, armySquadsById, curUnlockedSquads } = require("%enlist/soldiers/model/state.nut")
let { gradientProgressBar } = require("%enlSqGlob/ui/defComponents.nut")
let { mkColoredGradientX } = require("%enlSqGlob/ui/gradients.nut")
let { promoWidget } = require("%enlist/components/mkPromoWidget.nut")
let { researchToShow } = require("researchesFocus.nut")
let { purchaseMsgBox } = require("%enlist/currency/purchaseMsgBox.nut")
let { mkCurrency } = require("%enlist/currency/currenciesComp.nut")
let { currenciesList } = require("%enlist/currency/currencies.nut")
let { jumpToArmyProgress } = require("%enlist/mainMenu/sectionsState.nut")
let { disableSquadExp } = require("%enlist/campaigns/campaignConfig.nut")

let {
  mkViewStructure, tableStructure, selectedTable, hasResearchesSection,
  curArmySquadsProgress, allSquadsPoints, viewSquadId, armiesResearches,
  viewArmy, researchStatuses, selectedResearch, curSquadProgress, curSquadPoints,
  isBuyLevelInProgress, isResearchInProgress, closestTargets, buySquadLevel,
  RESEARCHED, CAN_RESEARCH, NOT_ENOUGH_EXP
} = require("researchesState.nut")
let {
  contentOffset, columnGap, colPart, colFull, smallPadding, midPadding, accentColor,
  panelBgColor, darkTxtColor, titleTxtColor, defTxtColor,
  bigPadding, weakTxtColor, negativeTxtColor, darkPanelBgColor, brightAccentColor,
  attentionTxtColor, leftAppearanceAnim, completedTxtColor, hoverSlotBgColor
} = require("%enlSqGlob/ui/designConst.nut")
let spinner = require("%ui/components/spinner.nut")


const FOUR_TO_NEXT_BRANCH = 4
const THREE_TO_NEXT_BRANCH = 3
const TWO_TO_NEXT_BRANCH = 2

let levelAndExpColor = 0xFFFFB200
let commonIconColor = 0xFFFFFFFF
let smallUnseenIcon = blinkUnseenIcon(0.7)
let pagesIcons = [ "upgrades_icon_squad", "upgrades_icon_personnel", "upgredes_icon_work_shop" ]
let waitingSpinner = spinner(hdpx(35))

let btnSound = freeze({
  hover = "ui/enlist/button_highlight"
  click = "ui/enlist/button_click"
  active = "ui/enlist/button_action"
})

let iconSize = colPart(0.2)
let squadLineWidth = colFull(2)
let researchInfoWidth = colFull(5)
let lineDashSize = hdpx(3)
let priceIconSize = colPart(0.4)

let headerHeight = colPart(2.7)
let pageSize        = [colPart(2.5), colPart(1.2)]
let pageIconSize    = [colPart(0.8), colPart(0.8)]
let itemSlotArea    = [colPart(4.5), colPart(1.7)]
let childSlotSize   = [colPart(2),   colPart(3)]
let slotSize        = [colPart(2),   colPart(2)]
let slotGapSize     = [colPart(2.5), colPart(2)]
let slotMiniGapSize = [colPart(1),   colPart(2)]
let vertLineSize    = [colPart(2),   colPart(1)]
let itemSlotSize    = [colPart(3.5), colPart(1.2)]

let defTxtStyle = { color = defTxtColor }.__update(fontMedium)
let priceTxtStyle = { color = titleTxtColor }.__update(fontMedium)
let headerTxtStyle = { color = titleTxtColor }.__update(fontLarge)
let hintTxtStyle = { color = weakTxtColor }.__update(fontSmall)
let nameTxtStyle = { color = titleTxtColor }.__update(fontLarge)
let attentionTxtStyle = { color = attentionTxtColor }.__update(fontLarge)

let progressBarBgImage = mkColoredGradientX({colorLeft=0xFFFC7A40, colorRight=brightAccentColor})

let scrollHandler = ScrollHandler()

let iconSquadPoints = {
  rendObj = ROBJ_IMAGE
  size = array(2, iconSize)
  image = Picture("!ui/uiskin/research/squad_points_icon.svg:{0}:{0}:K".subst(iconSize))
}

let priceIcon = {
  rendObj = ROBJ_IMAGE
  size = [priceIconSize, priceIconSize]
  image = Picture("!ui/uiskin/research/squad_points_icon.svg:{0}:{0}:K".subst(priceIconSize))
}

let researchedSign = faComp("check-circle-o", {
  fontSize = colPart(1)
  color = completedTxtColor
})
let researchedPageSign = faComp("check-circle-o", {
  vplace = ALIGN_BOTTOM
  margin = [midPadding, columnGap]
  fontSize = colPart(0.5)
  color = completedTxtColor
})

let classesTagsTable = mkGlyphsStyle(colPart(0.4))

let mkText = @(txt, override) {
  rendObj = ROBJ_TEXT
  text = txt
}.__update(override)

let mkTextarea = @(txt, override) {
  size = [flex(), SIZE_TO_CONTENT]
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  tagsTable = classesTagsTable
  text = txt
}.__update(override)


let mkSquadExp = function(squadId) {
  let exp = Computed(@() allSquadsPoints.value?[squadId] ?? 0)
  return @(sf, selected) @() mkActiveBlock(sf, selected, [
    mkCardText(exp.value, sf, selected)
    iconSquadPoints
  ]).__update({ watch = exp, valign = ALIGN_CENTER, gap = hdpx(3) })
}

let function mkSquadMkChild(squadId, curUnseen) {
  return @(sf, selected) {
    hplace = ALIGN_RIGHT
    margin = smallPadding
    flow = FLOW_VERTICAL
    halign = ALIGN_RIGHT
    valign = ALIGN_CENTER
    children = [
      mkSquadExp(squadId)(sf, selected)
      squadId in curUnseen ? smallUnseenIcon : null
    ]
  }
}

let mkResearchesSquads = @(curUnseenState)
  Computed(@() (curUnlockedSquads.value ?? [])
    .map(@(s) s.__merge({
      mkChild = mkSquadMkChild(s.squadId, curUnseenState.value)
      level = curArmySquadsProgress.value?[s.squadId].level ?? 0
    })))


let mkPicName = memoize(@(pageIdx) $"!ui/uiskin/research/{pagesIcons[pageIdx]}.svg:{pageIconSize[0]}:{pageIconSize[1]}:K")

let selectedColor = mul_color(panelBgColor, 1.25)

let mkResearchPageSlot = @(pageIdx, isSelected, isHover) {
  rendObj = ROBJ_BOX
  size = pageSize
  fillColor = isHover
    ? hoverSlotBgColor
    : isSelected ? selectedColor : panelBgColor
  borderWidth = isSelected ? [0, 0, hdpx(4), 0] : 0
  borderColor = isSelected ? accentColor : 0
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = {
    rendObj = ROBJ_IMAGE
    size = pageIconSize
    color = isHover
      ? darkTxtColor
      : isSelected ? titleTxtColor : defTxtColor
    image = Picture(mkPicName(pageIdx))
  }
}

let function gotoNextPage() {
  let total = tableStructure.value?.pages.len() ?? 0
  if (total > 0)
    selectedTable((selectedTable.value + 1) % total)
}

let switchPageKey = @() {
  size = [0, SIZE_TO_CONTENT]
  watch = isGamepad
  padding = columnGap
  vplace = ALIGN_CENTER
  children = isGamepad.value ? mkHotkey("J:X", gotoNextPage) : null
}

let function calculateCount(researches) {
  let existingResearches = {}
  return researches.reduce(function(count, research) {
    if (research?.isLocked ?? false)
      return count
    let { multiresearchGroup = 0 } = research
    if (multiresearchGroup == 0)
      return count + 1
    if (multiresearchGroup in existingResearches)
      return count
    existingResearches[multiresearchGroup] <- true
    return count + 1
  }, 0)
}

let mkPagesListUi = @(pagesInfo) function() {
  let { pages = [] } = tableStructure.value
  return {
    watch = tableStructure
    hplace = ALIGN_CENTER
    flow = FLOW_HORIZONTAL
    children = pages.map(function(_curPage, pageIdx) {
      let isSelected = Computed(@() selectedTable.value == pageIdx)
      let isCompleted = Computed(function() {
        let { available = 0, completed = 0 } = pagesInfo.value?[pageIdx]
        return available > 0 && completed >= available
      })
      return {
        children = [
          watchElemState(@(sf) {
            watch = isSelected
            behavior = Behaviors.Button
            onClick = @() selectedTable(pageIdx)
            sound = btnSound
            children = mkResearchPageSlot(pageIdx, isSelected.value, sf & S_HOVER)
          })
          @() {
            watch = isCompleted
            children = isCompleted.value ? researchedPageSign : null
          }
        ]
      }
    })
    .append(switchPageKey)
  }
}

let function mkPagesInfoUi(pagesInfo) {
  let mkResearchPageInfo = @(pageName, pageDesc, statusTxt) {
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    gap = midPadding
    children = [
      {
        size = [flex(), SIZE_TO_CONTENT]
        flow = FLOW_HORIZONTAL
        gap = { size = flex() }
        children = [
          pageName!= null ? mkText(utf8ToUpper(loc(pageName)), headerTxtStyle) : null
          mkText(loc(statusTxt), headerTxtStyle)
        ]
      }
      {
        key = pageDesc
        size = [flex(), SIZE_TO_CONTENT]
        rendObj = ROBJ_TEXTAREA
        behavior = Behaviors.TextArea
        text = loc(pageDesc)
      }.__update(defTxtStyle)
    ]
  }

  let pInfo = Computed(@() pagesInfo.value?[selectedTable.value])
  return function() {
    let { name = "", description = "", completed = 0, available = 0 } = pInfo.value
    return {
      watch = pInfo
      size = [flex(), SIZE_TO_CONTENT]
      children = mkResearchPageInfo(name, description, $"{completed}/{available}")
    }
  }
}

let function mkHeaderUi() {
  let pagesInfo = Computed(function() {
    let statuses = researchStatuses.value
    let { pages = [] } = tableStructure.value
    let res = pages.map(function(page) {
      let { tables = {}, name = null, description = null } = page
      let available = calculateCount(tables)
      let completed = tables.reduce(@(res, val)
        statuses?[val.research_id] == RESEARCHED ? res + 1 : res, 0)
      return { name, description, available, completed }
    })
    return res
  })
  return {
    size = [pageSize[0] * 3, headerHeight]
    hplace = ALIGN_CENTER
    flow = FLOW_VERTICAL
    gap = columnGap
    children = [
      mkPagesListUi(pagesInfo)
      mkPagesInfoUi(pagesInfo)
    ]
  }
}


let researchHoverBg = {
  rendObj = ROBJ_IMAGE
  size = [colPart(4), colPart(4)]
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  image = Picture($"!ui/uiskin/research/research_select_bg.avif?Ac")
}

let pageIcons = [
  "page_squad_upgrades_bg",
  "page_personnel_upgrades_bg",
  "page_workshop_upgrades_bg"
]

let iconColors = {
  disabled = 0x99999999
  veteran = 0xCCF6FF00
  disabled_veteran = 0x55F6FF00
}

let customIcons = freeze({
  artillery_type_unlock_3_icon = "artillery_type_unlock_2_icon"
  artillery_type_unlock_4_icon = "artillery_type_unlock_2_icon"
  artillery_type_unlock_5_icon = "artillery_type_unlock_2_icon"
  artillery_type_unlock_6_icon = "artillery_type_unlock_2_icon"
  artillery_type_unlock_7_icon = "artillery_type_unlock_2_icon"
  artillery_type_unlock_8_icon = "artillery_type_unlock_2_icon"
  artillery_type_unlock_9_icon = "artillery_type_unlock_2_icon"
  artillery_type_unlock_10_icon = "artillery_type_unlock_2_icon"
  artillery_type_unlock_11_icon = "artillery_type_unlock_2_icon"
  artillery_type_unlock_12_icon = "artillery_type_unlock_2_icon"
  artillery_type_unlock_13_icon = "artillery_type_unlock_2_icon"
})

let blinkAnim = {
  prop = AnimProp.opacity, from = 0.6, to = 1, easing = CosineFull,
  duration = 2, play = true, loop = true
}

let function mkResearchIcon(
  pageIdx, iconId, hasResearched, canResearch, isHover, isSelected, researchId
) {
  let isActive = hasResearched || canResearch
  let bgName = pageIcons?[pageIdx]
  let disabledSuffix = hasResearched ?  "" : "_disabled"
  let bgImgPath = $"!ui/uiskin/research/icons/{bgName}{disabledSuffix}.avif?Ac"
  let bgSaturate = isActive ? 1 : 0.3

  let isVeteran = iconId.endswith("_veteran")
  let iconName = isVeteran ? "common_veteran" : (customIcons?[iconId] ?? $"{iconId}")
  let iconPath = $"!ui/uiskin/research/icons/{pageIdx}_{iconName}.avif?Ac"

  let iconColor = isVeteran
    ? (isActive ? iconColors["veteran"] : iconColors["disabled_veteran"])
    : (isActive ? commonIconColor : iconColors["disabled"])

  let frameObj = canResearch
    ? {
        key = $"frame_{researchId}"
        rendObj = ROBJ_IMAGE
        size = flex()
        image = Picture($"!ui/uiskin/research/icons/{bgName}_frame.avif?Ac")
        animations = [ blinkAnim ]
      }
    : null

  return {
    size = flex()
    padding = [0, midPadding]
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    children = [
      isHover || isSelected ? researchHoverBg : null
      {
        rendObj = ROBJ_IMAGE
        size = flex()
        image = Picture(bgImgPath)
        picSaturate = bgSaturate
      }
      frameObj
      {
        rendObj = ROBJ_IMAGE
        size = flex()
        image = Picture(iconPath)
        color = iconColor
      }
    ]
  }
}

let lockSign = faComp("ban", {
  margin = [0, columnGap]
  vplace = ALIGN_BOTTOM
  fontSize = colPart(0.7)
  color = negativeTxtColor
})

let function mkResearchSlot(pageIdx, research, selectedId, statuses, onClick, onDoubleClick, multViewData = null) {
  let { hasMultUsed = false, hasSelectedInGroup = false, hasResearchedInGroup = false } = multViewData
  let { research_id = null, icon_id = null } = research
  let isSelected = research_id == selectedId
  let status = statuses?[research_id]
  let hasResearched = status == RESEARCHED
  let canResearch = status == CAN_RESEARCH
  let hasLockSign = hasMultUsed && status != RESEARCHED
    && (hasResearchedInGroup || (hasSelectedInGroup && !isSelected))

  return watchElemState(function(sf) {
    let isHover = (sf & S_HOVER) != 0
    return {
      size = slotSize
      behavior = Behaviors.Button
      onClick
      sound = btnSound
      onDoubleClick
      xmbNode = XmbNode({
        canFocus = @() true
        wrap = false
        isGridLine=true
        scrollToEdge = [true, false]
      })
      children = [
        hoverImage.create({
          sf = sf
          uid = research_id
          size = slotSize
          image = null
          pivot = [0.5, 0.5]
          children = mkResearchIcon(pageIdx, icon_id, hasResearched,
            canResearch, isHover, isSelected, research_id)
        })
        hasLockSign ? lockSign : null
      ]
    }
  })
}


let ORIENTATIONS = freeze({
  TOP = "TOP"
  BOTTOM = "BOTTOM"
  BOTTOM_LEFT = "BOTTOM_LEFT"
  BOTTOM_RIGHT = "BOTTOM_RIGHT"
})

let lineOffset = (columnGap / 2).tointeger()

let baseLineStyle = {
  color = 0xFF999999
  lineWidth = hdpx(1)
}
let gainLineStyle = {
  color = brightAccentColor
  lineWidth = hdpx(2)
}

let vectorStyle = {
  size = flex()
  margin = [lineOffset, 0]
  rendObj = ROBJ_VECTOR_CANVAS
  lineWidth = hdpx(1)
}

let topVector = { commands = [[ VECTOR_LINE, 50, 0, 50, 100 ]] }
let diagonalVector = { commands = [[ VECTOR_LINE, 100, 0, 0, 100 ]] }
let btmLeftVector = { commands = [[ VECTOR_LINE, 80, 0, 65, 100 ]] }
let btmRightVector = { commands = [[ VECTOR_LINE, 20, 0, 35, 100 ]] }

let multResearchSelectHint = mkText(loc("multResearchSelectHint"), {
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
}.__update(hintTxtStyle))

let mkTopMultVector = @(override = {}) {
  commands = [
    [ VECTOR_LINE_DASHED, 50, 0, 50, 30, lineDashSize, lineDashSize ],
    [ VECTOR_LINE_DASHED, 50, 80, 50, 100, lineDashSize, lineDashSize ],
    [ VECTOR_LINE_DASHED, 5, 100, 95, 100, lineDashSize, lineDashSize ]
  ]
  children = multResearchSelectHint
}.__update(override)

let mkBtmMultVector = @(override = {}) {
  commands = [
    [ VECTOR_LINE_DASHED, 50, 100, 50, 80, lineDashSize, lineDashSize ],
    [ VECTOR_LINE_DASHED, 50, 30, 50, 0, lineDashSize, lineDashSize ],
    [ VECTOR_LINE_DASHED, 5, 0, 95, 0, lineDashSize, lineDashSize ]
  ]
  children = multResearchSelectHint
}.__update(override)

let mkChainVertLine = @(override = {}) {
  size = flex()
  children = vectorStyle.__merge(topVector.__merge(override))
}

let mkChainBtmLeftLine = @(override = {}) {
  size = flex()
  children = vectorStyle.__merge(btmLeftVector.__merge(override))
}

let mkChainBtmRightLine = @(override = {}) {
  size = flex()
  children = vectorStyle.__merge(btmRightVector.__merge(override))
}

let mkGapLongHorLine = @(override = {}) vectorStyle.__merge({
  size = slotGapSize
  margin = 0
  commands = [[ VECTOR_LINE, 0, 50, 100, 50 ]]
}, override)

let mkGapVertTopLine = @(override = {}) {
  size = slotMiniGapSize
  children = {
    size = vertLineSize
    pos = [slotMiniGapSize[0], -vertLineSize[1]]
    children = mkChainVertLine(override)
  }
}

let mkGapVertBtmLine = @(override = {}) {
  size = slotMiniGapSize
  children = {
    size = vertLineSize
    pos = [slotMiniGapSize[0], slotSize[1]]
    children = mkChainVertLine(override)
  }
}

let mkResearcheMiniGap = @(override = {}) vectorStyle.__merge({
  size = slotMiniGapSize
  margin = 0
  commands = [[ VECTOR_LINE, 0, 50, 100, 50 ]]
}, override)

let stepLengtGaps4 = {
  [1] = mkGapVertBtmLine,
  [2] = mkResearcheMiniGap,
  [3] = mkGapVertTopLine,
  [4] = mkResearcheMiniGap
}
let stepLengtGaps3 = {
  [1] = mkResearcheMiniGap,
  [2] = mkGapVertBtmLine,
  [3] = mkResearcheMiniGap
}
let stepLengtGaps2 = {
  [1] = mkResearcheMiniGap,
  [2] = @(override = {}) {
    size = [colPart(1), colPart(3)]
    pos = [0, colPart(1)]
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    children = {
      size = slotSize
      children = vectorStyle.__merge(diagonalVector, override)
    }
  }
}

let mkVertTopGapWithoutOffset = @(override = {}) {
  size = [0, slotMiniGapSize[1]]
  children = {
    size = vertLineSize
    pos = [0, -vertLineSize[1]]
    children = mkChainVertLine(override)
  }
}

let mkVertBtmGapWithoutOffset = @(override = {}) {
  size = [0, slotMiniGapSize[1]]
  children = {
    size = vertLineSize
    pos = [0, slotSize[1]]
    children = mkChainVertLine(override)
  }
}

let function mkResearchMult(pageIdx, researches, selectedId, statuses, cbCtor, doubleCbCtor, orientation) {
  let multViewData = {
    hasMultUsed = true
    hasResearchedInGroup = researches.findvalue(@(r) statuses?[r.research_id] == RESEARCHED ) != null
    hasSelectedInGroup = researches.findvalue(@(r) r.research_id == selectedId ) != null
  }
  let isTop = orientation == ORIENTATIONS.TOP
  local yPos = isTop ? -childSlotSize[1] : slotSize[1]

  let hasGained = researches.findindex(function(r) {
    let status = statuses[r.research_id]
    return status == RESEARCHED || status == CAN_RESEARCH
  }) != null
  let lineStyle = hasGained ? gainLineStyle : baseLineStyle
  return {
    pos = [0, yPos]
    size = childSlotSize
    halign = ALIGN_CENTER
    children = {
      size = [SIZE_TO_CONTENT, flex()]
      flow = FLOW_VERTICAL
      children = [
        isTop ? null : vectorStyle.__merge(mkTopMultVector(lineStyle))
        {
          flow = FLOW_HORIZONTAL
          children = researches.map(@(r)
            mkResearchSlot(pageIdx, r, selectedId, statuses, cbCtor(r), doubleCbCtor(r), multViewData))
        }
        isTop ? vectorStyle.__merge(mkBtmMultVector(lineStyle)) : null
      ]
    }
  }
}

let function mkResearchChain(pageIdx, researches, selectedId, statuses, cbCtor, doubleCbCtor, orientation) {
  let xPos = orientation == ORIENTATIONS.BOTTOM_LEFT ? (-0.6 * slotSize[0]).tointeger()
    : orientation == ORIENTATIONS.BOTTOM_RIGHT ? (0.6 * slotSize[0]).tointeger()
    : 0
  let isBottom = orientation != ORIENTATIONS.TOP
  local yPos = isBottom ? slotSize[1] : -childSlotSize[1]
  return {
    children = researches.map(function(r, idx) {
      let status = statuses[r.research_id]
      let hasGained = status == RESEARCHED || status == CAN_RESEARCH
      let lineStyle = hasGained ? gainLineStyle : baseLineStyle
      yPos += childSlotSize[1] * idx * (isBottom ? 1 : -1)
      return {
        pos = [xPos, yPos]
        size = childSlotSize
        flow = FLOW_VERTICAL
        children = [
          orientation == ORIENTATIONS.TOP ? null
            : orientation == ORIENTATIONS.BOTTOM || idx > 0 ? mkChainVertLine(lineStyle)
            : orientation == ORIENTATIONS.BOTTOM_LEFT ? mkChainBtmLeftLine(lineStyle)
            : orientation == ORIENTATIONS.BOTTOM_RIGHT ? mkChainBtmRightLine(lineStyle)
            : null
          mkResearchSlot(pageIdx, r, selectedId, statuses, cbCtor(r), doubleCbCtor(r))
          orientation == ORIENTATIONS.TOP ? mkChainVertLine(lineStyle) : null
        ]
      }
    })
  }
}

let function mkResearchChildren(
  pageIdx, children, selectedId, statuses, cbCtor, orientation, doubleCbCtor
) {
  let { researches = null, multiresearchGroup = 0 } = children
  if (researches == null)
    return null

  let ctor = multiresearchGroup > 0 ? mkResearchMult : mkResearchChain
  return ctor(pageIdx, researches, selectedId, statuses, cbCtor, doubleCbCtor, orientation)
}

let function mkResearchColumn(pageIdx, idx, main, children, selectedId, statuses,
  hasLongBranches, cbCtor, doubleCbCtor, rGap
) {
  let [ btmChildren = null, topChildren = null, addBtmChildren = null ] = children
  let { research_id } = main

  let hasMultiresearch = (topChildren?.multiresearchGroup ?? 0) > 0
    || (btmChildren?.multiresearchGroup ?? 0) > 0
  let reqOptimization = !hasMultiresearch && hasLongBranches

  let btmOrientation = addBtmChildren != null || (reqOptimization && topChildren != null)
    ? ORIENTATIONS.BOTTOM_LEFT
    : ORIENTATIONS.BOTTOM

  let topOrientation = !reqOptimization || btmChildren == null
    ? ORIENTATIONS.TOP
    : ORIENTATIONS.BOTTOM_RIGHT

  return {
    flow = FLOW_HORIZONTAL
    children = [
      idx == 0 ? null : rGap
      {
        key = research_id
        size = slotSize
        children = [
          mkResearchChildren(pageIdx, topChildren, selectedId, statuses, cbCtor,
            topOrientation, doubleCbCtor)
          mkResearchSlot(pageIdx, main, selectedId, statuses, cbCtor(main),
            doubleCbCtor(main))
          mkResearchChildren(pageIdx, btmChildren, selectedId, statuses, cbCtor,
            btmOrientation, doubleCbCtor)
          mkResearchChildren(pageIdx, addBtmChildren, selectedId, statuses, cbCtor,
            ORIENTATIONS.BOTTOM_RIGHT, doubleCbCtor)
        ]
      }
    ]
  }
}


let fourStepLength = {
  [2] = {
    size = [0, SIZE_TO_CONTENT]
    pos = [0, childSlotSize[1]]
  },
  [3] = { pos = [0, childSlotSize[1]] },
  [4] = { size = [0, SIZE_TO_CONTENT] }
}
let threeStepLength = {
  [1] = {
    size = [0, SIZE_TO_CONTENT]
    pos = [0, -childSlotSize[1]]
  },
  [2] = { pos = [0, -childSlotSize[1]] },
  [3] = { size = [0, SIZE_TO_CONTENT] }
}


let function mkResearchesTreeUi() {
  let researchCbCtor = @(research) @() selectedResearch(research)
  let researchDoubleCbCtor = @(research) function() {
    let statuses = researchStatuses.value
    if (statuses == null || research == null)
      return

    let { research_id = null } = research
    let status = statuses?[research_id]
    let cfg = researchStatusesCfg?[status](research)

    let { onResearch = null } = cfg
    if (onResearch != null)
      onResearch()
  }

  let viewStructure = mkViewStructure()

  let columnsInfo = Computed(function() {
    let columnPositions = [0]
    let { researches = {} } = tableStructure.value
    let { research_id = null } = selectedResearch.value
    let pageIdx = selectedTable.value
    let rStatuses = researchStatuses.value
    let { columns, maxChildHeight } = viewStructure.value
    let hasResearchItem = columns.findindex(@(c)
      (c?.template ?? "") != "" && (c?.tplCount ?? 0) > 0) != null
    let needTopCurveSpace = columns.findindex(@(c)
        (c?.toChildren ?? 0) >= FOUR_TO_NEXT_BRANCH) == null
      && columns.findindex(@(c) (c?.toChildren ?? 0) >= TWO_TO_NEXT_BRANCH) != null

    let hasLongBranches = (maxChildHeight?[0] ?? 0) + (maxChildHeight?[1] ?? 0) > 2
    let offsetFactor = hasLongBranches || hasResearchItem ? 0
      : needTopCurveSpace ? 35
      : 100 * (maxChildHeight[1] + 1) / (maxChildHeight[0] + maxChildHeight[1] + 3)
    let hasItemLink = columns.findindex(@(c) c?.template != null) != null

    local req4CustomNests = false
    local req3CustomNests = false
    local req2CustomNests = false
    local needTopLine = false

    let researchColumns = columns.map(function(column, idx) {
      let { main, children, toChildren } = column

      let prevChildren = columns?[idx - 1].children ?? []
      let hasChildren = children.findvalue(@(ch) ch != null) != null
        && prevChildren.findvalue(@(ch) ch != null) != null
      let hasMult = children.findvalue(@(ch) (ch?.multiresearchGroup ?? 0) > 0) != null
        && req4CustomNests
      let hasLongBranch = children.reduce(@(r, ch) r + (ch?.children ?? []).len(), 0) > 2

      if (toChildren >= FOUR_TO_NEXT_BRANCH)
        req4CustomNests = true
      else if (!req4CustomNests && !hasLongBranches
          && toChildren == THREE_TO_NEXT_BRANCH)
        req3CustomNests = true
      else if (!req3CustomNests && !hasLongBranches
          && !req4CustomNests && toChildren == TWO_TO_NEXT_BRANCH)
        req2CustomNests = true
      else if (toChildren == 0) {
        needTopLine = req3CustomNests || req2CustomNests
        req4CustomNests = false
        req3CustomNests = false
        req2CustomNests = false
      }

      let chStyleId = hasItemLink || hasChildren || hasMult || hasLongBranch ? 0
        : req4CustomNests || req3CustomNests || req2CustomNests ? toChildren
        : FOUR_TO_NEXT_BRANCH

      let rMain = researches[main]
      let rMainId = rMain.research_id
      let rChildren = children.map(@(child) child == null ? null
        : {
            multiresearchGroup = child.multiresearchGroup
            researches = child.children.map(@(c) researches[c])
          })

      let nest = req4CustomNests ? (fourStepLength?[chStyleId] ?? {})
        : req3CustomNests ? (threeStepLength?[chStyleId] ?? {})
        : req2CustomNests ? (threeStepLength?[chStyleId] ?? {})
        : {}

      let hasGained = rStatuses[rMainId] == RESEARCHED || rStatuses[rMainId] == CAN_RESEARCH
      let lineStyle = hasGained ? gainLineStyle : baseLineStyle
      local researchGap = null
      if (req4CustomNests)
        researchGap = chStyleId == 3 && idx == 1
          ? mkVertTopGapWithoutOffset(lineStyle)
          : stepLengtGaps4?[min(chStyleId, stepLengtGaps4.len())](lineStyle)
              ?? mkGapLongHorLine(lineStyle)
      else if (req3CustomNests)
        researchGap = chStyleId == 2 && idx == 1
          ? mkVertBtmGapWithoutOffset(lineStyle)
          : stepLengtGaps3?[min(chStyleId, stepLengtGaps3.len())](lineStyle)
              ?? mkGapLongHorLine(lineStyle)
      else if (req2CustomNests)
        researchGap = chStyleId == 1 && idx == 1
          ? mkResearcheMiniGap(lineStyle)
          : stepLengtGaps2?[min(chStyleId, stepLengtGaps2.len())](lineStyle)
              ?? mkGapLongHorLine(lineStyle)
      else
        researchGap = needTopLine
          ? mkGapVertTopLine(lineStyle)
          : stepLengtGaps4?[min(chStyleId, stepLengtGaps4.len())](lineStyle)
              ?? mkGapLongHorLine(lineStyle)

      needTopLine = false
      let isNestSame = "size" in nest && nest.size[0] == 0
      let prevPos = columnPositions[columnPositions.len() - 1]
      columnPositions.append(isNestSame
        ? prevPos
        : prevPos + slotSize[0] + (researchGap?.size[0] ?? 0))

      let rGap = researchGap.__merge(hasGained ? gainLineStyle : baseLineStyle)
      let columnObject = mkResearchColumn(pageIdx, idx, rMain, rChildren, research_id, rStatuses,
        hasLongBranches, researchCbCtor, researchDoubleCbCtor, rGap)
      return { children = columnObject }.__update(nest)
    })
    return {offsetFactor, hasItemLink, hasLongBranches, researchColumns, columns, columnPositions}
  })

  let hasScroll = Computed(function() {
    let {columnPositions} = columnsInfo.value
    let contentWidth = (columnPositions.len()> 0 ? columnPositions.top() : 0)+ slotSize[0]
    let saBorders = safeAreaBorders.value
    let saSideOffset = saBorders[1] + saBorders[3]
    let freeWidth = sw(100) - (saSideOffset + colPart(1) + researchInfoWidth + squadLineWidth)
    return contentWidth > freeWidth
  })


  let needScrollClosest = Watched(false)
  let closestResearch = Computed(@() closestTargets.value?[selectedTable.value])
  closestResearch.subscribe(@(_) needScrollClosest(true))

  let function scrollToResearch(columns, curResearch) {
    if (columns == null)
      return

    let column = columns.findindex(@(col) col.main == curResearch
      || col.children.findvalue(@(branch) (branch?.children ?? [])
          .indexof(curResearch) != null) != null)
    if (column != null)
      scrollHandler.scrollToX(columnsInfo.value.columnPositions?[column] ?? 0)
  }

  let xmbContainer = XmbContainer({
    isGridLine = true
    canFocus = @() false
    wrap = false
    scrollSpeed = [2.0, 0]
  })

  let attractResearchWatchers = [researchToShow, needScrollClosest,
    closestResearch, viewStructure]

  let attractorFunc = function(_) {
    let r = needScrollClosest.value ? closestResearch.value : researchToShow.value
    if (r == null)
      return

    let { columns } = viewStructure.value
    let { research_id } = r
    scrollToResearch(columns, research_id)
    defer(function() {
      researchToShow(null)
      needScrollClosest(false)
    })
  }
  let onAttach = function() {
    foreach (w in attractResearchWatchers)
      w.subscribe(attractorFunc)
  }
  let onDetach = function() {
    foreach (w in attractResearchWatchers)
      w.unsubscribe(attractorFunc)
  }

  let function mkResearchItem(column, isLast) {
    let { template = null, tplCount = 0 } = column
    if (template == null || tplCount == 0)
      return isLast ? null : { size = [itemSlotArea[0], 0] }

    return {
      size = isLast ? [SIZE_TO_CONTENT, itemSlotArea[1]] : itemSlotArea
      children = [
        {
          pos = [-columnGap, 0]
          size = [tplCount * itemSlotArea[0] - colPart(1), itemSlotArea[1] + colPart(9)]
          rendObj = ROBJ_SOLID
          opacity = 0.05
          color = 0xFFFFFF
        }
        {
          flow = FLOW_VERTICAL
          children = [
            mkText(getItemName(template), {
              margin = [columnGap, 0, smallPadding, 0]
            }.__update(defTxtStyle))
            {
              size = itemSlotSize
              rendObj = ROBJ_SOLID
              color = panelBgColor
              children = iconByGameTemplate(template, {
                width = itemSlotSize[0] - 4 * smallPadding
                height = itemSlotSize[1] - 2 * smallPadding
              })
            }
          ]
        }
      ]
    }
  }

  return function researchesTreeUi() {
    let { columns, hasItemLink, offsetFactor, researchColumns } = columnsInfo.value
    let researchTree = {
      flow = FLOW_HORIZONTAL
      children = researchColumns
    }

    let researchItemsRow = !hasItemLink ? null : {
      flow = FLOW_HORIZONTAL
      children = columns.map(@(column, idx) mkResearchItem(column, idx == columns.len() - 1))
    }

    let treeObject = {
      size = [SIZE_TO_CONTENT, flex()]
      flow = FLOW_VERTICAL
      gap = columnGap
      padding = [0, colPart(1)]
      onAttach
      onDetach
      children = [
        researchItemsRow
        {
          size = [SIZE_TO_CONTENT, flex()]
          flow = FLOW_VERTICAL
          children = [
            { size = [0, ph(offsetFactor)] }
            researchTree
          ]
        }
      ]
    }
    return {
      watch = [columnsInfo, hasScroll]
      size = flex()
      children = hasScroll.value
        ? makeHorizScroll({
            xmbNode = xmbContainer
            children = treeObject
            size = [SIZE_TO_CONTENT, flex()]
          }, {
            size = flex()
            scrollHandler
            rootBase = {
              behavior = Behaviors.Pannable
              wheelStep = 1
            }
          })
        : {
            size = flex()
            valign = ALIGN_BOTTOM
            vplace = ALIGN_BOTTOM
            children = treeObject
          }
    }
  }
}


let mkPointsInfo = @(level, points) {
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  children = [
    mkText(loc("levelInfo", { level = level + 1 }), nameTxtStyle)
    {
      size = [flex(), SIZE_TO_CONTENT]
      flow = FLOW_HORIZONTAL
      gap = smallPadding
      halign = ALIGN_RIGHT
      valign = ALIGN_CENTER
      children = [
        mkText(loc("research/availPoints"), defTxtStyle)
        priceIcon
        mkText(points, nameTxtStyle)
      ]
    }
  ]
}

let function getProgressTooltip(curLvl, maxLvl, curExp, expToNextLvl, accColor){
  let lvlBlock = colorize(accColor, $"{curLvl + 1}/{maxLvl + 1}")
  let expBlock = colorize(accColor, $"{curExp}/{expToNextLvl}")
  return $"{lvlBlock} {loc("research/squad_level")}\n{loc("research/squad_next_level")} {expBlock}"
}

let mkProgressUi = @(curSquadData) function() {
  let res = {
    watch = [curSquadData, curSquadProgress, curSquadPoints]
  }
  let isSquadPrem = isSquadPremium(curSquadData.value)
  if (isSquadPrem)
    return res

  let { level, maxLevel, exp, nextLevelExp } = curSquadProgress.value
  let points = curSquadPoints.value
  let progressValue = nextLevelExp > 0 ? exp.tofloat() / nextLevelExp
    : level == maxLevel ? 1.0
    : 0.0
  return res.__update({
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    gap = midPadding
    behavior = Behaviors.Button
    onHover = @(on) cursors.setTooltip(on
      ? getProgressTooltip(level, maxLevel, exp, nextLevelExp, levelAndExpColor)
      : null)
    children = [
      mkPointsInfo(level, points)
      gradientProgressBar(progressValue, {
        vplace = ALIGN_BOTTOM
        bgImage = progressBarBgImage
        emptyColor = panelBgColor
      })
    ]
  })
}

let function mkResearchInfo(research) {
  if (research == null)
    return null

  let { research_id, name = null, description = null, params = null } = research
  return {
    size = flex()
    flow = FLOW_VERTICAL
    gap = columnGap
    children = [
      mkTextarea(utf8ToUpper(loc(name, params)), {
        key = $"name_{research_id}"
      }.__update(attentionTxtStyle, leftAppearanceAnim(0)))
      mkTextarea(loc(description, params), {
        key = $"desc_{research_id}"
      }.__update(defTxtStyle, leftAppearanceAnim(0.1)))
    ]
  }
}


let mkResearchUnlockedView = @(research_id) {
  size = [flex(), SIZE_TO_CONTENT]
  children = {
    key = research_id
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    gap = columnGap
    children = [
      researchedSign
      mkText(utf8ToUpper(loc("research/unlocked")), headerTxtStyle)
    ]
  }.__update(leftAppearanceAnim(0.1))
}

let function mkResearchPrice(researchDef) {
  let { price = 0 } = researchDef
  return price == 0 ? null : {
    valign = ALIGN_CENTER
    flow = FLOW_HORIZONTAL
    gap = smallPadding
    children = [
      mkText(loc("research/researchPrice", { price = "" }), priceTxtStyle)
      priceIcon
      mkText(price, headerTxtStyle)
    ]
  }
}

let mkResearchBtn = @(onResearch, researchText, canResearch) @() {
  hplace = ALIGN_RIGHT
  watch = isResearchInProgress
  children = isResearchInProgress.value
    ? waitingSpinner
    : (canResearch ? PrimaryFlat : Bordered)(researchText, onResearch, {
        margin = 0
        txtParams = fontLarge
        hotkeys = [[ "^J:Y", { description = { skip = true }} ]]
      })
}

let mkUnlockPrice = @(researchDef, specialPrice, onResearch) onResearch == null ? null
  : specialPrice ?? mkResearchPrice(researchDef)

let mkUnlockButton = @(researchText, onResearch, canResearch)
  onResearch == null ? null
    : mkResearchBtn(onResearch, researchText ?? loc("research/researchBtnText"), canResearch)

let function buySquadLevelMsg() {
  let { levelCost = 0, level = 0 } = curSquadProgress.value
  purchaseMsgBox({
    price = levelCost
    currencyId = "EnlistedGold"
    title = loc("squadLevel", { level = level + 2 })
    description = loc("buy/squadLevelConfirm")
    purchase = @() buySquadLevel(function(isSuccess) {
      if (isSuccess)
        sound_play("ui/purchase_level_squad")
    })
    srcComponent = "buy_researches_level"
  })
}

let mkBuyLevelPrice = @(levelCost) function() {
  let currency = currenciesList.value.findvalue(@(c) c.id == "EnlistedGold")
  return {
    watch = currenciesList
    hplace = ALIGN_RIGHT
    children = mkCurrency({
      currency
      price = levelCost
      iconSize = priceIconSize
    })
  }
}

let mkBuyLevelButton = @(level) function() {
  let btnText = loc("squads/buyLvl", {
    item = loc("squads/lvlShort", { level = level + 1 })
  })
  return {
    watch = isBuyLevelInProgress
    hplace = ALIGN_RIGHT
    children = isBuyLevelInProgress.value
      ? waitingSpinner
      : Purchase(btnText, buySquadLevelMsg, { margin = 0 })
  }
}

let mkResearchBtnsUi = @() function() {
  let res = { watch = [selectedResearch, researchStatuses, disableSquadExp, curSquadProgress] }
  let researchDef = selectedResearch.value
  if (!researchDef)
    return res

  let statuses = researchStatuses.value
  if (statuses == null)
    return res

  let { research_id } = researchDef
  let status = statuses?[research_id]
  let cfg = researchStatusesCfg?[status](researchDef)
  if (cfg == null)
    return res.__update(mkResearchUnlockedView(research_id))

  let {
    info = null, warning = null, onResearch = null, researchPrice = null, researchText = null
  } = cfg
  let { levelCost = 0, level = 0 } = curSquadProgress.value
  let canBuy = (status == CAN_RESEARCH || status == NOT_ENOUGH_EXP)
    && levelCost > 0 && !disableSquadExp.value
  return res.__update({
    key = $"research_footer_{research_id}"
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    gap = columnGap
    children = [
      info == null ? null : mkTextarea(utf8ToUpper(info), headerTxtStyle)
      warning == null ? null : mkTextarea(utf8ToUpper(warning), attentionTxtStyle)
      {
        size = [flex(), SIZE_TO_CONTENT]
        valign = ALIGN_CENTER
        children = [
          mkUnlockPrice(researchDef, researchPrice, onResearch)
          mkUnlockButton(researchText, onResearch, status == CAN_RESEARCH)
        ]
      }
      !canBuy ? null : {
        size = [flex(), SIZE_TO_CONTENT]
        valign = ALIGN_CENTER
        flow = FLOW_HORIZONTAL
        gap = { size = flex() }
        children = [
          mkBuyLevelPrice(levelCost)
          mkBuyLevelButton(level)
        ]
      }
    ]
  }.__update(leftAppearanceAnim(0.1)))
}


let function mkResearchInfoUi() {
  let curSquadData = Computed(@() armySquadsById.value?[viewArmy.value][viewSquadId.value])
  let nameLocId = Computed(function() {
    let res = armiesResearches.value?[curArmy.value].squads[viewSquadId.value].name ?? ""
    return res != "" ? res : (curSquadData.value?.manageLocId ?? "")
  })
  let progressUi = mkProgressUi(curSquadData)
  let btns = mkResearchBtnsUi()

  return @() {
    watch = [selectedResearch, nameLocId] //FIXME
    size = [researchInfoWidth, flex()]
    hplace = ALIGN_RIGHT
    flow = FLOW_VERTICAL
    gap = colPart(1)
    padding = columnGap
    rendObj = ROBJ_SOLID
    color = darkPanelBgColor
    children = [
      promoWidget("research_section", null, { margin = [columnGap, 0] })
      {
        size = [flex(), SIZE_TO_CONTENT]
        flow = FLOW_VERTICAL
        gap = columnGap
        children = [
          nameLocId.value == "" ? null : mkTextarea(loc(nameLocId.value), nameTxtStyle)
          progressUi
        ]
      }
      mkResearchInfo(selectedResearch.value)
      btns
    ]
  }
}


let emptyResearchesText = mkText(loc("researches/willBeAvailableSoon"), {
  vplace = ALIGN_CENTER
  hplace = ALIGN_CENTER
}.__update(nameTxtStyle))

let lowCampaignLevelText = {
  flow = FLOW_VERTICAL
  gap = columnGap
  vplace = ALIGN_CENTER
  hplace = ALIGN_CENTER
  halign = ALIGN_CENTER
  children = [
    mkText(loc("researches/levelTooLowForWorkshop"), nameTxtStyle)
    Bordered(loc("menu/campaignRewards"), jumpToArmyProgress, {
      hotkeys = [[ "^J:Y", { description = {skip = true}} ]]
    })
  ]
}

let setCurSquadId = @(squadId) viewSquadId(squadId)

let function mkResearchesUi() {
  let curUnseenState = mkCurUnseenResearchesBySquads()
  let researchesSquads = mkResearchesSquads(curUnseenState)
  let isBranchEmpty = Computed(@() (tableStructure.value?.researches ?? {}).len() == 0)
  let isCampaignLevelLow = Computed(@() selectedResearch.value?.isLockedByCampaignLvl ?? false)
  return {
    size = flex()
    children = [
      {
        size = flex()
        flow = FLOW_HORIZONTAL
        children = [
          mkCurSquadsList({
            curSquadsList = researchesSquads
            curSquadId = viewSquadId
            setCurSquadId = setCurSquadId
          })
          function() {
            return {
              watch = [isBranchEmpty, isCampaignLevelLow]
              padding = [headerHeight, 0,0,0]
              size = flex()
              children = isBranchEmpty.value
                ? emptyResearchesText
                  : isCampaignLevelLow.value
                    ? lowCampaignLevelText
                    : mkResearchesTreeUi()
            }
          }
          mkResearchInfoUi()
        ]
      }
      mkHeaderUi()
    ]
  }
}

let function buildResearchesUi() {
  let disabledSection = mkDisabledSectionBlock({ descLocId = "menu/lockedByCampaignDesc" })
  return mkLockByCampaignProgress(@() {
    watch = hasResearchesSection
    size = flex()
    flow = FLOW_VERTICAL
    margin = [contentOffset,0,0,0]
    gap = bigPadding
    children = [
      {
        flow = FLOW_HORIZONTAL
        gap = bigPadding
        valign = ALIGN_BOTTOM
        children = [
          armySelectUi
          promoWidget("research_section", null)
        ]
      }
      hasResearchesSection.value ? mkResearchesUi() : disabledSection
    ]
  })
}

return { buildResearchesUi }