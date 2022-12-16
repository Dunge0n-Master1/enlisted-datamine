require app
require ecs
require math
require math.base
require EnlistedNet
require game.es.events
require game.events_game
require game.utils.team
require enlisted.events_enlisted
require common_shooter.events_common_shooter
require common_shooter.es.human_attached_gun_common
require danetlibs.native_dasevents.main.native_events
require Gun
require EnlistedHuman
require EnlistedWeapon
require EnlistedActor
require HumanPhys
require DagorMath
require GamePhys
require GeomNodeTree
require AnimV20
require Dacoll
require DagorSystem
require PhysVars
require EffectorData
require PhysDecl


[es(on_disappear)]
def human_attached_gun_destroy_es(evt : Event;
                                  var human_attached_gun__attachedGunEid : EntityId&)
  reset_attached_gun(human_attached_gun__attachedGunEid)
  human_attached_gun__attachedGunEid = INVALID_ENTITY_ID


def attach_to_gun(eid : EntityId;
                  gun_eid : EntityId;
                  var gun : MountedGun?;
                  var human_attached_gun__attachedGunEid : EntityId&)

  reset_attached_gun(human_attached_gun__attachedGunEid)

  human_attached_gun__attachedGunEid = gun_eid

  query(gun_eid) <| $ [es] (var animchar__updatable : bool&)
    animchar__updatable = true

  if gun != null
    query(gun_eid) <| $ [es] (transform : float3x4)
      gun.wishLookDir = transform[2]
      gun.initialTm = transform

    (*gun) |> mounted_gun_attach(gun_eid, eid)

  if is_server()
    send_net_event(eid, [[HumanAttachToGunResponse gun_eid=gun_eid]])

  sendEventImmediate(eid, [[HumanAttachToGunComplete gun_eid=gun_eid]])

  query(eid) <| $ [es] (animchar : AnimcharBaseComponent const?;
                        human_attached_gun__nodeLhName : string;
                        human_attached_gun__nodeName : string;
                        team : int = TEAM_UNASSIGNED;
                        var human_net_phys : HumanActor;
                        var human_attached_gun__lhandNodeIdx : int&;
                        var human_attached_gun__rhandNodeIdx : int&)
    let humanAnimChar = animchar
    let humanTeam = team

    query(gun_eid) <| $ [es] (animchar : AnimcharBaseComponent const?;
                              dependsOnBuildingEid : EntityId = INVALID_ENTITY_ID;
                              var team : int?)
      let gunAnimChar = animchar

      if team != null
        *team = humanTeam

      query(dependsOnBuildingEid) <| $ [es] (var team : int&)
        team = humanTeam

      if (humanAnimChar != null && gunAnimChar != null &&
         humanAnimChar.animGraph != null && humanAnimChar.animState != null)
        let nodeTree = (*gunAnimChar).nodeTree
        let lhandNodeIdx = *nodeTree |> geomtree_findNodeIndex(human_attached_gun__nodeLhName)
        human_attached_gun__lhandNodeIdx = lhandNodeIdx
        if human_attached_gun__lhandNodeIdx == -1
          logerr("<{getEntityTemplateName(gun_eid)}> does not have '{human_attached_gun__nodeLhName}' animchar node")

        let rhandNodeIdx = *nodeTree |> geomtree_findNodeIndex(human_attached_gun__nodeName)
        human_attached_gun__rhandNodeIdx = rhandNodeIdx
        if human_attached_gun__rhandNodeIdx == -1
          logerr("<{getEntityTemplateName(gun_eid)}> does not have '{human_attached_gun__nodeName}' animchar node")
      else
        human_attached_gun__lhandNodeIdx = -1
        human_attached_gun__rhandNodeIdx = -1

      human_net_phys.phys.currentState |> human_phys_state_set_isAttached(true)


def attach_to_gun_impl(human_eid : EntityId;
                       gun_eid : EntityId;
                       var human_attached_gun__attachedGunEid : EntityId&)
  query(gun_eid) <| $ [es] (var mounted_gun : MountedGun?)
    attach_to_gun(human_eid, gun_eid, mounted_gun,
                  human_attached_gun__attachedGunEid)

[es(after=human_inventory_input_proc_es)]
def human_disable_melee_attack_es(input : UpdateStageUpdateInput;
                                  human_attached_gun__attachedGunEid : EntityId;
                                  var human_net_phys : HumanActor)
  if human_attached_gun__attachedGunEid != INVALID_ENTITY_ID
    human_net_phys.phys.producedCT |> human_control_state_set_control_bit(HumanPhysControlType HCT_MELEE, false)

def move_to_pos_ccd(var human_net_phys : HumanActor; var pos : float3)
  var ccdTm : float3x4
  location_toTM(human_net_phys.phys.currentState.location, ccdTm)
  let ccdPos = human_net_phys.phys.ccdPos
  let prevWorldCcdPos = ccdTm * ccdPos

  human_net_phys.phys.currentState.location.P = DPoint3(pos)

  ccdTm[3] = pos

  let collRad = human_net_phys.phys.collRad
  let ccdRad  = human_net_phys.phys.ccdRad
  let speedCollisionHardness = human_net_phys.phys.speedCollisionHardness
  let ccdToPos = ccdTm * ccdPos
  let totalOffset = ccdToPos - prevWorldCcdPos

  human_net_phys.phys |> human_phys_processCcdOffset(ccdTm, ccdToPos, totalOffset, collRad - ccdRad, speedCollisionHardness, true, ccdPos)

[es]
def human_attached_gun_update_phys(update : CmdPostPhysUpdate;
                                   eid aka human_eid : EntityId;
                                   human_attached_gun__attachedGunEid : EntityId;
                                   bipod__enabled : bool;
                                   var human_net_phys : HumanActor&)
  human_net_phys.phys.currentState |> human_phys_state_set_attachedToExternalGun(!!human_attached_gun__attachedGunEid || bipod__enabled)
  query(human_attached_gun__attachedGunEid) <| $ [es] (transform aka gun_transform : float3x4;
                                                       stationary_gun__humanOffset : float3;
                                                       stationary_gun__maxPhysOffsetSq : float)

    assume currentState = human_net_phys.phys.currentState
    assume producedCT = human_net_phys.phys.producedCT

    let shoot = producedCT |> is_control_bit_set(HumanPhysControlType HCT_SHOOT)
    let aim = producedCT |> is_control_bit_set(HumanPhysControlType HCT_AIM)

    producedCT |> human_control_state_set_neutral_ctrl()
    if currentState |> human_phys_state_get_canShoot()
      human_net_phys.phys.producedCT |> human_control_state_set_control_bit(HumanPhysControlType HCT_SHOOT, shoot)
      human_net_phys.phys.producedCT |> human_control_state_set_control_bit(HumanPhysControlType HCT_AIM, aim)
    let attachPos = gun_transform * stationary_gun__humanOffset
    let dest = float3(attachPos.x, float(currentState.location.P.y), attachPos.z)
    human_net_phys |> move_to_pos_ccd(dest)
    human_net_phys.phys.currentState.bodyOrientDir = human_net_phys.phys.currentState.gunDir.xz
    var tm : float3x4
    currentState.location |> location_toTM(tm)
    tm[1] = currentState.vertDirection
    tm[2] = normalize(cross(tm[0], tm[1]))
    tm[0] = normalize(cross(tm[1], tm[2]))
    let orient = quat(tm)
    currentState.location.O |> orient_setQuat(orient)
    currentState.moveState = HUMoveState EMS_STAND
    let posAfter = float3(currentState.location.P)
    if distance_sq(attachPos, posAfter) > stationary_gun__maxPhysOffsetSq
      sendEvent(human_eid, [[CmdDetachAttachedGun]])
      sendEvent(human_eid, [[CmdHeroLogEvent event="human_attached_gun_lost", text="human_attached_gun_lost"]])

[es(track=human_attached_gun__attachedGunEid)]
def human_track_attached_gun(evt : Event;
                             human_attached_gun__attachedGunEid : EntityId;
                             var human_attached_gun__isAttached : bool&)
  human_attached_gun__isAttached = !!human_attached_gun__attachedGunEid

[es(after=(after_net_phys_sync, human_weap_update_es), before=human_anim_es)]
def human_attached_gun_rotate_body(update : UpdateStageInfoAct;
                                   human_attached_gun__attachedGunEid : EntityId;
                                   var transform aka human_transform : float3x4&)
  query(human_attached_gun__attachedGunEid) <| $ [es] (transform aka gun_transform : float3x4; stationary_gun__humanOffset : float3)
    human_transform[0] = -gun_transform[2]
    human_transform[2] = cross(human_transform[0], human_transform[1])
    orthonormalize(human_transform)
    let physY = human_transform[3].y
    human_transform[3] = gun_transform * stationary_gun__humanOffset
    human_transform[3].y = min(physY, human_transform[3].y)

def interp_dir(prev : float3; cur : float3; interpK : float)
  let q = slerp(dir_to_quat(prev), dir_to_quat(cur), interpK)
  return q |> quat_get_forward()


[es(after=after_net_phys_sync, before=(human_anim_es, mounted_gun_es))]
def human_attached_gun_controls_update_es(info : UpdateStageInfoAct;
                                          eid : EntityId;
                                          isAlive : bool;
                                          isDowned : bool = false;
                                          human_weap__gunOffsAngles : float3 = float3(0.0, 0.0, 0.0);
                                          human_net_phys : HumanActor;
                                          var human_attached_gun__attachedGunEid : EntityId&)
  let isHeroAlive = isAlive
  query(human_attached_gun__attachedGunEid) <| $ [es] (isAlive : bool = false;
                                                       var phys_vars : PhysVars;
                                                       var gun : Gun?;
                                                       var mounted_gun : MountedGun?)
    let netRole = uint(RoleFlags URF_AUTHORITY | RoleFlags URF_LOCAL_CONTROL)
    if (uint(human_net_phys.role) & netRole) != 0u && gun != null && mounted_gun != null
      var gunDir, headDir : float3
      var shoot : bool

      if (uint(human_net_phys.role) & uint(RoleFlags URF_LOCAL_CONTROL)) != 0u
        gunDir = human_net_phys.phys.producedCT.wishShootDir
        headDir = human_net_phys.phys.producedCT.wishLookDir
        shoot = human_net_phys.phys.producedCT |> is_control_bit_set(HumanPhysControlType HCT_SHOOT) && isAlive;
      else
        let interpK = get_phys_interpk_clamped(human_net_phys.phys, info.curTime)
        gunDir = interp_dir(human_net_phys.phys.previousState.gunDir,
                            human_net_phys.phys.currentState.gunDir, interpK)
        headDir = interp_dir(human_net_phys.phys.previousState.headDir,
                             human_net_phys.phys.currentState.headDir, interpK)
        shoot = human_net_phys.phys.appliedCT |> is_control_bit_set(HumanPhysControlType HCT_SHOOT) && isAlive;// Not alive by default to detach destroyed entity as well

      let offsAngles = float2(human_weap__gunOffsAngles.x, human_weap__gunOffsAngles.y)
      *mounted_gun |> mounted_gun_setControls(*gun, gunDir, headDir, shoot, human_net_phys.phys.timeStep,
                                              info.curTime, phys_vars, offsAngles)

    if (!isHeroAlive || !isAlive || isDowned)
      detach_from_gun(eid, human_attached_gun__attachedGunEid)


[es(before=animchar_effectors_update_es, after=(after_net_phys_sync, human_anim_es))]
def human_attached_gun_effectors_update_es(info : UpdateStageInfoAct;
                                           var human_net_phys : HumanActor;
                                           var animchar_effectors__effectorsState : Object&;
                                           animchar : AnimcharBaseComponent const?;
                                           human_attached_gun__lhandNodeIdx : int;
                                           human_attached_gun__rhandNodeIdx : int;
                                           human_attached_gun__attachedGunEid : EntityId;
                                           human_attached_gun__disableIK : bool = false;
                                           human_attached_gun__breathAmplitude : float = 0.3)
  let humanAnimChar = animchar
  query(human_attached_gun__attachedGunEid) <| $ [es] (animchar : AnimcharBaseComponent)
    var rightHandEffector = animchar_effectors__effectorsState |> getNullableRW_EffectorData("r.hand")
    var leftHandEffector = animchar_effectors__effectorsState |> getNullableRW_EffectorData("l.hand")

    if rightHandEffector != null && leftHandEffector != null
      human_net_phys.phys.currentState.breathAmplitudeMult = human_attached_gun__breathAmplitude
      if humanAnimChar != null && !human_attached_gun__disableIK
        let d_wofs = *animchar.nodeTree |> geomtree_getWtmOfs() - *humanAnimChar.nodeTree |> geomtree_getWtmOfs()

        let arms = *animchar.nodeTree |> geomtree_getNodeWposRel(human_attached_gun__rhandNodeIdx) + d_wofs

        (*rightHandEffector).position = arms
        *animchar.nodeTree |> geomtree_getNodeWtmRelScalar(human_attached_gun__rhandNodeIdx, (*rightHandEffector).wtm)
        (*rightHandEffector).wtm[3] = (*rightHandEffector).wtm[3] + d_wofs
        (*rightHandEffector).weight = 1.0

        var armLh = arms
        if human_attached_gun__lhandNodeIdx >= 0
          armLh = *animchar.nodeTree |> geomtree_getNodeWposRel(human_attached_gun__lhandNodeIdx) + d_wofs

        (*leftHandEffector).position = armLh
        *animchar.nodeTree |> geomtree_getNodeWtmRelScalar(human_attached_gun__lhandNodeIdx, (*leftHandEffector).wtm)
        (*leftHandEffector).wtm[3] = (*leftHandEffector).wtm[3] + d_wofs
        (*leftHandEffector).weight = 1.0
      else
        (*rightHandEffector).weight = 0.0
        (*leftHandEffector).weight = 0.0


[es(tag=(gameClient, net))]
def human_attach_to_gun_response(evt : HumanAttachToGunResponse;
                                 eid : EntityId;
                                 var human_attached_gun__attachedGunEid : EntityId&)
  let gunEid = evt.gun_eid
  query(gunEid) <| $ [es] (var mounted_gun : MountedGun?)
    if mounted_gun != null
      attach_to_gun(eid, gunEid, mounted_gun,
                    human_attached_gun__attachedGunEid)


def detach_from_gun_event_impl(eid : EntityId;
                               var human_net_phys : HumanActor;
                               var human_attached_gun__attachedGunEid : EntityId&)
  if human_attached_gun__attachedGunEid != INVALID_ENTITY_ID
    detach_from_gun(eid, human_attached_gun__attachedGunEid)
    human_net_phys.phys.currentState.weapEquipState.progress = 0.0
    human_net_phys.phys.currentState.weapEquipState.curState = HUWeaponEquipState EES_EQUIPING

[es(tag=(gameClient, net))]
def human_detach_from_gun_response(evt : HumanDetachFromGunResponse;
                                   eid : EntityId;
                                   var human_net_phys : HumanActor;
                                   var human_attached_gun__attachedGunEid : EntityId&)
  detach_from_gun_event_impl(eid, human_net_phys,
                             human_attached_gun__attachedGunEid)


[es(tag=server, REQUIRE=mounted_gun)]
def mounted_gun_attach_es(evt : CmdUse; eid aka gun_eid : EntityId)
  query(evt.requesterEid) <| $ [es] (eid : EntityId;
                                     var human_attached_gun__attachedGunEid : EntityId&)
    if !!human_attached_gun__attachedGunEid
      detach_from_gun(eid, human_attached_gun__attachedGunEid)
    else
      attach_to_gun_impl(eid, gun_eid, human_attached_gun__attachedGunEid)

[es(tag=server, on_event=(CmdDetachAttachedGun, CmdTeleportEntity))]
def mounted_gun_deattach_es(evt : Event;
                            eid : EntityId;
                            var human_attached_gun__attachedGunEid : EntityId&)
  if human_attached_gun__attachedGunEid != INVALID_ENTITY_ID
    detach_from_gun(eid, human_attached_gun__attachedGunEid)

[es(track=human_use_object__lockStationaryGunUse)]
def human_lock_stationary_gun_use_es(evt : Event;
                                     eid : EntityId;
                                     human_attached_gun__attachedGunEid : EntityId;
                                     human_use_object__lockStationaryGunUse : bool)
  if human_use_object__lockStationaryGunUse && human_attached_gun__attachedGunEid != INVALID_ENTITY_ID
    sendEvent(human_attached_gun__attachedGunEid, [[CmdUse requesterEid=eid]])

[es(track=possessedByPlr)]
def human_attached_gun_autodetach_bots_es(evt : Event;
                                          eid : EntityId;
                                          possessedByPlr : EntityId;
                                          human_attached_gun__attachedGunEid : EntityId)
  if !possessedByPlr && !!human_attached_gun__attachedGunEid
    sendEvent(eid, [[CmdDetachAttachedGun]])


def detach_human_from_gun(gunEid : EntityId)
  query() <| $ [es] (eid : EntityId;
                     var human_attached_gun__attachedGunEid : EntityId&)
    if (human_attached_gun__attachedGunEid == gunEid)
      detach_from_gun(eid, human_attached_gun__attachedGunEid)


[es(REQUIRE=stationary_gun, on_disappear)]
def mouted_gun_destroyed_es(evt : Event;
                            eid : EntityId)
  detach_human_from_gun(eid)


[es(REQUIRE=stationary_gun)]
def mouted_gun_died_es(evt : EventEntityDied;
                       eid : EntityId;
                       transform : float3x4;
                       var ragdoll : PhysRagdoll?;
                       var animchar__updatable : bool&;
                       var ragdoll__applyParams : bool&;
                       var animchar : AnimcharBaseComponent;
                       var ragdoll__active : bool&)
  detach_human_from_gun(eid)

  ragdoll__active = true
  if ragdoll != null && distance_sq(transform[3], get_hidden_pos()) > 1.0
    animchar__updatable = true

    let interactLayer = PhysLayer EPL_CHARACTER
    let interactMask = PhysLayer EPL_ALL & (~(PhysLayer EPL_KINEMATIC | PhysLayer EPL_CHARACTER))
    *ragdoll |> ragdoll_startRagdoll(int(interactLayer),
                                     int(interactMask))
    let vel = float3(0.0, 0.0, 0.0)
    *ragdoll |> ragdoll_setOverrideVel(vel)
    ragdoll__applyParams = true
    sendEvent(eid, [[CmdApplyRagdollParameters  cur_time=get_sync_time()]])

    animchar |> animchar_setPostController(*ragdoll)
    animchar |> animchar_act(0.0, true)