import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let { TEAM_UNASSIGNED } = require("team")
let { watchedHeroEid } = require("%ui/hud/state/watched_hero.nut")
let is_teams_friendly = require("%enlSqGlob/is_teams_friendly.nut")

let active_grenades = Watched({})
let function deleteGrenade(eid){
  if (eid in active_grenades.value)
    delete active_grenades.value[eid]
}

let getGrenadeOwnerTeamQuery = ecs.SqQuery("getGrenadeOwnerTeamQuery", {comps_ro = [["team", ecs.TYPE_INT]]})
let getHeroTeam = @(heroEid) getGrenadeOwnerTeamQuery.perform(heroEid, @(_eid, comp) comp["team"]) ?? TEAM_UNASSIGNED

let function getWillDamageHero(heroEid, grenadeOwner, grenadeRethrower) {
  if (grenadeOwner == heroEid && heroEid != INVALID_ENTITY_ID && grenadeOwner != INVALID_ENTITY_ID)
    return true
  let heroTeam = getHeroTeam(heroEid)
  if (!is_teams_friendly(heroTeam, getHeroTeam(grenadeOwner)))
    return true
  if (grenadeRethrower != INVALID_ENTITY_ID && !is_teams_friendly(heroTeam, getHeroTeam(grenadeRethrower)))
    return true
  return false
}

ecs.register_es(
  "active_grenades_hud_es",
  {
    [["onInit", "onChange"]] = function(eid, comp){
      if (!(comp.active || comp["shell__explTime"] == 0.0))
        deleteGrenade(eid)
      else{
        active_grenades.mutate(function(v) {
          let grenadeOwner = comp["shell__owner"]
          let grenadeRethrower = comp["shell__rethrower"]
          let heroEid = watchedHeroEid.value ?? INVALID_ENTITY_ID
          v[eid] <- {
            willDamageHero = getWillDamageHero(heroEid, grenadeOwner, grenadeRethrower)
            maxDistance = comp["hud_marker__max_distance"]
          }
        })
      }
    }
    function onDestroy(eid, _comp){
      deleteGrenade(eid)
    }
  },
  {
    comps_ro = [
      ["shell__explTime", ecs.TYPE_FLOAT, 0.0],
      ["shell__owner", ecs.TYPE_EID, INVALID_ENTITY_ID],
      ["shell__rethrower", ecs.TYPE_EID, INVALID_ENTITY_ID],
      ["hud_marker__max_distance", ecs.TYPE_FLOAT, 10.0]
    ]
    comps_track = [["active", ecs.TYPE_BOOL]]
    comps_rq = ["hud_grenade_marker"]
  }
)

return {
  active_grenades
}