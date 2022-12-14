require ecs
require ecs.common
require app
require EnlistedNet
require game.es.events
require EnlistedHuman
require EnlistedWeapon
require DagorMath
require DagorSystem
require AnimV20
require GeomNodeTree
require common_shooter.events_common_shooter
require common_shooter.es.human_weap_common


[es]
def human_optics_deviation_es(info : UpdateStageInfoAct;
                              eid : EntityId;
                              human_net_phys : HumanActor;
                              human_weap__currentGunEid : EntityId;
                              human_weap__currentGunModEids : ecs::EidList;
                              var entity_mods__shotDeviationMods : ecs::Object)
  var gunScopeEid = find_scope_eid(human_weap__currentGunModEids)
  let isIntegratedScope = get_bool(human_weap__currentGunEid, "gun__integratedScope") ?? false

  if isIntegratedScope && !gunScopeEid
    gunScopeEid = human_weap__currentGunEid

  var devMult = 1.0
  if human_net_phys.phys.currentState.isAiming
    query(gunScopeEid) <| $ [es] (gunmod__deviationMult : float)
      devMult = gunmod__deviationMult

  let itf = entity_mods__shotDeviationMods |> get_float("optics_devitiation")

  var changed = false
  if itf != null
    if (*itf) != devMult
      changed = true
  else
    changed = true

  entity_mods__shotDeviationMods |> set("optics_devitiation", devMult)

  if changed
    sendEvent(eid, [[EventOnModsChanged]])


def set_lookat_from_sight_node(cur_time : float;
                               human_net_phys : HumanActor;
                               optics_cam_node : int;
                               animchar : AnimcharBaseComponent;
                               human__aimTm : float3x4;
                               human_weap__recoilPunchPos : float;
                               gun_tm : float3x4;
                               bindedCamera : EntityId;
                               cam_shift_min : float;
                               cam_shift_max : float;
                               cam_fov_min : float;
                               cam_fov_max : float;
                               gunmod_eid : EntityId;
                               var camera__look_at : DPoint3&;
                               var gun_aim_offset : float2&)
  if optics_cam_node < 0
    return

  let nodeDir = -DPoint3(gun_tm[2])
  let wposRelScalar = *animchar.nodeTree |> geomtree_getNodeWposRel(optics_cam_node)
  let wtmOfs = *animchar.nodeTree |> geomtree_getWtmOfs()
  var wpos = DPoint3(wposRelScalar) + DPoint3(wtmOfs)

  query(bindedCamera) <| $ [es] (fov : float;
                                 camera__active : bool)
    if !camera__active
      return

    let lookDir = normalize(human__aimTm[0])
    let shift = cvt(fov, cam_fov_min, cam_fov_max, cam_shift_min, cam_shift_max) - human_weap__recoilPunchPos
    let threshold = 0.5
    wpos += nodeDir * threshold - DPoint3(lookDir) * (shift + threshold)

  assume hphys = human_net_phys.phys
  let interpK = get_phys_interpk_clamped(hphys, cur_time)
  let aimPosition = lerp(hphys.previousState.aimPosition, hphys.currentState.aimPosition, interpK)
  let zoomPosition = lerp(hphys.previousState.zoomPosition, hphys.currentState.zoomPosition, interpK)
  let baseValue = has(gunmod_eid, "isCameraAlwaysOnScope") ? 1.0 : 0.0
  let lerpFactor = lerp(0.0, max(zoomPosition, baseValue), aimPosition)
  camera__look_at = lerp(camera__look_at, wpos, lerpFactor)
  gun_aim_offset = lerp(gun_aim_offset, float2(0.0, 0.0), float2(lerpFactor))


[es(tag=render,
     before=before_camera_sync,
     after=(human_fpv_cam_pos, animchar_cam_target_es, animchar_cam_target_with_offset_es, human_gun_lookat_camera_es),
     REQUIRE=hero)]
def human_optics_lookat_camera_es(info : UpdateStageInfoAct;
                                  human__aimTm : float3x4;
                                  human_net_phys : HumanActor;
                                  human_weap__currentGunEid : EntityId;
                                  human_weap__currentGunModEids : ecs::EidList;
                                  human_weap__recoilPunchPos : float;
                                  bindedCamera : EntityId;
                                  var camera__look_at : DPoint3&;
                                  var camera__gunAimOffset : float2&)
  var gunScopeEid = find_scope_eid(human_weap__currentGunModEids)
  let isIntegratedScope = get_bool(human_weap__currentGunEid, "gun__integratedScope") ?? false
  if isIntegratedScope && !gunScopeEid
    gunScopeEid = human_weap__currentGunEid

  var gunTm = human__aimTm
  query(human_weap__currentGunEid) <| $ [es] (animchar : AnimcharBaseComponent)
    animchar |> animchar_get_tm(gunTm)


  query(gunScopeEid) <| $ [es] (gunmod__camNodeId : int;
                                animchar : AnimcharBaseComponent;
                                gunmod__camShiftMin : float;
                                gunmod__camShiftMax : float;
                                gunmod__camFovMin : float;
                                gunmod__camFovMax : float)
    set_lookat_from_sight_node(info.curTime, human_net_phys,
                               gunmod__camNodeId, animchar,
                               human__aimTm, human_weap__recoilPunchPos,
                               gunTm, bindedCamera,
                               gunmod__camShiftMin, gunmod__camShiftMax,
                               gunmod__camFovMin, gunmod__camFovMax,
                               gunScopeEid,
                               camera__look_at,
                               camera__gunAimOffset)


def human_weap_mod_activate(eid : EntityId;
                            isDowned : bool;
                            human_weap__gunEids : EidList;
                            human_weap__gunMods : Array;
                            human_weap__reloadFinishTime : float;
                            slot_id : int;
                            activate : bool;
                            var human_weap__weapModActivateStartTime : float&;
                            var human_weap__weapModActivateFinishTime : float&)
  verify(is_server())

  if slot_id < 0 || slot_id >= length(human_weap__gunMods) || isDowned
    return

  let curTime = get_sync_time()
  let inProgress = curTime <= human_weap__weapModActivateFinishTime
  if inProgress
    return

  if !human_weap_can_reload(eid, human_weap__gunEids[slot_id]) || (human_weap__reloadFinishTime > curTime)
    return

  let gunModEids = get_ecs_EidList(human_weap__gunMods[slot_id])
  for gunMod in *gunModEids
    query(gunMod) <| $ [es] (weapon_mod__active : bool;
                             weapon_mod__activateTime : float;
                             weapon_mod__deactivateTime : float;
                             gun__ammo : int;
                             gun__totalAmmo : int;
                             ramrodGun : Tag const?)
      if weapon_mod__active == activate || (
        ramrodGun != null && gun__ammo == 0 && gun__totalAmmo == 0)
        return

      human_weap__weapModActivateStartTime = curTime
      human_weap__weapModActivateFinishTime = curTime + (activate ? weapon_mod__activateTime : weapon_mod__deactivateTime)


[es]
def human_weap_mod_toggle_es(evt : CmdWeapModToggle; eid : EntityId; human_weap__gunMods : Array)
  if evt.slotId < 0 || evt.slotId >= length(human_weap__gunMods)
    return

  let gunModEids = get_ecs_EidList(human_weap__gunMods[evt.slotId])
  for gunMod in *gunModEids
    ecs::query(gunMod) <| $ [es] (weapon_mod__active : bool)
      sendEvent(eid, [[CmdWeapModActivate slotId=evt.slotId, activate=!weapon_mod__active]])


[es(tag=server, before=net_phys_update_es, before=human_weap_update_es)]
def human_weap_mod_active_update_es(info : UpdateStageInfoAct;
                                    human_weap__gunMods : Array;
                                    human_weap__currentGunSlot : int;
                                    var human_weap__weapModActivateStartTime : float&;
                                    var human_weap__weapModActivateFinishTime : float&)
  if (human_weap__weapModActivateStartTime < 0.0) || (human_weap__currentGunSlot < 0)
    return

  let inProgress = info.curTime <= human_weap__weapModActivateFinishTime
  if inProgress
    return

  let gunModEids = get_ecs_EidList(human_weap__gunMods[human_weap__currentGunSlot])
  for gunMod in *gunModEids
    ecs::query(gunMod) <| $ [es] (var weapon_mod__active : bool&)
      weapon_mod__active = !weapon_mod__active
      human_weap__weapModActivateStartTime = -1.0
      human_weap__weapModActivateFinishTime = -1.0


[es(tag=server)]
def human_weap_mod_activate_server_es(evt : CmdWeapModActivate;
                                      eid : EntityId;
                                      isDowned : bool;
                                      human_weap__gunEids : EidList;
                                      human_weap__gunMods : Array;
                                      human_weap__reloadFinishTime : float;
                                      var human_weap__weapModActivateStartTime : float&;
                                      var human_weap__weapModActivateFinishTime : float&)
  human_weap_mod_activate(eid, isDowned, human_weap__gunEids, human_weap__gunMods,
                          human_weap__reloadFinishTime,
                          evt.slotId, evt.activate,
                          human_weap__weapModActivateStartTime,
                          human_weap__weapModActivateFinishTime)


[es(tag=netClient)]
def human_weap_mod_activate_client_es(evt : CmdWeapModActivate; eid : EntityId)
  send_net_event(eid, [[HumanRequestModActivate slotId=evt.slotId, activate=evt.activate]])


[es(tag=server)]
def human_weap_mod_activate_req_es(evt : HumanRequestModActivate;
                                   eid : EntityId;
                                   isDowned : bool;
                                   human_weap__gunEids : EidList;
                                   human_weap__gunMods : Array;
                                   human_weap__reloadFinishTime : float;
                                   var human_weap__weapModActivateStartTime : float&;
                                   var human_weap__weapModActivateFinishTime : float&)
  human_weap_mod_activate(eid, isDowned, human_weap__gunEids, human_weap__gunMods,
                          human_weap__reloadFinishTime,
                          evt.slotId, evt.activate,
                          human_weap__weapModActivateStartTime,
                          human_weap__weapModActivateFinishTime)


[es(REQUIRE=watchedByPlr, after=camera_set_sync, before=before_camera_sync, REQUIRE_NOT=deadEntity)]
def human_optics_camera_es(info : UpdateStageInfoAct;
                           human_net_phys : HumanActor;
                           human_weap__currentGunEid : EntityId;
                           human_weap__currentGunModEids : EidList;
                           var camera__magnification : float&;
                           var human_weap__opticsAttached : bool&)
  var gunScopeEid = find_scope_eid(human_weap__currentGunModEids)
  let isIntegratedScope = get_bool(human_weap__currentGunEid, "gun__integratedScope") ?? false

  if isIntegratedScope && !gunScopeEid
    gunScopeEid = human_weap__currentGunEid

  if !human_weap__currentGunEid
    camera__magnification = 1.0
    return

  let interpK = get_phys_interpk_clamped(human_net_phys.phys, info.curTime)
  let aimPosition = lerp(human_net_phys.phys.previousState.aimPosition, human_net_phys.phys.currentState.aimPosition, interpK)

  let zoomFactor = get_float(gunScopeEid, "gunmod__zoomFactor") ?? 0.0
  let zoomPosition = lerp(human_net_phys.phys.previousState.zoomPosition,
                          human_net_phys.phys.currentState.zoomPosition, interpK)

  human_weap__opticsAttached = zoomFactor > 0.0

  // TODO: remove this sideeffect and make ECS_TAG
  setOptional(human_weap__currentGunEid, "gun__opticsAttached", human_weap__opticsAttached)

  if !human_weap__opticsAttached
    let gunMagnification = get_float(human_weap__currentGunEid, "gun__magnification") ?? 1.5
    camera__magnification = lerp(1.0, gunMagnification, zoomPosition)
    return

  camera__magnification = lerp(1.0, zoomFactor, lerp(0.0, zoomPosition, aimPosition))

[es(tag=gameClient, on_appear, REQUIRE=(deadEntity, watchedByPlr), after=camera_set_sync, before=before_camera_sync)]
def human_reset_optics_on_die_es(evt : Event; var camera__magnification : float&)
  camera__magnification = 1.0

[es(tag=gameClient, on_appear)]
def human_optics_init_cam_node(evt : Event;
                               eid : EntityId;
                               animchar : AnimcharBaseComponent;
                               gunmod__camNode : string;
                               var gunmod__camNodeId : int&)
  gunmod__camNodeId = geomtree_findNodeIndex(*animchar.nodeTree, gunmod__camNode)
  if gunmod__camNodeId < 0
    logerr("node '{gunmod__camNode}' not found in animchar of gun '{getEntityTemplateName(eid)}'")