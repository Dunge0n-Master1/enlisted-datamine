from "%enlSqGlob/ui_library.nut" import *

let { fontMedium, fontSmall } = require("%enlSqGlob/ui/fontsStyle.nut")
let mkCountdownTimer = require("%enlSqGlob/ui/mkCountdownTimer.nut")
let { colFull, accentColor, titleTxtColor, smallPadding, bigPadding, colPart, commonBorderRadius,
  defBdColor, hoverBdColor, defTxtColor, hoverSlotBgImg, defSlotBgImg, defAvailSlotBgImg,
  hoverAvailSlotBgImg, rightAppearanceAnim
} = require("%enlSqGlob/ui/designConst.nut")
let { mkSquadIcon, mkSquadTypeIcon } = require("%enlSqGlob/ui/squadInfoPkg.nut")
let faComp = require("%ui/components/faComp.nut")
let { changeSquadOrderByUnlockedIdx, chosenSquads, selectedSquadId
} = require("%enlist/soldiers/model/chooseSquadsState.nut")
let openSquadTextTutorial = require("%enlist/tutorial/squadTextTutorial.nut")
let { unseenSquadTutorials, markSeenSquadTutorial
} = require("%enlist/tutorial/unseenSquadTextTutorial.nut")


let premIconSize = colPart(0.60)
let selectionLineHeight = colPart(0.08)
let selectionLineOffset = colPart(0.1)
let squadCardSize = [colFull(2), colPart(1.55) + selectionLineHeight + selectionLineOffset]
let squadContentSize = [colFull(2), colPart(1.55)]
const defaultSquadIcon = "!ui/uiskin/squad_default.svg"
let isSquadDragged = Watched(false)


let squadBgImgCommon = @(flags, selected)
  selected ? hoverSlotBgImg
    : flags & S_HOVER ? hoverSlotBgImg
    : defSlotBgImg


let squadBgImgReserve = @(flags, selected)
  selected ? hoverAvailSlotBgImg
    : flags & S_HOVER ? hoverAvailSlotBgImg
    : defAvailSlotBgImg


let emptySquadBgColor = @(flags, hasData) hasData && flags > 0 ? accentColor
  : hasData ? accentColor
  : defBdColor


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


let function onDrop(squadIdx, curIdx) {
  foreach (cSquad in chosenSquads.value){
    let { squadType = null } = cSquad
    if (squadType in unseenSquadTutorials.value){
      openSquadTextTutorial(squadType)
      markSeenSquadTutorial(squadType)
      break
    }
  }
  changeSquadOrderByUnlockedIdx(squadIdx, curIdx)
}


let mkDraggableSquadCard = kwarg(function(idx, squadId, addChild = null, icon = "",
  squadType = null, level = null, premIcon = null, onClick = null, expireTime = 0,
  isReserve = false, animDelay = 0
) {
  icon = (icon ?? "").len() > 0 ? icon : defaultSquadIcon
  let isCardSelected = Computed(@() selectedSquadId.value == squadId)
  return watchElemState(@(sf) {
    watch = isCardSelected
    key = $"squad{idx}"
    size = squadCardSize
    flow = FLOW_VERTICAL
    gap = selectionLineOffset
    behavior = Behaviors.DragAndDrop
    transform = {}
    stopHover = true
    stopMouse = true
    onDrop = @(squadIdx) onDrop(squadIdx, idx)
    dropData = idx
    onDragMode = function(on, idx){
      onClick()
      isSquadDragged(on ? idx : null)
    }
    opacity = (sf & S_DRAG) ? 0.5 : 1.0
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
                image = isReserve
                  ? squadBgImgReserve(sf, isCardSelected.value)
                  : squadBgImgCommon(sf, isCardSelected.value)
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
      isCardSelected.value ? selectionLine : null
    ]
  }.__update(rightAppearanceAnim(animDelay)))
})


let emptySquadArrow = @(hasData, sf) faComp("chevron-down", {
  fontSize = premIconSize / 2
  color = sf > 0 && hasData ? accentColor
    : hasData ? titleTxtColor
    : defTxtColor })

let emptySquadSlot = @(curIdx, animDelay = 0) watchElemState(@(sf) {
  watch = isSquadDragged
  rendObj = ROBJ_BOX
  size = squadContentSize
  borderWidth = hdpx(1)
  borderRadius = commonBorderRadius
  borderColor = emptySquadBgColor(sf, isSquadDragged.value)
  behavior = [Behaviors.DragAndDrop, Behaviors.Button]
  onDrop = @(squadIdx) onDrop(squadIdx, curIdx)
  flow = FLOW_VERTICAL
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  children = [
    emptySquadArrow(isSquadDragged.value, sf)
    emptySquadArrow(isSquadDragged.value, sf)
  ]
}.__update(rightAppearanceAnim(animDelay)))


let squadSlotToPurchase = @(onClick, purchaseIcon = null) watchElemState(@(sf) {
  rendObj = ROBJ_BOX
  size = squadContentSize
  borderWidth = hdpx(1)
  borderRadius = commonBorderRadius
  borderColor = sf & S_HOVER ? hoverBdColor : defBdColor
  behavior = Behaviors.Button
  onClick
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  padding = smallPadding
  children = [
    purchaseIcon
    {
      rendObj = ROBJ_IMAGE
      size = [premIconSize, premIconSize]
      image = Picture("!ui/squads/plus.svg:{0}:{0}:K".subst(premIconSize))
    }
  ]
})


return {
  mkDraggableSquadCard
  emptySquadSlot
  squadSlotToPurchase
  isSquadDragged
}