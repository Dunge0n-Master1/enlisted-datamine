from "%enlSqGlob/ui_library.nut" import *

let faComp = require("%ui/components/faComp.nut")
let hoverImage = require("%enlist/components/hoverImage.nut")

let { utf8ToUpper } = require("%sqstd/string.nut")
let { fontXSmall, fontMedium, fontLarge, fontXLarge } = require("%enlSqGlob/ui/fontsStyle.nut")
let { RESEARCHED, CAN_RESEARCH } = require("researchesState.nut")
let { iconByGameTemplate, getItemName } = require("%enlSqGlob/ui/itemsInfo.nut")
let {
  colFull, colPart, columnGap, panelBgColor,
  defTxtColor, titleTxtColor, negativeTxtColor, attentionTxtColor,
  smallPadding, defAvailSlotBgImg, accentColor, activeTabBgImg, weakTxtColor
} = require("%enlSqGlob/ui/designConst.nut")


let hintTxtStyle = { color = weakTxtColor }.__update(fontXSmall)
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
let itemSlotArea = [colPart(4.5), colPart(1.7)]
let itemSlotSize = [colPart(3.5), colPart(1.2)]


let lineDashSize = hdpx(3)

let animXMove = colPart(3)
let mkPageInfoAnim = @(delay) {
  transform = {}
  animations = [
    { prop = AnimProp.opacity, from = 0, to = 0, duration = delay, play = true }
    { prop = AnimProp.opacity, from = 0, to = 1, delay, duration = 0.2, play = true }
    { prop = AnimProp.translate, from = [-animXMove,0], to = [0,0], delay,
      duration = 0.3, play = true, easing = OutQuart }
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

let researchPngIcons = {
  squad_size = "research_default"
}


let function mkResearchIcon(iconId, isDisabled, isHover = false, isSelected = false) {
  let imageName = researchPngIcons?[iconId] ?? "research_default"
  let suffix = isSelected ? "_hover" : ""
  let iconPath = $"!ui/uiskin/research/{imageName}{suffix}.avif?Ac"
  return {
    size = flex()
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    children = [
      isHover || isSelected ? researchHoverBg : null
      {
        rendObj = ROBJ_IMAGE
        size = isSelected ? [colPart(2.3), colPart(2.3)] : flex()
        picSaturate = isDisabled ? 0.3 : 1
        opacity = isDisabled && !isSelected ? 0.7 : 1
        image = Picture(iconPath)
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

let function mkResearchSlot(research, selectedId, statuses, onClick, onDoubleClick, multViewData = null) {
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
          pivot = [0.5, 0.9]
          children = mkResearchIcon(icon_id, isDisabled, isHover, isSelected)
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

let topMultVector = {
  commands = [
    [ VECTOR_LINE_DASHED, 50, 0, 50, 100, lineDashSize, lineDashSize ],
    [ VECTOR_LINE_DASHED, 0, 100, 100, 100, lineDashSize, lineDashSize ]
  ]
}
let btmMultVector = {
  commands = [
    [ VECTOR_LINE_DASHED, 50, 100, 50, 0, lineDashSize, lineDashSize ],
    [ VECTOR_LINE_DASHED, 0, 0, 100, 0, lineDashSize, lineDashSize ]
  ]
}

let chainVertLine = {
  size = flex()
  children = vectorStyle.__merge(topVector)
}

let researcheGap = vectorStyle.__merge({
  size = slotGapSize
  margin = 0
  commands = [[ VECTOR_LINE, 0, 50, 100, 50 ]]
})

let function mkResearchMult(researches, selectedId, statuses, cbCtor, doubleCbCtor, isTop) {
  let multViewData = {
    hasMultUsed = true
    hasResearchedInGroup = researches.findvalue(@(r) statuses?[r.research_id] == RESEARCHED ) != null
    hasSelectedInGroup = researches.findvalue(@(r) r.research_id == selectedId ) != null
  }

  local yPos = isTop ? slotSize[1] : -childSlotSize[1]
  return {
    pos = [0, yPos]
    size = childSlotSize
    halign = ALIGN_CENTER
    children = {
      size = [SIZE_TO_CONTENT, flex()]
      flow = FLOW_VERTICAL
      children = [
        isTop ? vectorStyle.__merge(topMultVector) : null
        {
          children = [
            {
              flow = FLOW_HORIZONTAL
              children = researches.map(@(r)
                mkResearchSlot(r, selectedId, statuses, cbCtor(r), doubleCbCtor(r), multViewData))
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
        isTop ? null : vectorStyle.__merge(btmMultVector)
      ]
    }
  }
}

let function mkResearchChain(researches, selectedId, statuses, cbCtor, doubleCbCtor, isTop) {
  local yPos = isTop ? slotSize[1] : -childSlotSize[1]
  return {
    children = researches.map(function(r, idx) {
      yPos += childSlotSize[1] * idx * (isTop ? 1 : -1)
      return {
        pos = [0, yPos]
        size = childSlotSize
        flow = FLOW_VERTICAL
        children = [
          isTop ? chainVertLine : null
          mkResearchSlot(r, selectedId, statuses, cbCtor(r), doubleCbCtor(r))
          isTop ? null : chainVertLine
        ]
      }
    })
  }
}

let function mkResearchChildren(children, selectedId, statuses, cbCtor, doubleCbCtor, isTop = false) {
  let { researches = null, multiresearchGroup = 0 } = children
  if (researches == null)
    return null

  let ctor = multiresearchGroup > 0 ? mkResearchMult : mkResearchChain
  return ctor(researches, selectedId, statuses, cbCtor, doubleCbCtor, isTop)
}


let function mkResearchColumn(idx, main, children, selectedId, statuses, cbCtor, doubleCbCtor) {
  let [ topChildren = null, btmChildren = null ] = children
  let { research_id } = main
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
          mkResearchChildren(topChildren, selectedId, statuses, cbCtor, doubleCbCtor, true)
          mkResearchSlot(main, selectedId, statuses, cbCtor(main), doubleCbCtor(main))
          mkResearchChildren(btmChildren, selectedId, statuses, cbCtor, doubleCbCtor)
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
        rendObj = ROBJ_IMAGE
        image = defAvailSlotBgImg
        opacity = 0.2
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
      }.__update(attentionTxtStyle, mkPageInfoAnim(0))
      {
        key = $"desc_{research_id}"
        size = [flex(), SIZE_TO_CONTENT]
        rendObj = ROBJ_TEXTAREA
        behavior = Behaviors.TextArea
        text = loc(description, params)
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
  slotGapSize
  mkWarningText
}
