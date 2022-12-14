from "%enlSqGlob/ui_library.nut" import *

let { sub_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let faComp = require("%ui/components/faComp.nut")
let fontIconButton = require("%ui/components/fontIconButton.nut")
let mkCountdownTimer = require("%enlSqGlob/ui/mkCountdownTimer.nut")
let {
  mkCardText, squadBgColor, mkSquadIcon, mkSquadTypeIcon, mkSquadPremIcon,
  txtColor
} = require("%enlSqGlob/ui/squadsUiComps.nut")
let {
  bigPadding, smallPadding, squadSlotHorSize,
  listCtors, defTxtColor, selectedTxtColor, activeBgColor
} = require("%enlSqGlob/ui/viewConst.nut")
let { nameColor, txtDisabledColor } = listCtors
let { getItemName } = require("%enlSqGlob/ui/itemsInfo.nut")
let {
  selectedSquadId, reserveSquads, chosenSquads, getCantTakeReason
} = require("model/chooseSquadsState.nut")
let { isGamepad } = require("%ui/control/active_controls.nut")
let openSquadTextTutorial = require("%enlist/tutorial/squadTextTutorial.nut")
let { sound_play } = require("sound")

let squadIconSize = [hdpx(60), hdpx(60)]
let squadTypeIconSize = hdpxi(20)
let dragIconWidth = hdpxi(25)

let curDropData = Watched(null)
let curDropTgtIdx = Watched(-1)
curDropData.subscribe(@(_) curDropTgtIdx(-1))

let highlightSlots = Computed(function() {
  let allSlots = chosenSquads.value
  let total = allSlots.len()
  local reserveIdx = curDropData.value?.squadIdx
  if (reserveIdx != null)
    reserveIdx -= total
  else {
    let selSquadId = selectedSquadId.value
    reserveIdx = reserveSquads.value.findindex(@(s) s.squadId == selSquadId)
  }

  let squad = reserveSquads.value?[reserveIdx]
  return squad == null ? []
    : allSlots.map(@(_, idx) getCantTakeReason(squad, allSlots, idx) == null)
})

let getMoveDirSameList = @(idx, dropIdx, targetIdx)
  dropIdx < idx && targetIdx >= idx ? -1
    : dropIdx > idx && targetIdx <= idx ? 1
    : 0

let function squadDragAnim(idx, fixedSlots, stateFlags, content,
                              chContent, needMoveCursor = false) {
  let watch = [curDropData, curDropTgtIdx].extend(content?.watch == null ? []
    : typeof content.watch != "array" ? [content.watch]
    : content.watch)

  let dropIdx = curDropData.value?.squadIdx ?? -1
  let targetIdx = curDropTgtIdx.value

  local moveDir = 0
  if (targetIdx >= 0 && dropIdx >= 0)
    if (idx < fixedSlots)
      moveDir = dropIdx < fixedSlots && targetIdx < fixedSlots
        ? getMoveDirSameList(idx, dropIdx, targetIdx)
        : 0
    else
      moveDir = dropIdx >= fixedSlots && targetIdx >= fixedSlots
          ? getMoveDirSameList(idx, dropIdx, targetIdx)
        : dropIdx < fixedSlots && targetIdx >= fixedSlots && targetIdx <= idx ? 1
        : 0

  let function onAttach(elem) {
    if (isGamepad.value && needMoveCursor)
      move_mouse_cursor(elem, false)
  }

  let function onElemState(sf) {
    stateFlags(sf)
    if (!curDropData.value || curDropData.value.squadIdx == idx)
      return
    if (sf & S_ACTIVE)
      curDropTgtIdx(idx)
    else if (curDropTgtIdx.value == idx)
      curDropTgtIdx(-1)
  }

  let transform = idx == dropIdx ? {}
    : { translate = [0, moveDir * (squadSlotHorSize[1] + bigPadding)] }

  return content.__merge({
    watch
    behavior = [Behaviors.DragAndDrop, Behaviors.RecalcHandler]
    onAttach
    xmbNode = XmbNode()
    canDrop = @(data) data?.dragid == "squad"
    dropData = "dropData" in content ? content.dropData : { squadIdx = idx, dragid = "squad" }
    onDragMode = function(on, data){
      if (on)
        sound_play("ui/inventory_item_take")
      curDropData(on ? data : null)

    }
    onElemState
    transform = {}
    children = chContent.__merge({
      transform
      transitions = [{ prop = AnimProp.translate, duration = 0.3, easing = OutQuad }]
    })
  })
}

let bonusText = @(val) "+{0}%".subst((100 * val).tointeger())

let highlightBorder = {
  size = flex()
  rendObj = ROBJ_FRAME
  borderWidth = hdpx(1)
  color = activeBgColor
}

let mkInfoBtn = @(onInfoCb, squadId, override, isHovered, isSelected)
  fontIconButton("info", {
    onClick = @() onInfoCb(squadId)
    margin = 0
    iconParams = { size = [dragIconWidth, dragIconWidth], halign = ALIGN_CENTER }
    fontSize = dragIconWidth
    iconColor = @(sflag) sflag & S_ACTIVE ? selectedTxtColor
      : sflag & S_HOVER ? Color(70,70,70)
      : isHovered || isSelected ? selectedTxtColor
      : defTxtColor
  }.__update(override))

let dragIcon = @(sf) {
  rendObj = ROBJ_IMAGE
  size = [dragIconWidth, dragIconWidth]
  margin = [0, bigPadding, 0, 0]
  keepAspect = true
  image = Picture("!ui/squads/drag_squads.svg:{0}:{0}:K".subst(dragIconWidth))
  color = txtColor(sf)
}

let tutorialIcon = @(squadType, isHovered, isSelected) watchElemState(@(sf) {
  rendObj = ROBJ_IMAGE
  behavior = Behaviors.Button
  keepAspect = true
  onClick = @() openSquadTextTutorial(squadType)
  size = [dragIconWidth, dragIconWidth]
  image = Picture("!ui/squads/tutorial_squad.svg:{0}:{0}:K".subst(dragIconWidth))
  color = sf & S_ACTIVE ? selectedTxtColor
    : sf & S_HOVER ? Color(70,70,70)
    : isHovered || isSelected ? selectedTxtColor
    : defTxtColor
})

let mkHorizontalSlot = kwarg(function (guid, squadId, idx, onClick, manageLocId,
  isSelected = Watched(false), onInfoCb = null, onDropCb = null, group = null, addChildren = null,
  icon = "", squadType = "", level = 0, vehicle = null, squadSize = null, battleExpBonus = 0,
  isOwn = true, fixedSlots = -1, override = {}, premIcon = null, isLocked = false, unlocObj = null,
  needMoveCursor = false, firstSlotToAnim = null, secondSlotToAnim = null, stateFlags = null,
  needSquadTutorial = false, expireTime = 0, size = null
) {
  let stateFlagsUnfiltered = stateFlags ?? Watched(0)
  stateFlags = Computed(@() stateFlagsUnfiltered.value & ~S_TOP_HOVER)

  let function onDrop(data) {
    onDropCb?(data?.squadIdx, idx)
  }

  let isDropTarget = Computed(@() idx < fixedSlots
    && curDropTgtIdx.value == idx
    && (curDropData.value?.squadIdx ?? -1) >= fixedSlots)

  let needHighlight = Computed(@() highlightSlots.value?[idx] ?? false)

  let key = $"slot{guid}{idx}" //used for animations and tutorial

  let animations = [
    { prop=AnimProp.translate, from=[0, squadSlotHorSize[1]], to=[0, 0], duration=0.2, trigger = $"squadMoveTop{idx}",  easing=OutCubic }
    { prop=AnimProp.translate, from=[0, -squadSlotHorSize[1]], to=[0, 0], duration=0.2, trigger = $"squadMoveBottom{idx}", easing=OutCubic }
  ]

  let function onAttach() {
    if (firstSlotToAnim != null || secondSlotToAnim != null) {
      anim_start($"squadMoveTop{min(firstSlotToAnim, secondSlotToAnim)}")
      anim_start($"squadMoveBottom{max(firstSlotToAnim, secondSlotToAnim)}")
    }
  }

  let squadIcon = mkSquadIcon(icon, { size = squadIconSize, margin = bigPadding })

  let squadPremIcon = mkSquadPremIcon(premIcon, { margin = [0, hdpx(5), 0, hdpx(2)] })

  let watch = [isSelected, stateFlags, isDropTarget, needHighlight, isGamepad]
  let infoBtnStateFlags = Watched(0)

  return function() {
    let sf = stateFlags.value
    let selected = isSelected.value || isDropTarget.value
    let timerObj = expireTime == 0 ? null
      : mkCountdownTimer({
          timestamp = expireTime
          prefixLocId = loc("rented")
          expiredLocId = loc("rentExpired")
          color = txtColor(sf, selected)
          prefixColor = txtColor(sf, selected)
        })

    let bgColor = squadBgColor(sf, selected, isLocked)
    let chContent = {
      key
      size = flex()
      opacity = isOwn ? 1.0 : 0.5
      transform = {}
      onAttach
      animations
      children = [
        {
          rendObj = ROBJ_SOLID
          flow = FLOW_HORIZONTAL
          size = flex()
          valign = ALIGN_CENTER
          gap = bigPadding
          color = bgColor
          children = [
            squadIcon
            {
              size = flex()
              flow = FLOW_VERTICAL
              valign = ALIGN_CENTER
              gap = smallPadding
              clipChildren = true
              children = [
                {
                  size = [flex(), SIZE_TO_CONTENT]
                  group = group
                  behavior = Behaviors.Marquee
                  scrollOnHover = true
                  flow = FLOW_HORIZONTAL
                  children = [
                    squadPremIcon
                    mkCardText(loc(manageLocId), sf, selected)
                  ]
                }
                {
                  size = SIZE_TO_CONTENT
                  flow = FLOW_HORIZONTAL
                  valign = ALIGN_CENTER
                  children = [
                    mkSquadTypeIcon(squadType, sf, selected, squadTypeIconSize)
                    battleExpBonus == 0
                      ? mkCardText(loc("levelInfo", { level = level + 1 }), sf, selected)
                      : mkCardText("".concat(loc("XP"), loc("ui/colon"), bonusText(battleExpBonus)),
                        sf, selected)
                    mkCardText(", {0} ".subst(loc("squad/contain")), sf, selected)
                    mkCardText(squadSize ?? size, sf, selected)
                    faComp("user-o", {
                      fontSize = hdpx(12)
                      color = txtColor(sf & S_HOVER, selected)
                    })
                    vehicle == null
                      ? null
                      : mkCardText($", {loc("menu/vehicle")} {getItemName(vehicle)}", sf, selected)
                  ]
                }
              ]
            }
            timerObj
            unlocObj
            needSquadTutorial ? tutorialIcon(squadType, sf & S_HOVER, selected) : null
            onInfoCb != null && !isGamepad.value
              ? mkInfoBtn(onInfoCb, squadId,
                          override.__merge({stateFlags = infoBtnStateFlags}),
                          sf & S_HOVER, selected)
              : null
            !isLocked ? dragIcon(sf) : null
          ]
        }
        needHighlight.value ? highlightBorder : null
      ].extend(addChildren ?? [])
    }

    return onDropCb != null
      ? squadDragAnim(idx, fixedSlots, stateFlagsUnfiltered,
          {
            watch
            group
            size = squadSlotHorSize
            key = $"{guid}{idx}"
            onDrop
            onClick
          }.__update(override),
          chContent, needMoveCursor)
      : {
          watch
          group
          size = squadSlotHorSize
          onClick
          behavior = Behaviors.Button
          onElemState = @(sf) stateFlagsUnfiltered(sf)
          transform = {}
          children = chContent
        }
  }
})


let horSlotText = @(hasBlink, isDropTarget, text, style = {}) {
  rendObj = ROBJ_TEXT
  key = $"hasBlink{hasBlink}"
  text
  color = hasBlink
    ? nameColor(0, isDropTarget)
    : txtDisabledColor(0, isDropTarget)
  animations = hasBlink
    ? [{
        prop = AnimProp.opacity, from = 0.4, to = 0.6,
        duration = 1, play = true, loop = true, easing = Blink
      }]
    : null
}.__merge(sub_txt, style)

let angleLeft = faComp("angle-left", { hplace = ALIGN_RIGHT, padding = [0, hdpx(15)], fontSize = hdpx(30)})

let mkEmptyHorizontalSlot = kwarg(
  function(idx, onDropCb, fixedSlots = -1, group = null, hasBlink = false) {
    let stateFlags = Watched(0)
    let isDropTarget = Computed(@() idx < fixedSlots
      && curDropTgtIdx.value == idx
      && (curDropData.value?.squadIdx ?? -1) >= fixedSlots)
    let needHighlight = Computed(@() highlightSlots.value?[idx] ?? false)
    let onDrop = @(data) onDropCb(data?.squadIdx, idx)

    return function() {
      let chContent = {
        rendObj = ROBJ_SOLID
        key = $"empty_slot{idx}" //used in animations and tutorial
        size = flex()
        halign = ALIGN_CENTER
        valign = ALIGN_CENTER
        transform = {}
        color = squadBgColor(0, isDropTarget.value)
        children = [
          horSlotText(hasBlink, isDropTarget.value, loc("squads/squadFreeSlot"),{
            padding = [0, hdpx(20)],
            hplace = ALIGN_LEFT
          })
          horSlotText(hasBlink, isDropTarget.value, loc("squads/dragFromReserve"),{
            padding = [0, hdpx(40)],
            hplace = ALIGN_RIGHT
          })
          horSlotText(hasBlink, isDropTarget.value, null, angleLeft)
          needHighlight.value ? highlightBorder : null
        ]
      }
      return squadDragAnim(idx, fixedSlots, stateFlags,
        {
          watch = [stateFlags, isDropTarget, needHighlight]
          size = squadSlotHorSize
          key = $"empty_{idx}"
          onDrop
          dropData = null
          fixedSlots = fixedSlots
          group = group
        },
        chContent)
    }
  })

return {
  mkHorizontalSlot
  mkEmptyHorizontalSlot
  curDropData
}
