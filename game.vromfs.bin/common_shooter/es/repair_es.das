require ecs
require ecs.common
require dm
require DngDm
require math.base
require vehicle
require game.es.events
require game.events_game
require game.es.vehicle.vehicle_events
require common_shooter.events_common_shooter
require common_shooter.es.repair_common

def set_repairable_state(inProgress; operatorEid; targetEid; partId : int; repairTimeMult : float  = 1.f; recoveryRatioAdd : float = 0.f)
  query(targetEid) <| $ [es] (var maintainable__operator : EntityId&;
                              var repairable__repairTime : float&;
                              var repairable__repairTimeByPart : FloatList&;
                              var repairable__repairPart : int&;
                              var repairable__repairTotalTime : float&;
                              var repairable__inProgress : bool&;
                              var repairable__recoveryRatio : float&;
                              repairable__baseRepairTotalTime : float;
                              repairable__baseRecoveryRatio : float)
    maintainable__operator = operatorEid
    repairable__inProgress = inProgress
    repairable__repairPart = partId
    repairable__recoveryRatio = repairable__baseRecoveryRatio + recoveryRatioAdd
    if partId < 0
      return
    if repairable__repairTimeByPart[partId] <= 0.f && inProgress
      repairable__repairTotalTime = repairable__baseRepairTotalTime * repairTimeMult
      repairable__repairTimeByPart[partId] = repairable__repairTotalTime
      repairable__repairTime = repairable__repairTotalTime

def stop_repair(maintenance__target)
  set_repairable_state(false, INVALID_ENTITY_ID, maintenance__target, -1)
  return false


def use_repair_kit(maintainable__operator)
  query(maintainable__operator) <| $ [es] (var repair__active : bool&;
                                           repair__repairKit : EntityId)
    repair__active = false
    query(repair__repairKit) <| $ [es] (var repair_kit__useCounter : int&)
      repair_kit__useCounter += 1
    sendEvent(maintainable__operator, [[EventOnLootUse itemEid=repair__repairKit]])

[es(tag=server, track=(extinguisher__usesLeft, repair_kit__useCounter))]
def remove_used_repair_kit(evt : Event;
                           eid : EntityId;
                           item__ownerEid : EntityId;
                           extinguisher__usesLeft : int;
                           repair_kit__useCounter : int;
                           entity_mods__vehicleRepairUsagesPerKit : int = -1)
  query(item__ownerEid) <| $ [es] (var itemContainer : EidList&)
    if extinguisher__usesLeft <= 0 && repair_kit__useCounter > 0 && repair_kit__useCounter >= entity_mods__vehicleRepairUsagesPerKit
      let idx = itemContainer |> find_index(eid)
      if idx >= 0
        erase(itemContainer, idx)

def find_repair_kit(item_container : EidList; uses_per_kit : int)
  for itemEid in item_container
    let repairUses = get_int(itemEid, "repair_kit__useCounter")
    if repairUses != null && (*repairUses == 0 || *repairUses < uses_per_kit)
      return itemEid
  return INVALID_ENTITY_ID

def calculate_total_repair_count(item_container : EidList; uses_per_kit : int) : int
  var totalRepairCount = 0
  for itemEid in item_container
    let repairUses = get_int(itemEid, "repair_kit__useCounter")
    if repairUses != null && (*repairUses == 0 || *repairUses < uses_per_kit)
      totalRepairCount += uses_per_kit - *repairUses
  return totalRepairCount

[es(tag=server, on_appear, track=itemContainer)]
def check_item_container_has_repair_kit(evt : Event;
                                        itemContainer : EidList;
                                        entity_mods__vehicleRepairUsagesPerKit : int = -1;
                                        human_weap__gunEids : EidList;
                                        var repair__hasRepairKit : bool&;
                                        var repair__repairKit : EntityId&)
  repair__repairKit = find_repair_kit(itemContainer, entity_mods__vehicleRepairUsagesPerKit)
  repair__hasRepairKit = !!repair__repairKit
  for gunEid in human_weap__gunEids
    query(gunEid) <| $ [es] (repairKitWeapon : Tag const?;
                             var gun__ammo : int&)
      if repairKitWeapon != null
        gun__ammo = calculate_total_repair_count(itemContainer, entity_mods__vehicleRepairUsagesPerKit)

[es(tag=server, track=repair_kit__useCounter, on_appear)]
def track_repair_kit_uses(evt : Event; eid : EntityId; item__ownerEid : EntityId; repair_kit__useCounter : int)
  query(item__ownerEid) <| $ [es] (itemContainer : EidList;
                                   entity_mods__vehicleRepairUsagesPerKit : int = -1;
                                   human_weap__gunEids : EidList;
                                   var repair__hasRepairKit : bool&;
                                   var repair__repairKit : EntityId&)
    if repair__repairKit == eid && repair_kit__useCounter > 0 && repair_kit__useCounter >= entity_mods__vehicleRepairUsagesPerKit
      repair__repairKit = find_repair_kit(itemContainer, entity_mods__vehicleRepairUsagesPerKit)
      repair__hasRepairKit = !!repair__repairKit
    for gunEid in human_weap__gunEids
      query(gunEid) <| $ [es] (repairKitWeapon : Tag const?;
                               var gun__ammo : int&)
        if repairKitWeapon != null
          gun__ammo = calculate_total_repair_count(itemContainer, entity_mods__vehicleRepairUsagesPerKit)

[es(tag=server, on_appear, REQUIRE=repairKitWeapon)]
def total_repair_count_on_weapon_appear(evt : Event;
                                        gun__owner : EntityId;
                                        var gun__ammo : int&)
  query(gun__owner) <| $ [es] (itemContainer : EidList;
                               entity_mods__vehicleRepairUsagesPerKit : int = -1)
    gun__ammo = calculate_total_repair_count(itemContainer, entity_mods__vehicleRepairUsagesPerKit)

def check_repair_require(damage_model : DamageModel&;
                         dm_parts__canRepair : BoolList;
                         dm_parts__considerAsAliveThreshold : float)
  for i, canRepair in iter_range(dm_parts__canRepair), dm_parts__canRepair
    if !canRepair
      continue
    assume part = damage_model.dmData.parts[i]
    if uint(part.relHpFixed) < uint(dm_parts__considerAsAliveThreshold * float(MAX_REL_HP_FIXED))
      return true
  return false

[es(tag=server)]
def need_repair_check_on_part_damaged_es(evt : EventOnPartDamaged;
                                         damage_model : DamageModel&;
                                         dm_parts__canRepair : BoolList;
                                         var repairable__repairRequired : bool&;
                                         dm_parts__considerAsAliveThreshold : float = 0.9)
  repairable__repairRequired ||= check_repair_require(damage_model, dm_parts__canRepair, dm_parts__considerAsAliveThreshold)

[es(tag=server, after=damage_model_es)]
def need_repair_check_on_volumetric_damaged_es(evt : EventOnVolumetricDamage;
                                               damage_model : DamageModel&;
                                               dm_parts__canRepair : BoolList;
                                               var repairable__repairRequired : bool&;
                                               dm_parts__considerAsAliveThreshold : float = 0.9)
  repairable__repairRequired ||= check_repair_require(damage_model, dm_parts__canRepair, dm_parts__considerAsAliveThreshold)

[es(tag=server)]
def need_repair_check_on_meta_part_damage_es(evt : EventOnMetaPartDamage; var repairable__repairRequired : bool&)
  if evt.damage > 0.f
    repairable__repairRequired = true

[es(tag=server)]
def repair_es(evt : CmdStartRepair;
              eid : EntityId;
              var repair__active : bool&;
              entity_mods__vehicleRepairTimeMult : float = 1.f;
              entity_mods__vehicleRepairRecoveryRatioAdd : float = 0.f)
  if evt.partId < 0
    return
  query(evt.target) <| $ [es] (damage_model : DamageModel;
                               dm_parts__repairPartGroupIds : UInt8List;
                               dm_parts__considerAsAliveThreshold : float = 0.9)
    let partGroup = dm_parts__repairPartGroupIds[evt.partId]
    if int(partGroup) > 0
      for i in range(length(dm_parts__repairPartGroupIds))
        if dm_parts__repairPartGroupIds[i] == partGroup
          assume part = damage_model.dmData.parts[i]
          if uint(part.relHpFixed) < uint(dm_parts__considerAsAliveThreshold * float(MAX_REL_HP_FIXED))
            repair__active = true
            //we want to init from first part in group, because timer isn't shared by the group
            set_repairable_state(true, eid, evt.target, i, entity_mods__vehicleRepairTimeMult, entity_mods__vehicleRepairRecoveryRatioAdd)
            return
    else
      assume part = damage_model.dmData.parts[evt.partId]
      if uint(part.relHpFixed) < uint(dm_parts__considerAsAliveThreshold * float(MAX_REL_HP_FIXED))
        repair__active = true
        set_repairable_state(true, eid, evt.target, evt.partId, entity_mods__vehicleRepairTimeMult, entity_mods__vehicleRepairRecoveryRatioAdd)

[es(REQUIRE=maintenance__target)]
def repair_stop_es(evt : CmdStopRepair; var repair__active : bool&)
  repair__active = stop_repair(evt.target)

[es(tag=server, no_order)]
def check_repairing_conditions(info : UpdateStageInfoAct;
                               maintenance__target : EntityId;
                               var repair__active : bool&;
                               transform aka operator_transform : float3x4;
                               repair__effectiveDistance : float;
                               maintenance__canMaintainVehicle : bool = true)
  if !repair__active
    return
  var isDistanceValid = false
  if maintenance__canMaintainVehicle
    query(maintenance__target) <| $ [es] (transform aka target_transform : float3x4)
      isDistanceValid = length_sq(target_transform[3] - operator_transform[3]) < square(repair__effectiveDistance)
  if !isDistanceValid || !maintenance__canMaintainVehicle
    repair__active = stop_repair(maintenance__target)

[es(tag=server, before=find_maintainable_object_event)]
def stop_repairing_on_enter_vehicle_es(evt : EventEnterVehicle;
                                       maintenance__target : EntityId;
                                       var maintenance__hasTarget : bool&;
                                       var repair__active : bool&;
                                       isInVehicle = false)
  if !isInVehicle || !repair__active
    return
  repair__active = stop_repair(maintenance__target)
  maintenance__hasTarget = false

[es(tag=server, no_order)]
def repair_external_es(info : UpdateStageInfoAct;
                       eid : EntityId;
                       var damage_model : DamageModel&;
                       var fire_protection : FireProtection&;
                       repairable__recoveryRatio : float;
                       maintainable__operator : EntityId;
                       repairable__repairPart : int;
                       dm_parts__canRepair : BoolList;
                       dm_parts__repairPartGroupIds : UInt8List;
                       var repairable__repairTime : float&;
                       var repairable__repairTimeByPart : FloatList&;
                       var repairable__inProgress : bool&;
                       var repairable__repairRequired : bool&;
                       dm_parts__considerAsAliveThreshold : float = 0.9)
  if repairable__repairPart < 0 || !maintainable__operator || !repairable__inProgress
    return

  repairable__repairTime = repairable__repairTimeByPart[repairable__repairPart]
  if repairable__repairTime <= 0.f
    return

  repairable__repairTimeByPart[repairable__repairPart] -= info.dt
  if repairable__repairTimeByPart[repairable__repairPart] > 0.f
    return

  repairable__inProgress = false
  let partGroup = dm_parts__repairPartGroupIds[repairable__repairPart]
  if int(partGroup) > 0
    for i in range(length(dm_parts__repairPartGroupIds))
      if dm_parts__repairPartGroupIds[i] == partGroup
        repair_vehicle_part(repairable__recoveryRatio, i, damage_model, fire_protection)
  else
    repair_vehicle_part(repairable__recoveryRatio, repairable__repairPart, damage_model, fire_protection)

  repairable__repairRequired = check_repair_require(damage_model, dm_parts__canRepair, dm_parts__considerAsAliveThreshold)
  use_repair_kit(maintainable__operator)
  sendEvent(maintainable__operator, [[CmdStopRepair target=eid]])
  sendEvent(eid, [[CmdStopBurn]])
  sendEvent(eid, [[EventOnRepaired eid=maintainable__operator]])

[es(on_event=EventOnRepaired)]
def on_repair_phys_wakeup_es(evt : Event; var vehicle_net_phys : VehiclePhysActor)
  vehicle_net_phys.phys |> wakeUp()
