from "%enlSqGlob/ui_library.nut" import *

let { mkSquadCard } = require("%enlSqGlob/ui/squadsUiComps.nut")
let { smallPadding } = require("%enlSqGlob/ui/designConst.nut")
let { makeHorizScroll, styling } = require("%ui/components/scrollbar.nut")


let scrollStyle = styling.__merge({ Bar = styling.Bar(false) })

let function mkSquadList(children) {
  return {
    flow = FLOW_HORIZONTAL
    gap = smallPadding
    children
  }
}


let mkCurSquadsList = kwarg(@(curSquadsList, curSquadId, setCurSquadId, preChild = null,
  addedObj = null, onAttach = null, onDetach = null,
  reserveIdx = Watched(0), maxSquadsLen = 0, maxWidth = SIZE_TO_CONTENT, squadCardSize = null
) function() {
  let sqv = curSquadsList.value ?? []
  let squadsList = sqv.map(function(squad, idx) {
    return squad == null ? null : mkSquadCard(squad.__merge({
      onClick = @() setCurSquadId(squad.squadId)
      isSelected = Computed(@() curSquadId.value == squad.squadId)
      isLocked = maxSquadsLen > 0 && idx >= maxSquadsLen
      squadCardSize
      idx
    }), KWARG_NON_STRICT)
  })
  let res = {
    watch = [curSquadsList, curSquadId, reserveIdx]
    onAttach
    onDetach
  }
  if (squadsList.len() <= 0)
    return res

  let listComp = mkSquadList(squadsList)
  return res.__update({
    size = [flex(), SIZE_TO_CONTENT]
    gap = smallPadding
    flow = FLOW_HORIZONTAL
    vplace = ALIGN_BOTTOM
    xmbNode = XmbContainer({ wrap = false })
    children = [
      preChild
      {
        children = makeHorizScroll(listComp, {
          size = SIZE_TO_CONTENT
          maxWidth
          rootBase = {
            key = "squadList"
            behavior = Behaviors.Pannable
            wheelStep = 0.2
          }
          styling = scrollStyle
        })
      }
      addedObj
    ]
  })
})


return mkCurSquadsList