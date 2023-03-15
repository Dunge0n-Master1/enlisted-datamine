from "%enlSqGlob/ui_library.nut" import *

let { mkSquadCard } = require("%enlSqGlob/ui/mkSquadCard.nut")
let { mkDraggableSquadCard, emptySquadSlot
} = require("%enlist/squadmanagement/mkSquadAdditionalCard.nut")
let { bigPadding, colFullMin, DEF_APPEARANCE_TIME } = require("%enlSqGlob/ui/designConst.nut")
let { makeHorizScroll, styling } = require("%ui/components/scrollbar.nut")


let delayTime = @(allSquads) DEF_APPEARANCE_TIME / allSquads
let defSquadCardCtor = @(squad, idx, squadLen) mkSquadCard({
  idx
  animDelay = idx * delayTime(squadLen)
}.__update(squad), KWARG_NON_STRICT)
let dragSquadCardCtor  = @(squad, idx, squadLen)
  mkDraggableSquadCard({
    idx
    animDelay = idx * delayTime(squadLen)
  }.__update(squad), KWARG_NON_STRICT)

let mkSquadList = @(squads, isDraggable) {
  flow = FLOW_HORIZONTAL
  gap = bigPadding
  children = squads.map(@(squad, idx) squad == null ? emptySquadSlot(idx)
    : isDraggable ? dragSquadCardCtor(squad, idx, squads.len())
    : defSquadCardCtor(squad, idx, squads.len()))
}

let scrollStyle = styling.__merge({ Bar = styling.Bar(false) })


let mkCurSquadsList = kwarg(@(curSquadsList, curSquadId, setCurSquadId,
  addedObj = null, isDraggable = false
) function() {
  let squadsList = (curSquadsList.value ?? []).map(function(squad) {
    return squad == null ? null : squad.__merge({
      onClick = @() setCurSquadId(squad.squadId)
      isSelected = Computed(@() curSquadId.value == squad.squadId)
    })
  })
  let res = { watch = [curSquadsList, curSquadId] }
  if (squadsList.len() <= 0)
    return res

  local children = []
  let listComp = mkSquadList(squadsList, isDraggable)
  children = [
    makeHorizScroll(listComp,
      {
        size = SIZE_TO_CONTENT
        maxWidth = colFullMin(17)
        rootBase = class {
          key = "squadList"
          behavior = Behaviors.Pannable
          wheelStep = 0.2
        }
        styling = scrollStyle
      })
    addedObj
  ]

  return res.__update({
    size = [flex(), SIZE_TO_CONTENT]
    gap = bigPadding
    flow = FLOW_HORIZONTAL
    vplace = ALIGN_BOTTOM
    xmbNode = XmbContainer({
      canFocus = @() false
      scrollSpeed = 10.0
      isViewport = true
    })
    children
  })
})


return mkCurSquadsList