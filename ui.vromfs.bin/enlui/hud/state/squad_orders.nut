import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let { SquadOrder } = require("%enlSqGlob/dasenums.nut")
let { localPlayerEid } = require("%ui/hud/state/local_player.nut")
let { mkWatchedSetAndStorage, MK_COMBINED_STATE } = require("%ui/ec_to_watched.nut")

let {
  squad_orders_State,
  squad_orders_UpdateEid,
  squad_orders_DestroyEid
} = mkWatchedSetAndStorage("squad_orders_", MK_COMBINED_STATE)

ecs.register_es("squad_orders_ui_es",
  {
    [["onInit", "onChange"]] = function(_evt, eid, comp) {
      squad_orders_UpdateEid(eid, {
          leader = comp["squad__leader"]
          orderType = comp["squad__orderType"]
          owner = comp["squad__ownerPlayer"]
          orderPosition = comp["squad__orderPosition"]
          persistent = false
          isAlive = comp["squad__isAlive"]
        }
      )
    },
    function onDestroy(_evt, eid, _comp) {
      squad_orders_DestroyEid(eid)
    }
  },
  {
    comps_track = [
      ["squad__ownerPlayer", ecs.TYPE_EID],
      ["squad__leader", ecs.TYPE_EID],
      ["squad__orderType", ecs.TYPE_INT],
      ["squad__orderPosition", ecs.TYPE_POINT3],
      ["squad__isAlive", ecs.TYPE_BOOL]
    ]
  }
)

let localSquadOrder = Computed(function() {
  let v = squad_orders_State.value.findvalue(@(v) v.owner == localPlayerEid.value)
  if (v != null && v.orderType == SquadOrder.ESO_DEFEND_POINT && v.isAlive==true)
    return v.orderPosition
  return null
})

return {
  localSquadOrder
}
