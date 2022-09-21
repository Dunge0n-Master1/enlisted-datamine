import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let { watchedTable2TableOfWatched } = require("%sqstd/frp.nut")
let defValue = {
  battleAreasPolygon  = null
  nextBattleAreasPolygon  = null
}
let state = Watched(defValue)
let { battleAreasPolygon, nextBattleAreasPolygon } = watchedTable2TableOfWatched(state)

let function battleAreaHud(_eid, comps) {
  let bap = comps.battle_area__activeBattleAreasPolygon.getAll()
  let nbap = comps.battle_area__nextBattleAreasPolygon.getAll()
  state({
    battleAreasPolygon = bap.len() > 0 ? bap : null
    nextBattleAreasPolygon = nbap.len() > 0 ? nbap : null
  })
}

ecs.register_es("battle_areas_ui_state", {
  [["onInit", "onChange"]] = battleAreaHud
}, {
  comps_track = [
    ["battle_area__activeBattleAreasPolygon", ecs.TYPE_POINT2_LIST],
    ["battle_area__nextBattleAreasPolygon", ecs.TYPE_POINT2_LIST],
  ]
})
return {
  battleAreasPolygon
  nextBattleAreasPolygon
}
