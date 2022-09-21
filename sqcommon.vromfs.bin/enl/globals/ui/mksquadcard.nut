from "%enlSqGlob/ui_library.nut" import *

let { fontMedium, fontSmall } = require("%enlSqGlob/ui/fontsStyle.nut")
let mkCountdownTimer = require("%enlSqGlob/ui/mkCountdownTimer.nut")
let { colFull, tabBgColor, titleTxtColor, smallPadding,
  bigPadding, colPart, commonBorderRadius } = require("%enlSqGlob/ui/designConst.nut")
let { mkSquadIcon, mkSquadTypeIcon } = require("%enlSqGlob/ui/squadInfoPkg.nut")


let premIconSize = colPart(0.60)
let selectionLineHeight = colPart(0.08)
let selectionLineOffset = colPart(0.1)
let squadCardSize = [colFull(2), colPart(1.55) + selectionLineHeight + selectionLineOffset]
let squadContentSize = [flex(), colPart(1.55)]

const defaultSquadIcon = "!ui/uiskin/squad_default.svg"

let defSquadBgColor = 0xFF242D31
let hoverSquadBgColor = 0xFF45545C
let activeSquadBgColor = 0xFF6A7B84

let defLockedBgColor = 0xFF4A2222
let hoverLockedBgColor = 0xFF6C3535
let activeLockedBgColor = 0xFF9F5858

let squadBgColorCommon = @(flags, selected)
  selected ? activeSquadBgColor
    : flags & S_HOVER ? hoverSquadBgColor
    : defSquadBgColor


let squadBgColorLocked = @(flags, selected)
  selected ? activeLockedBgColor
    : flags & S_HOVER ? hoverLockedBgColor
    : defLockedBgColor


let defTxtStyle = {
  color = titleTxtColor
}.__update(fontMedium)

let smallTxtStyle = {
  color = titleTxtColor
}.__update(fontSmall)


let mkCardText = @(text, txtStyle = defTxtStyle) {
  rendObj = ROBJ_TEXT
  text
}.__update(txtStyle)


let mkSquadLevel = @(level) mkCardText(loc("level/short", { level = level + 1 }),
  smallTxtStyle.__merge({ vplace = ALIGN_BOTTOM }))

let squadTimer = @(expireTime) mkCountdownTimer({
  timestamp = expireTime
  color = titleTxtColor
  override = { vplace = ALIGN_BOTTOM }
  isSmall = true
})


let mkSquadInfoBlock = @(squadType, level, addChild = null, isLocked = false, expireTime = 0) {
  size = flex()
  halign = ALIGN_CENTER
  children = [
    mkSquadTypeIcon(squadType, isLocked)
    expireTime <= 0 ? mkSquadLevel(level) : squadTimer(expireTime)
    {
      pos = [colPart(0.05), -colPart(0.16)]
      hplace = ALIGN_RIGHT
      children = addChild
    }
  ]
}

let mkSquadPremIcon = @(premIcon, override = null) premIcon == null ? null : {
  rendObj = ROBJ_IMAGE
  size = [premIconSize, premIconSize]
  keepAspect = true
  image = Picture($"{premIcon}:{premIconSize}:{premIconSize}:K")
}.__update(override ?? {})


let selectionLine = {
  rendObj = ROBJ_SOLID
  vplace = ALIGN_BOTTOM
  size = [flex(), selectionLineHeight]
  color = tabBgColor
}


let mkSquadCard = kwarg(function (idx, isSelected, addChild = null, icon = "",
  squadType = null, level = null, premIcon = null, onClick = null, expireTime = 0,
  isLocked = false
) {
  let isCardSelected = isSelected.value
  icon = (icon ?? "").len() > 0 ? icon : defaultSquadIcon

  return watchElemState(@(sf) {
    key = $"squad{idx}"
    size = squadCardSize
    flow = FLOW_VERTICAL
    gap = selectionLineOffset
    behavior = Behaviors.Button
    onClick = onClick
    xmbNode = XmbNode()
    children = [
      {
        size = flex()
        children = [
          {
            rendObj = ROBJ_BOX
            fillColor = isLocked
              ? squadBgColorLocked(sf, isCardSelected)
              : squadBgColorCommon(sf, isCardSelected)
            borderRadius = commonBorderRadius
            size = squadContentSize
            padding = [bigPadding, smallPadding]
            flow = FLOW_HORIZONTAL
            children = [
              mkSquadIcon(icon)
              mkSquadInfoBlock(squadType, level, addChild, isLocked, expireTime)
            ]
          }
          mkSquadPremIcon(premIcon)
        ]
      }
      isCardSelected ? selectionLine : null
    ]
  })
})


return {
  mkSquadCard
}