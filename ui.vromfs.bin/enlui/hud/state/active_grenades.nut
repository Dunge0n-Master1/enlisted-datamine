import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let { watchedHeroEid, watchedTeam } = require("%ui/hud/state/watched_hero.nut")
let is_teams_friendly = require("%enlSqGlob/is_teams_friendly.nut")
let { getTeam } = require("get_team.nut")

let { mkWatchedSetAndStorage } = require("%ui/ec_to_watched.nut")

let {
  active_grenades_Set,
  active_grenades_GetWatched,
  active_grenades_UpdateEid,
  active_grenades_DestroyEid
} = mkWatchedSetAndStorage("active_grenades_")


let function getWillDamageHero(heroEid, grenadeOwner, grenadeRethrower) {
  if (grenadeOwner == heroEid && heroEid != ecs.INVALID_ENTITY_ID && grenadeOwner != ecs.INVALID_ENTITY_ID)
    return true
  let heroTeam = watchedTeam.value
  if (!is_teams_friendly(heroTeam, getTeam(grenadeOwner)))
    return true
  if (grenadeRethrower != ecs.INVALID_ENTITY_ID && !is_teams_friendly(heroTeam, getTeam(grenadeRethrower)))
    return true
  return false
}

ecs.register_es(
  "active_grenades_hud_es",
  {
    [["onInit", "onChange"]] = function(_, eid, comp){
      if (!(comp.active || comp["shell__explTime"] == 0.0))
        active_grenades_DestroyEid(eid)
      else{
        let grenadeOwner = comp["shell__owner"]
        let grenadeRethrower = comp["shell__rethrower"]
        let heroEid = watchedHeroEid.value ?? ecs.INVALID_ENTITY_ID
        let willDamageHero = getWillDamageHero(heroEid, grenadeOwner, grenadeRethrower)
        active_grenades_UpdateEid(eid, {
            willDamageHero
            maxDistance = comp["hud_marker__max_distance"]
          }
       )
      }
    }
    function onDestroy(_, eid, _comp){
      active_grenades_DestroyEid(eid)
    }
  },
  {
    comps_ro = [
      ["shell__explTime", ecs.TYPE_FLOAT, 0.0],
      ["shell__owner", ecs.TYPE_EID, ecs.INVALID_ENTITY_ID],
      ["shell__rethrower", ecs.TYPE_EID, ecs.INVALID_ENTITY_ID],
      ["hud_marker__max_distance", ecs.TYPE_FLOAT, 10.0]
    ]
    comps_track = [["active", ecs.TYPE_BOOL]]
    comps_rq = ["hud_grenade_marker"]
  }
)

return {
  active_grenades_Set,
  active_grenades_GetWatched
}