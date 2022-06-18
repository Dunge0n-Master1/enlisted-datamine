require ecs
require ecs.common
require dm
require EnlistedDm
require math.base
require vehicle
require game.es.events
require game.events_game
require game.es.vehicle.vehicle_events
require common_shooter.events_common_shooter
require common_shooter.es.repair_common

def find_repair_kit(itemContainer)
  for itemEid in itemContainer
    if has(itemEid, "item__isRepairTool")
      return itemEid
  return INVALID_ENTITY_ID


def set_repairable_state(inProgress; operatorEid; targetEid; repairTimeMult : float  = 1.f; recoveryRatioAdd : float = 0.f)
  query(targetEid) <| $ [es] (var maintainable__operator : EntityId&;
                              var repairable__repairTime : float&;
                              var repairable__repairTotalTime : float&;
                              var repairable__inProgress : bool&;
                              var repairable__recoveryRatio : float&;
                              repairable__baseRepairTotalTime : float;
                              repairable__baseRecoveryRatio : float)
    maintainable__operator = operatorEid
    repairable__inProgress = inProgress
    repairable__recoveryRatio = repairable__baseRecoveryRatio + recoveryRatioAdd
    if repairable__repairTime < 0.f && inProgress
      repairable__repairTotalTime = repairable__baseRepairTotalTime * repairTimeMult
      repairable__repairTime = repairable__repairTotalTime


def stop_repair(maintenance__target)
  set_repairable_state(false, INVALID_ENTITY_ID, maintenance__target)
  return false


def use_repair_kit(maintainable__operator)
  ecs::query(maintainable__operator) <| $ [es] (var repair__active : bool&;
                                                var repair__repairKit : EntityId&;
                                                var repair__hasRepairKit : bool&;
                                                var itemContainer : EidList&;
                                                entity_mods__vehicleRepairUsagesPerKit = -1;
                                                possessedByPlr = INVALID_ENTITY_ID)
    repair__active = false
    let idx = find_index(itemContainer, repair__repairKit)
    if idx == -1
      return
    var isFullyUsed = false
    ecs::query(repair__repairKit) <| $ [es] (var repair_kit__useCounter : int&)
      isFullyUsed = entity_mods__vehicleRepairUsagesPerKit <= ++repair_kit__useCounter
    sendEvent(maintainable__operator, [[EventOnLootUse itemEid=repair__repairKit]])
    sendEvent(possessedByPlr, [[EventPlayerOnLootUse entityToUse=repair__repairKit]])
    if !isFullyUsed
      return
    destroyEntity(repair__repairKit)
    erase(itemContainer, idx)
    repair__repairKit = find_repair_kit(itemContainer)
    repair__hasRepairKit = !!repair__repairKit

[es(on_appear)]
def repair_kit_owner_init_es(evt : Event;
                             itemContainer : EidList;
                             var repair__hasRepairKit : bool&;
                             var repair__repairKit : EntityId&)
  repair__repairKit = find_repair_kit(itemContainer)
  repair__hasRepairKit = !!repair__repairKit

[es]
def pickup_repair_kit_on_drop_es(evt : EventOnLootDrop;
                                 itemContainer : EidList;
                                 var repair__hasRepairKit : bool&;
                                 var repair__repairKit : ecs::EntityId&)
  if evt.itemEid == repair__repairKit
    repair__repairKit = find_repair_kit(itemContainer)
    repair__hasRepairKit = !!repair__repairKit

[es]
def pickup_repair_kit_on_pickup_es(evt : EventOnLootPickup;
                                   var repair__hasRepairKit : bool&;
                                   var repair__repairKit : ecs::EntityId&)
  if !repair__hasRepairKit && has(evt.itemEid, "item__isRepairTool")
    repair__hasRepairKit = true
    repair__repairKit = evt.itemEid

[es(on_event=EventComponentChanged, on_appear, track=item__ownerEid, REQUIRE=item__isRepairTool, tag=server)]
def repair_kit_init_es(evt : Event; eid : EntityId; item__ownerEid : EntityId)
  ecs::query(item__ownerEid) <| $ [es] (var repair__hasRepairKit : bool&; var repair__repairKit : EntityId&)
    repair__hasRepairKit = true
    repair__repairKit = eid

[es(tag=server)]
def need_repair_check_on_part_damaged_es(evt : EventOnPartDamaged; var repairable__repairRequired : bool&)
  if int(evt.hpFixed) == 0
    repairable__repairRequired = true

[es(tag=server)]
def need_repair_check_on_volumetric_damaged_es(evt : EventOnVolumetricDamage; var repairable__repairRequired : bool&)
  for part in evt.damagedParts
    if get_int(get_ecs_object(part), "hpFixed") ?? -1 == 0
      repairable__repairRequired = true
      break

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
  repair__active = true
  set_repairable_state(true, eid, evt.target, entity_mods__vehicleRepairTimeMult, entity_mods__vehicleRepairRecoveryRatioAdd)

[es(REQUIRE=maintenance__target)]
def repair_stop_es(evt : CmdStopRepair; var repair__active : bool&)
  repair__active = stop_repair(evt.target)

[es(tag=server, no_order)]
def check_repairing_distance_es(info : UpdateStageInfoAct;
                                maintenance__target : EntityId;
                                var repair__active : bool&;
                                transform : float3x4;
                                repair__effectiveDistance : float)
  if !repair__active
    return
  var targetPosition : float3
  ecs::query(maintenance__target) <| $ [es] (transform : float3x4)
    targetPosition = transform[3]
  if length_sq(targetPosition - transform[3]) > square(repair__effectiveDistance)
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
                       var meta_parts_state : MetaPartsState&;
                       var fire_protection : FireProtection&;
                       repairable__recoveryRatio : float;
                       maintainable__operator : EntityId;
                       var repairable__repairTime : float&;
                       var repairable__inProgress : bool&;
                       var repairable__repairRequired : bool&)
  if !maintainable__operator || repairable__repairTime < 0.f
    return
  repairable__repairTime = repairable__repairTime - info.dt
  if repairable__repairTime > 0.f
    return
  repairable__inProgress = false
  repairable__repairRequired = false
  repair_vehicle(repairable__recoveryRatio, meta_parts_state, damage_model, fire_protection)
  use_repair_kit(maintainable__operator)
  sendEvent(maintainable__operator, [[CmdStopRepair target=eid]])
  sendEvent(eid, [[CmdStopBurn]])
  sendEvent(eid, [[EventOnRepaired eid=maintainable__operator]])

[es(on_event=EventOnRepaired)]
def on_repair_phys_wakeup_es(evt : Event; var vehicle_net_phys : VehiclePhysActor)
  vehicle_net_phys.phys |> wakeUp()
