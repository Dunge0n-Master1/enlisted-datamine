require ecs
require ecs.common
require game.utils.team
require EnlistedNet
require vehicle
require player
require math
require math.base
require game.es.events
require game.es.vehicle.vehicle_events
require AnimV20
require GeomNodeTree
require CollRes
require DagorSystem

[es(tag=gameClient, REQUIRE=input__enabled, no_order)]
def find_maintainable_object(info : UpdateStageInfoAct;
                             eid : EntityId;
                             bindedCamera : EntityId;
                             var maintenance__target : EntityId&;
                             var maintenance__hasTarget : bool&;
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
    ? geomtree_getNodeWpos(animchar.nodeTree, human_use_object__nodeId)
    : camTm[3])
  var t = human_use_object__useDist
  var newMaintenanceTarget = INVALID_ENTITY_ID
  find_query() <| $ [es(REQUIRE=maintainable__operator)] (eid : EntityId;
                                                          collres : CollisionResource;
                                                          transform : float3x4;
                                                          animchar : AnimcharBaseComponent;
                                                          team : int = TEAM_UNASSIGNED)
    var norm : float3
    if ((is_teams_friendly(team, maintainable_team) || maintainable_team == TEAM_UNASSIGNED || team == TEAM_UNASSIGNED) &&
        collres_traceray(collres, transform, animchar.nodeTree, tracePos, traceDir, t, norm))
      newMaintenanceTarget = eid
      return true
    return false
  if newMaintenanceTarget != maintenance__target
    if maintenance__target != INVALID_ENTITY_ID
      sendEvent(eid, [[CmdStopMaintenance target=maintenance__target]])
    maintenance__target = newMaintenanceTarget
  maintenance__hasTarget = maintenance__target != INVALID_ENTITY_ID

[es(tag=gameClient)]
def find_maintainable_object_event(evt : EventEnterVehicle;
                                   var maintenance__target : EntityId&;
                                   var maintenance__hasTarget : bool&)
  maintenance__target = INVALID_ENTITY_ID
  maintenance__hasTarget = false

[es(tag=server, REQUIRE=maintenance__target)]
def maintenance_net_start(evt : RequestStartMaintenance; eid : EntityId)
  send_net_event(eid, [[CmdStartMaintenance target=evt.target]])

[es(tag=server, REQUIRE=maintenance__target)]
def maintenance_net_stop(evt : RequestStopMaintenance; eid : EntityId)
  sendEvent(eid, [[CmdStopMaintenance target=evt.target]])

[es(tag=netClient)]
def request_start_maintenance_client(evt : CmdStartMaintenance; eid : EntityId; isInVehicle : bool)
  if isInVehicle
    return
  send_net_event(eid, [[RequestStartMaintenance target=evt.target]])

[es(tag=netClient)]
def request_stop_maintenance_client(evt : CmdStopMaintenance; eid : EntityId)
  send_net_event(eid, [[RequestStopMaintenance target=evt.target]])

[es(tag=server)]
def maintenance_dispatcher_start(evt : CmdStartMaintenance;
                                 eid : EntityId;
                                 var maintenance__target : EntityId&;
                                 repair__hasRepairKit : bool = true)
  maintenance__target = evt.target
  if !repair__hasRepairKit
    return
  let isBurn = get_bool(maintenance__target, "fire_damage__isBurn") ?? false
  if isBurn
    sendEvent(eid, [[CmdActivateExtinguisher eid=maintenance__target]])
    return
  let isNeedRepair = get_bool(maintenance__target, "repairable__repairRequired") ?? false
  if isNeedRepair && repair__hasRepairKit
    sendEvent(eid, [[CmdStartRepair target=maintenance__target]])

[es(tag=server, REQUIRE=maintenance__target)]
def maintenance_dispatcher_stop(evt : CmdStopMaintenance;
                                eid : EntityId;
                                extinguisher__active : bool = false;
                                repair__active : bool = false)
  if extinguisher__active
    sendEvent(eid, [[CmdStopExtinguisher eid=evt.target]])
  elif repair__active
    sendEvent(eid, [[CmdStopRepair target=evt.target]])
