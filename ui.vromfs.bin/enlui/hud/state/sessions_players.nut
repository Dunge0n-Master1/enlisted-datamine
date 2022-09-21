import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let userInfo = require("%enlSqGlob/userInfo.nut")
let remap_nick = require("%enlSqGlob/remap_nick.nut")

let players = Watched({})
let names = Computed(@() players.value.values().map(
  @(v) v == userInfo.value?.name ? userInfo.value.nameorig : remap_nick(v)
))

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