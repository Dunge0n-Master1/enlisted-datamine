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
let { watchedTable2TableOfWatched } = require("%sqstd/frp.nut")

let whDefValue = freeze({
  watchedHeroEid = ecs.INVALID_ENTITY_ID
  watchedHeroTeam = TEAM_UNASSIGNED
})
let whState = mkWatched(persist, "watchedHero", whDefValue)
let whStateSetValue = @(v) whState(v)

let { watchedHeroEid, watchedHeroTeam } = watchedTable2TableOfWatched(whState)

let watchedHeroPlayerEid = mkWatched(persist, "watchedHeroPlayerEid", ecs.INVALID_ENTITY_ID)
let watchedHeroPlayerEidSetValue = @(v) watchedHeroPlayerEid(v)


let watchedTeam = Computed(@() watchedHeroEid.value != ecs.INVALID_ENTITY_ID ? watchedHeroTeam.value : localPlayerTeam.value)

ecs.register_es("watched_hero_player_eid_es", {
  [["onInit","onChange"]] = function(_, _eid, comp){
    let w = comp["possessedByPlr"] ?? ecs.INVALID_ENTITY_ID
    watchedHeroPlayerEidSetValue(w)
  }
  onDestroy = @() watchedHeroPlayerEidSetValue(ecs.INVALID_ENTITY_ID)
}, {comps_track=[["possessedByPlr", ecs.TYPE_EID]],comps_rq=[["watchedByPlr", ecs.TYPE_EID]]})


ecs.register_es("watched_hero_eid_es", {
  onInit = function(_, eid, comp) {
    log("watchedHeroEid:" eid)
    whStateSetValue({
      watchedHeroEid = eid
      watchedHeroTeam = comp.team
    })
  }
  onDestroy = function(_, eid, _comp) {
    if (watchedHeroEid.value == eid)
      whStateSetValue(whDefValue)
  }
}, {comps_rq=[["watchedByPlr", ecs.TYPE_EID]], comps_ro = [["team", ecs.TYPE_INT, TEAM_UNASSIGNED]]})


return {
  watchedHeroEid,
  watchedHeroPlayerEid,
  watchedTeam
}