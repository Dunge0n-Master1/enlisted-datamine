from "%enlSqGlob/ui_library.nut" import *

let { mkSquadCard } = require("%enlSqGlob/ui/squadsUiComps.nut")
let { bigPadding, smallPadding } = require("%enlSqGlob/ui/viewConst.nut")
let { makeVertScroll, thinStyle } = require("%ui/components/scrollbar.nut")

let defSquadCardCtor = @(squad, idx) mkSquadCard({idx}.__update(squad), KWARG_NON_STRICT)

let mkSquadsVert = @(squads) {
  flow = FLOW_VERTICAL
  gap = bigPadding
  children = squads.map(defSquadCardCtor)
}

let mkSquadsList = kwarg(@(
  curSquadsList, curSquadId, setCurSquadId, addedObj = null,
  createHandlers = null, hasOffset = true
) function() {
  let squadsList = curSquadsList.value ?? []
  let function defCreateHandlers(squads){
    squads.each(@(squad)
      squad.__update({
        onClick = @() setCurSquadId(squad.squadId)
        isSelected = Computed(@() curSquadId.value == squad.squadId)
      })
    )
  }
  createHandlers = createHandlers ?? defCreateHandlers
  createHandlers?(squadsList)
  local children = []
  if (squadsList.len() > 0) {
    let listComp = mkSquadsVert(squadsList)
    let maxHeight = hasOffset ? null : calc_comp_size(listComp)[1]
    children = [
      makeVertScroll(listComp, {
        size = [SIZE_TO_CONTENT, flex()]
        styling = thinStyle
        maxHeight
      })
      addedObj
    ]
  }
  return {
    watch = [curSquadsList, curSquadId]
    size = [SIZE_TO_CONTENT, flex()]
    flow = FLOW_VERTICAL
    gap = smallPadding
    clipChildren = true
    xmbNode = XmbContainer({ wrap = false })
    children
  }
})

return mkSquadsList
