from "%enlSqGlob/ui_library.nut" import *

let faComp = require("%ui/components/faComp.nut")
let hoverImage = require("%enlist/components/hoverImage.nut")

let { utf8ToUpper } = require("%sqstd/string.nut")
let { fontMedium, fontLarge, fontXXLarge } = require("%enlSqGlob/ui/fontsStyle.nut")
let { RESEARCHED, CAN_RESEARCH } = require("researchesState.nut")
let {
  colFull, colPart, columnGap, panelBgColor, activeBgColor, hoverBgColor,
  defTxtColor, titleTxtColor, negativeTxtColor, attentionTxtColor
} = require("%enlSqGlob/ui/designConst.nut")


let defTxtStyle = { color = defTxtColor }.__update(fontMedium)
let nameTxtStyle = { color = titleTxtColor }.__update(fontLarge)
let attentionTxtStyle = { color = attentionTxtColor }.__update(fontLarge)
let headerTxtStyle = { color = titleTxtColor }.__update(fontXXLarge)


let txtGap = (columnGap * 0.5).tointeger()
let pageDescWidth = colFull(5)
let squadInfoWidth = colFull(9)
let pageSize = [colPart(2.5), colPart(1.3)]
let pageIconSize = [colPart(1.2), colPart(1.2)]
let slotSize = [colPart(2), colPart(2)]
let childSlotSize = [colPart(2), colPart(3)]
let slotGapSize = [colPart(2.5), colPart(2)]


let lineDashSize = hdpx(3)

let animXMove = colPart(3)
let mkPageInfoAnim = @(delay) {
  transform = {}
  animations = [
    { prop = AnimProp.opacity, from = 0, to = 0, duration = delay, play = true }
    { prop = AnimProp.opacity, from = 0, to = 1, delay, duration = 0.2, play = true }
    { prop = AnimProp.translate, from = [-animXMove,0], to = [0,0], delay,
      duration = 0.5, play = true, easing = OutQuart }
    { prop = AnimProp.opacity, from = 1, to = 0, duration = 0.4,
      playFadeOut = true }
    { prop = AnimProp.translate, from = [0,0], to = [animXMove,0], duration = 0.4,
      playFadeOut = true }
  ]
}

let function mkResearchPageSlot(iconPath, isSelected, onClick) {
  return watchElemState(@(sf) {
    size = pageSize
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    clipChildren = true
    rendObj = ROBJ_SOLID
    color = isSelected ? activeBgColor
      : (sf & S_HOVER) ? hoverBgColor
      : panelBgColor
    behavior = Behaviors.Button
    onClick
    children = [
      iconPath == null ? null
        : {
            rendObj = ROBJ_IMAGE
            size = pageIconSize
            image = Picture($"!{iconPath}:{pageIconSize[0]}:{pageIconSize[1]}:K")
          }
    ]
  })
}

let mkResearchPageInfo = @(pageName, pageDesc, statusTxt) {
  flow = FLOW_VERTICAL
  gap = columnGap
  children = [
    {
      flow = FLOW_HORIZONTAL
      gap = colPart(1)
      children = [
        {
          key = pageName
          rendObj = ROBJ_TEXT
          text = utf8ToUpper(loc(pageName))
        }.__update(headerTxtStyle, mkPageInfoAnim(0.2))
        {
          key = $"{pageName}_info"
          rendObj = ROBJ_TEXT
          text = loc(statusTxt)
        }.__update(headerTxtStyle, mkPageInfoAnim(0.3))
      ]
    }
    {
      key = pageDesc
      size = [pageDescWidth, SIZE_TO_CONTENT]
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      text = loc(pageDesc)
    }.__update(defTxtStyle, mkPageInfoAnim(0.4))
  ]
}


let researchHoverBg = {
  rendObj = ROBJ_IMAGE
  size = [colPart(5), colPart(5)]
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  image = Picture($"!ui/uiskin/research/research_select_bg.png?Ac")
}

let researchPngIcons = {
  squad_size = "research_default"
}


let function mkResearchIcon(iconId, isDisabled, isHover = false, isSelected = false) {
  let imageName = researchPngIcons?[iconId] ?? "research_default"
  let suffix = isSelected ? "_hover" : ""
  let iconPath = $"!ui/uiskin/research/{imageName}{suffix}.png?Ac"
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

let function mkResearchSlot(research, selectedId, statuses, onClick, hasMultUsed = false) {
  let { research_id = null, icon_id = null } = research
  let isSelected = research_id == selectedId
  let status = statuses?[research_id]
  let isDisabled = status != RESEARCHED && status != CAN_RESEARCH

  return watchElemState(function(sf) {
    let isHover = (sf & S_HOVER) != 0
    return {
      size = slotSize
      behavior = Behaviors.Button
      onClick
      children = [
        hoverImage.create({
          sf = sf
          uid = research_id
          size = slotSize
          image = null
          pivot = [0.5, 0.9]
          children = mkResearchIcon(icon_id, isDisabled, isHover, isSelected)
        })
        isDisabled && hasMultUsed ? lockSign : null
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
let btmVector = { commands = [[ VECTOR_LINE, 50, 100, 50, 0 ]] }

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

let researcheGap = vectorStyle.__merge({
  size = slotGapSize
  margin = 0
  commands = [[ VECTOR_LINE, 0, 50, 100, 50 ]]
})

let function mkResearchChildren(researches, selectedId, statuses, cbCtor, isTop = false) {
  if (researches == null)
    return null

  let isMult = researches.len() > 1
  let hasMultUsed = isMult && researches.findvalue(function(r) {
    let status = statuses?[r.research_id]
    return status == RESEARCHED || status == CAN_RESEARCH
  }) != null
  let yPos = isTop ? slotSize[1] : -childSlotSize[1]

  return {
    size = childSlotSize
    halign = ALIGN_CENTER
    pos = [0, yPos]
    children = {
      size = [SIZE_TO_CONTENT, flex()]
      flow = FLOW_VERTICAL
      children = [
        isTop ? vectorStyle.__merge(isMult ? topMultVector : topVector) : null
        {
          flow = FLOW_HORIZONTAL
          children = researches.map(@(r)
            mkResearchSlot(r, selectedId, statuses, cbCtor(r), hasMultUsed))
        }
        isTop ? null : vectorStyle.__merge(isMult ? btmMultVector : btmVector)
      ]
    }
  }
}


let function mkResearchColumn(idx, main, children, selectedId, statuses, cbCtor) {
  let [ btmChildren = null, topChildren = null ] = children
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
          mkResearchChildren(topChildren, selectedId, statuses, cbCtor, true)
          mkResearchSlot(main, selectedId, statuses, cbCtor(main))
          mkResearchChildren(btmChildren, selectedId, statuses, cbCtor)
        ]
      }.__update(mkPageInfoAnim(idx * 0.1))
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
      }.__update(attentionTxtStyle, mkPageInfoAnim(0.2))
      {
        key = $"desc_{research_id}"
        size = [flex(), SIZE_TO_CONTENT]
        rendObj = ROBJ_TEXTAREA
        behavior = Behaviors.TextArea
        text = loc(description, params)
      }.__update(defTxtStyle, mkPageInfoAnim(0.3))
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
  mkResearchInfo
  mkPageInfoAnim
  mkPointsInfo
  priceIcon
  priceIconSize
  squadInfoWidth
  pageSize
  mkWarningText
}
