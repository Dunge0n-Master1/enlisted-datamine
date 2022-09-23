import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let { remap_others } = require("%enlSqGlob/remap_nick.nut")

let players = Watched({})
let names = Computed(@() players.value.values().map(remap_others))

ecs.register_es("session_players_bots_es",
  {
    [["onInit", "onChange"]] = @(eid, comp) players.mutate(@(p) p[eid] <- comp.name)
  },
  {
    comps_track = [["name", ecs.TYPE_STRING]],
    comps_rq = ["player"],
    comps_no = ["playerIsBot"],
  }
)

return names