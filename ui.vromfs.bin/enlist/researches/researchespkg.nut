from "%enlSqGlob/ui_library.nut" import *

let faComp = require("%ui/components/faComp.nut")
let hoverImage = require("%enlist/components/hoverImage.nut")

let { mkGlyphsStyle } = require("%enlSqGlob/ui/soldierClasses.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { fontSmall, fontMedium, fontLarge, fontXLarge } = require("%enlSqGlob/ui/fontsStyle.nut")
let { RESEARCHED, CAN_RESEARCH } = require("researchesState.nut")
let { iconByGameTemplate, getItemName } = require("%enlSqGlob/ui/itemsInfo.nut")
let {
  colFull, colPart, columnGap, panelBgColor, midPadding,
  defTxtColor, titleTxtColor, negativeTxtColor, attentionTxtColor,
  smallPadding, defAvailSlotBgImg, accentColor, activeTabBgImg, weakTxtColor
} = require("%enlSqGlob/ui/designConst.nut")


let ORIENTATIONS = {
  TOP = "TOP"
  BOTTOM = "BOTTOM"
  BOTTOM_LEFT = "BOTTOM_LEFT"
  BOTTOM_RIGHT = "BOTTOM_RIGHT"
}


let hintTxtStyle = { color = weakTxtColor }.__update(fontSmall)
let defTxtStyle = { color = defTxtColor }.__update(fontMedium)
let nameTxtStyle = { color = titleTxtColor }.__update(fontLarge)
let attentionTxtStyle = { color = attentionTxtColor }.__update(fontLarge)
let headerTxtStyle = { color = titleTxtColor }.__update(fontXLarge)


let txtGap = (columnGap * 0.5).tointeger()
let pageDescWidth = colFull(5)
let squadInfoWidth = colFull(9)
let pageSize = [colPart(2.5), colPart(1.2)]
let pageIconSize = [colPart(0.8), colPart(0.8)]
let slotSize = [colPart(2), colPart(2)]
let childSlotSize = [colPart(2), colPart(3)]
let slotGapSize = [colPart(2.5), colPart(2)]
let slotMiniGapSize = [colPart(1), colPart(2)]
let itemSlotArea = [colPart(4.5), colPart(1.7)]
let itemSlotSize = [colPart(3.5), colPart(1.2)]
let vertLineSize = [colPart(2), colPart(1)]


let lineDashSize = hdpx(3)

let animXMove = colPart(3)
let mkPageInfoAnim = @(delay) {
  transform = {}
  animations = [
    { prop = AnimProp.opacity, from = 0, to = 0, duration = delay, play = true }
    { prop = AnimProp.opacity, from = 0, to = 1, delay, duration = 0.1, play = true }
    { prop = AnimProp.translate, from = [-animXMove,0], to = [0,0], delay,
      duration = 0.2, play = true, easing = OutQuart }
    { prop = AnimProp.opacity, from = 1, to = 0, duration = 0.2,
      playFadeOut = true }
    { prop = AnimProp.translate, from = [0,0], to = [animXMove,0], duration = 0.2,
      playFadeOut = true }
  ]
}


let idlePageSlotOverride = {
  rendObj = ROBJ_SOLID
  color = panelBgColor
}

let activePageSlotOverride = {
  rendObj = ROBJ_IMAGE
  image = activeTabBgImg
}

let selectedPageSlotLine = {
  size = [flex(), smallPadding]
  vplace = ALIGN_BOTTOM
  rendObj = ROBJ_SOLID
  color = accentColor
}

let pagesIcons = [ "upgrades_icon_squad", "upgrades_icon_personnel", "upgredes_icon_work_shop" ]

let mkResearchPageSlot = @(pageIdx, isSelected, isHover) {
  size = pageSize
  children = [
    {
      size = flex()
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      children = {
        rendObj = ROBJ_IMAGE
        size = pageIconSize
        image = Picture($"!ui/uiskin/research/{pagesIcons[pageIdx]}.svg:{pageIconSize[0]}:{pageIconSize[1]}:K")
      }
    }.__update(isSelected || isHover ? activePageSlotOverride : idlePageSlotOverride)
    isSelected ? selectedPageSlotLine : null
  ]
}


let mkResearchPageInfo = @(pageName, pageDesc, statusTxt) {
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_VERTICAL
  gap = columnGap
  children = [
    {
      size = [flex(), SIZE_TO_CONTENT]
      children = [
        {
          key = pageName
          rendObj = ROBJ_TEXT
          text = utf8ToUpper(loc(pageName))
        }.__update(headerTxtStyle, mkPageInfoAnim(0))
        {
          key = $"{pageName}_info"
          hplace = ALIGN_RIGHT
          rendObj = ROBJ_TEXT
          text = loc(statusTxt)
        }.__update(headerTxtStyle, mkPageInfoAnim(0.1))
      ]
    }
    {
      key = pageDesc
      size = [pageDescWidth, SIZE_TO_CONTENT]
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      text = loc(pageDesc)
    }.__update(defTxtStyle, mkPageInfoAnim(0.2))
  ]
}


let researchHoverBg = {
  rendObj = ROBJ_IMAGE
  size = [colPart(5), colPart(5)]
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  image = Picture($"!ui/uiskin/research/research_select_bg.avif?Ac")
}

let pageIcons = [
  "page_squad_upgrades_bg",
  "page_personnel_upgrades_bg",
  "page_workshop_upgrades_bg"
]

let commonIconColor = 0xFFFFFFFF

let iconColors = {
  disabled_0 = 0x999FC2E2
  disabled_1 = 0x99FABDC2
  disabled_2 = 0x999FC2E2
  veteran_0 = 0xFFF0E3A6
  veteran_1 = 0xFFF0E3A6
  veteran_2 = 0xFFFFAE8B
  disabled_veteran_0 = 0x999FC2E2
  disabled_veteran_1 = 0x99FADDC2
  disabled_veteran_2 = 0x99CF9C86
}

let function mkResearchIcon(pageIdx, iconId, isDisabled, isHover = false, isSelected = false) {
  let bgName = pageIcons?[pageIdx]
  let disabledSuffix = isDisabled ? "_disabled" : ""
  let bgImgPath = $"!ui/uiskin/research/icons/{bgName}{disabledSuffix}.avif?Ac"

  let isVeteran = iconId.endswith("_veteran")
  let iconPath = isVeteran ? $"!ui/uiskin/research/icons/{pageIdx}_common_veteran.avif?Ac"
    : $"!ui/uiskin/research/icons/{pageIdx}_{iconId}.avif?Ac"

  let iconColor = !isDisabled && !isVeteran ? commonIconColor
    : isDisabled && !isVeteran ? iconColors[$"disabled_{pageIdx}"]
    : !isDisabled && isVeteran ? iconColors[$"veteran_{pageIdx}"]
    : iconColors[$"disabled_veteran_{pageIdx}"]

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
      }
      {
        rendObj = ROBJ_IMAGE
        size = isSelected ? [colPart(2), colPart(2.3)] : flex()
        image = Picture(iconPath)
        color = iconColor
      }
    ]
  }
}


let lockSign = faComp("ban", {
  margin = [0, columnGap]
  vplace = ALIGN_BOTTOM
  fontSize = hdpx(32)
  color = negativeTxtColor
})

let function mkResearchSlot(pageIdx, research, selectedId, statuses, onClick, onDoubleClick, multViewData = null) {
  let { hasMultUsed = false, hasSelectedInGroup = false, hasResearchedInGroup = false } = multViewData
  let { research_id = null, icon_id = null } = research
  let isSelected = research_id == selectedId
  let status = statuses?[research_id]
  let isDisabled = status != RESEARCHED && status != CAN_RESEARCH

  let hasLockSign = hasMultUsed && status != RESEARCHED
    && (hasResearchedInGroup || (hasSelectedInGroup && !isSelected))

  return watchElemState(function(sf) {
    let isHover = (sf & S_HOVER) != 0
    return {
      size = slotSize
      behavior = Behaviors.Button
      onClick
      onDoubleClick
      children = [
        hoverImage.create({
          sf = sf
          uid = research_id
          size = slotSize
          image = null
          pivot = [0.5, 0.5]
          children = mkResearchIcon(pageIdx, icon_id, isDisabled, isHover, isSelected)
        })
        hasLockSign ? lockSign : null
      ]
    }
  })
}

let vectorStyle = {
  size = flex()
  margin = [columnGap, 0]
  rendObj = ROBJ_VECTOR_CANVAS
  lineWidth = hdpx(1)
}

let topVector = { commands = [[ VECTOR_LINE, 50, 0, 50, 100 ]] }
let btmLeftVector = { commands = [[ VECTOR_LINE, 80, 0, 65, 100 ]] }
let btmRightVector = { commands = [[ VECTOR_LINE, 20, 0, 35, 100 ]] }

let topMultVector = {
  commands = [
    [ VECTOR_LINE_DASHED, 50, 0, 50, 100, lineDashSize, lineDashSize ],
    [ VECTOR_LINE_DASHED, 5, 100, 95, 100, lineDashSize, lineDashSize ]
  ]
}
let btmMultVector = {
  commands = [
    [ VECTOR_LINE_DASHED, 50, 100, 50, 0, lineDashSize, lineDashSize ],
    [ VECTOR_LINE_DASHED, 5, 0, 95, 0, lineDashSize, lineDashSize ]
  ]
}

let chainVertLine = {
  size = flex()
  children = vectorStyle.__merge(topVector)
}

let chainBtmLeftLine = {
  size = flex()
  children = vectorStyle.__merge(btmLeftVector)
}

let chainBtmRightLine = {
  size = flex()
  children = vectorStyle.__merge(btmRightVector)
}

let baseResearchGap = vectorStyle.__merge({
  size = slotGapSize
  margin = 0
  commands = [[ VECTOR_LINE, 0, 50, 100, 50 ]]
})

let researcheMiniGap = vectorStyle.__merge({
  size = slotMiniGapSize
  margin = 0
  commands = [[ VECTOR_LINE, 0, 50, 100, 50 ]]
})

let researcheGaps = {
  [1] = {
    size = slotMiniGapSize
    children = {
      size = vertLineSize
      pos = [slotMiniGapSize[0], slotSize[1]]
      children = chainVertLine
    }
  },
  [2] = researcheMiniGap,
  [3] = {
    size = slotMiniGapSize
    children = {
      size = vertLineSize
      pos = [slotMiniGapSize[0], -vertLineSize[1]]
      children = chainVertLine
    }
  },
  [4] = researcheMiniGap,
}

let function mkResearchMult(pageIdx, researches, selectedId, statuses, cbCtor, doubleCbCtor, orientation) {
  let multViewData = {
    hasMultUsed = true
    hasResearchedInGroup = researches.findvalue(@(r) statuses?[r.research_id] == RESEARCHED ) != null
    hasSelectedInGroup = researches.findvalue(@(r) r.research_id == selectedId ) != null
  }
  let isTop = orientation == ORIENTATIONS.TOP
  local yPos = isTop ? -childSlotSize[1] : slotSize[1]
  return {
    pos = [0, yPos]
    size = childSlotSize
    halign = ALIGN_CENTER
    children = {
      size = [SIZE_TO_CONTENT, flex()]
      flow = FLOW_VERTICAL
      children = [
        isTop ? null : vectorStyle.__merge(topMultVector)
        {
          children = [
            {
              flow = FLOW_HORIZONTAL
              children = researches.map(@(r)
                mkResearchSlot(pageIdx, r, selectedId, statuses, cbCtor(r), doubleCbCtor(r), multViewData))
            }
            {
              pos = [0, hdpx(16)]
              rendObj = ROBJ_TEXT
              hplace = ALIGN_CENTER
              vplace = ALIGN_BOTTOM
              text = loc("multResearchSelectHint")
            }.__update(hintTxtStyle)
          ]
        }
        isTop ? vectorStyle.__merge(btmMultVector) : null
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
      yPos += childSlotSize[1] * idx * (isBottom ? 1 : -1)
      return {
        pos = [xPos, yPos]
        size = childSlotSize
        flow = FLOW_VERTICAL
        children = [
          orientation == ORIENTATIONS.TOP ? null
            : orientation == ORIENTATIONS.BOTTOM || idx > 0 ? chainVertLine
            : orientation == ORIENTATIONS.BOTTOM_LEFT ? chainBtmLeftLine
            : orientation == ORIENTATIONS.BOTTOM_RIGHT ? chainBtmRightLine
            : null
          mkResearchSlot(pageIdx, r, selectedId, statuses, cbCtor(r), doubleCbCtor(r))
          orientation == ORIENTATIONS.TOP ? chainVertLine : null
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
  hasLongBranches, cbCtor, doubleCbCtor, toChildren
) {
  let [ btmChildren = null, topChildren = null ] = children
  let { research_id } = main

  let hasMultiresearch = (topChildren?.multiresearchGroup ?? 0) > 0
    || (btmChildren?.multiresearchGroup ?? 0) > 0
  let reqOptimization = !hasMultiresearch && hasLongBranches

  let btmOrientation = !reqOptimization || topChildren == null
    ? ORIENTATIONS.BOTTOM
    : ORIENTATIONS.BOTTOM_LEFT

  let topOrientation = !reqOptimization || btmChildren == null
    ? ORIENTATIONS.TOP
    : ORIENTATIONS.BOTTOM_RIGHT

  let researcheGap = researcheGaps?[min(toChildren, researcheGaps.len())] ?? baseResearchGap
  return {
    flow = FLOW_HORIZONTAL
    children = [
      idx == 0 ? null
        : researcheGap.__merge(
            { key = $"vector_{research_id}" },
            mkPageInfoAnim(idx * 0.1 + 0.05)
          )
      {
        key = $"slot_{research_id}"
        size = slotSize
        children = [
          mkResearchChildren(pageIdx, topChildren, selectedId, statuses, cbCtor, topOrientation, doubleCbCtor)
          mkResearchSlot(pageIdx, main, selectedId, statuses, cbCtor(main), doubleCbCtor(main))
          mkResearchChildren(pageIdx, btmChildren, selectedId, statuses, cbCtor, btmOrientation, doubleCbCtor)
        ]
      }.__update(mkPageInfoAnim(idx * 0.1))
    ]
  }
}


let function mkResearchItem(column, isLast) {
  let { template = null, tplCount = 0 } = column
  if (template == null || tplCount == 0)
    return isLast ? null : { size = [itemSlotArea[0], 0] }

  return {
    size = isLast ? [SIZE_TO_CONTENT, itemSlotArea[1]]: itemSlotArea
    children = [
      {
        pos = [-columnGap, -columnGap]
        size = [tplCount * itemSlotArea[0] - colPart(2), itemSlotArea[1] + colPart(9)]
        rendObj = ROBJ_SOLID
        opacity = 0.05
        color = 0xFFFFFF
      }
      {
        flow = FLOW_VERTICAL
        children = [
          {
            margin = [columnGap, 0, smallPadding, 0]
            rendObj = ROBJ_TEXT
            text = getItemName(template)
          }.__update(defTxtStyle)
          {
            size = itemSlotSize
            rendObj = ROBJ_IMAGE
            image = defAvailSlotBgImg
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


let classesTagsTable = mkGlyphsStyle(colPart(0.4))

let function mkResearchInfo(research) {
  if (research == null)
    return null

  let { research_id, name = null, description = null, params = null } = research
  return {
    size = flex()
    flow = FLOW_VERTICAL
    gap = columnGap
    children = [
      {
        key = $"name_{research_id}"
        size = [flex(), SIZE_TO_CONTENT]
        rendObj = ROBJ_TEXTAREA
        behavior = Behaviors.TextArea
        text = utf8ToUpper(loc(name, params))
        tagsTable = classesTagsTable
      }.__update(attentionTxtStyle, mkPageInfoAnim(0))
      {
        key = $"desc_{research_id}"
        size = [flex(), SIZE_TO_CONTENT]
        rendObj = ROBJ_TEXTAREA
        behavior = Behaviors.TextArea
        text = loc(description, params)
        tagsTable = classesTagsTable
      }.__update(defTxtStyle, mkPageInfoAnim(0.1))
    ]
  }
}


let priceIconSize = colPart(0.5)

let priceIcon = {
  rendObj = ROBJ_IMAGE
  size = [priceIconSize, priceIconSize]
  image = Picture("!ui/uiskin/research/squad_points_icon.svg:{0}:{0}:K".subst(priceIconSize))
}

let mkPointsInfo = @(level, points) {
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_HORIZONTAL
  children = [
    {
      rendObj = ROBJ_TEXT
      text = loc("levelInfo", { level })
    }.__update(nameTxtStyle)
    {
      size = [flex(), SIZE_TO_CONTENT]
      flow = FLOW_HORIZONTAL
      gap = txtGap
      halign = ALIGN_RIGHT
      valign = ALIGN_CENTER
      children = [
        {
          rendObj = ROBJ_TEXT
          text = loc("research/availPoints")
        }.__update(defTxtStyle)
        priceIcon
        {
          rendObj = ROBJ_TEXT
          text = points
        }.__update(nameTxtStyle)
      ]
    }
  ]
}


let mkWarningText = @(locId) {
  size = flex()
  valign = ALIGN_CENTER
  flow = FLOW_HORIZONTAL
  children = [
    { size = [squadInfoWidth, 0] }
    {
      size = [colFull(7), SIZE_TO_CONTENT]
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      text = loc(locId)
    }.__update(nameTxtStyle)
  ]
}


return {
  mkResearchPageSlot
  mkResearchPageInfo
  mkResearchColumn
  mkResearchItem
  mkResearchInfo
  mkPageInfoAnim
  mkPointsInfo
  priceIcon
  priceIconSize
  squadInfoWidth
  pageSize
  slotSize
  childSlotSize
  slotGapSize
  slotMiniGapSize
  mkWarningText
}
