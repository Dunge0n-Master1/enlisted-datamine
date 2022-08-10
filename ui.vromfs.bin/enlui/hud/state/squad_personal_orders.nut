import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let { watchedHeroSquadEid } = require("%ui/hud/state/squad_members.nut")
let { mkWatchedSetAndStorage } = require("%ui/ec_to_watched.nut")

let {
  watchedHeroSquadPersonalOrdersSet,
  watchedHeroSquadPersonalOrdersGetWatched,
  watchedHeroSquadPersonalOrdersUpdateEid,
  watchedHeroSquadPersonalOrdersDestroyEid
} = mkWatchedSetAndStorage("watchedHeroSquadPersonalOrders")

ecs.register_es("squad_personal_orders_ui_es",
  {
    [["onInit", "onChange"]] = function(_, eid, comp) {
      if (comp["squad_member__isPersonalOrder"] && comp["squad_member__squad"] == watchedHeroSquadEid.value) {
        watchedHeroSquadPersonalOrdersUpdateEid(eid, {
            orderType = comp["squad_member__orderType"]
            orderPosition = comp["squad_member__orderPosition"]
          }
        )
      }
      else {
        watchedHeroSquadPersonalOrdersDestroyEid(eid)
      }
    },
    function onDestroy(_, eid, _comp) {
      watchedHeroSquadPersonalOrdersDestroyEid(eid)
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
  watchedHeroSquadPersonalOrdersSet, watchedHeroSquadPersonalOrdersGetWatched
}
