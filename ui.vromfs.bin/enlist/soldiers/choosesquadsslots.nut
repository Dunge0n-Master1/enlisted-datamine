from "%enlSqGlob/ui_library.nut" import *

let { sub_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let faComp = require("%ui/components/faComp.nut")
let fontIconButton = require("%ui/components/fontIconButton.nut")
let {
  mkCardText, squadBgColor, mkSquadIcon, mkSquadTypeIcon, mkSquadPremIcon
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
let { txtColor } = listCtors
let { isGamepad } = require("%ui/control/active_controls.nut")
let openSquadTextTutorial = require("%enlist/tutorial/squadTextTutorial.nut")

let squadIconSize = [hdpx(60), hdpx(60)]
let squadTypeIconSize = hdpx(20).tointeger()

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
  local watch = content?.watch ?? []
  if (typeof watch != "array")
    watch = [watch]
  watch.append(curDropData, curDropTgtIdx)

  let dropIdx = curDropData.value?.squadIdx ?? -1
  let targetIdx = curDropTgtIdx.value
  local moveDir = 0
  if (targetIdx >= 0 && dropIdx >= 0)
    if (idx < fixedSlots)
      moveDir = dropIdx < fixedSlots && targetIdx < fixedSlots ? getMoveDirSameList(idx, dropIdx, targetIdx) : 0
    else
      moveDir = dropIdx >= fixedSlots && targetIdx >= fixedSlots ? getMoveDirSameList(idx, dropIdx, targetIdx)
        : dropIdx < fixedSlots && targetIdx >= fixedSlots && targetIdx <= idx ? 1
        : 0
  return content.__merge({
    watch = watch
    behavior = [Behaviors.DragAndDrop, Behaviors.RecalcHandler]
    onAttach = function(elem){
      if(isGamepad.value && needMoveCursor)
        move_mouse_cursor(elem, false)
    }
    xmbNode = XmbNode()
    canDrop = @(data) data?.dragid == "squad"
    dropData = "dropData" in content ? content.dropData : { squadIdx = idx, dragid = "squad" }
    onDragMode = @(on, data) curDropData(on ? data : null)
    onElemState = function(sf) {
      stateFlags(sf)
      if (!curDropData.value || curDropData.value.squadIdx == idx)
        return
      if (sf & S_ACTIVE)
        curDropTgtIdx(idx)
      else if (curDropTgtIdx.value == idx)
        curDropTgtIdx(-1)
    }
    transform = {}
    children = chContent.__merge({
      transform = idx == dropIdx ? {} : { translate = [0, moveDir * (squadSlotHorSize[1] + bigPadding)] }
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

let mkInfoBtn = @(onInfoCb, squadId, override, containerHovered, containerSelected) {
  size = [ph(100), flex()]
  children = fontIconButton("info", {
    onClick = @() onInfoCb(squadId)
    margin = 0
    size = flex()
    iconColor = @(sflag) sflag & S_ACTIVE ? selectedTxtColor
      : sflag & S_HOVER ? Color(70,70,70)
      : containerHovered || containerSelected ? selectedTxtColor
      : defTxtColor
  }.__update(override))
}

let dragIcon = @(sf, sizeArr = [hdpx(30), hdpx(20)]) {
  rendObj = ROBJ_IMAGE
  size = sizeArr
  margin = [0,smallPadding,0,0]
  keepAspect = true
  image = Picture("!ui/squads/drag_squads.svg:{0}:{1}:K".subst(sizeArr[0], sizeArr[1]))
  color = txtColor(sf)
}

let tutorialIcon = @(squadType, slotHovered, slotSelected) {
  rendObj = ROBJ_IMAGE
  behavior = Behaviors.Button
  keepAspect = true
  onClick = @() openSquadTextTutorial(squadType)
  size = [hdpx(25).tointeger(), hdpx(25).tointeger()]
  margin = [0,smallPadding,0,0]
  image = Picture("!ui/squads/tutorial_squad.svg:{0}:{0}:K".subst(hdpx(25).tointeger()))
  color = slotSelected ? selectedTxtColor
    : slotHovered ? Color(70,70,70)
    : defTxtColor
}


let mkHorizontalSlot = kwarg(function (guid, squadId, idx, onClick, manageLocId,
  isSelected = Watched(false), onInfoCb = null, onDropCb = null, group = null, addChildren = null,
  icon = "", squadType = "", level = 0, vehicle = null, squadSize = null, battleExpBonus = 0,
  isOwn = true, fixedSlots = -1, override = {}, premIcon = null, isLocked = false, unlocObj = null,
  needMoveCursor = false, firstSlotToAnim = null, secondSlotToAnim = null, needSquadTutorial = false
) {
  let stateFlags = Watched(0)
  let function onDrop(data) {
    onDropCb?(data?.squadIdx, idx)
  }
  let isDropTarget = Computed(@() idx < fixedSlots && curDropTgtIdx.value == idx
    && (curDropData.value?.squadIdx ?? -1) >= fixedSlots)
  let needHighlight = Computed(@() highlightSlots.value?[idx] ?? false)
  return function() {
    let sf = stateFlags.value
    let selected = isSelected.value
    let watch = [isSelected, stateFlags, isDropTarget, needHighlight, isGamepad]

    let bgColor = squadBgColor(sf, selected || isDropTarget.value, isLocked)
    let chContent = {
      key = $"slot{guid}{idx}" //used for animations and tutorial
      size = flex()
      opacity = isOwn ? 1.0 : 0.5
      transform = {}
      onAttach = function() {
        if(firstSlotToAnim != null || secondSlotToAnim != null){
          anim_start($"squadMoveTop{min(firstSlotToAnim, secondSlotToAnim)}")
          anim_start($"squadMoveBottom{max(firstSlotToAnim, secondSlotToAnim)}")
        }
      }
      animations = [
        { prop=AnimProp.translate, from=[0, squadSlotHorSize[1]], to=[0, 0], duration=0.2, trigger = $"squadMoveTop{idx}",  easing=OutCubic }
        { prop=AnimProp.translate, from=[0, -squadSlotHorSize[1]], to=[0, 0], duration=0.2, trigger = $"squadMoveBottom{idx}", easing=OutCubic }
      ]
      children = [
        {
          rendObj = ROBJ_SOLID
          flow = FLOW_HORIZONTAL
          size = flex()
          valign = ALIGN_CENTER
          color = bgColor
          children = [
            mkSquadIcon(icon, { size = squadIconSize, margin = bigPadding })
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
                    mkSquadPremIcon(premIcon, { margin = [0, hdpx(5), 0, hdpx(2)] })
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
                    mkCardText(squadSize, sf, selected)
                    faComp("user-o", {
                      fontSize = hdpx(12)
                      color = txtColor(sf & S_HOVER, isSelected.value)
                    })
                    vehicle == null
                      ? null
                      : mkCardText($", {loc("menu/vehicle")} {getItemName(vehicle)}", sf, selected)
                  ]
                }
              ]
            }
            unlocObj
            needSquadTutorial ? tutorialIcon(squadType, sf & S_HOVER, isSelected.value) : null
            onInfoCb != null && !isGamepad.value
              ? mkInfoBtn(onInfoCb, squadId, override, sf & S_HOVER, isSelected.value)
              : null
            !isLocked ? dragIcon(sf, [hdpx(40), hdpx(25)]) : null
          ]
        }
        needHighlight.value ? highlightBorder : null
      ].extend(addChildren ?? [])
    }

    return onDropCb != null
      ? squadDragAnim(idx, fixedSlots, stateFlags,
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
          onElemState = @(sf) stateFlags(sf)
          transform = {}
          children = chContent
        }
  }
})

let horSlotText = @(hasBlink, isDropTarget, text, style = {}){
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
    let isDropTarget = Computed(@() idx < fixedSlots && curDropTgtIdx.value == idx
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
          onDrop = onDrop
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
