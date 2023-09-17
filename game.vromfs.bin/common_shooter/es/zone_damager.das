require ecs
require ecs.common
require math.base
require dm
require DngDm
require zones
require game.utils.team
require DagorSystem
require Grid
require GridCollision
require DagorMath
require game.es.voxel.voxel_grid_common
require AnimV20
require GeomNodeTree

let ZERO_MULT = 0.001 //To avoid division by zero problem when multipliers are removed 0 = 0.001

def is_friendly_damage(victim_eid, offender_eid : EntityId; victim_team : int) : bool
  if offender_eid == INVALID_ENTITY_ID || victim_eid == offender_eid
    return false
  let offenderTeam = get_int(offender_eid, "team") ?? TEAM_UNASSIGNED
  return offenderTeam == victim_team


def burn_damage(cur_time, dt : float; victim_eid, offender_eid : EntityId; victim_team : int; victim_pos : float3;
                fire_affect, fire_start_time : float; gun_props_id, shell_id : int)
  ecs::query(victim_eid) <| $ [es] (var burning__isBurning : bool&;
                                    var burning__offender : EntityId&;
                                    var burning__tickIncrement : float&;
                                    var burning__offenderGunPropsId : int&;
                                    var burning__offenderShellId : int&;
                                    burning__friendlyDamagePerSecond : float = 0.0;
                                    burning__friendlyDamageProtectionTime : float = 3.0;
                                    entity_mods__fireDamageMult : float = 1.0)
    let isFriendlyDamageTime = fire_start_time >= 0.0 && cur_time < fire_start_time + burning__friendlyDamageProtectionTime
    if isFriendlyDamageTime && is_friendly_damage(victim_eid, offender_eid, victim_team)
      let friendlyDamage = burning__friendlyDamagePerSecond * dt * entity_mods__fireDamageMult
      let ddesc = DamageDesc(DamageType DM_FIRE, friendlyDamage, victim_pos)
      damage_entity(victim_eid, offender_eid, ddesc)
    else
      let fireDamage = fire_affect * dt * entity_mods__fireDamageMult
      if fireDamage <= 0.0
        return

      burning__isBurning = true
      burning__offender = offender_eid
      burning__tickIncrement = max(burning__tickIncrement, fireDamage)
      burning__offenderGunPropsId = gun_props_id
      burning__offenderShellId = shell_id


def dmgzone_check_visitor(zone_eid, visitor_eid, offender_eid : EntityId;
                          curTime, dt, dmgzone_damage, dmgzone_fireAffect, fire_source__startTime : float;
                          gun_props_id, shell_id, team_to_damage, damage_type_id : int;
                          damage_in_vehicle : bool; ignore_fire_resistance : bool;
                          dmgzone__doNotDamageUnderwater : Tag const?;
                          var eids_in_zone : EidList?)
  ecs::query(visitor_eid) <| $ [es(REQUIRE=dmgzoneVulnerable, REQUIRE_NOT=deadEntity)] (transform : float3x4;
                                                                                        isInVehicleHidden : bool = false;
                                                                                        team : int = TEAM_UNASSIGNED;
                                                                                        game_effect__invisible : bool = false;
                                                                                        entity_mods__zoneDamageMult : float = 1.0;
                                                                                        human_net_phys__isUnderwater : bool = false;
                                                                                        dmgzone_fire_resistance__maxTicks : int = 0;
                                                                                        var dmgzone_fire_resistance__currentTicks : int&;
                                                                                        var dmgzone_fire_resistance__lastTickAt : float&)
    if !damage_in_vehicle && isInVehicleHidden
      return
    if team_to_damage != TEAM_UNASSIGNED && team_to_damage != team
      return
    if human_net_phys__isUnderwater && dmgzone__doNotDamageUnderwater != null
      return
    if game_effect__invisible && offender_eid |> has("dmgzone__ignoreInvisibleTargets")
      return

    if !check_voxel_grid(zone_eid, visitor_eid)
      return

    if eids_in_zone != null
      *eids_in_zone |> push(visitor_eid)

    if dmgzone_damage > 0.0 && entity_mods__zoneDamageMult > ZERO_MULT
      let damage = dmgzone_damage * dt * entity_mods__zoneDamageMult
      var ddesc = DamageDesc(DamageType(damage_type_id), damage, transform[3])
      ddesc.gunPropsId = int16(gun_props_id)
      ddesc.shellId = int16(shell_id)
      damage_entity(visitor_eid, offender_eid, ddesc)

    if ignore_fire_resistance || dmgzone_fireAffect > 0.0 && dmgzone_fire_resistance__currentTicks >= 0 //check is human dry
      dmgzone_fire_resistance__currentTicks += 1
      dmgzone_fire_resistance__lastTickAt = curTime
      let shouldDamage = ignore_fire_resistance || dmgzone_fire_resistance__maxTicks < dmgzone_fire_resistance__currentTicks

      if shouldDamage
        burn_damage(curTime, dt, visitor_eid, offender_eid, team, transform[3],
                    dmgzone_fireAffect, fire_source__startTime, gun_props_id, shell_id)

def check_voxel_grid(zone_eid : EntityId; victim_eid : EntityId)
  var res = true
  query(zone_eid) <| $ [es] (transform : float3x4;
                             voxel_grid__resolution : int;
                             voxel_grid__step : float;
                             voxel_grid__voxels : BoolList;
                             voxel_grid_init__inProgress : Tag const?)
    res = false
    if voxel_grid_init__inProgress != null
      return
    query(victim_eid) <| $ [es] (animchar : AnimcharBaseComponent;
                                 dmgzone__voxelVictimNodeIds : IntList)
      for nodeId in dmgzone__voxelVictimNodeIds
        let pos = geomtree_getNodeWpos(*animchar.nodeTree, nodeId)
        let voxelIndex = get_voxel_index(transform, pos, voxel_grid__resolution, voxel_grid__step)
        res ||= voxelIndex >= 0 && voxel_grid__voxels[voxelIndex]
  return res

[es(tag=server, on_appear)]
def dmgzone_init_victim_voxel_nodes(evt : Event;
                                    eid : EntityId;
                                    animchar : AnimcharBaseComponent;
                                    dmgzone__voxelVictimNodes : StringList;
                                    var dmgzone__voxelVictimNodeIds : IntList&)
  for node in dmgzone__voxelVictimNodes
    peek(node) <| $(nodeName : string const#)
      let nodeId = geomtree_findNodeIndex(*animchar.nodeTree, nodeName)
      if nodeId < 0
        logerr("Invalid node for voxel dmgzone victim {getEntityTemplateName(eid)}: {nodeName}")
      else
        dmgzone__voxelVictimNodeIds |> push(nodeId)

[es(tag=server, on_appear, before=init_voxel_grid)]
def dmgzone_init_voxel_grid_resolution(evt : Event;
                                       sphere_zone__radius : float;
                                       voxel_grid__step : float;
                                       dmgzone__maxRadius : float = 0.;
                                       var voxel_grid__resolution : int&)
  let radius = dmgzone__maxRadius > 0.0 ? dmgzone__maxRadius : sphere_zone__radius
  voxel_grid__resolution = floori(safediv(radius, voxel_grid__step)) * 2

[es(tag=server, before=fire_damage)]
def dmgzone_es(info : UpdateStageInfoAct;
               eid aka zone_eid : EntityId;
               transform : float3x4;
               dmgzone__damage : float;
               var dmgzone__lastUpdate : float&;
               var dmgzone__eidsInZone : EidList?;
               dmgzone__igniteEntitiesInitially : Tag const?;
               dmgzone__doNotDamageUnderwater : Tag const?;
               dmgzone__updateInterval : float = 1.0;
               dmgzone__teamToDamage : int = TEAM_UNASSIGNED;
               dmgzone__damageInVehicle : bool = true;
               dmgzone__fireAffect : float = -1.0;
               dmgzone__offender : EntityId const?;
               dm__damageTypeId : int = int(DamageType DM_ZONE);
               fire_source__startTime : float = -1.0;
               dmgzone__gunPropsId : int = -1;
               dmgzone__shellId : int = -1;
               sphere_zone__radius : float;
               sphere_zone__inverted : bool = false)
  var dt : float
  var ignoreFireResistance = false

  if dmgzone__lastUpdate > 0.f
    dt = info.curTime - dmgzone__lastUpdate
    if dt < dmgzone__updateInterval
      return
    dmgzone__lastUpdate = info.curTime
  else // initial update
    dmgzone__lastUpdate = info.curTime + dmgzone__updateInterval * eid_frnd(eid)
    if dmgzone__igniteEntitiesInitially != null
      ignoreFireResistance = true
      dt = 0.001 // this causes fire damage to be greater than 0
    else
      return

  if dmgzone__eidsInZone != null
    *dmgzone__eidsInZone |> clear()
  let offenderEid = dmgzone__offender ?? eid

  if !sphere_zone__inverted
    for_each_entity_in_grid(ecs_hash("humans"), BSphere3(transform[3], sphere_zone__radius), GridEntCheck BOUNDING) <| $(visitorEid : EntityId)
      dmgzone_check_visitor(zone_eid, visitorEid, offenderEid,
                            info.curTime, dt, dmgzone__damage, dmgzone__fireAffect, fire_source__startTime,
                            dmgzone__gunPropsId, dmgzone__shellId, dmgzone__teamToDamage, dm__damageTypeId,
                            dmgzone__damageInVehicle, ignoreFireResistance, dmgzone__doNotDamageUnderwater, dmgzone__eidsInZone)
  else
    let invTm = inverse(transform)
    let zoneRadiusSq = square(sphere_zone__radius)
    ecs::query() <| $ [es(REQUIRE=dmgzoneVulnerable, REQUIRE_NOT=deadEntity)] (eid : EntityId; transform : float3x4)
      if sphere_zone__inverted == (length_sq(invTm * transform[3]) < zoneRadiusSq)
        return
      dmgzone_check_visitor(zone_eid, eid, offenderEid,
                            info.curTime, dt, dmgzone__damage, dmgzone__fireAffect, fire_source__startTime,
                            dmgzone__gunPropsId, dmgzone__shellId, dmgzone__teamToDamage, dm__damageTypeId,
                            dmgzone__damageInVehicle, ignoreFireResistance, dmgzone__doNotDamageUnderwater, dmgzone__eidsInZone)


[es(tag=server, tag=dev, on_appear, REQUIRE=box_zone, REQUIRE=dmgzone__damage)]
def logerr_on_box_dmgzone_es(evt : Event)
  logerr("dmgzone with box_zone is not implemented")


[es(tag=server, tag=dev, on_appear, REQUIRE=box_zone__boxMin, REQUIRE=dmgzone__damage)]
def logerr_on_relative_box_dmgzone_es(evt : Event)
  logerr("dmgzone with relitive box zone is not implemented")


[es(tag=server, tag=dev, on_appear, REQUIRE=battleAreaPoints, REQUIRE=dmgzone__damage)]
def logerr_on_poly_dmgzone_es(evt : Event)
  logerr("dmgzone with poly zone is not implemented")
