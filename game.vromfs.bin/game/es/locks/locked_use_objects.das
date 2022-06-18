require ecs
require game.events_game
require game.es.game_effect_macro
require game.es.vehicle.vehicle_events

[es_game_effect(bool_flag=human_use_object__lockGrenadeRethrowing, tag=locked_use_object__lockGrenadeRethrowing)]
def lock_grenade_rethrowing_es() { pass; }

[es_game_effect(bool_flag=locked__stationaryGunUseLockedByAffect, tag=locked_use_object__lockStationaryGunUse)]
def lock_stationary_gun_use_es() { pass; }

[es_game_effect(bool_flag=human_use_object__lockDoorUse, tag=locked_use_object__lockDoorUse)]
def lock_door_use_es() { pass; }

[es_game_effect(bool_flag=human_use_object__lockVehicleUse, tag=locked_use_object__lockVehicleUse)]
def lock_vehicle_use_es() { pass; }

[es(REQUIRE=locked_use_object__lockVehicleEnter)]
def lock_can_take_seat_es(evt : GameEffectStateChanged; eid : EntityId)
  lock_can_take_seat(evt.activated, evt.attachedTo, eid)

[es(REQUIRE=locked_use_object__lockVehicleUse)]
def lock_can_take_seat_of_vehicle_use_es(evt : GameEffectStateChanged; eid : EntityId)
  lock_can_take_seat(evt.activated, evt.attachedTo, eid)

def lock_can_take_seat(value : bool; target_eid, effect_eid : EntityId)
  ecs::query(target_eid) <| $ [es] (var human_vehicle__can_take_seat : bool&)
    var lock = value
    lock ||= ecs::find_query() <| $ [es(REQUIRE=locked_use_object__lockVehicleUse)] (eid, game_effect__attachedTo : EntityId)
      return eid != effect_eid && game_effect__attachedTo == target_eid
    lock ||= ecs::find_query() <| $ [es(REQUIRE=locked_use_object__lockVehicleEnter)] (eid, game_effect__attachedTo : EntityId)
      return eid != effect_eid && game_effect__attachedTo == target_eid
    human_vehicle__can_take_seat = !lock

[es(track=human_use_object__lockVehicleUse)]
def force_exit_from_vehicle_on_lock(evt : Event; eid : EntityId; human_use_object__lockVehicleUse : bool; human_anim__vehicleSelected : EntityId)
  if human_use_object__lockVehicleUse && !!human_anim__vehicleSelected
    sendEvent(human_anim__vehicleSelected, [[CmdKickFromVehicle eid=eid]])
