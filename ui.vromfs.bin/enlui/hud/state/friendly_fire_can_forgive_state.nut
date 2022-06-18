import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let canForgivePlayers = Watched({})

ecs.register_es("track_can_forgive_friendly_fire_players",
  {
    [["onInit", "onChange"]] = function(_ect, _eid, comp) {
      if (comp.is_local)
        canForgivePlayers(comp["friendly_fire__canForgivePlayers"].getAll())
    }
  },
  {
    comps_ro = [["is_local", ecs.TYPE_BOOL]],
    comps_track = [["friendly_fire__canForgivePlayers", ecs.TYPE_OBJECT]]
  }
)

return canForgivePlayers