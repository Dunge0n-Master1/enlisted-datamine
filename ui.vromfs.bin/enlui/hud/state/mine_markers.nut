import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let { watchedTeam } = require("%ui/hud/state/watched_hero.nut")

let {TEAM_UNASSIGNED} = require("team")
let is_teams_friendly = require("%enlSqGlob/is_teams_friendly.nut")
let { mkWatchedSetAndStorage } = require("%ui/ec_to_watched.nut")

let {
  mine_markers_Set,
  mine_markers_GetWatched,
  mine_markers_UpdateEid,
  mine_markers_DestroyEid
} = mkWatchedSetAndStorage("mine_markers_")

ecs.register_es(
  "mine_markers_es",
  {
    [["onInit", "onChange"]] = function(_evt, eid, comp){
      let isFriendlyMine = is_teams_friendly(comp["placeable_item__ownerTeam"], watchedTeam.value)
      if (!isFriendlyMine || !comp["mine__activated"])
        mine_markers_DestroyEid(eid)
      else
        mine_markers_UpdateEid(eid, {
          type = comp.item__mineType ?? comp.item__grenadeLikeType
          blockedToTime = comp["mine__blockedToTime"]
          installBlockTime = comp["mine__installBlockTime"]
        })
    }
    onDestroy = @(_evt, eid, _comp) mine_markers_DestroyEid(eid)
  },
  {
    comps_rq = ["transform", "ui__placeableItemMarker"]
    comps_track = [
      ["item__mineType", ecs.TYPE_STRING, null],
      ["item__grenadeLikeType", ecs.TYPE_STRING, null],
      ["mine__activated", ecs.TYPE_BOOL, true],
      ["mine__blockedToTime", ecs.TYPE_FLOAT, -1.0],
      ["mine__installBlockTime", ecs.TYPE_FLOAT, 0.0],
      ["placeable_item__ownerTeam", ecs.TYPE_INT, TEAM_UNASSIGNED]
    ]
  }
)

return{
  mine_markers_Set, mine_markers_GetWatched
}