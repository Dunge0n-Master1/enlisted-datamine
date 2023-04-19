options no_aot
require ecs
require DagorMath
require common_shooter.events_common_shooter
require debug.logerr_once


[es(tag=sound, REQUIRE=gunSound)]
def gun_sound_debug_on_shot(evt : EventShot; eid : EntityId)
  if length_sq(evt.launchDesc.tm[3]) == 0.
    logerr_once("EventShot evt.launchDesc.tm[3] is not valid({evt.launchDesc.tm[3]}), template: {getEntityTemplateName(eid)}")
