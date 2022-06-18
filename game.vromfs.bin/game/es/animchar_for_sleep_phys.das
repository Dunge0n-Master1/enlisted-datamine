require ecs
require vehicle
require EnlistedPhysObj
require EnlistedShip
require EnlistedActor

[es(after=vehicle_seats_update_sleep_physobj_es, tag=server)]
def save_phys_obj_sleep_state_phys_es(info : UpdateStageInfoAct;
                                      phys_obj_net_phys : PhysObjActor;
                                      var phys__isAsleep : bool&)
  phys__isAsleep = phys_obj_net_phys.isAsleep

[es(after=(vehicle_seats_update_sleep_vehicle_es, vehicle_floats_wakeup_es), tag=server)]
def save_vehicle_sleep_state_phys_es(info : UpdateStageInfoAct;
                                     vehicle_net_phys : VehiclePhysActor;
                                     var phys__isAsleep : bool&)
  phys__isAsleep = vehicle_net_phys.isAsleep


[es(after=vehicle_seats_update_sleep_ship_es, tag=server)]
def save_ship_sleep_state_phys_es(info : UpdateStageInfoAct;
                                  ship_net_phys : ShipActor;
                                  var phys__isAsleep : bool&)
  phys__isAsleep = ship_net_phys.isAsleep

[es(track=phys__isAsleep, on_appear)]
def animchar_update_sleep_phys_es(evt : Event;
                                  eid : EntityId;
                                  phys__isAsleep : bool;
                                  var animchar__updatable : bool&)
  animchar__updatable = has(eid, "animchar__updatableOnSleepPhys") || !phys__isAsleep

[es(on_appear, REQUIRE=animchar__updatableOnSleepPhys)]
def wakeup_sleeping_animchar(evt : Event; var animchar__updatable : bool&)
  animchar__updatable = true
