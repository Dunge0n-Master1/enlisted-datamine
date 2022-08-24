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
let oldWatchedHero = persist("oldWatchedHero" @(){eid=INVALID_ENTITY_ID, team = TEAM_UNASSIGNED})
let oldWatchedHeroPlayer = persist("oldWatchedHeroPlayer" @(){v=INVALID_ENTITY_ID})
let { watchedTable2TableOfWatched } = require("%sqstd/frp.nut")
let { mkFrameIncrementObservable } = require("%ui/ec_to_watched.nut")

let whDefValue = freeze({
  watchedHeroEid = oldWatchedHero.eid
  watchedHeroTeam = oldWatchedHero.team
})
let { whState, whStateSetValue } = mkFrameIncrementObservable(whDefValue, "whState")
let { watchedHeroEid, watchedHeroTeam} = watchedTable2TableOfWatched({state=whState, defValue=whDefValue})

let { watchedHeroPlayerEid, watchedHeroPlayerEidSetValue } = mkFrameIncrementObservable(oldWatchedHeroPlayer.v, "watchedHeroPlayerEid")


let watchedTeam = Computed(@() watchedHeroEid.value != INVALID_ENTITY_ID ? watchedHeroTeam.value : localPlayerTeam.value)

ecs.register_es("watched_hero_player_eid_es", {
  [["onInit","onChange"]] = function(_, _eid, comp){
    let w = comp["possessedByPlr"] ?? INVALID_ENTITY_ID
    watchedHeroPlayerEidSetValue(w)
    oldWatchedHeroPlayer.v=w
  }
  onDestroy = @() watchedHeroPlayerEidSetValue(INVALID_ENTITY_ID)
}, {comps_track=[["possessedByPlr", ecs.TYPE_EID]],comps_rq=[["watchedByPlr", ecs.TYPE_EID]]})


ecs.register_es("watched_hero_eid_es", {
  onInit = function(_, eid, comp) {
    log("watchedHeroEid:" eid)
    oldWatchedHero.eid = eid
    oldWatchedHero.team = comp.team
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