import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let {localPlayerTeam} = require("%ui/hud/state/local_player.nut")
let {TEAM_UNASSIGNED} = require("team")
//let {EventHeroChanged} = require("gameevents")
/*!!!!!ATTENTION!!!!
  player != avatar(hero)
  player can change heros and avatars (by respawn or something). Avatar can be dead and than ressurrect. Player is USER. Avatar is game changeable entity.
  One avatar\hero is controlled by one player (most likely), but player can have NO Avatars for example at all.
*/


let watchedHeroEid = Watched(INVALID_ENTITY_ID)//watchedHeroEidmkWatched(persist, "watchedHeroEid", INVALID_ENTITY_ID)
let watchedHeroTeam = Watched(TEAM_UNASSIGNED)//mkWatched(persist, "watchedHeroTeam", TEAM_UNASSIGNED)
let watchedHeroPlayerEid = Watched(INVALID_ENTITY_ID)//mkWatched(persist, "watchedHeroPlayerEid", INVALID_ENTITY_ID)
let watchedTeam = Computed(@() watchedHeroEid.value != INVALID_ENTITY_ID ? watchedHeroTeam.value : localPlayerTeam.value)

ecs.register_es("watched_hero_player_eid_es", {
  onInit = function(_eid, comp){ watchedHeroPlayerEid.update(comp["possessedByPlr"] ?? INVALID_ENTITY_ID) }
  onChange = function(_eid, comp){ watchedHeroPlayerEid.update(comp["possessedByPlr"] ?? INVALID_ENTITY_ID)}
  onDestroy = @() watchedHeroPlayerEid(INVALID_ENTITY_ID)
}, {comps_track=[["possessedByPlr", ecs.TYPE_EID]],comps_rq=[["watchedByPlr", ecs.TYPE_EID]]})


ecs.register_es("watched_hero_eid_es", {
  onInit = function(_, eid, comp) {
    log("watchedHeroEid:" eid)
    watchedHeroEid.update(eid)
    watchedHeroTeam(comp.team)
  }
  onDestroy = function(eid, _comp) {
    if (watchedHeroEid.value == eid) {
      watchedHeroEid.update(INVALID_ENTITY_ID)
      watchedHeroTeam(TEAM_UNASSIGNED)
    }
  }
}, {comps_rq=[["watchedByPlr", ecs.TYPE_EID]], comps_ro = [["team", ecs.TYPE_INT, TEAM_UNASSIGNED]]})


return {
  watchedHeroEid,
  watchedHeroPlayerEid,
  watchedTeam
}