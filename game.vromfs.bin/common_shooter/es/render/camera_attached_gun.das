require ecs
require app
require game.es.events
require game.es.camera_common
require game.utils.hero
require common_shooter.events_common_shooter
require DagorSystem
require DngCamera
require DngHuman


[es(tag=gameClient)]
def human_attach_to_gun_complete_es(evt : HumanAttachToGunComplete;
                                    eid : EntityId;
                                    var human_attached_gun__gunCamEid : EntityId&;
                                    var human_attached_gun__prevCamEid : EntityId&)
  let gunEid = evt.gun_eid
  if has(eid, "hero")
    human_attached_gun__prevCamEid = get_cur_cam_entity()
    if human_attached_gun__gunCamEid == INVALID_ENTITY_ID
      let gunCamTemplate = get_ecs_string(gunEid, "gun__cameraTemplate")
      let gunName = (gunCamTemplate != null) ? (*gunCamTemplate) |> string() : "gun_cam"
      human_attached_gun__gunCamEid = create_camera_by_name(gunName,
                                                               gunEid,
                                                               null,
                                                               uint(CreateCameraFlags CCF_SET_ENTITY))

    // set & save prev cam for restore
    set_scene_camera_entity(human_attached_gun__gunCamEid)


[es(tag=gameClient, on_event=HumanDetachFromGunComplete, on_disappear, REQUIRE=watchedByPlr)]
def human_detach_from_gun_complete_es(evt : Event;
                                      eid : EntityId;
                                      var human_attached_gun__gunCamEid : EntityId&;
                                      var human_attached_gun__prevCamEid : EntityId&)
  if human_attached_gun__gunCamEid != INVALID_ENTITY_ID
    destroyEntity(human_attached_gun__gunCamEid)
    human_attached_gun__gunCamEid = INVALID_ENTITY_ID
    set_scene_camera_entity(human_attached_gun__prevCamEid) // restore prev cam
    human_attached_gun__prevCamEid = INVALID_ENTITY_ID
    sendEvent(eid, [[EventOnEntityReset]])


[es(after=camera_set_sync, before=before_camera_sync)]
def human_attached_gun_camera_es(info : UpdateStageInfoAct;
                                 human_attached_gun__attachedGunEid : EntityId;
                                 human_net_phys : HumanActor)
  // Entity might be destroyed but not detached yet (which will happens further in update es)
  if doesEntityExist(human_attached_gun__attachedGunEid)
    let interpK = get_phys_interpk_clamped(human_net_phys.phys, get_sync_time())
    let aimPosition = lerp(human_net_phys.phys.previousState.aimPosition, human_net_phys.phys.currentState.aimPosition, interpK)
    let gunMagnification = get_float(human_attached_gun__attachedGunEid, "gun__magnification") ?? 1.5

    query(human_attached_gun__attachedGunEid) <| $ [es] (var camera__magnification : float&)
      camera__magnification = lerp(1.0, gunMagnification, aimPosition)