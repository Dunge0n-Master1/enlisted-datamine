require ecs
require ecs.common
require game.utils.team
require DngNet
require vehicle
require player
require math
require math.base
require game.es.events
require game.es.vehicle.vehicle_events
require enlisted.events_enlisted
require AnimV20
require GeomNodeTree
require CollRes
require DngHuman
require DagorSystem
require HumanPhys
require danetlibs.native_dasevents.main.native_events
require common_shooter.events_common_shooter

[es(tag=gameClient, REQUIRE=input__enabled)]
def find_maintainable_object(info : ParallelUpdateFrameDelayed;
                             eid : EntityId;
                             bindedCamera : EntityId;
                             var maintenance__target : EntityId&;
                             var maintenance__hasTarget : bool&;
                             var maintenance__targetNeedsRepair : bool&;
                             var maintenance__targetNeedsExtinguishing : bool&;
                             human_net_phys__states : int;
                             human_use_object__nodeId : int;
                             human_use_object__useDist : float;
                             animchar : AnimcharBaseComponent;
                             input__enabled : bool;
                             team aka maintainable_team : int = TEAM_UNASSIGNED;
                             isInVehicle : bool = false)
  if !input__enabled || isInVehicle
    return
  let camTmRef = get_TMatrix(bindedCamera, "transform")
  if camTmRef == null
    return
  let camTm = *camTmRef
  let traceDir : float3 = camTm[2]
  let tracePos : float3 = (human_use_object__nodeId > 0
    ? geomtree_getNodeWpos(*animchar.nodeTree, human_use_object__nodeId)
    : camTm[3])
  var newMaintenanceTarget = INVALID_ENTITY_ID
  var needsRepair = false
  var needsExtinguisher = false
  find_query() <| $ [es(REQUIRE_NOT=deadEntity, REQUIRE=maintainable__operator)] (eid : EntityId;
                                                                                  collres : CollisionResource;
                                                                                  transform : float3x4;
                                                                                  animchar : AnimcharBaseComponent;
                                                                                  repairable__repairRequired : bool = false;
                                                                                  repairable__extinguishRequired : bool = false;
                                                                                  team : int = TEAM_UNASSIGNED)
    if ((is_teams_friendly(team, maintainable_team) || maintainable_team == TEAM_UNASSIGNED || team == TEAM_UNASSIGNED) &&
        collres_rayhit(collres, transform, animchar.nodeTree, tracePos, traceDir, human_use_object__useDist))
      newMaintenanceTarget = eid
      needsRepair = repairable__repairRequired
      needsExtinguisher = repairable__extinguishRequired
      return true
    return false


  let isHumanJumping = ((uint(human_net_phys__states) & uint(StateFlag ST_JUMP)) != 0u)
  let isMaintenanceInterrupted =  isHumanJumping
  let isNeedStopMaintenance = !!maintenance__target && (newMaintenanceTarget != maintenance__target || isMaintenanceInterrupted)
  if isNeedStopMaintenance
    sendEvent(eid, [[CmdStopMaintenance target=maintenance__target]])

  maintenance__target = isMaintenanceInterrupted ? INVALID_ENTITY_ID : newMaintenanceTarget

  maintenance__hasTarget = maintenance__target != INVALID_ENTITY_ID
  maintenance__targetNeedsRepair = needsRepair
  maintenance__targetNeedsExtinguishing = needsExtinguisher

[es(tag=server, on_appear, REQUIRE=maintenance__target, track=(isAlive, isDowned, isInVehicle, enter_vehicle__timerEnabled, burning__isBurning))]
def can_maintain_vehicle(event : Event;
                         isAlive : bool;
                         isDowned : bool;
                         isInVehicle : bool;
                         enter_vehicle__timerEnabled : bool;
                         burning__isBurning : bool;
                         var maintenance__canMaintainVehicle : bool&)
  maintenance__canMaintainVehicle = isAlive && !isDowned && !isInVehicle && !enter_vehicle__timerEnabled && !burning__isBurning

[es(tag=gameClient)]
def find_maintainable_object_event(evt : EventEnterVehicle;
                                   var maintenance__target : EntityId&;
                                   var maintenance__hasTarget : bool&)
  maintenance__target = INVALID_ENTITY_ID
  maintenance__hasTarget = false

[es(tag=server, REQUIRE=maintenance__target)]
def maintenance_net_start(evt : RequestStartMaintenance; eid : EntityId)
  sendEvent(eid, [[CmdStartMaintenance target=evt.target, partId=evt.partId]])

[es(tag=server, REQUIRE=maintenance__target)]
def maintenance_net_stop(evt : RequestStopMaintenance; eid : EntityId)
  sendEvent(eid, [[CmdStopMaintenance target=evt.target]])

[es(tag=netClient)]
def request_start_maintenance_client(evt : CmdStartMaintenance; eid : EntityId; isInVehicle : bool)
  if isInVehicle
    return
  send_net_event(eid, [[RequestStartMaintenance target=evt.target, partId=evt.partId]])

[es(tag=netClient)]
def request_stop_maintenance_client(evt : CmdStopMaintenance; eid : EntityId)
  send_net_event(eid, [[RequestStopMaintenance target=evt.target]])

[es(tag=server, on_appear, track=(fire_damage__isBurn, attached_fire__isAnyFireAttached))]
def update_extinguish_required(evt : Event;
                               fire_damage__isBurn : bool = false;
                               attached_fire__isAnyFireAttached : bool = false;
                               var repairable__extinguishRequired : bool&)
  repairable__extinguishRequired = fire_damage__isBurn || attached_fire__isAnyFireAttached

[es(tag=server)]
def maintenance_dispatcher_start(evt : CmdStartMaintenance;
                                 eid : EntityId;
                                 var maintenance__target : EntityId&;
                                 repair__hasRepairKit : bool = true;
                                 extinguisher__hasExtinguisher : bool = true)
  maintenance__target = evt.target
  query(maintenance__target) <| $ [es(REQUIRE_NOT=deadEntity)] (repairable__extinguishRequired : bool = false;
                                                                repairable__repairRequired : bool = false)
    let canRepair = repairable__repairRequired && repair__hasRepairKit
    if repairable__extinguishRequired
      if extinguisher__hasExtinguisher
        sendEvent(eid, [[CmdActivateExtinguisher eid=maintenance__target]])
      elif canRepair
        sendEvent(eid, [[CmdHeroLogEvent event="repair_blocked_by_fire", text="repair_blocked_by_fire"]])
    elif canRepair
      sendEvent(eid, [[CmdRepairKitWeaponUse target=maintenance__target, partId=evt.partId]])
    elif !repair__hasRepairKit
      sendEvent(eid, [[CmdHeroLogEvent event="repair_blocked_no_parts", text="repair_blocked_no_parts"]])


def find_repair_weapon_in_inventory(itemContainer : EidList)
  for itemEid in itemContainer
    if has(itemEid, "repairKitWeapon")
      return itemEid
  return INVALID_ENTITY_ID


[es(tag=server, on_appear, track=repair__hasRepairKit)]
def create_repair_kit_weapon(evt : Event;
                             eid : EntityId;
                             repair__hasRepairKit : bool;
                             itemContainer : EidList;
                             var repair__repairKitWeapCreated : bool&)
  if !repair__hasRepairKit || repair__repairKitWeapCreated
    return
  if !repair__repairKitWeapCreated && !find_repair_weapon_in_inventory(itemContainer)
    repair__repairKitWeapCreated = true
    createEntity("repair_kit_item_weapon") <| $(var init : ComponentsInitializer)
      set(init, "item__lastOwner", eid)
      set(init, "item__ownerEid", eid)
      set(init, "gun__owner", eid)

[es(on_event=CmdStartMaintenance)]
def maintenance_on_create_repair_weap(evt : Event;
                                      eid : EntityId;
                                      repair__hasRepairKit : bool;
                                      human_net_phys : HumanActor;
                                      itemContainer : EidList;
                                      human_weap__gunEids : EidList;
                                      var forcedNextInventoryGunEid : EntityId&)
  assume ct = human_net_phys.phys.producedCT
  assume specialWeapon = human_weap__gunEids[int(HUWeaponSlots EWS_SPECIAL)]

  if repair__hasRepairKit
    if ct.chosenWeapon != HUWeaponSlots EWS_SPECIAL
      sendEvent(eid, [[HumanWeapSetCurrentGun slot=uint8(HUWeaponSlots EWS_SPECIAL)]])
    if !has(specialWeapon, "repairKitWeapon")
      forcedNextInventoryGunEid = find_repair_weapon_in_inventory(itemContainer)
      send_net_event(eid, [[CmdNextSpecialGun]])

[es(tag=gameClient, on_disappear, REQUIRE=(watchedPlayerItem, repairKitWeapon))]
def maintenance_on_destroy_repair_weap(evt : Event;
                                       gun__owner : EntityId)
  query(gun__owner) <| $ [es] (human_net_phys : HumanActor;
                               human_weap__gunEids : ecs::EidList)
    assume ct = human_net_phys.phys.producedCT
    if ct.chosenWeapon != HUWeaponSlots EWS_SPECIAL
      return
    for i, gunEid in iter_range(human_weap__gunEids), human_weap__gunEids
      if !!gunEid
        sendEvent(gun__owner, [[HumanWeapSetCurrentGun slot=uint8(i)]])
        return

[es(tag=server)]
def maintenance_create_repair_weap(evt : CmdRepairKitWeaponUse;
                                   eid : EntityId;
                                   human_weap__currentGunEid : EntityId)
  if has(human_weap__currentGunEid, "repairKitWeapon")
    sendEvent(eid, [[CmdStartRepair target=evt.target, partId=evt.partId]])

[es(tag=server, REQUIRE=maintenance__target)]
def maintenance_dispatcher_stop(evt : CmdStopMaintenance;
                                eid : EntityId;
                                extinguisher__active : bool = false;
                                repair__active : bool = false)
  if extinguisher__active
    sendEvent(eid, [[CmdStopExtinguisher eid=evt.target]])
  elif repair__active
    sendEvent(eid, [[CmdStopRepair target=evt.target]])


[es(tag=gameClient, track=(repair__hasRepairKit, extinguisher__hasExtinguisher, maintenance__canMaintainVehicle, maintenance__targetNeedsExtinguishing, maintenance__targetNeedsRepair))]
def human_vehicle_maintenance_available(evt : Event;
                                        repair__hasRepairKit : bool;
                                        extinguisher__hasExtinguisher : bool;
                                        maintenance__canMaintainVehicle : bool;
                                        maintenance__targetNeedsExtinguishing : bool;
                                        maintenance__targetNeedsRepair : bool;
                                        var maintenance__isExtinguishAvailable : bool&;
                                        var maintenance__isRepairAvailable : bool&)
  maintenance__isExtinguishAvailable = maintenance__canMaintainVehicle && extinguisher__hasExtinguisher && maintenance__targetNeedsExtinguishing
  maintenance__isRepairAvailable = maintenance__canMaintainVehicle && repair__hasRepairKit && maintenance__targetNeedsRepair
