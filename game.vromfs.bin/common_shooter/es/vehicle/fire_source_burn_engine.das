require ecs
require DagorMath
require AnimV20
require dm
require math.base
require CollRes
require game.utils.team
require EnlistedDm
require common_shooter.es.vehicle.vehicle_damage_common

def should_fire_affect_engine_at_pos(collres : CollisionResource;
                                     animchar : AnimcharBaseComponent;
                                     transform : float3x4;
                                     damage_model : DamageModel;
                                     dm_phys_parts__enginePartIds : IntList;
                                     fire_pos : float3;
                                     radius : float) : bool
  let radiusSq = square(radius)
  for partId in dm_phys_parts__enginePartIds
    let collisionNodeId = damage_model.dmData.parts[partId].collisionNodeId
    let node = collres_get_node(collres, collisionNodeId)
    if node == null
      continue
    var engineTm : float3x4
    collres_get_collision_node_tm(collres, collisionNodeId, transform, animchar.nodeTree, engineTm)
    let engineBoundingSphere = (*node).boundingSphere
    let enginePos = engineTm * engineBoundingSphere.c

    if fire_pos.y > enginePos.y && length_sq(enginePos.xz - fire_pos.xz) < radiusSq
      return true
  return false


[es(tag=server, REQUIRE=fire_source, on_appear)]
def fire_source_damage_engine_add(evt : Event;
                                  node_attached__entity : EntityId;
                                  transform : float3x4;
                                  dmgzone__burningOffender : EntityId = INVALID_ENTITY_ID)
  let fireTeam = get_int(dmgzone__burningOffender, "team") ?? TEAM_UNASSIGNED
  let firePos = transform[3]
  query(node_attached__entity) <| $ [es] (team : int;
                                          animchar : AnimcharBaseComponent;
                                          transform : float3x4;
                                          collres : CollisionResource;
                                          damage_model : DamageModel;
                                          dm_phys_parts__enginePartIds : IntList;
                                          attached_fire__engineAffectRadius : float;
                                          var attached_fire__isEngineAffected : bool&;
                                          var attached_fire__offender : EntityId&)
    let radius = attached_fire__engineAffectRadius
    if attached_fire__isEngineAffected
      return
    let shouldAffectEngine = (!is_teams_friendly(fireTeam, team) &&
      should_fire_affect_engine_at_pos(collres, animchar, transform, damage_model, dm_phys_parts__enginePartIds, firePos, radius))
    if shouldAffectEngine
      attached_fire__isEngineAffected = true
      attached_fire__offender = dmgzone__burningOffender

[es(tag=server, REQUIRE=fire_source, on_disappear)]
def fire_source_damage_engine_remove(evt : Event; eid : EntityId; node_attached__entity : ecs::EntityId)
  let wasAttachedTo = node_attached__entity
  let removedEid = eid
  query(node_attached__entity) <| $ [es] (var attached_fire__isEngineAffected : bool&;
                                          team : int;
                                          animchar : AnimcharBaseComponent;
                                          transform : float3x4;
                                          collres : CollisionResource;
                                          damage_model : DamageModel;
                                          dm_phys_parts__enginePartIds : IntList;
                                          attached_fire__engineAffectRadius : float)
    let vehicleTransform = transform
    let vehicleTeam = team
    attached_fire__isEngineAffected = find_query() <| $ [es(REQUIRE=fire_source)] (eid : EntityId;
                                                                                   node_attached__entity : EntityId;
                                                                                   transform : float3x4;
                                                                                   dmgzone__burningOffender : EntityId = INVALID_ENTITY_ID)
      let fireTeam = get_int(dmgzone__burningOffender, "team") ?? TEAM_UNASSIGNED
      let radius = attached_fire__engineAffectRadius
      return (eid != removedEid
              && wasAttachedTo == node_attached__entity
              && !is_teams_friendly(vehicleTeam, fireTeam)
              && should_fire_affect_engine_at_pos(collres, animchar, vehicleTransform, damage_model, dm_phys_parts__enginePartIds, transform[3], radius))

[es(tag=server, no_order)]
def fire_source_damage_engine(info : UpdateStageInfoAct;
                              eid : EntityId;
                              dm_phys_parts__enginePartIds : IntList;
                              attached_fire__isEngineAffected : bool;
                              attached_fire__offender : EntityId;
                              attached_fire__updateInterval : float = 1.0;
                              attached_fire__engineDmgPerSec : float = 4.0;
                              fire_damage__fireParamsPreset : string;
                              var attached_fire__lastUpdate : float&;
                              var damage_model : DamageModel;
                              var fire_damage__isBurn : bool&;
                              var fire_damage : FireDamageComponent&)
  if !attached_fire__isEngineAffected || attached_fire__engineDmgPerSec <= 0.0
    attached_fire__lastUpdate = -1.0
    return
  if attached_fire__lastUpdate < 0.f // initial update
    attached_fire__lastUpdate = info.curTime
    return
  let dt = info.curTime - attached_fire__lastUpdate
  if dt < attached_fire__updateInterval
    return

  attached_fire__lastUpdate = info.curTime

  let damage = attached_fire__engineDmgPerSec * dt
  let dmgMask = 1 << int(DamageEffectType DM_EFFECT_NOTHING)
  for partId in dm_phys_parts__enginePartIds
    damage_model |> deal_damage_to_part(eid, partId, 0, dmgMask, damage, HitData())
    let damageFixed = uint(rel_hp_float_to_fixed_ceil(safediv(damage, get_max_hp(damage_model.dmData, partId))))
    let partHpFixed = uint(damage_model.dmData.parts[partId].relHpFixed)
    if partHpFixed > 0u && partHpFixed <= uint(damageFixed)
      vehicle_start_burn_part(eid, partId, attached_fire__offender, damage_model, fire_damage__fireParamsPreset, fire_damage__isBurn, fire_damage)
