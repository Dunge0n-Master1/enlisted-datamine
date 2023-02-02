from "%enlSqGlob/ui_library.nut" import *

let { mkPerksPoints, mkPerksListBtn, mkRetrainingPoints, perksUi
} = require("%enlist/soldiers/soldierPerksPkg.nut")
let scrollbar = require("%ui/components/scrollbar.nut")

return kwarg(@(soldier, canManage = true) {
  flow = FLOW_VERTICAL
  size = flex()
  children = [
    {
      size = [flex(), SIZE_TO_CONTENT]
      flow = FLOW_HORIZONTAL
      children = [
        canManage ? mkPerksPoints(soldier.guid) : null
        mkPerksListBtn(soldier)
      ]
    }
    canManage ? mkRetrainingPoints(soldier.guid) : null
    scrollbar.makeVertScroll(perksUi(soldier, canManage), { needReservePlace = false })
  ]
})
