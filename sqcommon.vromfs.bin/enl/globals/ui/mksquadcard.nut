from "%enlSqGlob/ui_library.nut" import *

let { fontMedium, fontSmall } = require("%enlSqGlob/ui/fontsStyle.nut")
let mkCountdownTimer = require("%enlSqGlob/ui/mkCountdownTimer.nut")
let { colFull, titleTxtColor, smallPadding, midPadding, bigPadding, colPart,
  commonBorderRadius, defSlotBgImg, hoverSlotBgImg, accentColor, defLockedSlotBgImg,
  hoverLockedSlotBgImg, rightAppearanceAnim
} = require("%enlSqGlob/ui/designConst.nut")
let { mkSquadIcon, mkSquadTypeIcon } = require("%enlSqGlob/ui/squadInfoPkg.nut")
let faComp = require("%ui/components/faComp.nut")


let premIconSize = colPart(0.60)
let selectionLineHeight = colPart(0.08)
let selectionLineOffset = colPart(0.1)
let squadCardSize = [colFull(2), colPart(1.55) + selectionLineHeight + selectionLineOffset]
let squadContentSize = [colFull(2), colPart(1.55)]
const defaultSquadIcon = "!ui/uiskin/squad_default.svg"
const LOCKED_SQUAD_PANEL_COLOR = 0xCC000000


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


let mkSquadInfoBlock = @(squadType, level, addChild = null, expireTime = 0) {
  size = flex()
  halign = ALIGN_CENTER
  children = [
    mkSquadTypeIcon(squadType, false)
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
  keepAspect = KEEP_ASPECT_FIT
  image = Picture($"{premIcon}:{premIconSize}:{premIconSize}:K")
}.__update(override ?? {})


let selectionLine = {
  size = [flex(), selectionLineHeight]
  rendObj = ROBJ_BOX
  borderWidth = 0
  borderRadius = commonBorderRadius
  fillColor = accentColor
  vplace = ALIGN_BOTTOM
}


let mkSquadCard = kwarg(function(idx, isSelected, addChild = null, icon = "", onDoubleClick = null,
  squadType = null, level = null, premIcon = null, onClick = null, expireTime = 0, animDelay = 0
) {
  let isCardSelected = isSelected.value
  icon = (icon ?? "").len() > 0 ? icon : defaultSquadIcon

  return watchElemState(@(sf) {
    key = $"squad{idx}"
    size = squadCardSize
    flow = FLOW_VERTICAL
    gap = selectionLineOffset
    behavior = Behaviors.Button
    onClick
    onDoubleClick
    xmbNode = XmbNode()
    children = [
      {
        size = flex()
        children = [
          {
            rendObj = ROBJ_BOX
            size = squadContentSize
            borderRadius = commonBorderRadius
            children = [
              {
                rendObj = ROBJ_IMAGE
                size = squadContentSize
                image = isCardSelected ? hoverSlotBgImg
                  : sf & S_HOVER ? hoverSlotBgImg
                  : defSlotBgImg
              }
              {
                size = flex()
                padding = [bigPadding, smallPadding]
                flow = FLOW_HORIZONTAL
                children = [
                  mkSquadIcon(icon)
                  mkSquadInfoBlock(squadType, level, addChild, expireTime)
                ]
              }
            ]
          }
          mkSquadPremIcon(premIcon)
        ]
      }
      isCardSelected ? selectionLine : null
    ]
  }.__update(rightAppearanceAnim(animDelay)))
})


let lockedSquadInfo = @(unlockLvl) unlockLvl == null ? null : {
  rendObj = ROBJ_SOLID
  size = [flex(), SIZE_TO_CONTENT]
  color = LOCKED_SQUAD_PANEL_COLOR
  padding = [smallPadding, midPadding]
  vplace = ALIGN_BOTTOM
  valign = ALIGN_CENTER
  children = [
    {
      rendObj = ROBJ_TEXTAREA
      size = [flex(), SIZE_TO_CONTENT]
      behavior = Behaviors.TextArea
      text = loc("squads/reqLevel", { level = unlockLvl})
    }.__update(smallTxtStyle)
    faComp("lock", {
      fontSize = fontMedium.fontSize
      color = smallTxtStyle.color
      hplace = ALIGN_RIGHT
    })
  ]
}


let mkLockedSquadCard = kwarg(function(idx, icon = "", squadType = null,
  level = null, onClick = null, animDelay = 0, premIcon = null
) {
  icon = (icon ?? "").len() > 0 ? icon : defaultSquadIcon
  return watchElemState(@(sf) {
    rendObj = ROBJ_BOX
    borderRadius = commonBorderRadius
    key = $"squad{idx}"
    size = squadContentSize
    behavior = Behaviors.Button
    onClick = onClick
    xmbNode = XmbNode()
    children = [
      {
        rendObj = ROBJ_IMAGE
        image = sf & S_HOVER ? hoverLockedSlotBgImg : defLockedSlotBgImg
        size = squadContentSize
      }
      {
        size = [flex(), SIZE_TO_CONTENT]
        padding = [bigPadding, smallPadding]
        flow = FLOW_HORIZONTAL
        children = [
          mkSquadIcon(icon)
          {
            size = [flex(), SIZE_TO_CONTENT]
            halign = ALIGN_CENTER
            children = mkSquadTypeIcon(squadType, false)
          }
        ]
      }
      premIcon == null ? lockedSquadInfo(level) : mkSquadPremIcon(premIcon)
    ]
  }.__update(rightAppearanceAnim(animDelay)))
})


return {
  mkSquadCard
  mkLockedSquadCard
}