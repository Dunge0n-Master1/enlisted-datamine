import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let {localPlayerTeam, localPlayerEid} = require("%ui/hud/state/local_player.nut")
let orders = Watched({})

let function deleteEid(eid, state){
  if (eid in state.value && eid != INVALID_ENTITY_ID)
    state.mutate(@(v) delete v[eid])
}
ecs.register_es("squad_orders_ui_es",
  {
    [["onInit", "onChange"]] = function(_evt, _eid, comp) {
      let playerEid = comp["squad__ownerPlayer"]
      if (playerEid != localPlayerEid.value) {
        deleteEid(playerEid, orders)
        return
      }
      orders.mutate(function(value) {
        value[playerEid] <- {
          team = localPlayerTeam.value
          leader = comp["squad__leader"]
          orderType = comp["squad__orderType"]
          orderPosition = comp["squad__orderPosition"]
          persistent = false
        }
      })
    },
    function onDestroy(_evt, _eid, comp) {
      deleteEid(comp["squad__ownerPlayer"], orders)
    }
  },
  {
    comps_track = [
      ["squad__ownerPlayer", ecs.TYPE_EID],
      ["squad__leader", ecs.TYPE_EID],
      ["squad__orderType", ecs.TYPE_INT],
      ["squad__orderPosition", ecs.TYPE_POINT3],
    ]
  }
)

return {
  squad_orders = orders
}
