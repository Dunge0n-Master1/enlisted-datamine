require app
require ecs
require math
require math.base
require EnlistedNet
require game.es.events
require game.events_game
require game.utils.team
require common_shooter.events_common_shooter
require common_shooter.es.human_attached_gun_common
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


let GUN_ATTACH_RADIUS_DEFAULT = 2.0


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
    (*gun) |> mounted_gun_attach(gun_eid, eid)

  if is_server()
    send_net_event(eid, [[HumanAttachToGunResponse gun_eid=gun_eid]])

  sendEventImmediate(eid, [[HumanAttachToGunComplete gun_eid=gun_eid]])

  query(eid) <| $ [es] (animchar : AnimcharBaseComponent?;
                        human_attached_gun__nodeLhName : string;
                        human_attached_gun__nodeName : string;
                        team : int = TEAM_UNASSIGNED;
                        var human_net_phys : HumanActor;
                        var human_attached_gun__lhandNodeIdx : int&;
                        var human_attached_gun__rhandNodeIdx : int&)
    let humanAnimChar = animchar
    let humanTeam = team

    query(gun_eid) <| $ [es] (animchar : AnimcharBaseComponent?;
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
        let lhandNodeIdx = nodeTree |> geomtree_findNodeIndex(human_attached_gun__nodeLhName)
        human_attached_gun__lhandNodeIdx = lhandNodeIdx
        if human_attached_gun__lhandNodeIdx == -1
          logerr("<{getEntityTemplateName(gun_eid)}> does not have '{human_attached_gun__nodeLhName}' animchar node")

        let rhandNodeIdx = nodeTree |> geomtree_findNodeIndex(human_attached_gun__nodeName)
        human_attached_gun__rhandNodeIdx = rhandNodeIdx
        if human_attached_gun__rhandNodeIdx == -1
          logerr("<{getEntityTemplateName(gun_eid)}> does not have '{human_attached_gun__nodeName}' animchar node")
      else
        human_attached_gun__lhandNodeIdx = -1
        human_attached_gun__rhandNodeIdx = -1

      human_net_phys.phys.currentState |> human_phys_state_set_isAttached(true)


def attach_to_gun_impl(eid : EntityId;
                       radius : float;
                       var human_attached_gun__attachedGunEid : EntityId&)
  let gunEid = find_gun_to_attach(eid, radius, false)
  if gunEid != INVALID_ENTITY_ID
    query(gunEid) <| $ [es] (var mounted_gun : MountedGun?)
      attach_to_gun(eid, gunEid, mounted_gun,
                    human_attached_gun__attachedGunEid)


def toggle_attach_gun(eid : EntityId;
                      radius : float;
                      var human_attached_gun__attachedGunEid : EntityId&)
  if is_server()
    if human_attached_gun__attachedGunEid != INVALID_ENTITY_ID
      detach_from_gun(eid, human_attached_gun__attachedGunEid)
    else
      attach_to_gun_impl(eid, radius,
                         human_attached_gun__attachedGunEid)
  else
    if human_attached_gun__attachedGunEid != INVALID_ENTITY_ID
      send_net_event(eid, [[HumanDetachFromGunRequest]])
      detach_from_gun(eid, human_attached_gun__attachedGunEid)
    else
      send_net_event(eid, [[HumanAttachToGunRequest]])


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

def get_best_possible_pos(possible_positions : float3[];
                          floor_height : float;
                          height_delta_down, height_delta_up : float;
                          var possible_best : float3&;
                          var vertical_pos : float&)
  var dh = floor_height
  for i in range(length(possible_positions))
    let possiblePos = possible_positions[i]
    let heightDelta = floor_height - possiblePos.y
    if (heightDelta >= height_delta_down &&
        heightDelta <= height_delta_up)
      possible_best = possiblePos
      vertical_pos = possible_best.y
      break
    elif abs(heightDelta) < abs(dh)
      dh = heightDelta
      possible_best = possiblePos
      possible_best.y += ((dh < 0.0)
                        ? max(dh, height_delta_down)
                        : min(dh, height_delta_up))
      vertical_pos = possible_best.y
      if ((i == 0 && possible_best.y > floor_height) ||
          (i > 0 && possible_best.y > floor_height + height_delta_up))
        possible_best.y = floor_height


[es]
def human_attached_gun_input_es(update : CmdPostPhysUpdate;
                                human_attached_gun__attachedGunEid : EntityId;
                                human_attached_gun__rhandNodeIdx : int;
                                human_attached_gun__nodeOffset : float3;
                                human_attached_gun__nodeOffsetStand : float3;
                                human_attached_gun__nodeOffsetCrouch : float3;
                                human_attached_gun__nodeOffsetCrawl : float3;
                                human_attached_gun__walkAnimPeriod : float = 0.3;
                                human_attached_gun__heightDeltaUp : float = 0.1;
                                human_attached_gun__heightDeltaDown : float = -0.05;
                                var human_net_phys : HumanActor;
                                var human_attached_gun__isAttached : bool&;
                                var human_attached_gun__walkDir : float2&;
                                var human_attached_gun__walkAnimAt : float&;
                                var human_attached_gun__hashPosition : float3&)
  // FIXME: extra phys state modification to separate ES
  let isAttached = (human_attached_gun__attachedGunEid != INVALID_ENTITY_ID)
  human_attached_gun__isAttached = isAttached
  assume currentState = human_net_phys.phys.currentState
  currentState |> human_phys_state_set_attachedToExternalGun(isAttached)

  // Entity might be destroyed but not detached yet (which will happens further in update es)
  if doesEntityExist(human_attached_gun__attachedGunEid)
    query(human_attached_gun__attachedGunEid) <| $ [es] (animchar : AnimcharBaseComponent)
      if human_attached_gun__rhandNodeIdx >= 0
        var wtm = IDENT_TM
        let nodeTree = animchar.nodeTree
        nodeTree |> geomtree_getNodeWtmScalar(human_attached_gun__rhandNodeIdx, wtm)
        let pos = wtm * human_attached_gun__nodeOffset

        assume producedCT = human_net_phys.phys.producedCT

        let shoot = producedCT |> is_control_bit_set(HumanPhysControlType HCT_SHOOT)
        let aim = producedCT |> is_control_bit_set(HumanPhysControlType HCT_AIM)

        producedCT |> human_control_state_set_neutral_ctrl()
        if currentState |> human_phys_state_get_canShoot()
          human_net_phys.phys.producedCT |> human_control_state_set_control_bit(HumanPhysControlType HCT_SHOOT, shoot)
          human_net_phys.phys.producedCT |> human_control_state_set_control_bit(HumanPhysControlType HCT_AIM, aim)

        var horzTransform = IDENT_TM
        horzTransform[0] = normalize(float3(wtm[0].x, 0.0, wtm[0].z))
        horzTransform[2] = cross(horzTransform[0], horzTransform[1])
        horzTransform[3] = wtm[3]

        var crawlPos = horzTransform * human_attached_gun__nodeOffsetCrawl
        query(human_attached_gun__attachedGunEid) <| $ [es] (transform : float3x4)
          crawlPos.y = (transform * human_attached_gun__nodeOffsetCrawl).y

        let possiblePositions = [[auto[]
          crawlPos;
          horzTransform * human_attached_gun__nodeOffsetCrouch;
          horzTransform * human_attached_gun__nodeOffsetStand]]

        let armsPosition = wtm * float3(human_attached_gun__nodeOffset.x, 0.0, 0.0)
        var approximateFloorHeight = 2.0;
        tracedown_normalized_with_mat_id(armsPosition, approximateFloorHeight,
                                         ETF_DEFAULT, human_net_phys.phys.rayMatId)
        let height = armsPosition.y - approximateFloorHeight

        var possibleBest = pos
        var verticalPos = pos.y
        get_best_possible_pos(possiblePositions, height, human_attached_gun__heightDeltaDown, human_attached_gun__heightDeltaUp, possibleBest, verticalPos)

        let beforeCcdPos = float3(human_net_phys.phys.currentState.location.P)
        human_net_phys |> move_to_pos_ccd(possibleBest)

        human_net_phys.phys.currentState.bodyOrientDir = float2(wtm[0].x, wtm[0].z)
        let afterCcdPos = float3(human_net_phys.phys.currentState.location.P)


        verticalPos = afterCcdPos.y
        get_best_possible_pos(possiblePositions, afterCcdPos.y, human_attached_gun__heightDeltaDown, human_attached_gun__heightDeltaUp, possibleBest, verticalPos)

        human_net_phys.phys.currentState.height = cvt(verticalPos, possiblePositions[0].y, possiblePositions[2].y, -1.0, 1.0)

        human_net_phys.phys.currentState.velocity = float3(0.0, 0.0, 0.0)
        human_net_phys.phys.currentState.moveState = HUMoveState EMS_STAND
        let time = get_sync_time()
        let moveDir3 = afterCcdPos - beforeCcdPos
        let moveDir = float2(moveDir3.x, moveDir3.z)

        if length(afterCcdPos - human_attached_gun__hashPosition) > 0.1
          human_attached_gun__walkAnimAt = time + human_attached_gun__walkAnimPeriod
          human_attached_gun__walkDir = moveDir
          human_attached_gun__hashPosition = afterCcdPos
        human_net_phys.phys.currentState.walkDir = human_attached_gun__walkDir
        if human_attached_gun__walkAnimAt > time
          human_net_phys.phys.currentState.moveState = HUMoveState EMS_WALK
        else
          human_attached_gun__walkDir = float2(0.0, 0.0)


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
    if (uint(human_net_phys.role) & netRole) != 0u
      let interpK = get_phys_interpk_clamped(human_net_phys.phys, info.curTime)

      var gunDir = interp_dir(human_net_phys.phys.previousState.gunDir,
                              human_net_phys.phys.currentState.gunDir, interpK)
      var headDir = interp_dir(human_net_phys.phys.previousState.headDir,
                               human_net_phys.phys.currentState.headDir, interpK)

      if (uint(human_net_phys.role) & uint(RoleFlags URF_LOCAL_CONTROL)) != 0u
        gunDir = human_net_phys.phys.producedCT.wishShootDir
        headDir = human_net_phys.phys.producedCT.wishLookDir

      let shoot = human_net_phys.phys.appliedCT |> is_control_bit_set(HumanPhysControlType HCT_SHOOT) && isAlive;// Not alive by default to detach destroyed entity as well
      if gun != null && mounted_gun != null
        let offsAngles = float2(human_weap__gunOffsAngles.x, human_weap__gunOffsAngles.y)
        *mounted_gun |> mounted_gun_setControls(*gun, gunDir, headDir, shoot,
                                                info.curTime, phys_vars, offsAngles)

    if (!isHeroAlive || !isAlive || isDowned)
      detach_from_gun(eid, human_attached_gun__attachedGunEid)


[es(before=animchar_effectors_update_es, after=(after_net_phys_sync, human_anim_es))]
def human_attached_gun_effectors_update_es(info : UpdateStageInfoAct;
                                           var human_net_phys : HumanActor;
                                           var animchar_effectors__effectorsState : Object&;
                                           animchar : AnimcharBaseComponent?;
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
        let d_wofs = animchar.nodeTree |> geomtree_getWtmOfs() - humanAnimChar.nodeTree |> geomtree_getWtmOfs()

        let arms = animchar.nodeTree |> geomtree_getNodeWposRel(human_attached_gun__rhandNodeIdx) + d_wofs

        (*rightHandEffector).position = arms
        animchar.nodeTree |> geomtree_getNodeWtmRelScalar(human_attached_gun__rhandNodeIdx, (*rightHandEffector).wtm)
        (*rightHandEffector).wtm[3] = (*rightHandEffector).wtm[3] + d_wofs
        (*rightHandEffector).weight = 1.0

        var armLh = arms
        if human_attached_gun__lhandNodeIdx >= 0
          armLh = animchar.nodeTree |> geomtree_getNodeWposRel(human_attached_gun__lhandNodeIdx) + d_wofs

        (*leftHandEffector).position = armLh
        animchar.nodeTree |> geomtree_getNodeWtmRelScalar(human_attached_gun__lhandNodeIdx, (*leftHandEffector).wtm)
        (*leftHandEffector).wtm[3] = (*leftHandEffector).wtm[3] + d_wofs
        (*leftHandEffector).weight = 1.0
      else
        (*rightHandEffector).weight = 0.0
        (*leftHandEffector).weight = 0.0


[es(tag=(server))]
def human_attach_to_gun_request(evt : HumanAttachToGunRequest;
                                eid : EntityId;
                                human_attached_gun__attachRadius : float = GUN_ATTACH_RADIUS_DEFAULT;
                                var human_attached_gun__attachedGunEid : EntityId&)
  attach_to_gun_impl(eid,
                     human_attached_gun__attachRadius,
                     human_attached_gun__attachedGunEid)


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


[es(tag=(server))]
def human_detach_from_gun_requence(evt : HumanDetachFromGunRequest;
                                   eid : EntityId;
                                   var human_net_phys : HumanActor;
                                   var human_attached_gun__attachedGunEid : EntityId&)
  detach_from_gun_event_impl(eid, human_net_phys,
                             human_attached_gun__attachedGunEid)


[es(tag=(gameClient, net))]
def human_detach_from_gun_response(evt : HumanDetachFromGunResponse;
                                   eid : EntityId;
                                   var human_net_phys : HumanActor;
                                   var human_attached_gun__attachedGunEid : EntityId&)
  detach_from_gun_event_impl(eid, human_net_phys,
                             human_attached_gun__attachedGunEid)


[es(REQUIRE=mounted_gun)]
def mounted_gun_attach_es(evt : CmdUse)
  query(evt.requesterEid) <| $ [es] (eid : EntityId;
                                     human_attached_gun__attachRadius : float = GUN_ATTACH_RADIUS_DEFAULT;
                                     var human_attached_gun__attachedGunEid : EntityId&)
    toggle_attach_gun(eid,
                      human_attached_gun__attachRadius,
                      human_attached_gun__attachedGunEid)


[es(on_event=(CmdDetachAttachedGun, CmdTeleportEntity))]
def mounted_gun_deattach_es(evt : Event;
                            eid : EntityId;
                            human_attached_gun__attachRadius : float = GUN_ATTACH_RADIUS_DEFAULT;
                            var human_attached_gun__attachedGunEid : EntityId&)
  if human_attached_gun__attachedGunEid != INVALID_ENTITY_ID
    toggle_attach_gun(eid,
                      human_attached_gun__attachRadius,
                      human_attached_gun__attachedGunEid)


[es(track=human_use_object__lockStationaryGunUse)]
def human_lock_stationary_gun_use_es(evt : Event;
                                     eid : EntityId;
                                     human_attached_gun__attachedGunEid : EntityId;
                                     human_use_object__lockStationaryGunUse : bool)
  if human_use_object__lockStationaryGunUse && human_attached_gun__attachedGunEid != INVALID_ENTITY_ID
    sendEvent(human_attached_gun__attachedGunEid, [[CmdUse requesterEid=eid]])


[es(no_order)]
def human_attached_gun_autodetach_es(info : UpdateStageInfoAct;
                                     eid : EntityId;
                                     human_attached_gun__attachedGunEid : EntityId;
                                     human_net_phys : HumanActor)
  let humanPos = float3(human_net_phys.phys.currentState.location.P)
  if gun_needs_detach(human_attached_gun__attachedGunEid, humanPos)
    sendEvent(eid, [[CmdDetachAttachedGun]])
    sendEvent(eid, [[CmdHeroLogEvent event="human_attached_gun_lost", text="human_attached_gun_lost"]])

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
    sendEventImmediate(eid, [[CmdApplyRagdollParameters  cur_time=get_sync_time()]])

    animchar |> animchar_setPostController(*ragdoll)
    animchar |> animchar_act(0.0, true)