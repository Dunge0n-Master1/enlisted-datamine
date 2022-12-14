import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *
let {EventHeroChanged} = require("gameevents")

let {get_controlled_hero} = require("%dngscripts/common_queries.nut")

/*!!!!!ATTENTION!!!!
  player != avatar(hero)
  player can change heros and avatars (by respawn or something). Avatar can be dead and than ressurrect. Player is USER. Avatar is game changeable entity.
  One avatar\hero is controlled by one player (most likely), but player can have NO Avatars for example at all.
*/

/// =====hero_eid ====
let controlledHeroEid = Watched(ecs.INVALID_ENTITY_ID)

wlog(controlledHeroEid, "controlled: ")

ecs.register_es("controlled_hero_eid_init_es", {
  [["onInit", "onDestroy", "onChange"]] = function(_eid,comp){
    if (comp.is_local)
      controlledHeroEid.update(get_controlled_hero())
  }
}, {comps_track=[["possessed", ecs.TYPE_EID]], comps_ro=[["is_local", ecs.TYPE_BOOL]], comps_rq=["player"]})

//this is special es, which doesn't require any components. However, we don't need any components! we work on evt.get[0] only
ecs.register_es("controlled_hero_eid_es", {
  [EventHeroChanged] = function(evt, _eid, _comp){
    let e = evt[0]
    log($"controlledHeroEid = {e}")
    controlledHeroEid.update(e)
  }
}, {})

return{
  controlledHeroEid
}