require ecs
require mech
require DagorMathUtils
require math.base
require ecs.common
require Dacoll
require DngActor
require DagorMath
require DngNet
require GamePhys
require game.es.events
require DagorRandom
require enlisted.events_enlisted
require game.es.vehicle.vehicle_events

[es(tag=server, track=isAlive)]
def fall_down_after_die(evt : Event;
                        isAlive : bool;
                        transform : float3x4;
                        var walker_net_phys : WalkerPhysActor;
                        mech__fallAfterDieProbability = 0.5)
  let probability = rnd_float(0., 1.)
  if !isAlive && probability < mech__fallAfterDieProbability
    walker_net_phys.phys.currentState.hasSupport = false
    walker_net_phys.phys.currentState.isFallenDown = true

    let itm = inverse(transform)
    for i in range(length(walker_net_phys.phys.limbs))
      assume limbState = walker_net_phys.phys.currentState.limbs[i]
      if limbState.inLocalCoordinates
        continue
      limbState.currentTm = itm * limbState.currentTm
      limbState.finalTm = itm * limbState.finalTm
      limbState.hasSupport = false
      limbState.realTm[3] = limbState.currentTm[3]
      limbState.inLocalCoordinates = true



[es(tag=server, before=walker_phys_events_es)]
def fix_limb_pos_after_teleport(evt : CmdTeleportEntity;
                                eid : EntityId;
                                transform : float3x4;
                                var walker_net_phys : WalkerPhysActor)
  let itm = inverse(transform)
  let newTm = evt.newTm
  for i in range(length(walker_net_phys.phys.limbs))
    assume limbState = walker_net_phys.phys.currentState.limbs[i]
    if limbState.inLocalCoordinates
      continue
    let curLimbTm = itm * limbState.currentTm
    limbState.currentTm = newTm * curLimbTm

    let curLimbFinalTm = itm * limbState.finalTm
    limbState.finalTm = newTm * curLimbFinalTm
    send_net_event(eid, [[EventMechStepInfo limbIdx = i, pos = limbState.finalTm[3], isNextStep = false,
                          detach = !walker_net_phys.phys.currentState.hasSupport]])

def kick_hatch_owners_and_deny_hatch(vehicle_eid : EntityId;
                                     vehicle_seats__seatEids : EidList)
  for seatEid in vehicle_seats__seatEids
    query(seatEid) <| $ [es] (seat__ownerEid : EntityId;
                              var seats_hatch_nodes__openPos : float&;
                              var seat__isInHatch : bool&;
                              var seats_hatch_nodes__isValid : bool&)
      seats_hatch_nodes__isValid = false
      if seat__isInHatch && !!seat__ownerEid
        seats_hatch_nodes__openPos = 0.f
        seat__isInHatch = false
        sendEvent(vehicle_eid, [[CmdKickFromVehicle eid=seat__ownerEid]])

[es(tag=server, on_event=CmdPostPhysUpdate, after=after_net_phys_sync)]
def send_limbs_diff_info(evt : Event;
                         eid : EntityId;
                         vehicle_seats__seatEids : EidList;
                         walker_net_phys : WalkerPhysActor)
  let roleFlags = RoleFlags URF_AUTHORITY | RoleFlags URF_LOCAL_CONTROL
  if (uint(walker_net_phys.role) & uint(roleFlags)) != 0u
    let hadSupport = walker_net_phys.phys.previousState.hasSupport
    for i in range(length(walker_net_phys.phys.limbs))
      assume limbState = walker_net_phys.phys.currentState.limbs[i]
      assume prevLimbState = walker_net_phys.phys.previousState.limbs[i]

      let supportChanged = walker_net_phys.phys.currentState.hasSupport != hadSupport
      if hadSupport && !walker_net_phys.phys.currentState.hasSupport
        kick_hatch_owners_and_deny_hatch(eid, vehicle_seats__seatEids)

      let isNextStep = prevLimbState.progress > 0.5f && limbState.progress < 0.5f
      let isDirectionChanged = length_sq(prevLimbState.wishDir - limbState.wishDir) > 1e5
      if isNextStep || isDirectionChanged || supportChanged
        send_net_event(eid, [[EventMechStepInfo limbIdx = i, pos = limbState.finalTm[3], isNextStep = isNextStep,
                              detach = !walker_net_phys.phys.currentState.hasSupport]])
      let wasCollisionImpulse = length(limbState.realTm[3] - prevLimbState.realTm[3]) > 0.1
      if wasCollisionImpulse
        send_net_event(eid, [[EventMechStepRelativeInfo limbIdx = i, pos = limbState.realTm[3]]])


def create_limb_fx(mechEid : EntityId;
                   walker_net_phys : WalkerPhysActor;
                   animchar__visible : bool;
                   step_shake__maxDist : float;
                   step_shake__wishShake : float)
  let hadSupport = walker_net_phys.phys.previousState.hasSupport
  if !hadSupport
    return
  for i in range(length(walker_net_phys.phys.limbs))
    assume limbState = walker_net_phys.phys.currentState.limbs[i]
    assume prevLimbState = walker_net_phys.phys.previousState.limbs[i]
    let isEndStep = (limb_getWishY(prevLimbState, walker_net_phys.phys.walkingProps) > FLT_EPSILON &&
                     limb_getWishY(limbState, walker_net_phys.phys.walkingProps) < FLT_EPSILON)
    if isEndStep
      let fxPos = limbState.finalTm[3]
      if animchar__visible
        var posTm = IDENT_TM
        posTm[3] = fxPos
        createEntity("mech_step_fx") <| $(var init : ComponentsInitializer)
          set(init, "transform", posTm)
      broadcastEvent([[EventStepShakeCamera position=fxPos, max_distance=step_shake__maxDist, wish_shake=step_shake__wishShake]])
      sendEvent(mechEid, [[EventMechStepSound pos=fxPos]])


[es(tag=gameClient, REQUIRE=vehicleWithWatched)]
def receive_limbs_detach_info(evt : ParallelUpdateFrameDelayed;
                              walker_net_phys : WalkerPhysActor;
                              var camera__isStabilized : bool&)
  camera__isStabilized = walker_net_phys.phys.currentState.hasSupport

[es(tag=gameClient, on_event = CmdPostPhysUpdate, after=send_limbs_diff_info)]
def next_step_controlled_state_fx(evt : Event;
                                  eid : EntityId;
                                  animchar__visible : bool;
                                  walker_net_phys : WalkerPhysActor;
                                  step_shake__maxDist = 20.0;
                                  step_shake__wishShake = 1.5)
  create_limb_fx(eid, walker_net_phys, animchar__visible, step_shake__maxDist, step_shake__wishShake)


[es(tag=gameClient)]
def receive_relative_limbs_diff_info(evt : EventMechStepRelativeInfo;
                                     var walker_net_phys : WalkerPhysActor&)
  assume limbState = walker_net_phys.phys.currentState.limbs[evt.limbIdx]
  limbState.realTm[3] = evt.pos

[es(tag=gameClient)]
def receive_limbs_diff_info(evt : EventMechStepInfo;
                            transform : float3x4;
                            var walker_net_phys : WalkerPhysActor&)

  let isRemoteShadow = walker_net_phys.role == NetRole ROLE_REMOTELY_CONTROLLED_SHADOW
  if !isRemoteShadow
    return

  assume limbState = walker_net_phys.phys.currentState.limbs[evt.limbIdx]
  var locTm = IDENT_TM
  make_tm(walker_net_phys.phys.currentState.location.O.quat, locTm)
  limbState.wishDir = locTm[0]
  if !evt.detach
    if evt.isNextStep && limbState.progress > 0.2f
      limbState.currentTm = limbState.finalTm
      limbState.progress = 0.f
    limbState.finalTm = walkerPhys_findLimbPos(walker_net_phys.phys, evt.pos, limbState.wishDir, walker_net_phys.phys.limbs[evt.limbIdx])
    if (limbState.inLocalCoordinates)
      limbState.currentTm = limbState.finalTm
  else
    let itm = inverse(transform)
    limbState.currentTm = itm * limbState.currentTm
    limbState.finalTm = itm * limbState.finalTm

  limbState.inLocalCoordinates = evt.detach


def update_limb_progres(limbIdx : int;
                        var limb_state : LimbState&;
                        var walker_net_phys : WalkerPhysActor;
                        cur_progress : float)
  let MAX_STEP_PROGRESS = 1.f
  let nextStepSize = walkerPhys_getCurStepSize(walker_net_phys.phys)

  limb_state.progress = cur_progress
  if cur_progress > MAX_STEP_PROGRESS && !limb_state.inLocalCoordinates
    limb_state.currentTm = limb_state.finalTm
    limb_state.progress = 0.0f
    walkerPhys_updateStepDestination(walker_net_phys.phys, limbIdx, walker_net_phys.phys.currentState.location.O.quat, nextStepSize)

  limb_state.state = (abs(walker_net_phys.phys.currentState.throttle) < walker_net_phys.phys.walkingProps.runThrottle ?
                          WalkingState WS_WALK : WalkingState WS_RUN)
  limb_state.motorized = (length_sq(limb_state.currentTm[3] -
                                    limb_state.finalTm[3]) > square(0.5f))

[es(tag=gameClient, REQUIRE_NOT=disableUpdate, after=walker_update_limbs_phys_es, after=before_net_phys_sync)]
def walker_interpolate_remote_phys_es(info : ParallelUpdateFrameDelayed;
                                      eid : EntityId;
                                      isAlive : bool;
                                      animchar__visible : bool;
                                      var walker_net_phys : WalkerPhysActor&;
                                      step_shake__maxDist = 20.0;
                                      step_shake__wishShake = 0.5)
  let isRemoteShadow = walker_net_phys.role == NetRole ROLE_REMOTELY_CONTROLLED_SHADOW
  if !isRemoteShadow
    return

  walker_net_phys.phys.previousState.limbs[0].progress = walker_net_phys.phys.currentState.limbs[0].progress
  walker_net_phys.phys.previousState.limbs[1].progress = walker_net_phys.phys.currentState.limbs[1].progress

  assume leftLimbState = walker_net_phys.phys.currentState.limbs[0]
  assume rightLimbState = walker_net_phys.phys.currentState.limbs[1]

  let limbPos = walker_net_phys.customPhys.limbsStateProgress
  var curProgress = float2(leftLimbState.progress,
                           rightLimbState.progress)

  let absThrot = abs(walker_net_phys.phys.currentState.throttle)
  let limbSpeed = cvt(absThrot, 0.3f, 1.f,
                      walker_net_phys.phys.walkingProps.stepsPerSecMin,
                      walker_net_phys.phys.walkingProps.stepsPerSecMax);

  curProgress.x += info.dt * limbSpeed * 0.5f;
  curProgress.y += info.dt * limbSpeed * 0.5f;

  if (limbPos.x - curProgress.x > 0.f && limbPos.x - curProgress.x < 0.5f)
    curProgress.x = approach(curProgress.x, limbPos.x, info.dt, 0.5f);
  if (limbPos.y - curProgress.y > 0.f && limbPos.y - curProgress.y < 0.5f)
    curProgress.y = approach(curProgress.y, limbPos.y, info.dt, 0.5f);

  update_limb_progres(0, leftLimbState, walker_net_phys, curProgress.x)
  update_limb_progres(1, rightLimbState, walker_net_phys, curProgress.y)
  if isAlive
    create_limb_fx(eid, walker_net_phys, animchar__visible, step_shake__maxDist, step_shake__wishShake)