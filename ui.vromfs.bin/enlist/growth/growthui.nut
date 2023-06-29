from "%enlSqGlob/ui_library.nut" import *

let { fontSmall, fontXSmall } = require("%enlSqGlob/ui/fontsStyle.nut")
let { columnGap, smallPadding, titleTxtColor, accentColor, defTxtColor,
  darkTxtColor, panelBgColor } = require("%enlSqGlob/ui/designConst.nut")
let { safeAreaSize } = require("%enlist/options/safeAreaState.nut")
let { curArmy } = require("%enlist/soldiers/model/state.nut")
let { allItemTemplates } = require("%enlist/soldiers/model/all_items_templates.nut")
let { GrowthStatus, curGrowthId, curGrowthConfig, curGrowthState, curGrowthSelected,
  callGrowthSelect, callGrowthRewardTake } = require("growthState.nut")
let armySelectUi = require("%enlist/soldiers/army_select.ui.nut")
let { mkColoredGradientX } = require("%enlSqGlob/ui/gradients.nut")
let { makeHorizScroll } = require("%ui/components/scrollbar.nut")
let { gradientProgressBar } = require("%enlSqGlob/ui/defComponents.nut")
let { splitThousands } = require("%sqstd/math.nut")
let { getItemName, getItemDesc } = require("%enlSqGlob/ui/itemsInfo.nut")
let { mkTierStars } = require("%enlSqGlob/ui/itemTier.nut")
let { itemTypeIcon } = require("%enlist/soldiers/components/itemTypesData.nut")
let iconByGameTemplate = require("%enlSqGlob/ui/icon3dByGameTemplate.nut")
let { squadsCfgById } = require("%enlist/soldiers/model/config/squadsConfig.nut")
let squadsPresentation = require("%enlSqGlob/ui/squadsPresentation.nut")
let { mkSquadIcon, squadTypeIcon } = require("%enlSqGlob/ui/squadsUiComps.nut")
let { Flat } = require("%ui/components/textButton.nut")

const DEFAULT_SQUAD_ICON = "!ui/uiskin/squad_default.svg"

let curTemplates = Computed(@() allItemTemplates.value?[curArmy.value] ?? {})
let curSquads = Computed(function() {
  let armyId = curArmy.value
  return (squadsCfgById.value?[armyId] ?? {})
    .map(@(squad, squadId) squad.__merge(squadsPresentation?[armyId][squadId] ?? {}))
})

let infoBlockSize = hdpx(250)
let scrollBarsWidth = hdpx(150)
let elemSize = [hdpx(150), hdpx(70)]
let gapSize = [hdpx(70), hdpx(15)]
let headerSize = hdpx(20)
let templateSize = {
  width = min(elemSize[0], (elemSize[1] - headerSize) * 3) - smallPadding * 2
  height = elemSize[1] - headerSize - smallPadding * 2
}
let typeBackSize = hdpxi(16)
let typeIconSize = hdpxi(13)
let squadIconSize = hdpxi(50)

let detailsTitleStyle = freeze({ color = titleTxtColor }.__update(fontSmall))
let detailsDescStyle = freeze({ color = defTxtColor }.__update(fontXSmall))
let progressTitleStyle = freeze({ color = accentColor }.__update(fontXSmall))
let progressValueStyle = freeze({ color = darkTxtColor }.__update(fontXSmall))

let progressBarStyle = freeze({
  bgImage = mkColoredGradientX({colorLeft=0xFFFC7A40, colorRight=accentColor})
  emptyColor = panelBgColor
})


let elemCurrent = freeze({
  rendObj = ROBJ_SOLID
  size = [elemSize[0], flex()]
  color = 0x55554422
})

let elemSelected = freeze({
  rendObj = ROBJ_SOLID
  size = [elemSize[0], flex()]
  color = 0x55445533
})

let elemRewarded = freeze({
  rendObj = ROBJ_IMAGE
  size = [elemSize[0], flex()]
  image = mkColoredGradientX({colorLeft=0x22222222, colorRight=0x00030303})
})

let elemActive = freeze({
  rendObj = ROBJ_IMAGE
  size = [elemSize[0], flex()]
  image = mkColoredGradientX({colorLeft=0x00223344, colorRight=0x00112233})
})

let elemInactive = freeze({
  rendObj = ROBJ_FRAME
  size = [elemSize[0], flex()]
  borderWidth = hdpx(1)
  color = 0x66666666
})

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
  margin = smallPadding
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

let mkSquadTypeIcon = @(squadType) squadType == null ? null
  : mkTypeIcon(squadTypeIcon(squadType, typeIconSize))

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
  size = [flex(), SIZE_TO_CONTENT]
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

let function mkElem(id, header, children) {
  let group = ElemGroup()
  return {
    size = elemSize
    flow = FLOW_VERTICAL
    group
    behavior = Behaviors.Button
    children = [
      {
        rendObj = ROBJ_TEXT
        size = [flex(), headerSize]
        text = header
        group
        behavior = Behaviors.Marquee
        clipChildren = true
        scrollOnHover = true
        color = titleTxtColor
      }.__update(fontXSmall)
      {
        size = flex()
        children
      }
    ]
    onClick = @() curGrowthId(id)
    onDoubleClick = @() callGrowthSelect(curArmy.value, id)
  }
}

let function mkGrowthElement(growthItem, progressState, tmplsCfg, squadsCfg) {
  let { itemTemplate = null, squadId = null } = growthItem?.reward
  let item = tmplsCfg?[itemTemplate]
  let squad = squadsCfg?[squadId]
  if (item == null && squad == null)
    return emptyCell

  let { id } = growthItem
  let { status = GrowthStatus.UNAVAILABLE } = progressState?[id]
  let isCurrent = Computed(@() curGrowthId.value == id)
  let isSelected = Computed(@() curGrowthSelected.value == id)
  let elemStatus = status == GrowthStatus.REWARDED ? elemRewarded
    : status == GrowthStatus.COMPLETED ? elemActive // TODO actually active is completed all requirements
    : elemInactive
  let back = @() {
    watch = [isCurrent, isSelected]
    size = flex()
    children = isCurrent.value ? elemCurrent
      : isSelected.value ? elemSelected
      : elemStatus
  }

  // Item reward
  if (item != null) {
    let { itemtype = null, itemsubtype = null, tier = 0, gametemplate = "" } = item
    return mkElem(id, getItemName(item), [
      back
      iconByGameTemplate(gametemplate, templateSize)
      mkItemTypeIcon(itemtype, itemsubtype)
      mkTierStars(tier, { vplace = ALIGN_BOTTOM, margin = smallPadding })
    ])
  }

  // Squad reward
  if (squad != null) {
    let { nameLocId, squadType = null, icon = null } = squad
    return mkElem(id, loc(nameLocId), [
      back
      mkSquadTypeIcon(squadType)
      mkSquadIcon(icon, {
        size = [squadIconSize, squadIconSize], vplace = ALIGN_CENTER, hplace = ALIGN_CENTER
      })
    ])
  }

  return null
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

let function growthTree() {
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
    .reduce(function(res, growth) {
      let { col = 0, line = 0 } = growth
      maxCol = max(col, maxCol)
      while (res.len() <= line)
        res.append([])
      let arr = res[line]
      if (arr.len() <= col)
        arr.resize(col + 1, null)
      arr[col] = growth
      return res
    }, [])
    .map(@(growthLine) {
      flow = FLOW_HORIZONTAL
      gap = gapSize[0]
      children = growthLine.map(@(growthItem)
        mkGrowthElement(growthItem, progress, curTemplates.value, curSquads.value))
    })

  let maxLine = growthElements.len() - 1
  return {
    watch = [curGrowthConfig, curGrowthState, curTemplates, curSquads]
    size = flex()
    halign = ALIGN_CENTER
    children = [
      makeHorizScroll({
        xmbNode = XmbContainer({
          canFocus = @() false
          scrollSpeed = 10.0
          isViewport = true
        })
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
        ]
      }, { scrollHandler = treeScrollHandler })
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

let function itemProgressUi() {
  let res = { watch = [curGrowthId, curGrowthConfig, curGrowthState] }
  let { expRequired = 0 } = curGrowthConfig.value?[curGrowthId.value]
  if (expRequired <= 0)
    return res

  let { exp = 0, status = GrowthStatus.UNAVAILABLE } = curGrowthState.value?[curGrowthId.value]
  let statusLocId = status == GrowthStatus.ACTIVE ? "growth/statusActive"
    : status == GrowthStatus.COMPLETED ? "growth/statusCompleted"
    : status == GrowthStatus.REWARDED ? "growth/statusRewarded"
    : "growth/statusUnavailable"
  return res.__update({
    size = [flex(), SIZE_TO_CONTENT]

    gap = smallPadding
    flow = FLOW_VERTICAL
    children = [
      mkText(loc(statusLocId), progressTitleStyle)
      gradientProgressBar(exp.tofloat() / expRequired.tofloat(), progressBarStyle)
      mkLabel($"{splitThousands(exp)} / {splitThousands(expRequired)}", progressValueStyle)
    ]
  })
}

let horDivider = {
  size = [flex(), hdpx(1)]
  margin = [columnGap, 0]
  rendObj = ROBJ_SOLID
  fillColor = 0xFFFFFFFF
}

let function elemDetailsUi() {
  let { itemTemplate = null, squadId = null } = curGrowthConfig.value?[curGrowthId.value].reward
  let item = curTemplates.value?[itemTemplate]
  let squad = curSquads.value?[squadId]
  let children = []

  if (item != null) {
    children.append({
      size = [flex(), SIZE_TO_CONTENT]
      flow = FLOW_VERTICAL
      gap = columnGap
      children = [
        mkText(getItemName(item), detailsTitleStyle)
        mkText(getItemDesc(item), detailsDescStyle)
      ]
    })
  }

  if (squad != null) {
    let { nameLocId, announceLocId } = squad
    children.append({
      size = [flex(), SIZE_TO_CONTENT]
      flow = FLOW_VERTICAL
      gap = columnGap
      children = [
        mkText(loc(nameLocId), detailsTitleStyle)
        mkText(loc(announceLocId), detailsDescStyle)
      ]
    })
  }

  return {
    watch = [curGrowthId, curGrowthConfig, curTemplates, curSquads]
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    gap = horDivider
    children
  }
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
  size = [infoBlockSize, SIZE_TO_CONTENT]
  flow = FLOW_VERTICAL
  gap = columnGap
  children = [
    itemProgressUi
    growthControlsUi
    elemDetailsUi
  ]
}

let growthUi = @() {
  size = flex()
  flow = FLOW_VERTICAL
  children = [
    armySelectUi
    {
      size = flex()
      flow = FLOW_HORIZONTAL
      gap = columnGap
      children = [
        infoBlock
        growthTree
      ]
    }
  ]
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

return growthUi
