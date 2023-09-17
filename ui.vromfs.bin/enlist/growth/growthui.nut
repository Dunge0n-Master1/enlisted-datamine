from "%enlSqGlob/ui_library.nut" import *

let { fontSub } = require("%enlSqGlob/ui/fontsStyle.nut")
let { largePadding, smallPadding, titleTxtColor, defTxtColor, midPadding, accentColor,
  brightAccentColor, darkTxtColor, panelBgColor, defBdColor, squadSlotBgHoverColor, defItemBlur,
  fullTransparentBgColor, inventoryItemDetailsWidth,commonBtnHeight, hoverSlotBgColor, contentOffset
} = require("%enlSqGlob/ui/designConst.nut")
let { safeAreaSize } = require("%enlist/options/safeAreaState.nut")
let { curArmy } = require("%enlist/soldiers/model/state.nut")
let armySelectUi = require("%enlist/soldiers/army_select.ui.nut")
let { GrowthStatus, curGrowthId, curGrowthConfig, curGrowthState, curGrowthSelected,
  callGrowthSelect, callGrowthRewardTake, curSquads, curTemplates, growthRelations, curGrowthTiers,
  tierProgressByArmy
} = require("growthState.nut")
let { mkColoredGradientX } = require("%enlSqGlob/ui/gradients.nut")
let { makeHorizScroll } = require("%ui/components/scrollbar.nut")
let { gradientProgressBar } = require("%enlSqGlob/ui/defComponents.nut")
let { splitThousands, getRomanNumeral } = require("%sqstd/math.nut")
let { getItemName } = require("%enlSqGlob/ui/itemsInfo.nut")
let { mkTierStars } = require("%enlSqGlob/ui/itemTier.nut")
let { itemTypeIcon } = require("%enlist/soldiers/components/itemTypesData.nut")
let iconByGameTemplate = require("%enlSqGlob/ui/icon3dByGameTemplate.nut")
let { Flat } = require("%ui/components/textButton.nut")
let { mkSquadDetails, mkItemDetails } = require("%enlist/growth/growthPkg.nut")

const DEFAULT_SQUAD_ICON = "!ui/uiskin/squad_default.svg"

let scrollBarsWidth = hdpx(150)
let elemSize = [hdpx(218), hdpx(100)]
let gapSize = [hdpx(30), hdpx(12)]
let headerSize = hdpx(20)
let tierHeight = hdpx(26)
let templateSize = {
  width = min(elemSize[0], (elemSize[1] - headerSize) * 3) - midPadding * 2
  height = elemSize[1] - headerSize - midPadding * 2
}
let typeBackSize = hdpxi(20)
let typeIconSize = hdpxi(14)
let squadIconSize = [hdpxi(24), hdpxi(15)]
let relationIconSize = [hdpxi(24), hdpxi(24)]

let detailsTitleStyle = freeze({ color = titleTxtColor }.__update(fontSub))
let progressTitleStyle = freeze({ color = titleTxtColor }.__update(fontSub))
let progressValueStyle = freeze({ color = titleTxtColor }.__update(fontSub))

let selectedWithBorder = [hdpx(1), hdpx(1), hdpx(4), hdpx(1)]
let selectedNonBorder = [0,0, hdpx(4), 0]
let activeProgressColor = 0xFF58603A
let inactiveProgressColor = 0xFF667079
let activeElemBgColor = 0xFFB0B2B3
let unavailableElemBgColor = 0x99905D5D
let rewardedElemBgColor = 0x99586476
let activeElemsColor = 0xFF313841
let defElemsColor = 0xFFB3BDC1

let infoTabs = {
  item = {
    locId = "weaponry"
    ctor = mkItemDetails
  }
  squad = {
    locId = "squad"
    ctor = mkSquadDetails
  }
}

let curInfoTabId = Watched(null)
let tabsToShow = Computed(function() {
  let { itemTemplate = null, squadId = null, armyId = null
    } = curGrowthConfig.value?[curGrowthId.value].reward
  let res = []
  let item = curTemplates.value?[itemTemplate]
  if (item != null)
    res.append({
      tabId = "item"
      data = {
        item
        itemTemplate
        armyId
      }
    })

  let squad = curSquads.value?[squadId]
  if (squad != null)
    res.append({
      tabId = "squad"
      data = {
        squad
        armyId
      }
    })
  return res
})

tabsToShow.subscribe(function(v) {
  if (v.len() == 0)
    return
  if (curInfoTabId.value == null){
    curInfoTabId(v[0].tabId)
    return
  }
  let idxToSet = v.findindex(@(v) v.tabId == curInfoTabId.value)
  if (idxToSet == null)
    curInfoTabId(v[0].tabId)
  else
    curInfoTabId(v[idxToSet].tabId)
  })

let progressBarStyle = freeze({
  size = [flex(), hdpx(22)]
  bgImage = mkColoredGradientX({colorLeft=0xFFFC7A40, colorRight=titleTxtColor})
  emptyColor = panelBgColor
})

let elemInactive = @(isSelected, ...) {
  rendObj = ROBJ_BOX
  size = [elemSize[0], flex()]
  borderWidth = isSelected ? selectedNonBorder : 0
  borderColor = isSelected ? accentColor : defBdColor
  padding = isSelected ? selectedWithBorder : 0
}

let elemActive = @(isSelected, progress, isCurrent) {
  rendObj = ROBJ_BOX
  size = [elemSize[0], flex()]
  borderWidth = isSelected ? selectedWithBorder : hdpx(1)
  borderColor = isSelected ? accentColor
    : isCurrent ? brightAccentColor
    : defBdColor
  padding = isSelected ? selectedWithBorder : hdpx(1)
  children = progress == 0 ? null : {
    size = [pw(progress), flex()]
    rendObj = ROBJ_SOLID
    color = isCurrent ? activeProgressColor : inactiveProgressColor
  }
}

let lineDashSize = hdpx(10)
let lineInactiveStyle = { rendObj = ROBJ_VECTOR_CANVAS, color = 0x66666666, lineWidth = hdpx(1) }
let lineActiveStyle = { rendObj = ROBJ_VECTOR_CANVAS, color = 0x55445533, lineWidth = hdpx(3) }

let lineStyles = {
  inactive = {
    hor = @(pos, size) lineInactiveStyle.__merge({
      size, pos, commands = [[VECTOR_LINE_DASHED, 0, 50, 100, 50, lineDashSize, lineDashSize]]
    })
    ver = @(pos, size) lineInactiveStyle.__merge({
      size, pos, commands = [[VECTOR_LINE_DASHED, 50, 0, 50, 100, lineDashSize, lineDashSize]]
    })
  }
  active = {
    hor = @(pos, size) lineActiveStyle.__merge({
      size, pos, commands = [[VECTOR_LINE, 0, 50, 100, 50]]
    })
    ver = @(pos, size) lineActiveStyle.__merge({
      size, pos, commands = [[VECTOR_LINE, 50, 0, 50, 100]]
    })
  }
}

// TODO unify and move to library
let mkTypeIcon = @(children) {
  rendObj = ROBJ_VECTOR_CANVAS
  size = [typeBackSize, typeBackSize]
  hplace = ALIGN_RIGHT
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  commands = [[ VECTOR_ELLIPSE, 50, 50, 50, 50 ]]
  fillColor = 0xFF000000
  color = 0xFF000000
  children
}

let tinyIconSize = { size = [typeIconSize, typeIconSize] }

let mkItemTypeIcon = @(itemtype, itemsubtype) itemtype == null ? null
  : mkTypeIcon(itemTypeIcon(itemtype, itemsubtype, tinyIconSize))

enum LineDir {
  NONE
  LESS
  MORE
}

let coordHor = @(index, dir = LineDir.NONE) (elemSize[0] + gapSize[0]) * index
  + (dir == LineDir.LESS ? 0 : dir == LineDir.MORE ? elemSize[0] : elemSize[0] * 0.5)

let coordVer = @(index, dir = LineDir.NONE) (elemSize[1] + gapSize[1]) * index
  + (dir == LineDir.LESS ? 0 : dir == LineDir.MORE ? elemSize[1] : elemSize[1] * 0.5)

let function mkGrowthLine(res, colFrom, lineFrom, colTo, lineTo, isActive = false) {
  let lines = isActive ? lineStyles.active : lineStyles.inactive
  local horPos, verPos

  // vertical lines
  if (colFrom == colTo) {
    horPos = coordHor(colFrom, LineDir.LESS)
    if (lineFrom > lineTo) {
      verPos = coordVer(lineTo, LineDir.MORE)
      res.append(lines.ver(
        [horPos, verPos],
        [elemSize[0], coordVer(lineFrom, LineDir.LESS) - verPos]))
    }
    if (lineFrom < lineTo) {
      verPos = coordVer(lineFrom, LineDir.MORE)
      res.append(lines.ver(
        [horPos, verPos],
        [elemSize[0], coordVer(lineTo, LineDir.LESS) - verPos]))
    }
    return res
  }

  // horizontal lines
  if (lineFrom == lineTo) {
    verPos = coordVer(lineFrom, LineDir.LESS) + headerSize * 0.5
    if (colFrom > colTo) {
      horPos = coordHor(colTo, LineDir.MORE)
      res.append(lines.hor(
        [horPos, verPos],
        [coordHor(colFrom, LineDir.LESS) - horPos, elemSize[1]]))
    }
    if (colFrom < colTo) {
      horPos = coordHor(colFrom, LineDir.MORE) + headerSize * 0.5
      res.append(lines.hor(
        [horPos, verPos],
        [coordHor(colTo, LineDir.LESS) - horPos, elemSize[1]]))
    }
    return res
  }

  // angled lines vertical
  horPos = coordHor(colTo, LineDir.LESS)
  if (lineFrom > lineTo) {
    verPos = coordVer(lineTo, LineDir.MORE)
    res.append(lines.ver(
      [horPos, verPos],
      [elemSize[0], coordVer(lineFrom) - verPos + headerSize * 0.5]))
  }
  if (lineFrom < lineTo) {
    verPos = coordVer(lineFrom)
    res.append(lines.ver(
      [horPos, verPos + headerSize * 0.5],
      [elemSize[0], coordVer(lineTo, LineDir.LESS) - verPos]))
  }

  // angled lines horizontal
  verPos = coordVer(lineFrom, LineDir.LESS) + headerSize * 0.5
  if (colFrom > colTo) {
    horPos = coordHor(colTo)
    res.append(lines.hor(
      [horPos, verPos],
      [coordHor(colFrom, LineDir.LESS) - horPos, elemSize[1]]))
  }
  if (colFrom < colTo) {
    horPos = coordHor(colFrom, LineDir.MORE) + headerSize * 0.5
    res.append(lines.hor(
      [horPos, verPos],
      [coordHor(colTo) - horPos, elemSize[1]]))
  }
  return res
}

let mkLabel = @(text, style) {
  rendObj = ROBJ_TEXT
  text
}.__update(style)

let mkText = @(text, style) {
  rendObj = ROBJ_TEXTAREA
  size = [flex(), SIZE_TO_CONTENT]
  behavior = Behaviors.TextArea
  text
}.__update(style)

let emptyCell = @() { size = elemSize }

let completedBgColor = @(sf, isSelected) isSelected || (sf & S_ACTIVE) ? activeProgressColor
  : sf & S_HOVER ? squadSlotBgHoverColor
  : activeProgressColor

let activeBgColor = @(sf, isSelected) isSelected || (sf & S_ACTIVE) ? activeElemBgColor
  : sf & S_HOVER ? squadSlotBgHoverColor
  : fullTransparentBgColor

let unavailableBgColor = @(sf, isSelected)
  isSelected || (sf & S_ACTIVE) ? unavailableElemBgColor
    : sf & S_HOVER ? squadSlotBgHoverColor
    : unavailableElemBgColor

let rewardedBgColor = @(sf, isSelected) isSelected || (sf & S_ACTIVE) ? activeElemBgColor
  : sf & S_HOVER ? squadSlotBgHoverColor
  : rewardedElemBgColor

let slotBgColorMap = {
  [GrowthStatus.COMPLETED] = completedBgColor,
  [GrowthStatus.ACTIVE] = activeBgColor,
  [GrowthStatus.UNAVAILABLE] = unavailableBgColor,
  [GrowthStatus.REWARDED] = rewardedBgColor
}

let defChColor = @(sf, isSelected) isSelected || (sf & S_ACTIVE) || (sf & S_HOVER)
  ? activeElemsColor
  : defElemsColor

let elemChildrenColorsMap = {
  [GrowthStatus.COMPLETED] = brightAccentColor,
  [GrowthStatus.REWARDED] = defElemsColor,
  [GrowthStatus.UNAVAILABLE] = activeElemsColor
}

let squadIcon = @(color) {
  rendObj = ROBJ_IMAGE
  size = squadIconSize
  hplace = ALIGN_RIGHT
  vplace = ALIGN_BOTTOM
  keepAspect = KEEP_ASPECT_FIT
  margin = [0, 0, midPadding, 0]
  image = Picture("!ui/squads/squad_icon.svg:{0}:{1}:K".subst(squadIconSize[0], squadIconSize[1]))
  color
}

let relationsIcon = @(color) {
  rendObj = ROBJ_IMAGE
  size = relationIconSize
  vplace = ALIGN_BOTTOM
  keepAspect = KEEP_ASPECT_FIT
  margin = [0, 0, midPadding, 0]
  image = Picture("!ui/squads/angle_icon.svg:{0}:{1}:K"
    .subst(relationIconSize[0], relationIconSize[1]))
  color
}

let function mkElem(id, item, squad, curItemRelations, status, back, isSelected, isCurrent) {
  let { itemtype = null, itemsubtype = null, tier = 0, gametemplate = "" } = item
  let group = ElemGroup()
  let itemName = getItemName(item)
  let itemIcon = iconByGameTemplate(gametemplate, templateSize)
  let typeIcon = mkItemTypeIcon(itemtype, itemsubtype)
  return watchElemState(function(sf) {
    let elemsColor = isCurrent.value ? brightAccentColor
      : elemChildrenColorsMap?[status] ?? defChColor(sf, isSelected.value)
    return {
      watch = [isSelected, isCurrent]
      size = elemSize
      flow = FLOW_VERTICAL
      group
      behavior = Behaviors.Button
      children = [
        {
          rendObj = ROBJ_TEXT
          size = [flex(), headerSize]
          text = itemName
          group
          behavior = Behaviors.Marquee
          clipChildren = true
          scrollOnHover = true
          color = isCurrent.value || status == GrowthStatus.COMPLETED ? brightAccentColor
            : isSelected.value || (sf & S_ACTIVE) ? titleTxtColor
            : defTxtColor
        }.__update(fontSub)
        {
          rendObj = ROBJ_WORLD_BLUR_PANEL
          size = flex()
          fillColor = isCurrent.value
            ? activeBgColor(sf, isSelected.value)
            : slotBgColorMap[status](sf, isSelected.value)
          color = defItemBlur
          opacity = status == GrowthStatus.UNAVAILABLE && !isSelected.value ? 0.7 : 1
          children = [
            back
            {
              size = flex()
              padding = [smallPadding, midPadding]
              children = [
                itemIcon
                mkTierStars(tier, { fontSize = hdpxi(14) }.__update({ color = elemsColor }))
                squad == null ? null : squadIcon(elemsColor)
                curItemRelations == null ? null : relationsIcon(elemsColor)
                typeIcon
              ]
            }
          ]
        }
      ]
      onClick = @() curGrowthId(id)
      onDoubleClick = @() callGrowthSelect(curArmy.value, id)
    }
  })
}

let elemBgMap = {
  [GrowthStatus.UNAVAILABLE] = elemInactive,
  [GrowthStatus.REWARDED] = elemInactive,
  [GrowthStatus.ACTIVE] = elemActive,
  [GrowthStatus.COMPLETED] = elemActive
}

let function mkGrowthElement(growthItem, progressState, tmplsCfg, squadsCfg, relationsTbl) {
  let { itemTemplate = null, squadId = null } = growthItem?.reward
  let item = tmplsCfg?[itemTemplate]
  let squad = squadsCfg?[squadId]
  if (item == null && squad == null)
    return emptyCell

  let { id } = growthItem
  let curItemRelations = relationsTbl?[id]
  let { status = GrowthStatus.UNAVAILABLE } = progressState?[id]
  let isSelected = Computed(@() curGrowthId.value == id)
  let isCurrent = Computed(@() curGrowthSelected.value == id)

  let progress = Computed(function() {
    let { expRequired = 0 } = curGrowthConfig.value?[id]
    if (expRequired == 0)
      return 0

    let { exp = 0 } = curGrowthState.value?[id]
    return (exp.tofloat() / expRequired.tofloat()) * 100.0
  })


  let back = @() {
    watch = [isSelected, isCurrent, progress]
    size = flex()
    children = elemBgMap[status](isSelected.value, progress.value, isCurrent.value)
  }

  return mkElem(id, item, squad, curItemRelations, status, back, isSelected, isCurrent)
}

let treeScrollHandler = ScrollHandler()
let hasLeftScroll = Watched(false)
let hasRightScroll = Watched(true)

let function updateArrowButtons(elem) {
  hasLeftScroll(elem.getScrollOffsX() > 0)
  hasRightScroll(elem.getContentWidth() - elem.getScrollOffsX() > safeAreaSize.value[0])
}

treeScrollHandler.subscribe(function(_) {
  let { elem = null } = treeScrollHandler
  if (elem == null)
    return
  updateArrowButtons(elem)
})

let leftScroll = freeze({
  rendObj = ROBJ_IMAGE
  size = [scrollBarsWidth, flex()]
  image = mkColoredGradientX({colorLeft=0xFF060C12, colorRight=0x00000000})
})

let rightScroll = freeze({
  rendObj = ROBJ_IMAGE
  size = [scrollBarsWidth, flex()]
  image = mkColoredGradientX({colorLeft=0x00000000, colorRight=0xFF03090C})
})

let mkGrowthTree = @(relationsTbl) function() {
  local maxCol = 0
  local { progress = {} } = curGrowthState.value
  let growthLines = curGrowthConfig.value
    .reduce(function(res, growth) {
      let { col = 0, line = 0, requirements = [] } = growth
      foreach (reqId in requirements) {
        let reqGrowth = curGrowthConfig.value[reqId]
        let { status = GrowthStatus.UNAVAILABLE } = progress?[reqId]
        mkGrowthLine(res, col, line, reqGrowth?.col ?? 0, reqGrowth?.line ?? 0,
          status != GrowthStatus.UNAVAILABLE)
      }
      return res
    }, [])

  let growthElements = curGrowthConfig.value
    .reduce(function(res, growth, _, tbl) {
      let { id, col = 0, line = 0 } = growth
      maxCol = max(col, maxCol)
      while (res.len() <= line)
        res.append([])
      let arr = res[line]
      if (arr.len() <= col)
        arr.resize(col + 1, null)
      if (arr?[col] == null)
        arr[col] = growth
      else if (id in relationsTbl) {
        let relations = relationsTbl[id]
        let unRewardedElem = relations.findvalue(@(v) progress?[v] != GrowthStatus.REWARDED) ?? id
        arr[col] = tbl[unRewardedElem]
      }
      return res
    }, [])
    .map(@(growthLine) {
      flow = FLOW_HORIZONTAL
      gap = gapSize[0]
      children = growthLine.map(@(growthItem) mkGrowthElement(growthItem, progress,
        curTemplates.value, curSquads.value, relationsTbl))
    })

  let maxLine = growthElements.len() - 1
  return {
    watch = [curGrowthConfig, curGrowthState, curTemplates, curSquads]
    size = [SIZE_TO_CONTENT, flex()]
    children = [
      {
        size = [
          (elemSize[0] + gapSize[0]) * maxCol - gapSize[0],
          (elemSize[1] + gapSize[1]) * maxLine - gapSize[1]
        ]
        children = growthLines
      }
      {
        flow = FLOW_VERTICAL
        gap = gapSize[1]
        children = growthElements
      }
      @() {
        watch = hasLeftScroll
        size = [SIZE_TO_CONTENT, flex()]
        children = hasLeftScroll.value ? leftScroll : null
        hplace = ALIGN_LEFT
      }
      @() {
        watch = hasRightScroll
        size = [SIZE_TO_CONTENT, flex()]
        children = hasRightScroll.value ? rightScroll : null
        hplace = ALIGN_RIGHT
      }
    ]
  }
}

let function contentHeader() {
  let { itemTemplate = null, squadId = null } = curGrowthConfig.value?[curGrowthId.value].reward
  let res = { watch = [curTemplates, curGrowthConfig, curGrowthId] }
  if (itemTemplate == null && squadId == null)
    return res
  let item = curTemplates.value?[itemTemplate]
  let squad = curSquads.value?[squadId]
  let children = []

  if (item != null)
    children.append(mkText(getItemName(item), detailsTitleStyle))
  if (squad != null)
    children.append(mkText(loc(squad.nameLocId), detailsTitleStyle))

  return res.__update({
    watch = [curTemplates, curGrowthConfig, curGrowthId]
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    gap = smallPadding
    children
  })
}

let function mkInfoTab(tab) {
  let { tabId } = tab
  let isSelected = Computed(@() tabId == curInfoTabId.value)
  return watchElemState(@(sf) {
    watch = isSelected
    rendObj = ROBJ_BOX
    size = [flex(), commonBtnHeight]
    fillColor = isSelected.value || (sf & S_HOVER) ? hoverSlotBgColor : panelBgColor
    borderWidth = isSelected.value ? [0, 0, hdpx(4), 0] : 0
    borderColor = accentColor
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    behavior = Behaviors.Button
    onClick = @() curInfoTabId(tabId)
    children = {
      rendObj = ROBJ_TEXT
      size = [flex(), SIZE_TO_CONTENT]
      halign = ALIGN_CENTER
      color = isSelected.value ? titleTxtColor
        : (sf & S_HOVER) ? darkTxtColor
        : defTxtColor
      text = loc(infoTabs[tabId].locId)
    }
  })
}

let function infoTabsBlock() {
  let res = { watch = tabsToShow }
  if (tabsToShow.value.len() <= 0)
    return res

  let tabs = tabsToShow.value
  return res.__update(
    {
      size = [inventoryItemDetailsWidth, flex()]
      flow = FLOW_VERTICAL
      gap = largePadding
      children = [
        tabs.len() <= 1 ? null : {
          size = [flex(), SIZE_TO_CONTENT]
          flow = FLOW_HORIZONTAL
          children = tabs.map(mkInfoTab)
        }
        function() {
          let curId = curInfoTabId.value
          let curIdx = tabs.findindex(@(v) v.tabId == curId)
          return {
            watch = curInfoTabId
            size = flex()
            children = infoTabs[curId].ctor(tabs[curIdx].data)
          }
        }
      ]
    })
}

let function itemProgressUi() {
  let res = { watch = [curGrowthId, curGrowthConfig, curGrowthState, curGrowthSelected] }
  let { expRequired = 0 } = curGrowthConfig.value?[curGrowthId.value]
  if (expRequired <= 0)
    return res

  let { exp = 0, status = GrowthStatus.UNAVAILABLE } = curGrowthState.value?[curGrowthId.value]
  let isResearching = curGrowthId.value == curGrowthSelected.value
  let statusLocId = isResearching ?"growth/statusGrowthing"
    : status == GrowthStatus.ACTIVE ? "growth/statusActive"
    : status == GrowthStatus.COMPLETED ? "growth/statusCompleted"
    : status == GrowthStatus.REWARDED ? "growth/statusRewarded"
    : "growth/statusUnavailable"
  let textBlock = mkLabel($"{splitThousands(exp)} / {splitThousands(expRequired)}", {
    vplace = ALIGN_CENTER
    padding = [0, smallPadding]
  }.__update(progressValueStyle))
  return res.__update({
    size = [flex(), SIZE_TO_CONTENT]

    gap = smallPadding
    flow = FLOW_VERTICAL
    children = [
      mkText(loc(statusLocId), progressTitleStyle)
      {
        size = [flex(), SIZE_TO_CONTENT]
        valign = ALIGN_CENTER
        children = [
          gradientProgressBar(exp.tofloat() / expRequired.tofloat(), progressBarStyle)
          textBlock
        ]
      }
    ]
  })
}

let btnReward = Flat(loc("growth/btnTakeReward"), @()
  callGrowthRewardTake(curArmy.value, curGrowthId.value))

let btnSelect = Flat(loc("growth/btnSelectCurrent"), @()
  callGrowthSelect(curArmy.value, curGrowthId.value))

let function growthControlsUi() {
  let { status = GrowthStatus.UNAVAILABLE } = curGrowthState.value?[curGrowthId.value]
  return {
    watch = [curGrowthId, curGrowthState]
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_HORIZONTAL
    halign = ALIGN_RIGHT
    children = status == GrowthStatus.COMPLETED ? btnReward
      : status == GrowthStatus.ACTIVE ? btnSelect
      : null
  }
}

let infoBlock = {
  size = [inventoryItemDetailsWidth, flex()]
  flow = FLOW_VERTICAL
  gap = midPadding
  padding = [smallPadding, 0]
  children = [
    armySelectUi
    contentHeader
    itemProgressUi
    infoTabsBlock
    growthControlsUi
  ]
}

let function mkTier(tierData) {
  let { from, to, required, index } = tierData
  let tierLength = to - from + 1
  let tierWidth = elemSize[0] * tierLength + gapSize[0] * (tierLength - 1)
  return function() {
    let progress = tierProgressByArmy.value
    let progressText = $"{progress}/{required}"
    return {
      watch = [curGrowthConfig, tierProgressByArmy]
      size = [tierWidth, flex()]
      rendObj = ROBJ_SOLID
      color = panelBgColor
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      flow = FLOW_HORIZONTAL
      gap = smallPadding
      children = [
        mkLabel(loc("growth/tier", { tier = getRomanNumeral(index + 1) }),
          {hplace = ALIGN_CENTER}.__update(progressTitleStyle))
        mkLabel(progressText, {size = SIZE_TO_CONTENT}.__update(progressTitleStyle))
      ]
    }
  }
}

let function mkTiersHeader(tiersData) {
  let tiers = tiersData.map(mkTier)
  return {
    size = [flex(), tierHeight]
    flow = FLOW_HORIZONTAL
    children = tiers
    gap = gapSize[0]
  }
}

let function mkGrowthUi() {
  let relationsTbl = growthRelations()
  let growthTiers = curGrowthTiers()
  return {
    rendObj = ROBJ_WORLD_BLUR_PANEL
    size = flex()
    padding = [contentOffset,0,0,0]
    onAttach = function() {
      let autoSelect = curGrowthSelected.value
        ?? curGrowthState.value.findvalue(@(v) v.status == GrowthStatus.ACTIVE)?.id
      curGrowthId(autoSelect)
    }
    children = {
      size = flex()
      flow = FLOW_HORIZONTAL
      gap = largePadding
      children = [
        infoBlock
        makeHorizScroll(@() {
          watch = [relationsTbl, curArmy, growthTiers]
          flow = FLOW_VERTICAL
          gap = midPadding
          children = [
            mkTiersHeader(growthTiers.value)
            mkGrowthTree(relationsTbl.value)
          ]
        }, { size = flex() })
      ]
    }
  }
}

let function resetCurrent(_ = null) {
  if (curGrowthId.value in curGrowthConfig.value)
    return
  local growthId = curGrowthSelected.value
  if (growthId not in curGrowthConfig.value)
    growthId = curGrowthConfig.value.findindex(@(_) true)
  curGrowthId(growthId)
}

foreach (v in [curGrowthSelected, curGrowthConfig])
  v.subscribe(resetCurrent)
resetCurrent()

return mkGrowthUi