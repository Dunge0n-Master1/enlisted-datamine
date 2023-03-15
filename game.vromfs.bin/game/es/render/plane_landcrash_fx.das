require ecs
require game.es.vehicle.vehicle_events
require fx
require Plane
require math.base


[es(tag=render)]
def plane_landcrash_fx_on_crash(evt : EventCrashExplosionFatal;
                                transform : float3x4;
                                plane_landcrash_fx__landCrashEffect : string;
                                plane_landcrash_fx__waterCrashEffect : string;
                                var plane_landcrash_fx__fxEid : EntityId&)
  let isOnWater = evt.crashType == int(CrashType CRASH_TYPE_WATER)
  let effectTemplate = isOnWater ? plane_landcrash_fx__waterCrashEffect : plane_landcrash_fx__landCrashEffect

  plane_landcrash_fx__fxEid = createEntity(effectTemplate) <| $(var init)
    var fxTm = IDENT_TM
    fxTm[3] = transform[3]
    set(init, "transform", fxTm)


[es(tag=render, on_disappear)]
def plane_landcrash_fx_on_disappear(evt : Event; plane_landcrash_fx__fxEid : EntityId)
  destroyEntity(plane_landcrash_fx__fxEid)
