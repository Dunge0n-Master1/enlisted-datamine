require ecs
require game.events_game
require DagorMath
require game.utils.team
require math
require math.base
require app
require player
require replay
require DagorSystem
require game.es.respawn_base_common
require enlisted.events_enlisted
require game.es.paratroopers_common
require game.es.battle_area_common
require game.es.respawn_camera_common

[es(track=respawner__respStartTime, after=respawn_camera_apply_target_es)]
def respawn_camera_delay_change_target_es(evt : Event;
                                          respawner__respStartTime : float;
                                          team : int;
                                          var respawner__changeCameraAtTime : float&)
  if respawner__respStartTime <= 0.0
    print("respawn camera: reset camera timer {respawner__changeCameraAtTime}")
    respawner__changeCameraAtTime = 0.0
    return
  ecs::query() <| $ [es] (respawnCameraForTeam : int; respawnCamera__showDelay : float)
    if is_teams_friendly(team, respawnCameraForTeam) || respawnCameraForTeam == TEAM_UNASSIGNED
      respawner__changeCameraAtTime = get_sync_time() + respawnCamera__showDelay
      print("respawn camera: init respawn camera timer. Camera will be init at {respawner__changeCameraAtTime}")

[es(on_appear, REQUIRE=respawnCameraForTeam)]
def reset_respawn_camera_rotation(evt : Event; var transform : float3x4)
  var newTm = IDENT_TM
  newTm[3] = transform[3]
  transform = newTm

def create_respawn_cam(fromEid, toEid : EntityId; transform : float3x4)
  ecs::query(toEid) <| $ [es] (respawnCameraTemplate : string; respawnCameraForTeam : int)
    let respawnCam = createEntity(respawnCameraTemplate) <| $(var init : ComponentsInitializer)
      set(init, "camera__target", fromEid)
      set(init, "camera__active", true)
      set(init, "transform", transform)
      set(init, "team", respawnCameraForTeam)
      set(init, "shooter_cam__lastPos", transform[3])
      set(init, "respawnCameraTargerPoint", toEid)
    setup_camera_as_active(respawnCam, respawnCameraTemplate)
  update_respawn_cameras()

[es(tag=gameClient, on_appear)]
def set_respawn_camera_mode(evt : Event; var respawn_camera__lookSide : bool&)
  query(get_local_player_eid()) <| $ [es] (respawner__paratroopersChooserOn : bool)
    respawn_camera__lookSide = !respawner__paratroopersChooserOn

[es(REQUIRE=respawnCamera, after=lut_switcher_on_vehicle_gain_input_es)]
def respawn_camera_apply_target_test_es(info : UpdateStageInfoAct;
                                        var camera__target : EntityId&;
                                        var shooter_cam__alternative_settings : bool&;
                                        respawnCameraTargerPoint : EntityId)
  camera__target = respawnCameraTargerPoint
  shooter_cam__alternative_settings = true

def set_respawn_cam(targetEid : EntityId)
  query() <| $ [es] (var camera__active : bool&; camera__target : EntityId; transform : float3x4)
    if !camera__active
      return
    camera__active = false
    create_respawn_cam(camera__target, targetEid, transform)

def respawn_camera_apply_target(team : int; var respawner__changeCameraAtTime : float&)
  if respawner__changeCameraAtTime <= 0.0 || get_sync_time() < respawner__changeCameraAtTime
    return
  query() <| $ [es] (eid : EntityId; respawnCameraForTeam : int)
    if is_teams_friendly(team, respawnCameraForTeam) || respawnCameraForTeam == TEAM_UNASSIGNED
      set_respawn_cam(eid)
      ecs::find_query() <| $ [es(REQUIRE=color_grading)] (eid : EntityId)
        sendEvent(eid, [[EventLutSwitcherAliveState]])
        return true
  print("respawn camera: Respawn camera apply target complete. {respawner__changeCameraAtTime}")
  respawner__changeCameraAtTime = 0.0

[es(tag=gameClient, after=lut_switcher_on_vehicle_gain_input_es, REQUIRE=player)]
def respawn_camera_apply_target_respawner_es(info : UpdateStageInfoAct;
                                             team : int;
                                             is_local : bool;
                                             respawner__squad : EntityId = INVALID_ENTITY_ID;
                                             var respawner__changeCameraAtTime : float&)
  if !is_local || is_replay_playing()
    return
  var shouldEnableCam = !respawner__squad
  query(respawner__squad) <| $ [es] (squad__numAliveMembers : int = 0)
    shouldEnableCam = squad__numAliveMembers <= 0
  if shouldEnableCam
    respawn_camera_apply_target(team, respawner__changeCameraAtTime)

def get_camera_look_from(team : int; camera_height : float; respawn_mult : float3)
  // this naming is a mess and i hope you are brave enough to fix it. cause im not.
  var lookAt = find_middle_resp_point(team)
  let lookTo = find_target_point_for_respawn_cam()
  var found = false
  find_query() <| $ [es] (respawnBaseGroup : int)
    if respawnBaseGroup != -1
      found = true
    return found
  if found
    let diff = lookAt - lookTo._1
    lookAt += diff * respawn_mult
  lookAt[1] = lookAt[1] + camera_height
  return lookAt


def set_look_params_for_above_respawn_camera(eid : EntityId; isFirstSpawn : bool)
  query(eid) <| $ [es] (respawnCameraLookFromSide : float3;
                        respawnSelectorAboveHeight : float;
                        respawnSelectorDistanceMultAbove : float;
                        respawnCameraStaticSideLook : bool;
                        var respawn_camera__lookAt : float3&;
                        var respawnCameraLookFrom : float3&)
    var aboveCamTarget : float2
    if !respawnCameraStaticSideLook
      aboveCamTarget = get_above_camera_target()
    else
      find_query() <| $ [es(REQUIRE=initialCamTag)] (transform : float3x4)
        aboveCamTarget = transform[3].xz
        return true
    var diff : float3
    if isFirstSpawn || respawnCameraStaticSideLook
      query() <| $ [es(REQUIRE=initialCamTag)] (transform : float3x4)
        diff = -transform[2]
    else
      diff = respawnCameraLookFromSide - float3(aboveCamTarget.x, 0., aboveCamTarget.y)
    diff.y = 0.
    diff = normalize(diff)
    respawn_camera__lookAt = float3(aboveCamTarget.x, 0., aboveCamTarget.y)
    respawnCameraLookFrom = respawn_camera__lookAt + diff * respawnSelectorDistanceMultAbove + float3(0., respawnSelectorAboveHeight, 0.)


[es(tag=gameClient, after=set_respawn_camera_mode, on_appear, track=(respawnCameraLookFromSide, respawn_camera__lookSide), REQUIRE=(respawnCameraLookFromSide, respawn_camera__lookSide))]
def update_cameras_on_params_change(evt : Event)
  update_respawn_cameras()

[es(tag=server, on_appear, on_event=EventLevelLoaded, track=(active, team), REQUIRE=(active, respbase))]
def respawn_camera_set_look_from_side_es(evt : Event; team : int)
  query() <| $ [es] (moveCameraToHeight : float;
                     respawnCameraForTeam : int;
                     respawnSelectorDistanceMult : float;
                     var respawnCameraLookFromSide : float3&)
    if !(is_teams_friendly(respawnCameraForTeam, team) || respawnCameraForTeam == TEAM_UNASSIGNED)
      return

    respawnCameraLookFromSide = get_camera_look_from(team, moveCameraToHeight, float3(respawnSelectorDistanceMult))

def update_respawn_cameras()
  query() <| $ [es] (eid : EntityId;
                     respawn_camera__minSpeed : float;
                     respawnCameraLookFromSide : float3;
                     respawnCameraStaticSideLook : bool;
                     respawn_camera__lookSide : bool;
                     var respawnCameraLookFrom : float3&;
                     var respawn_camera__currentSpeed : float&;
                     var respawn_camera__lookAt : float3&)
    var isFirstSpawn = false
    query(get_local_player_eid()) <| $ [es] (respawner__isFirstSpawn : bool)
      isFirstSpawn = respawner__isFirstSpawn
    if !respawn_camera__lookSide
      set_look_params_for_above_respawn_camera(eid, isFirstSpawn)
    else
      if isFirstSpawn || respawnCameraStaticSideLook
        query() <| $ [es(REQUIRE=initialCamTag)] (transform : float3x4)
          respawnCameraLookFrom = transform[3]
          respawn_camera__lookAt = transform[3] + transform[2] * 100.
      else
        let lookAt = find_target_point_for_respawn_cam()
        if lookAt._0 > 0
          respawn_camera__lookAt = lookAt._1
          respawnCameraLookFrom = respawnCameraLookFromSide
    addSubTemplate(eid, "respawn_camera_update_transform")
    respawn_camera__currentSpeed = respawn_camera__minSpeed

[es(tag=gameClient, on_appear, track=battle_area__requireUpdate, REQUIRE=battle_area__requireUpdate)]
def update_cameras_on_battle_area_appear(evt : Event)
  update_respawn_cameras()

[es(tag=gameClient, on_appear, on_event=EventLevelLoaded, track=active, REQUIRE=active, REQUIRE=capzone)]
def respawn_camera_zone_changed_params_es(evt : Event)
  update_respawn_cameras()

[es(tag=gameClient, on_appear, on_event=EventLevelLoaded, REQUIRE=respawnCameraForTeam)]
def respawn_camera_appear_update(evt : Event)
  update_respawn_cameras()

[es(tag=gameClient, before=(shooter_cam_rotate_es, shooter_cam_update_tm_es), REQUIRE=respawnCameraUpdateTransform)]
def respawn_camera_update(info : UpdateStageInfoAct;
                          eid : EntityId;
                          respawnCameraLookFrom : float3;
                          respawn_camera__lookAt : float3;
                          respawn_camera__maxSpeed : float;
                          respawn_camera__minSpeed : float;
                          respawn_camera__acceleration : float;
                          var respawn_camera__lookAtCurrent : float3&;
                          var respawn_camera__currentSpeed : float&;
                          var camera__look_at : DPoint3;
                          var camera__lookDir : float3&;
                          var transform : float3x4)
  // We use increasing speed in a lerp function to get an effect of slow start and slow finish
  respawn_camera__currentSpeed = move_to_scalar(respawn_camera__currentSpeed, respawn_camera__maxSpeed,
                                                info.dt, respawn_camera__acceleration)
  let lookFromCurrent = approach_move(transform[3], respawnCameraLookFrom, info.dt,
                                      safediv(1.0, respawn_camera__currentSpeed), respawn_camera__minSpeed)
  respawn_camera__lookAtCurrent = approach_move(respawn_camera__lookAtCurrent, respawn_camera__lookAt, info.dt,
                                                safediv(1.0, respawn_camera__currentSpeed), respawn_camera__minSpeed)
  let lookDirCurrent = normalize(respawn_camera__lookAtCurrent - lookFromCurrent)

  transform[3] = lookFromCurrent
  camera__look_at.x = double(lookFromCurrent[0])
  camera__look_at.y = double(lookFromCurrent[1])
  camera__look_at.z = double(lookFromCurrent[2])
  camera__lookDir = lookDirCurrent

  if length(respawnCameraLookFrom - transform[3]) < 0.01 && length(respawn_camera__lookAtCurrent - respawn_camera__lookAt) < 0.01
    removeSubTemplate(eid, "respawn_camera_update_transform")

[es(tag=(server, dev), on_event=EventLevelLoaded)]
def check_respawn_camera_team_set(evt : Event; eid : EntityId; respawnCameraForTeam : int)
  if respawnCameraForTeam == TEAM_UNASSIGNED
    let templateName = getEntityTemplateName(eid)
    logerr("Respawn camera eid: {eid} template: {templateName} has no team assigned")


[es(tag=gameClient)]
def create_respawn_camera_on_turn_camera_mode(evt : CmdTurnParatroopersCamera;
                                              team : int;
                                              var respawner__isRespawnCameraCreated : bool&)
  if respawner__isRespawnCameraCreated || !evt.paratroopersCameraOn
    return
  if (find_query() <| $ [es(REQUIRE=respawnCamera)] () => true)
    return
  find_query() <| $ [es] (eid : EntityId;
                          respawnCameraForTeam : int;
                          transform : float3x4)
    if team != respawnCameraForTeam
      return false
    query() <| $ [es] (var camera__active : bool&)
      camera__active = false
    respawner__isRespawnCameraCreated = true
    create_respawn_cam(eid, eid, transform)
    return true

[es(tag=gameClient, on_appear)]
def apply_camera_on_camera_target_appear_on_first_spawn(evt : Event;
                                                        eid : EntityId;
                                                        respawnCameraForTeam : int;
                                                        transform : float3x4)
  if (find_query() <| $ [es(REQUIRE=respawnCamera)] () => true)
    return
  query(get_local_player_eid()) <| $ [es] (team : int;
                                           respawner__isFirstSpawn : bool;
                                           respawner__paratroopersChooserOn : bool;
                                           var respawner__isRespawnCameraCreated : bool&)
    if team != respawnCameraForTeam || !respawner__isFirstSpawn || respawner__isRespawnCameraCreated || !respawner__paratroopersChooserOn
      return
    query() <| $ [es] (var camera__active : bool&)
      camera__active = false
    respawner__isRespawnCameraCreated = true
    create_respawn_cam(eid, eid, transform)

[es(tag=gameClient, on_appear, REQUIRE=respawnCamera)]
def delete_respawn_non_active_respawn_cameras(evt : Event; eid aka activeCam_eid : EntityId)
  query() <| $ [es(REQUIRE=respawnCamera)] (eid aka oldCam_eid : EntityId)
    if oldCam_eid != activeCam_eid
      destroyEntity(oldCam_eid)
