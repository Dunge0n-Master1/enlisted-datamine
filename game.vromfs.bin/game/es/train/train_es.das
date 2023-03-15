require ecs
require EnlistedNet
require math.base
require math.shooter_phys_common
require GamePhys
require CollRes
require DagorMath
require DagorConsole
require PhysObj
require EnlistedPhysObj
require EnlistedHuman
require EnlistedActor
require game.es.events
require enlisted.events_enlisted
require enlisted.game.es.train.train_common
require danetlibs.native_dasevents.main.native_events


def project_train_on_railroad(train_box : BBox3; train_orient : quat; train_pos, train_vel : float3) : tuple<orient : quat; pos : float3>
  let trainForward = quat_get_forward(train_orient)
  let forwardSign = dot(trainForward, train_vel) < 0. ? -1. : 1.
  let forward     = 0.4 * forwardSign * train_box.width.x * trainForward

  let projectedFwd  = project_on_railroad(train_pos + forward)
  let projectedBack = project_on_railroad(train_pos - forward)
  let projectedDir  = normalize(projectedFwd - projectedBack)

  let wishTrainPos  = 0.5 * (projectedBack + projectedFwd) + float3(0., -0.1, 0.)
  let wishTrainQuat = dir_to_quat(projectedDir)

  return [[auto wishTrainQuat, wishTrainPos]]


def calc_train_transform(var train_tm : float3x4; train_destination : float3)
  let trainPos = train_tm[3]
  let direction = normalize_default(train_destination - trainPos, float3(1., 0., 0.))
  dir_to_quat(direction) |> make_tm(train_tm)
  train_tm[3] = trainPos


[es(on_appear, REQUIRE=train, after=init_railroad, tag=server)]
def train_init_es(evt : Event;
                  eid : EntityId;
                  var transform aka train_transform : float3x4)
  query() <| $ [es(REQUIRE=trainDestination)] (transform : float3x4)
    train_transform |> calc_train_transform(transform[3])
    train_transform[3] = project_on_railroad(train_transform[3])

    teleport_phys_actor(eid, train_transform)


[es(tag=server, on_appear, after=train_init_es, REQUIRE=train__primaryCart)]
def train_init_role_server_es(evt : Event; var phys_obj_net_phys : PhysObjActor)
  let role = (is_true_net_server()
              ? NetRole ROLE_REMOTELY_CONTROLLED_AUTHORITY
              : NetRole ROLE_LOCALLY_CONTROLLED_AUTHORITY)
  phys_obj_net_phys |> base_phys_actor_setRoleAndTickrateType(role, PhysTickRateType Normal)


[es(tag=netClient, on_appear, after=train_init_es, REQUIRE=train__primaryCart)]
def train_init_role_client_es(evt : Event; var phys_obj_net_phys : PhysObjActor)
  phys_obj_net_phys |> base_phys_actor_setRoleAndTickrateType(NetRole ROLE_LOCALLY_CONTROLLED_SHADOW, PhysTickRateType Normal)


[es(on_appear, on_event=DebugReinitTrain, after=train_init_es, tag=server)]
def train_init_carts_es(evt : Event;
                        transform : float3x4;
                        train__primaryCartTemplate : string;
                        train__secondaryCartTemplate : string;
                        train__teamOffense : int;
                        train__teamDefense : int;
                        train__carts : Array;
                        train__offenseTeamAdvantageWeight : int;
                        train__defenseTeamAdvantageWeight : int;
                        var train__cartOffsets : FloatList;
                        var train__cartEids : EidList)
  var cartTm := transform
  var totalOffset = 0.
  var primaryCartEid = INVALID_ENTITY_ID
  for cart, cartNo in train__carts, range(length(train__carts))
    let cartObj = get_ecs_object(cart)
    if cartObj == null
      continue

    let cartTamplate = cartObj |> get_string("template", "")
    let cartOffset   = cartObj |> get_float("offset") ?? 0.

    cartTm[3] += cartTm[0] * cartOffset

    totalOffset += cartOffset

    let finalCartTemplate = "{cartTamplate}+{cartNo == 0 ? train__primaryCartTemplate : train__secondaryCartTemplate}"
    let cartEid = createEntity(finalCartTemplate) <| $(var init)
      init |> set("transform", cartTm)
      init |> set("train__teamOffense", train__teamOffense)
      init |> set("train__teamDefense", train__teamDefense)
      init |> set("train__offset", totalOffset)
      if cartNo != 0
        init |> set("train__primaryCartEid", primaryCartEid)
      else
        init |> set("train__offenseTeamAdvantageWeight", train__offenseTeamAdvantageWeight)
        init |> set("train__defenseTeamAdvantageWeight", train__defenseTeamAdvantageWeight)

    if cartNo == 0
      primaryCartEid = cartEid

    train__cartEids |> push(cartEid)
    train__cartOffsets |> push(cartOffset)

    let capzoneObj = cartObj |> get_ecs_object("capzone")
    if capzoneObj != null
      let capzoneTemplate = capzoneObj |> get_string("template", "")
      let capzoneScale = capzoneObj |> get_Point3("scale") ?? float3(1.)
      createEntity(capzoneTemplate) <| $(var init)
        init |> set("capzone__trainEid", cartEid)
        init |> set("capzone__trainOffenseTeam", train__teamOffense)
        init |> set("capzone__advantageTeam", train__teamOffense)
        using() <| $(var obj : Object)
          obj |> set("{train__teamOffense}", train__offenseTeamAdvantageWeight)
          obj |> set("{train__teamDefense}", train__defenseTeamAdvantageWeight)
          init |> set("capzone__advantageWeights", obj)

        var capzoneTm := cartTm
        capzoneTm[0] *= capzoneScale.x
        capzoneTm[1] *= capzoneScale.y
        capzoneTm[2] *= capzoneScale.z
        init |> set("transform", capzoneTm)

        let componnetsObj = capzoneObj |> get_ecs_object("components")
        if componnetsObj != null
          for kv in *componnetsObj
            init |> set(kv.key, kv.value)

    let trainObstacleObj = cartObj |> get_ecs_object("train_obstacle")
    if trainObstacleObj != null
      let trainObstacleTemplate = trainObstacleObj |> get_string("template", "")
      createEntity(trainObstacleTemplate) <| $(var init)
        init |> set("train_obstacle__trainEid", cartEid)
        init |> set("transform", cartTm)

        let componnetsObj = trainObstacleObj |> get_ecs_object("components")
        if componnetsObj != null
          for kv in *componnetsObj
            init |> set(kv.key, kv.value)

[es(tag=server, REQUIRE=train)]
def schedule_train_velocity_change_es(evt : CmdPostPhysUpdate;
                                      train__teamOffense : int;
                                      train__teamDefense : int;
                                      train__changeVelocityInterval : float;
                                      var train__changeVelocityCheckAtTime : float&;
                                      var train__offenseCount : int&;
                                      var train__defenseCount : int&;
                                      var train__changeVelocityPacked : int3&)
  let curTime = float(evt.tick) * evt.dt
  let changeVelocityAtTick = train__changeVelocityPacked.z
  if (curTime < train__changeVelocityCheckAtTime ||
      changeVelocityAtTick != 0) // don't schedule velocity change if previous didn't finish
    return

  train__changeVelocityCheckAtTime += train__changeVelocityInterval

  let wasOffenseCount = train__offenseCount
  let wasDefenseCount = train__defenseCount
  query() <| $ [es(REQUIRE=trainZone)] (teamPresence : Object)
    let offense = get_ecs_array(teamPresence, "{train__teamOffense}")
    let defense = get_ecs_array(teamPresence, "{train__teamDefense}")
    train__offenseCount = offense != null ? length(*offense) : 0
    train__defenseCount = defense != null ? length(*defense) : 0

  if train__offenseCount != wasOffenseCount || train__defenseCount != wasDefenseCount
    train__changeVelocityPacked.x = train__offenseCount
    train__changeVelocityPacked.y = train__defenseCount
    train__changeVelocityPacked.z = nearest_physics_tick_number(curTime + train__changeVelocityInterval, evt.dt)

[es(REQUIRE=train)]
def adjust_train_schedule_es(evt : EventTickrateChanged;
                             var train__changeVelocityPacked : int3&)
  assert(evt.oldTickrate > 0)
  train__changeVelocityPacked.z = train__changeVelocityPacked.z * evt.newTickrate / evt.oldTickrate

[es(REQUIRE=train)]
def change_train_velocity_es(evt : CmdPostPhysUpdate;
                             var train__changeVelocityPacked : int3&;
                             var train__expectedVelocity : float&;
                             train__minVelocity : float;
                             train__maxVelocity : float;
                             train__offenseTeamAdvantageWeight : int;
                             train__defenseTeamAdvantageWeight : int;
                             train__enableRestVelocity : bool)
  let offenseCount         = train__changeVelocityPacked.x * train__offenseTeamAdvantageWeight
  let defenseCount         = train__changeVelocityPacked.y * train__defenseTeamAdvantageWeight
  let changeVelocityAtTick = train__changeVelocityPacked.z
  if changeVelocityAtTick <= 0 || evt.tick < changeVelocityAtTick
    return

  train__changeVelocityPacked = int3()

  let minVelocity = train__enableRestVelocity || offenseCount != 0 ? train__minVelocity : 0.
  let shouldMove = offenseCount > 0 && offenseCount > defenseCount
  let addVelocity = shouldMove ? train__maxVelocity : 0.0
  train__expectedVelocity = clamp(minVelocity + addVelocity, minVelocity, train__maxVelocity)


[es(tag=netClient, REQUIRE=train__primaryCart, after=(phys_obj_apply_authority_state_es, human_phys_apply_authority_state_es), before=update_phys_es)]
def calc_primary_cart_tick_es(info : ParallelUpdateFrameDelayed;
                              var net__upToCtrlTick : int&;
                              var train__netTicksOffset : int&)
  net__upToCtrlTick = -1
  train__netTicksOffset = 0

  find_query() <| $ [es(REQUIRE=hero, REQUIRE_NOT=isReplayObserved)] (human_net_phys : HumanActor)
    assume humanPhys = human_net_phys.phys

    let ctrlTick = humanPhys.currentState.lastAppliedControlsForTick + 1
    let unapprovedCTLen = length(humanPhys.unapprovedCT)
    let producedAtTick = unapprovedCTLen == 0 ? -1 : humanPhys.unapprovedCT[unapprovedCTLen - 1].producedAtTick
    let lastAASTick = human_net_phys.lastAASTick
    let upToCtrlTick = calc_phys_update_to_tick(info.curTime, humanPhys.timeStep, ctrlTick, producedAtTick, lastAASTick)

    var physTick = humanPhys.currentState.atTick
    var lastAppliedControlsForTick = humanPhys.currentState.lastAppliedControlsForTick
    for _tick in range(ctrlTick, upToCtrlTick)
      ++physTick
      lastAppliedControlsForTick = ctrlTick

    let tdelta = physTick - lastAppliedControlsForTick - 1
    train__netTicksOffset = tdelta
    net__upToCtrlTick     = upToCtrlTick + tdelta

    return true


[es(REQUIRE=train__primaryCart, before=human_phys_es, after=(apply_train_server_state_es, change_train_velocity_es))]
def move_primary_cart_es(evt : CmdPostPhysUpdate;
                         var phys_obj_net_phys aka primary_phys_obj_net_phys : PhysObjActor;
                         var train__currentVelocity : float&;
                         train__expectedVelocity : float;
                         collres : CollisionResource;
                         train__accelerationOffense : float;
                         train__accelerationDefense : float)
  assume primaryCurrentState = primary_phys_obj_net_phys.phys.currentState
  primaryCurrentState.isSleep = false

  train__currentVelocity = clamp(train__expectedVelocity,
                                 train__currentVelocity - train__accelerationDefense * evt.dt,
                                 train__currentVelocity + train__accelerationOffense * evt.dt)

  query() <| $ [es(REQUIRE=trainDestination)] (transform : float3x4)
    let wishDir = transform[3] - float3(primaryCurrentState.location.P)
    if length_sq(wishDir) > 1e-9
      let trainVel = train__currentVelocity * normalize(float3(wishDir.x, 0., wishDir.z))

      if length_sq(trainVel) > 1e-6
        let trainBox  = BBox3(collres.vFullBBox)
        let trainQuat = primaryCurrentState.location.O.quat
        let trainPos  = float3(primaryCurrentState.location.P)

        let projectedTrain = project_train_on_railroad(trainBox, trainQuat, trainPos, trainVel)

        primaryCurrentState.location.O |> orient_setQuat(projectedTrain.orient)
        primaryCurrentState.location.P = DPoint3(projectedTrain.pos)

      primaryCurrentState.velocity = trainVel
      primaryCurrentState.omega    = float3()

  query() <| $ [es] (train__cartEids : EidList)
    for cartEid in train__cartEids
      query(cartEid) <| $ [es(REQUIRE_NOT=train__primaryCart)] (var phys_obj_net_phys aka secondary_phys_obj_net_phys : PhysObjActor;
                                                                collres : CollisionResource;
                                                                train__offset : float)
        secondary_phys_obj_net_phys.phys.previousState = secondary_phys_obj_net_phys.phys.currentState
        secondary_phys_obj_net_phys.phys.previousState.atTick = evt.tick

        assume secondaryCurrentState = secondary_phys_obj_net_phys.phys.currentState
        secondaryCurrentState.isSleep = true
        secondary_phys_obj_net_phys.phys.skipUpdateOnSleep = true

        secondaryCurrentState.atTick = evt.tick + 1
        secondaryCurrentState.lastAppliedControlsForTick = evt.tick

        let trainVel = primaryCurrentState.velocity
        let trainFwd = primaryCurrentState.location.O.quat |> quat_get_forward()

        let withsecondaryPos = float3(primaryCurrentState.location.P) + trainFwd * train__offset
        secondaryCurrentState.location.P = DPoint3(withsecondaryPos)

        let trainBox  = BBox3(collres.vFullBBox)
        let trainQuat = secondaryCurrentState.location.O.quat

        let projectedTrain = project_train_on_railroad(trainBox, trainQuat, withsecondaryPos, trainVel)

        secondaryCurrentState.location.O |> orient_setQuat(projectedTrain.orient)
        secondaryCurrentState.location.P = DPoint3(projectedTrain.pos)

        secondaryCurrentState.velocity = trainVel
        secondaryCurrentState.omega    = float3()

        var cartTm : float3x4
        secondaryCurrentState.location |> location_toTM(cartTm)

        secondary_phys_obj_net_phys.phys |> updatePhysInWorld(cartTm)


def cacl_cart_visual_location(var phys_obj_net_phys : PhysObjActor; at_time : float; ticks_offset : int)
  assume phys = phys_obj_net_phys.phys

  let dt = phys.timeStep
  let physTime  = float(phys.previousState.atTick - ticks_offset) * dt
  let daltaTime = float(phys.currentState.atTick - phys.previousState.atTick) * dt
  let k = saturate((at_time - physTime) / daltaTime)

  let visualPos = lerp(float3(phys.previousState.location.P),
                       float3(phys.currentState.location.P), float3(k))

  let visualOrient = slerp(phys.previousState.location.O.quat,
                           phys.currentState.location.O.quat, k)

  phys.visualLocation.P = DPoint3(visualPos)
  phys.visualLocation.O |> orient_setQuat(visualOrient)


[es(tag=netClient, REQUIRE=train__primaryCart, after=update_phys_es)]
def move_primary_cart_client_es(info : ParallelUpdateFrameDelayed;
                                var phys_obj_net_phys : PhysObjActor;
                                var transform : float3x4;
                                train__netTicksOffset : int)
  phys_obj_net_phys |> cacl_cart_visual_location(info.curTime, train__netTicksOffset)
  phys_obj_net_phys.phys.visualLocation |> location_toTM(transform)


[es(tag=netClient, REQUIRE=train, REQUIRE_NOT=train__primaryCart, after=update_phys_es)]
def move_secondary_cart_client_es(info : ParallelUpdateFrameDelayed;
                                  var phys_obj_net_phys : PhysObjActor;
                                  var transform : float3x4)
  find_query() <| $ [es(REQUIRE=train__primaryCart)] (train__netTicksOffset : int)
    phys_obj_net_phys |> cacl_cart_visual_location(info.curTime, train__netTicksOffset)
    phys_obj_net_phys.phys.visualLocation |> location_toTM(transform)
    return true


[es(after=move_train_es)]
def move_capzone_es(evt : ParallelUpdateFrameDelayed;
                    capzone__trainEid : EntityId;
                    capzone__smokeEid : EntityId;
                    capzone__offsetFromTrain : float3;
                    var transform aka capzone_transform : float3x4)
  assume capzonePos = capzone_transform[3]
  query(capzone__trainEid) <| $ [es] (transform : float3x4)
    capzonePos = transform[3] + capzone__offsetFromTrain

  query(capzone__smokeEid) <| $ [es] (var transform : float3x4)
    transform[3] = capzonePos


[es(tag=server, REQUIRE=(capzone, trainTriggerable), after=update_phys_es)]
def check_train_distance_to_train_checkpoint_es(evt : ParallelUpdateFrameDelayed;
                                                eid : EntityId;
                                                transform : float3x4;
                                                active : bool;
                                                maxDistanceToTrain : float)
  if active
    let previousCheckpoint = eid
    let checkpointPos = transform[3]
    query() <| $ [es(REQUIRE=train)] (transform : float3x4;
                                      train__teamOffense : int)
      if length_sq(transform[3] - checkpointPos) < square(maxDistanceToTrain)
        sendEvent(previousCheckpoint, [[EventForceCapture team=train__teamOffense]])


[es(tag=server, REQUIRE=trainZone)]
def train_zone_enter(evt : EventCapZoneEnter)
  query(evt.visitor) <| $ [es] (var human_net_phys__isSimplifiedPhys : bool&;
                                var human_net_phys__isSimplifiedQueryWalkPosition : bool&)
    human_net_phys__isSimplifiedPhys = false
    human_net_phys__isSimplifiedQueryWalkPosition = false


[es(tag=server, REQUIRE=trainZone)]
def train_zone_leave(evt : EventCapZoneLeave)
  query(evt.visitor) <| $ [es] (beh_tree__enabled : bool;
                                var human_net_phys__isSimplifiedPhys : bool&;
                                var human_net_phys__isSimplifiedQueryWalkPosition : bool&)
    human_net_phys__isSimplifiedPhys = beh_tree__enabled
    human_net_phys__isSimplifiedQueryWalkPosition = beh_tree__enabled
