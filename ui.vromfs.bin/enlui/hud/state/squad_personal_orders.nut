import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let {watchedHeroSquadEid} = require("%ui/hud/state/squad_members.nut")
let watchedHeroSquadPersonalOrders = Watched({})

let function deleteEid(eid, state){
  if (eid in state.value && eid != INVALID_ENTITY_ID)
    state.mutate(@(v) delete v[eid])
}
ecs.register_es("squad_personal_orders_ui_es",
  {
    [["onInit", "onChange"]] = function(eid, comp) {
      if (comp["squad_member__isPersonalOrder"] && comp["squad_member__squad"] == watchedHeroSquadEid.value) {
        watchedHeroSquadPersonalOrders.mutate(function(value) {
          value[eid] <- {
            orderType = comp["squad_member__orderType"]
            orderPosition = comp["squad_member__orderPosition"]
          }
        })
      }
      else {
        deleteEid(eid, watchedHeroSquadPersonalOrders)
      }
    },
    function onDestroy(eid, _comp) {
      deleteEid(eid, watchedHeroSquadPersonalOrders)
    }
  },
  {
    comps_track = [
      ["squad_member__squad", ecs.TYPE_EID],
      ["squad_member__orderType", ecs.TYPE_INT],
      ["squad_member__orderPosition", ecs.TYPE_POINT3],
      ["squad_member__isPersonalOrder", ecs.TYPE_BOOL],
    ]
  }
)

return {
  watchedHeroSquadPersonalOrders
}
