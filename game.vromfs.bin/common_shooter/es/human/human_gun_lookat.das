require game.es.events
require ecs
require app
require EnlistedNet
require math
require math.base
require math.linear
require inventory
require EnlistedDm
require DagorMath
require GamePhys
require HumanPhys
require EnlistedHuman
require AnimV20
require GeomNodeTree

[es(tag=gameClient, before=human_gun_lookat_camera_on_action_es)]
def human_weap_camera_in_action_es(act : UpdateStageInfoAct;
                                   action__running : bool;
                                   human_weap__cameraTransitionOnActionTime : float = 0.2;
                                   var human_weap__cameraTransitionOnActionProgress : float&)
  if action__running || human_weap__cameraTransitionOnActionProgress > 0.0
    let change = safediv(act.dt, human_weap__cameraTransitionOnActionTime)
    human_weap__cameraTransitionOnActionProgress += action__running ? change : -change
    human_weap__cameraTransitionOnActionProgress = saturate(human_weap__cameraTransitionOnActionProgress)

[es(tag=render, REQUIRE=hero, after=(camera_set_sync, human_fpv_cam_pos), before=before_camera_sync,
     after=animchar_cam_target_es, after=animchar_cam_target_with_offset_es)]
def human_gun_lookat_camera_es(info : UpdateStageInfoAct;
                               human_net_phys : HumanActor;
                               human_weap__currentGunEid : EntityId;
                               human__aimTm : float3x4;
                               human_weap__gunOffset : float3;
                               action__running : bool = false;
                               var camera__gunAimOffset : float2&;
                               var camera__look_at : DPoint3&)

  query(human_weap__currentGunEid) <| $ [es] (entity_cam_nodes__aimNodeIdx : int;
                                              animchar : AnimcharBaseComponent;
                                              weapon_frontsight_node__nodeIdx : int?;
                                              weapon_rearsight_node__nodeIdx : int?;
                                              weapon_sight__minDistFrom : float = 0.05)

    if entity_cam_nodes__aimNodeIdx < 0
      return

    let interpK = get_phys_interpk_clamped(human_net_phys.phys, info.curTime)
    let physPreviousStateAimPosition = human_net_phys.phys.previousState.aimPosition
    let physCurrentStateAimPosition = human_net_phys.phys.currentState.aimPosition
    let aimPosition = lerp(physPreviousStateAimPosition, physCurrentStateAimPosition, interpK)

    let wofsF = animchar.nodeTree |> geomtree_getWtmOfs()
    let wofs = DPoint3(wofsF)
    var aimPos = animchar.nodeTree |> geomtree_getNodeWposRel(entity_cam_nodes__aimNodeIdx)
    var aimOffset = float2(0.0, 0.0)

    if weapon_frontsight_node__nodeIdx != null && weapon_rearsight_node__nodeIdx != null
      let weaponFrontsightNodeIdx = *weapon_frontsight_node__nodeIdx
      let weaponRearsightNodeIdx = *weapon_rearsight_node__nodeIdx

      assert(weaponFrontsightNodeIdx >= 0)
      assert(weaponRearsightNodeIdx >= 0)
      let fsPos = animchar.nodeTree |> geomtree_getNodeWposRel(weaponFrontsightNodeIdx)
      let rsPos = animchar.nodeTree |> geomtree_getNodeWposRel(weaponRearsightNodeIdx)

      var frontSightTm : float3x4
      animchar.nodeTree.root |> geomtreenode_getWtmScalar(frontSightTm)
      frontSightTm[3] = animchar.nodeTree |> geomtree_getNodeWposRel(weaponFrontsightNodeIdx)

      let relativeRearPos = inverse(frontSightTm) * rsPos // relative pos
      // Now construct augmented tm so we can use it
      var augmentedFrontSightTm = frontSightTm
      augmentedFrontSightTm[0] = human__aimTm[2]
      augmentedFrontSightTm[1] = human__aimTm[1]
      augmentedFrontSightTm[2] = -human__aimTm[0]

      var len = length(fsPos - aimPos)
      let dir = rsPos - fsPos
      let dist = length(dir)
      len = max(dist + weapon_sight__minDistFrom, len + human_weap__gunOffset.x)
      aimPos = augmentedFrontSightTm * (normalize(relativeRearPos) * len)
      aimOffset = float2(0.0, atan2(-relativeRearPos.y, relativeRearPos.z))

    if !action__running
      camera__look_at = lerp(camera__look_at, wofs + DPoint3(aimPos), aimPosition)
      aimOffset = lerp(float2(0.0, 0.0), aimOffset, float2(aimPosition))
    else
      aimOffset = float2(0.0, 0.0)

    camera__gunAimOffset = approach(camera__gunAimOffset, aimOffset, info.dt, 0.1)

[es(tag=render, REQUIRE=hero, after=camera_set_sync, before=before_camera_sync,
     after=human_gun_lookat_camera_es, after=human_optics_lookat_camera_es)]
def human_gun_lookat_camera_on_action_es(info : UpdateStageInfoAct;
                                         animchar : AnimcharBaseComponent;
                                         animchar_camera_target__nodeIndex : int;
                                         human_weap__cameraTransitionOnActionProgress : float;
                                         var camera__look_at : DPoint3&)
  let progress = saturate(human_weap__cameraTransitionOnActionProgress)
  if (progress > 0.0)
    let animcharCameraTargetPos = animchar.nodeTree |> geomtree_getNodeWpos(animchar_camera_target__nodeIndex)
    camera__look_at = lerp(camera__look_at, DPoint3(animcharCameraTargetPos), progress)