require ecs
require game.es.vehicle.vehicle_events
require game.es.events
require EnlistedNet
require dm
require EnlistedDm
require vehicle
require player

[es(tag=server, on_appear)]
def vehicle_hp_init_es(evt : Event;
                       damage_model : DamageModel;
                       vehicle__hpMetaPart : das_string;
                       var vehicle__hpMetaPartId : int&;
                       var vehicle__hp : float&;
                       var vehicle__maxHp : float&)

  vehicle__hpMetaPartId = damage_model |> find_meta_part_id_by_name(vehicle__hpMetaPart)
  if vehicle__hpMetaPartId >= 0
    vehicle__maxHp = damage_model |> get_meta_part_max_hp(vehicle__hpMetaPartId)
    vehicle__hp = vehicle__maxHp

def process_damage_effects(offender : ecs::EntityId;
                           vehicle : ecs::EntityId;
                           effects : int;
                           vehicle_seats__seatEids : EidList)

  let player = get_Eid(offender, "possessedByPlr") ?? INVALID_ENTITY_ID
  sendEvent(offender, [[EventOnVehicleDamageEffects offender=player, vehicle=vehicle, effects=effects]])

  for seatEid in vehicle_seats__seatEids
    let ownerEid = get_Eid(seatEid, "seat__ownerEid") ?? INVALID_ENTITY_ID
    let isPlayer = get_bool(seatEid, "seat__isPlayer") ?? false
    let victim = ownerEid
    if victim != offender && isPlayer && victim != INVALID_ENTITY_ID
      sendEvent(victim, [[CmdShowVehicleDamageEffectsHint offender=offender, vehicle=vehicle, effects=effects]])

[es(tag=server, REQUIRE=damage_model)]
def vehicle_hp_on_part_kill_effect_es(evt : EventOnPartKillEffects; eid : EntityId; vehicle_seats__seatEids : EidList)
  let effects = evt.effects
  if effects != 0
    let vehicle = eid
    process_damage_effects(evt.offender, vehicle, effects, vehicle_seats__seatEids)

[es(tag=server, REQUIRE=damage_model)]
def vehicle_hp_on_part_damage_effect_es(evt : EventOnPartDamageEffects; eid : EntityId; vehicle_seats__seatEids : EidList)
  let effects = evt.effects
  if effects != 0
    let vehicle = eid
    process_damage_effects(evt.offender, vehicle, effects, vehicle_seats__seatEids)

[es(tag=server, REQUIRE = damage_model)]
def vehicle_hp_on_meta_part_damage_es(evtData : EventOnMetaPartDamage;
                                      eid : ecs::EntityId;
                                      vehicle__hp : float;
                                      vehicle__sendMsgDamageThreshold : float)

  if evtData.damage >= vehicle__sendMsgDamageThreshold && vehicle__hp > 0.0
    let offender = evtData.offender
    let offenderPlayer = get_Eid(offender, "possessedByPlr") ?? INVALID_ENTITY_ID
    sendEvent(offender, [[EventOnVehicleDamaged offender=offenderPlayer, vehicle=eid, damage=evtData.damage, hp=evtData.hp, maxHp=evtData.maxHp]])

[es(tag=server, no_order)]
def vehicle_hp_es(info : ecs::UpdateStageInfoAct;
                  damage_model : DamageModel;
                  meta_parts_state : MetaPartsState;
                  vehicle__hpMetaPartId : int;
                  var vehicle__hp : float&)

  if vehicle__hpMetaPartId < 0
    return

  let relHp = meta_parts_state |> get_meta_part_rel_hp(vehicle__hpMetaPartId)
  let maxHp = damage_model |> get_meta_part_max_hp(vehicle__hpMetaPartId)

  vehicle__hp = relHp * maxHp

[es(tag=server, track=isExploded)]
def vehicle_on_explosion_es(evt : Event;
                            eid : ecs::EntityId;
                            vehicle__hp : float;
                            vehicle__maxHp : float;
                            isExploded : bool;
                            lastOffender : EntityId)
  if isExploded && lastOffender != INVALID_ENTITY_ID
    let player = get_Eid(lastOffender, "possessedByPlr") ?? INVALID_ENTITY_ID
    sendEvent(lastOffender, [[EventOnVehicleDamaged offender=player, vehicle=eid, damage=vehicle__maxHp, hp=vehicle__hp, maxHp=vehicle__maxHp]])
