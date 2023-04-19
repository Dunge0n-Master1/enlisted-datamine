require ecs
require app
require math.base
require game.es.events
require game.events_game
require enlisted.events_enlisted
require DagorMath
require AnimV20
require CollRes
require DngNet
require DngShip
require vehicle
require Dacoll


def get_gravity_scale()
  var result = 1.0
  find_query() <| $ [es] (phys_props__gravity : float; phys_props__initialGravity : float)
    result = safediv(phys_props__gravity, phys_props__initialGravity)
    return true
  return result


[es]
def push_object_req(evt : CmdPushObject;
                    isAlive : bool;
                    isDowned : bool;
                    isInVehicle : bool;
                    var push_object__target : EntityId&;
                    var push_object__nextPushTime : float&)
  push_object__target = INVALID_ENTITY_ID

  if !isAlive || isDowned || isInVehicle || !evt.target
    return

  if has(evt.target, "vehicle_net_phys") || has(evt.target, "ship_net_phys")
    push_object__target = evt.target
    push_object__nextPushTime = get_sync_time()


def can_push_object(human_tm : float3x4;
                    can_push_radius : float;
                    push_object_tm : float3x4;
                    push_object_collres : CollisionResource;
                    push_object_animchar : AnimcharBaseComponent;
                    push_object_ship_net_phys : ShipActor const?;
                    push_object_vehicle_net_phys : VehiclePhysActor const?)
  let humanCenter = human_tm[3]
  let traceStart = humanCenter
  let traceDir = normalize(push_object_tm[3] - traceStart)

  var t = can_push_radius
  var norm : float3
  var matId = -1
  if !collres_traceray(push_object_collres, push_object_tm, traceStart, traceDir, t, norm, matId) || t >= can_push_radius
    return false

  let downTraceT = 2.0
  let downDir = float3(0.0, -1.0, 0.0)
  if collres_rayhit(push_object_collres, push_object_tm, push_object_animchar.nodeTree, humanCenter, downDir, downTraceT)
    return false

  return push_object_vehicle_net_phys != null || push_object_ship_net_phys != null


[es(tag=server, no_order, REQUIRE_NOT=deadEntity)]
def push_object_update_server(info : UpdateStageInfoAct;
                              isDowned : bool;
                              isInVehicle : bool;
                              transform aka human_transform : float3x4;
                              push_object__pushDelay : float;
                              push_object__canPushRadius : float;
                              push_object__pushOffset = float3(0f, 0.2, 0f);
                              var push_object__target : EntityId&;
                              var push_object__nextPushTime : float&)
  if !push_object__target || info.curTime < push_object__nextPushTime
    return

  if isDowned || isInVehicle
    push_object__target = INVALID_ENTITY_ID
    return

  push_object__nextPushTime += push_object__pushDelay

  query(push_object__target) <| $ [es] (transform : float3x4;
                                        collres : CollisionResource;
                                        animchar : AnimcharBaseComponent;
                                        push_object__energyScale : float;
                                        ship_net_phys : ShipActor const?;
                                        vehicle_net_phys : VehiclePhysActor const?)
    if can_push_object(human_transform, push_object__canPushRadius, transform, collres, animchar, ship_net_phys, vehicle_net_phys)
      let dir = human_transform[0]
      let center = human_transform[3]
      let pushPos = center + push_object__pushOffset

      sendEvent(push_object__target, [[CmdVehiclePushPhys
        energyScaledDir=dir * push_object__energyScale * get_gravity_scale(),
        arm=pushPos,
        duration=0.0
      ]])


[es(tag=gameClient, REQUIRE=watchedByPlr, REQUIRE_NOT=deadEntity)]
def push_object_update_client(info : ParallelUpdateFrameDelayed;
                              isDowned : bool;
                              isInVehicle : bool;
                              useActionEid : EntityId;
                              transform aka human_transform : float3x4;
                              push_object__target : EntityId;
                              push_object__pushDelay : float;
                              push_object__canPushRadius : float;
                              var push_object__canPush : bool&;
                              var push_object__nextPushTime : float&)
  if !!push_object__target || info.curTime < push_object__nextPushTime
    return

  push_object__nextPushTime += push_object__pushDelay
  push_object__canPush = false

  if !useActionEid || isDowned || isInVehicle
    return

  query(useActionEid) <| $ [es(REQUIRE=push_object__energyScale)] (transform : float3x4;
                                                                   collres : CollisionResource;
                                                                   animchar : AnimcharBaseComponent;
                                                                   ship_net_phys : ShipActor const?;
                                                                   vehicle_net_phys : VehiclePhysActor const?)
    if can_push_object(human_transform, push_object__canPushRadius, transform, collres, animchar, ship_net_phys, vehicle_net_phys)
      push_object__canPush = true
