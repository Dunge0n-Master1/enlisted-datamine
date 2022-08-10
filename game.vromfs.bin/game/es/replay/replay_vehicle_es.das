require ecs
require game.events_game
require DagorMath
require CollRes

// Why: In replay mode we have a bug with fps camera in vehicle
// fps camera work same as tps, but vehicle part is hidden. So enable all vehicle part for now
[es(tag=playingReplay, on_appear, on_disappear, on_event=EventOnSeatOwnersChanged, REQUIRE=heroVehicle, after=vehicle_is_cockpit_seat)]
def replay_disable_hero_cockpit(evt : Event; var cockpit__isHeroInCockpit : bool&)
  cockpit__isHeroInCockpit = false

[es(tag=playingReplay, track=isInVehicle, REQUIRE=watchedByPlr, on_appear)]
def replay_camera_in_vehicle_es(evt : Event;
                                isInVehicle : bool;
                                isTpsView : bool;
                                bindedCamera : EntityId;
                                var replay__prevHumanCam : EntityId&)
  if !isInVehicle
    sendEvent(replay__prevHumanCam, [[ReplaySetCamera]])
    replay__prevHumanCam = INVALID_ENTITY_ID
    return

  if !replay__prevHumanCam
    replay__prevHumanCam = bindedCamera

  if !isTpsView
    broadcastEvent([[ReplaySetTpsCamera]])

[es(tag=playingReplay, REQUIRE=watchedByPlr, before=shooter_cam_update_tm_es,
  after=(human_fpv_cam_pos, animchar_cam_target_with_offset_es, animchar_cam_target_es))]
def replay_vehicle_set_tps_camera_look_at(evt : UpdateStageInfoAct;
                                          human_anim__vehicleSelected : EntityId;
                                          isTpsView : bool;
                                          var camera__look_at aka human__camera__look_at : DPoint3&)
  if !isTpsView
    return

  query(human_anim__vehicleSelected) <| $ [es] (transform : float3x4;
                                                collres : CollisionResource;
                                                var camera__look_at : DPoint3&)
    let box = transform * BBox3(collres.vFullBBox.bmin.xyz, collres.vFullBBox.bmax.xyz)
    let pos = box.center
    human__camera__look_at = DPoint3(pos)
    camera__look_at = DPoint3(pos)
