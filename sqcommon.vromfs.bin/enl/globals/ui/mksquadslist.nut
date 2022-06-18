from "%enlSqGlob/ui_library.nut" import *

let { note } = require("%enlSqGlob/ui/defcomps.nut")
let { mkSquadCard } = require("%enlSqGlob/ui/squadsUiComps.nut")
let { bigPadding, smallPadding, blurBgFillColor, blurBgColor, multySquadPanelSize
} = require("%enlSqGlob/ui/viewConst.nut")
let { makeVertScroll, thinStyle } = require("%ui/components/scrollbar.nut")

let defSquadCardCtor = @(squad, idx) mkSquadCard({idx = idx}.__update(squad), KWARG_NON_STRICT)

let mkSquadsVert = kwarg(@(squads, ctor = defSquadCardCtor, addedObj = null) {
  flow = FLOW_VERTICAL
  gap = bigPadding
  children = squads.map(ctor).append(addedObj)
})

let mkSquadsList = kwarg(@(
  curSquadsList, curSquadId, setCurSquadId, addedObj = null, createHandlers = null, bgOverride = {}
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
    let listComp = mkSquadsVert({ squads = squadsList })
    let maxHeight = calc_comp_size(listComp)[1]
    children = [
      note(loc("squads/battle")).__update({ size = [multySquadPanelSize[0], SIZE_TO_CONTENT] })
      makeVertScroll(listComp,
        { size = [SIZE_TO_CONTENT, flex()], maxHeight, styling = thinStyle })
      addedObj
    ]
  }
  return {
    watch = [curSquadsList, curSquadId]
    size = [multySquadPanelSize[0] + 2 * bigPadding, flex()]
    padding = [bigPadding, 0]
    halign = ALIGN_CENTER
    rendObj = ROBJ_WORLD_BLUR_PANEL
    color = blurBgColor
    fillColor = blurBgFillColor
    flow = FLOW_VERTICAL
    gap = smallPadding
    xmbNode = XmbContainer({
      canFocus = @() false
      scrollSpeed = 10.0
      isViewport = true
    })
    children
  }.__merge(bgOverride)
})

return mkSquadsList
