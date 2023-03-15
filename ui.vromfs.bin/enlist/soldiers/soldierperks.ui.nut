from "%enlSqGlob/ui_library.nut" import *

let { mkPerksPoints, mkPerksListBtn, mkRetrainingPoints, perksUi
} = require("%enlist/soldiers/soldierPerksPkg.nut")
let scrollbar = require("%ui/components/scrollbar.nut")

return kwarg(function(soldier, canManage = true) {
  let soldierGuid = Computed(@() soldier.value?.guid)
  return function() {
    let res = { watch = soldierGuid }
    let guid = soldierGuid.value
    if (guid == null)
      return res
    return res.__update({
      watch = soldierGuid
      flow = FLOW_VERTICAL
      size = flex()
      children = [
        {
          size = [flex(), SIZE_TO_CONTENT]
          flow = FLOW_HORIZONTAL
          children = [
            canManage ? mkPerksPoints(guid) : null
            mkPerksListBtn(guid)
          ]
        }
        canManage ? mkRetrainingPoints(guid) : null
        scrollbar.makeVertScroll(perksUi(soldier, canManage), { needReservePlace = false })
      ]
    })
  }
})
