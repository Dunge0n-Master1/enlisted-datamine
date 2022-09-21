from "%enlSqGlob/ui_library.nut" import *

let { mkSquadCard } = require("%enlSqGlob/ui/mkSquadCard.nut")
let { bigPadding } = require("%enlSqGlob/ui/designConst.nut")
let { makeHorizScroll } = require("%ui/components/scrollbar.nut")

let defSquadCardCtor = @(squad, idx) mkSquadCard({ idx = idx }.__update(squad), KWARG_NON_STRICT)

let mkSquadList = @(squads) {
  flow = FLOW_HORIZONTAL
  gap = bigPadding
  children = squads.map(defSquadCardCtor)
}

let mkCurSquadsList = kwarg(@(curSquadsList, curSquadId, setCurSquadId,
  addedObj = null
) function() {
  let squadsList = (curSquadsList.value ?? []).map(@(squad)
    squad.__merge({
      onClick = @() setCurSquadId(squad.squadId)
      isSelected = Computed(@() curSquadId.value == squad.squadId)
    }))
  let res = { watch = [curSquadsList, curSquadId] }
  if (squadsList.len() <= 0)
    return res

  local children = []
  let listComp = mkSquadList(squadsList)
  children = [
    makeHorizScroll(listComp,
      {
        size = SIZE_TO_CONTENT
        rootBase = class {
          key = "squadList"
          behavior = Behaviors.Pannable
          wheelStep = 0.2
        }
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