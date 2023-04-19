from "%enlSqGlob/ui_library.nut" import *

let { mkHorScrollMask } = require("%enlSqGlob/ui/gradients.nut")
let { mkSquadCard, squadCardSize } = require("%enlSqGlob/ui/mkSquadCard.nut")
let {
  mkDraggableSquadCard, emptySquadSlot
} = require("%enlist/squadmanagement/mkSquadAdditionalCard.nut")
let {
  colPart, bigPadding, DEF_APPEARANCE_TIME } = require("%enlSqGlob/ui/designConst.nut")
let { makeHorizScroll, styling } = require("%ui/components/scrollbar.nut")


const MAX_SLOTS = 8

let scrollArea = MAX_SLOTS * squadCardSize[0] + MAX_SLOTS * bigPadding
let sideOffset = colPart(1.5)
let pageWidth  = scrollArea + sideOffset * 2
let pageMask   = mkHorScrollMask((pageWidth / 10).tointeger(), (sideOffset / 10).tointeger())

let delayTime = @(allSquads) DEF_APPEARANCE_TIME / allSquads
let defSquadCardCtor = @(squad, idx, squadLen, isReserve) mkSquadCard({
  idx
  isReserve
  animDelay = idx * delayTime(squadLen)
}.__update(squad), KWARG_NON_STRICT)
let dragSquadCardCtor  = @(squad, idx, squadLen)
  mkDraggableSquadCard({
    idx
    animDelay = idx * delayTime(squadLen)
  }.__update(squad), KWARG_NON_STRICT)

let mkSquadList = @(squads, isDraggable, reserveIdxVal) {
  flow = FLOW_HORIZONTAL
  gap = bigPadding
  children = squads.map(@(squad, idx) squad == null ? emptySquadSlot(idx)
    : isDraggable ? dragSquadCardCtor(squad, idx, squads.len())
    : defSquadCardCtor(squad, idx, squads.len(), reserveIdxVal > 0 && idx >= reserveIdxVal))
}

let scrollStyle = styling.__merge({ Bar = styling.Bar(false) })


let mkCurSquadsList = kwarg(@(curSquadsList, curSquadId, setCurSquadId,
  addedObj = null, isDraggable = false, onAttach = null, onDetach = null,
  reserveIdx = Watched(0), maxSquadsLen = 0
) function() {
  let squadsList = (curSquadsList.value ?? []).map(function(squad, idx) {
    return squad == null ? null : squad.__merge({
      onClick = @() setCurSquadId(squad.squadId)
      isSelected = Computed(@() curSquadId.value == squad.squadId)
      isLocked = maxSquadsLen > 0 && idx >= maxSquadsLen
    })
  })
  let res = {
    watch = [curSquadsList, curSquadId, reserveIdx]
    onAttach
    onDetach
  }
  if (squadsList.len() <= 0)
    return res

  let listComp = mkSquadList(squadsList, isDraggable, reserveIdx.value)
  let hasScroll = squadsList.len() > MAX_SLOTS
  return res.__update({
    size = [flex(), SIZE_TO_CONTENT]
    gap = hasScroll ? colPart(1) : bigPadding
    flow = FLOW_HORIZONTAL
    vplace = ALIGN_BOTTOM
    xmbNode = XmbContainer({
      canFocus = @() false
      scrollSpeed = 10.0
      isViewport = true
    })
    children = [
      hasScroll
        ? {
            size = [scrollArea, SIZE_TO_CONTENT]
            children = {
              pos = [-sideOffset, 0]
              size = [pageWidth, SIZE_TO_CONTENT]
              clipChildren = true
              rendObj = ROBJ_MASK
              image = pageMask
              children = makeHorizScroll({
                  padding = [0, sideOffset]
                  children = listComp
                }, {
                  size = [pageWidth, SIZE_TO_CONTENT]
                  rootBase = class {
                    key = "squadList"
                    behavior = Behaviors.Pannable
                    wheelStep = 0.2
                  }
                  styling = scrollStyle
                })
            }
          }
        : listComp
      addedObj
    ]
  })
})


return mkCurSquadsList