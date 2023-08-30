require ecs
require vehicle
require DngPhysObj
require DngShip
require DngActor
require enlisted.events_enlisted

[es(after=vehicle_seats_update_sleep_physobj_es, tag=server)]
def save_phys_obj_sleep_state_phys_es(info : ParallelUpdateFrameDelayed;
                                      phys_obj_net_phys : PhysObjActor;
                                      var phys__isAsleep : bool&)
  phys__isAsleep = phys_obj_net_phys.isAsleep

[es(after=(vehicle_seats_update_sleep_vehicle_es, vehicle_floats_wakeup_es), tag=server)]
def save_vehicle_sleep_state_phys_es(info : ParallelUpdateFrameDelayed;
                                     vehicle_net_phys : VehiclePhysActor;
                                     var phys__isAsleep : bool&)
  phys__isAsleep = vehicle_net_phys.isAsleep


[es(after=vehicle_seats_update_sleep_ship_es, tag=server)]
def save_ship_sleep_state_phys_es(info : ParallelUpdateFrameDelayed;
                                  ship_net_phys : ShipActor;
                                  var phys__isAsleep : bool&)
  phys__isAsleep = ship_net_phys.isAsleep


[es(after=after_net_phys_sync, before=(before_animchar_update_sync, anim_phys_updater_es), REQUIRE_NOT=animchar__updatableOnSleepPhys)]
def animchar_update_sleep_phys_es(evt : ParallelUpdateFrameDelayed;
                                  phys__isAsleep : bool;
                                  net_phys__lastAppliedControlsForTick : int;
                                  sleep_phys__animInterpTimeDef : float;
                                  var sleep_phys__animInterpTime : float&;
                                  var animchar__updatable : bool&;
                                  var sleep_phys__lastUpdateAtControls : int&)
  let requireUpdateByTick = sleep_phys__lastUpdateAtControls < net_phys__lastAppliedControlsForTick

  if phys__isAsleep && requireUpdateByTick
    sleep_phys__animInterpTime = sleep_phys__animInterpTimeDef

  animchar__updatable = !phys__isAsleep || sleep_phys__animInterpTime > 0.

  if sleep_phys__animInterpTime > 0.
    sleep_phys__animInterpTime -= evt.dt

  sleep_phys__lastUpdateAtControls = net_phys__lastAppliedControlsForTick

[es(on_appear, REQUIRE=animchar__updatableOnSleepPhys)]
def wakeup_sleeping_animchar(evt : Event; var animchar__updatable : bool&)
  animchar__updatable = true
