import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

/*!!!!!ATTENTION!!!!
  player != avatar(hero)
  player can change heros and avatars (by respawn or something). Avatar can be dead and than ressurrect. Player is USER. Avatar is game changeable entity.
  One avatar\hero is controlled by one player (most likely), but player can have NO Avatars for example at all.
*/


let watchedHeroEid = Watched(INVALID_ENTITY_ID)
let watchedHeroPlayerEid = Watched(INVALID_ENTITY_ID)

wlog(watchedHeroEid, "watched:")

ecs.register_es("watched_hero_player_eid_es", {
  onInit = function(_eid, comp){ watchedHeroPlayerEid.update(comp["possessedByPlr"] ?? INVALID_ENTITY_ID); }
  onChange = function(_eid, comp){ watchedHeroPlayerEid.update(comp["possessedByPlr"] ?? INVALID_ENTITY_ID);}
  onDestroy = @() watchedHeroPlayerEid(INVALID_ENTITY_ID)
}, {comps_track=[["possessedByPlr", ecs.TYPE_EID]],comps_rq=[["watchedByPlr", ecs.TYPE_EID]]})


ecs.register_es("watched_hero_eid_es", {
  onInit = @(eid, _comp) watchedHeroEid.update(eid)
}, {comps_rq=[["watchedByPlr", ecs.TYPE_EID]]})

return {
  watchedHeroEid, watchedHeroPlayerEid
}