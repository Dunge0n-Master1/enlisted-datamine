import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let {EventOnEntityHit} = require("dasevents")
let {watchedHeroEid} = require("%ui/hud/state/watched_hero.nut")
let hitAnimTrigger = persist("hitAnimTrigger", @() {})

ecs.register_es("hit_trigger_ui_es", {
  [EventOnEntityHit] = function onEntityHit(evt, _eid, _comp) {
      let victim_eid = evt.victim
      if (victim_eid == watchedHeroEid.value) {
        anim_start(hitAnimTrigger)
      }
  },
})

return {hitAnimTrigger}