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
                       vehicle__hpMetaPart : string;
                       var vehicle__hpMetaPartId : int&;
                       var vehicle__hp : float&;
                       var vehicle__maxHp : float&)

  vehicle__hpMetaPartId = damage_model |> find_meta_part_id_by_name(vehicle__hpMetaPart)
  if vehicle__hpMetaPartId >= 0
    vehicle__maxHp = damage_model.metaPartProps[vehicle__hpMetaPartId].hp
    vehicle__hp = vehicle__maxHp

def process_damage_effects(offender : ecs::EntityId;
                           vehicle : ecs::EntityId;
                           effects : int)

  let player = get_Eid(offender, "possessedByPlr") ?? INVALID_ENTITY_ID
  send_net_event(offender, [[EventOnVehicleDamageEffects offender=player, vehicle=vehicle, effects=effects]])

[es(tag=server, REQUIRE=damage_model)]
def vehicle_hp_on_part_kill_effect_es(evt : EventOnPartKillEffects; eid : EntityId)
  let effects = evt.effects
  if effects != 0
    process_damage_effects(evt.offender, eid, effects)

[es(tag=server, REQUIRE=damage_model)]
def vehicle_hp_on_part_damage_effect_es(evt : EventOnPartDamageEffects; eid : EntityId)
  let effects = evt.effects
  if effects != 0
    process_damage_effects(evt.offender, eid, effects)

[es(tag=server, REQUIRE = damage_model)]
def vehicle_hp_on_meta_part_damage_es(evtData : EventOnMetaPartDamage;
                                      eid : ecs::EntityId;
                                      vehicle__hp : float;
                                      vehicle__sendMsgDamageThreshold : float)

  if evtData.damage >= vehicle__sendMsgDamageThreshold && vehicle__hp > 0.0
    let offender = evtData.offender
    let offenderPlayer = get_Eid(offender, "possessedByPlr") ?? INVALID_ENTITY_ID
    send_net_event(offender, [[EventOnVehicleDamaged offender=offenderPlayer, vehicle=eid, damage=evtData.damage, hp=evtData.hp, maxHp=evtData.maxHp]])

[es(tag=server, no_order)]
def vehicle_hp_es(info : ecs::UpdateStageInfoAct;
                  damage_model : DamageModel;
                  meta_parts_state : MetaPartsState;
                  vehicle__hpMetaPartId : int;
                  var vehicle__hp : float&)

  if vehicle__hpMetaPartId < 0
    return

  let relHp = rel_hp_fixed_to_float(meta_parts_state.state[vehicle__hpMetaPartId].hp)
  let maxHp = damage_model.metaPartProps[vehicle__hpMetaPartId].hp

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
    send_net_event(lastOffender, [[EventOnVehicleDamaged offender=player, vehicle=eid, damage=vehicle__maxHp, hp=vehicle__hp, maxHp=vehicle__maxHp]])
