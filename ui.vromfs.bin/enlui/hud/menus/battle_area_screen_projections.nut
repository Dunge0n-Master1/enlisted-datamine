import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let { watchedTable2TableOfWatched } = require("%sqstd/frp.nut")
let defValue = {
  battleAreasProjections = null
}
let state = Watched(defValue)
let { battleAreasProjections } = watchedTable2TableOfWatched(state)
let projectionOn = Watched(false)

let function battleAreaProj(_eid, comps) {
  let bap = comps.battle_area__activeBattleAreasScreenProjections.getAll()
  state({
    battleAreasProjections = bap.len() > 0 ? bap : null
  })
  projectionOn(comps.battle_area__projectionOn)
}

ecs.register_es("battle_areas_projections_state", {
  [["onInit", "onChange"]] = battleAreaProj
}, {
  comps_track = [
    ["battle_area__activeBattleAreasScreenProjections", ecs.TYPE_FLOAT_LIST],
    ["battle_area__projectionOn", ecs.TYPE_BOOL]
  ]
})

let battleAreaScreenProjection = function() {
  if (battleAreasProjections.value == null)
    return { watch = [battleAreasProjections] }
  let commands = [[VECTOR_INVERSE_POLY].extend(battleAreasProjections.value)]
  return {
    watch = [ battleAreasProjections ]
    color = Color(0, 0, 0, 150)
    fillColor = Color(0, 0, 0, 150)
    rendObj = ROBJ_VECTOR_CANVAS
    commands
    lineWidth = hdpx(1)
    size = [sw(100), sh(100)]
  }
}

return {
  battleAreaScreenProjection
  projectionOn
}
