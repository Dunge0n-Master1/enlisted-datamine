from "%enlSqGlob/ui_library.nut" import *

let { fontMedium, fontSmall } = require("%enlSqGlob/ui/fontsStyle.nut")
let mkCountdownTimer = require("%enlSqGlob/ui/mkCountdownTimer.nut")
let { colFull, titleTxtColor, smallPadding, midPadding, bigPadding, colPart, commonBorderRadius,
  defSlotBgColor, defItemBlur, hoverSlotBgColor, reseveSlotBgColor, accentColor,
  rightAppearanceAnim, deadTxtColor, defLockedSlotBgColor, hoverSlotTxtColor,
  hoverLockedSlotBgColor, levelNestGradient, hoverLevelNestGradient, miniPadding, darkTxtColor
} = require("%enlSqGlob/ui/designConst.nut")
let { mkSquadIcon, mkSquadTypeIcon } = require("%enlSqGlob/ui/squadInfoPkg.nut")
let { mkSquadPremIcon } = require("%enlSqGlob/ui/squadsUiComps.nut")
let faComp = require("%ui/components/faComp.nut")


let premIconSize = colPart(0.60)
let selectionLineHeight = colPart(0.08)
let selectionLineOffset = colPart(0.1)
let bottomOffset = selectionLineHeight + selectionLineOffset
let squadCardSize = [colFull(2), colPart(1.55) + bottomOffset]
let squadContentSize = [colFull(2), colPart(1.55)]
let unavaliableIconSize = colPart(0.55)
const defaultSquadIcon = "!ui/uiskin/squad_default.svg"
const LOCKED_SQUAD_PANEL_COLOR = 0x77000000


let defTxtStyle = {
  color = titleTxtColor
}.__update(fontMedium)

let smallTxtStyle = {
  color = titleTxtColor
}.__update(fontSmall)


let hoverSmallTxtStyle = {
  color = darkTxtColor
}.__update(fontSmall)



let squadBgCommon = @(flags, isSelected) isSelected || (flags & S_HOVER) != 0 ? hoverSlotBgColor
  : defSlotBgColor
let squadBgReserve = @(flags, isSelected) isSelected || (flags & S_HOVER) != 0 ? hoverSlotBgColor
: reseveSlotBgColor


let mkCardText = @(text, txtStyle = defTxtStyle) {
  rendObj = ROBJ_TEXT
  text
}.__update(txtStyle)


let mkSquadLevel = @(level, sf, isSelected) mkCardText(loc("level/short", { level = level + 1 }),
  { vplace = ALIGN_BOTTOM }.__merge(isSelected || (sf & S_HOVER) != 0 || (sf & S_ACTIVE) != 0
    ? hoverSmallTxtStyle
    : smallTxtStyle) )


let squadTimer = @(expireTime, sf, isSelected) mkCountdownTimer({
  timestamp = expireTime
  color = isSelected || (sf & S_HOVER) != 0|| (sf & S_ACTIVE) != 0 ? hoverSlotTxtColor : titleTxtColor
  override = { vplace = ALIGN_BOTTOM }
  isSmall = true
})


let mkSquadInfoBlock = @(squadType, addChild = null) {
  size = flex()
  halign = ALIGN_CENTER
  children = [
    mkSquadTypeIcon(squadType)
    {
      pos = [colPart(0.05), -colPart(0.16)]
      hplace = ALIGN_RIGHT
      children = addChild
    }
  ]
}


let selectionLine = {
  size = [flex(), selectionLineHeight]
  rendObj = ROBJ_BOX
  borderWidth = 0
  borderRadius = commonBorderRadius
  fillColor = accentColor
  vplace = ALIGN_BOTTOM
}


let mkLevelBlock = @(sf, isCardSelected, level = -1, expireTime = 0) {
  rendObj = ROBJ_IMAGE
  image = isCardSelected || (sf & S_HOVER) != 0 ? hoverLevelNestGradient : levelNestGradient
  size = [flex(), SIZE_TO_CONTENT]
  padding = [miniPadding, bigPadding]
  vplace = ALIGN_BOTTOM
  valign = ALIGN_CENTER
  halign = ALIGN_RIGHT
  children = expireTime > 0 ? squadTimer(expireTime)
    : level >= 0 ? mkSquadLevel(level, sf, isCardSelected)
    : null
}


let mkSquadCard = kwarg(function(idx, isSelected, addChild = null, icon = "", onDoubleClick = null,
  squadType = null, level = null, premIcon = null, onClick = null, expireTime = 0, animDelay = 0,
  isReserve = false
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
            rendObj = ROBJ_WORLD_BLUR
            size = squadContentSize
            fillColor = isReserve
              ? squadBgReserve(sf, isCardSelected)
              : squadBgCommon(sf, isCardSelected)
            color = defItemBlur
            children = [
              {
                size = flex()
                padding = [bigPadding, smallPadding]
                flow = FLOW_HORIZONTAL
                children = [
                  mkSquadIcon(icon)
                  mkSquadInfoBlock(squadType, addChild)
                ]
              }
              mkLevelBlock(sf, isCardSelected, level, expireTime)
            ]
          }
          mkSquadPremIcon(premIcon, { size = [premIconSize, premIconSize] })
        ]
      }
      isCardSelected ? selectionLine : null
    ]
  }.__update(rightAppearanceAnim(animDelay)))
})


let lockedSquadInfo = @(unlockLvl) unlockLvl == null ? null : {
  rendObj = ROBJ_SOLID
  size = [flex(), ph(40)]
  color = LOCKED_SQUAD_PANEL_COLOR
  padding = midPadding
  vplace = ALIGN_BOTTOM
  valign = ALIGN_CENTER
  children = [
    faComp("lock", {
      fontSize = defTxtStyle.fontSize
      color = defTxtStyle.color
    })
    {
      rendObj = ROBJ_TEXTAREA
      size = [flex(), SIZE_TO_CONTENT]
      behavior = Behaviors.TextArea
      text = loc("squads/reqLevel", { level = unlockLvl})
      halign = ALIGN_RIGHT
    }.__update(defTxtStyle)
  ]
}


let skullIcon = {
  rendObj = ROBJ_IMAGE
  image = Picture("ui/skin#skull_white.svg:{0}:{0}:K".subst(unavaliableIconSize))
  color = deadTxtColor
  vplace = ALIGN_BOTTOM
  size = [unavaliableIconSize, unavaliableIconSize]
}


let blockSign = {
  rendObj = ROBJ_IMAGE
  image = Picture($"!ui/uiskin/block_sign.svg:{unavaliableIconSize}:{unavaliableIconSize}:K")
  color = deadTxtColor
  vplace = ALIGN_BOTTOM
  size = [unavaliableIconSize, unavaliableIconSize]
}


let mkLockedSquadCard = kwarg(function(idx, icon = "", squadType = null, level = null,
  onClick = null, animDelay = 0, premIcon = null, canSpawn = true, isAlive = true, squadId = false,
  curSelectedSquad = Watched(null)
) {
  icon = (icon ?? "").len() > 0 ? icon : defaultSquadIcon
  return watchElemState(@(sf) {
    watch = curSelectedSquad
    size = squadCardSize
    flow = FLOW_VERTICAL
    gap = selectionLineOffset
    key = $"squad{idx}"
    behavior = Behaviors.Button
    onClick
    xmbNode = XmbNode()
    children = [
      {
        rendObj = ROBJ_WORLD_BLUR
        size = squadContentSize
        fillColor = sf & S_HOVER ? hoverLockedSlotBgColor : defLockedSlotBgColor
        color = defItemBlur
        children = [
          {
            size = [flex(), SIZE_TO_CONTENT]
            padding = [bigPadding, smallPadding]
            flow = FLOW_HORIZONTAL
            children = [
              mkSquadIcon(icon, { opacity = 0.6 })
              {
                size = [flex(), flex()]
                halign = ALIGN_CENTER
                children = [
                  mkSquadTypeIcon(squadType, isAlive || canSpawn ? {} : { opacity = 0.6 })
                  !isAlive ? skullIcon
                    : !canSpawn ? blockSign
                    : null
                ]
              }
            ]
          }
          premIcon != null ? mkSquadPremIcon(premIcon, { size = [premIconSize, premIconSize] })
            : !isAlive || !canSpawn ? null
            : lockedSquadInfo(level)
        ]
      }
      curSelectedSquad.value == squadId ? selectionLine : null
    ]
  }.__update(rightAppearanceAnim(animDelay)))
})


let mkRespawnSquadCard = kwarg(function(idx, isSelected, icon = "", squadType = null, level = null,
  premIcon = null, onClick = null, isAlive = true, canSpawn = true
) {
  let isCardSelected = isSelected.value
  icon = (icon ?? "").len() > 0 ? icon : defaultSquadIcon
  if (!isAlive || !canSpawn)
    return mkLockedSquadCard({ idx, icon, squadType, level, premIcon, canSpawn, isAlive })

  return watchElemState(@(sf) {
    key = $"squad{idx}"
    size = squadCardSize
    flow = FLOW_VERTICAL
    gap = selectionLineOffset
    behavior = Behaviors.Button
    onClick = isAlive ? onClick : null
    xmbNode = XmbNode()
    children = [
      {
        size = flex()
        children = [
          {
            rendObj = ROBJ_WORLD_BLUR
            size = squadContentSize
            fillColor = !canSpawn ? defLockedSlotBgColor
              : isCardSelected || (sf & S_HOVER) != 0 ? hoverSlotBgColor
              : defSlotBgColor
            color = defItemBlur
            children = [
              {
                size = flex()
                padding = [bigPadding, smallPadding]
                flow = FLOW_HORIZONTAL
                children = [
                  mkSquadIcon(icon)
                  mkSquadInfoBlock(squadType)
                ]
              }
              mkLevelBlock(sf, isCardSelected, level)
            ]
          }
          mkSquadPremIcon(premIcon, { size = [premIconSize, premIconSize] })
        ]
      }
      isCardSelected ? selectionLine : null
    ]
  })
})


return {
  mkSquadCard
  mkLockedSquadCard
  mkRespawnSquadCard
  squadCardSize
  mkSquadInfoBlock
  mkLevelBlock
  selectionLine
  squadContentSize
}