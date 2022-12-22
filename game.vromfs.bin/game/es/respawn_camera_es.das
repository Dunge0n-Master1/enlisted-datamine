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

def setup_camera_as_active(cam_eid : EntityId; cam_name : string)
  query(get_local_player_eid()) <| $ [es] (var activeCamEid : EntityId&; var activeCamName : das_string)
    activeCamEid = cam_eid
    activeCamName := cam_name

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
  ecs::query() <| $ [es] (eid : EntityId; respawnCameraForTeam : int)
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

def find_middle_resp_point(respTeam : int)
  var pos = float3(0.0, 0.0, 0.0)
  var respsFound = 0
  ecs::query() <| $ [es(REQUIRE=respbase, REQUIRE_NOT=(aircraftRespbase, playerRespawnBase))] (eid : EntityId; team : int; active : bool; transform : float3x4)
    if (active || has(eid, "customRespawnBase")) && (is_teams_friendly(team, respTeam) || team == TEAM_UNASSIGNED)
      respsFound++
      pos += transform[3]
  if respsFound > 0
    pos = pos / float(respsFound)
  return pos

def find_target_point_for_respawn_cam()
  var pos = float3(0.0, 0.0, 0.0)
  var pointsFound = 0
  ecs::query() <| $ [es(REQUIRE=capzone)] (active : bool; transform : float3x4)
    if active
      pointsFound++
      pos += transform[3]
  if pointsFound == 0
    ecs::query() <| $ [es(REQUIRE=respbase, REQUIRE_NOT=(aircraftRespbase, playerRespawnBase, customRespawnBase))] (active : bool; transform : float3x4)
      if active
        pointsFound++
        pos += transform[3]
  if pointsFound > 0
    pos = pos / float(pointsFound)
  return [[auto pointsFound, pos]]

[es(tag=server, on_appear, on_event=EventLevelLoaded, track=(active, team), REQUIRE=active, REQUIRE=respbase)]
def respawn_camera_set_target_params_es(evt : Event; team : int)
  ecs::query() <| $ [es] (moveCameraToHeight : float;
                          var respawnCameraLookFrom : float3&;
                          respawnCameraForTeam : int;
                          respawnSelectorDistanceMult : float)
    if !(is_teams_friendly(respawnCameraForTeam, team) || respawnCameraForTeam == TEAM_UNASSIGNED)
      return
    var lookAt = find_middle_resp_point(team)
    let lookTo = find_target_point_for_respawn_cam()
    var found = false
    ecs::find_query() <| $ [es] (respawnBaseGroup : int)
      if respawnBaseGroup != -1
        found = true
      return found
    if found
      let diff = lookAt - lookTo._1
      lookAt += diff * respawnSelectorDistanceMult
    lookAt[1] = lookAt[1] + moveCameraToHeight
    respawnCameraLookFrom = lookAt;

def update_respawn_cameras()
  ecs::query() <| $ [es] (eid : EntityId;
                          respawn_camera__minSpeed : float;
                          var respawn_camera__currentSpeed : float&;
                          var respawn_camera__lookAt : float3&)
    let lookAt = find_target_point_for_respawn_cam()
    if lookAt._0 > 0
      respawn_camera__lookAt = lookAt._1
      addSubTemplate(eid, "respawn_camera_update_transform")
      respawn_camera__currentSpeed = respawn_camera__minSpeed

[es(tag=gameClient, on_appear, on_event=EventLevelLoaded, track=active, REQUIRE=active, REQUIRE=capzone)]
def respawn_camera_zone_changed_params_es(evt : Event)
  update_respawn_cameras()

[es(tag=gameClient, on_appear, on_event=EventLevelLoaded, REQUIRE=respawnCameraForTeam)]
def respawn_camera_appear_update(evt : Event)
  update_respawn_cameras()

[es(tag=gameClient, on_appear, track=respawnCameraLookFrom, REQUIRE=respawnCameraLookFrom)]
def respawn_camera_set_position_params_es(evt : Event;
                                          eid : EntityId;
                                          respawn_camera__minSpeed : float;
                                          var respawn_camera__currentSpeed : float&)
  addSubTemplate(eid, "respawn_camera_update_transform")
  respawn_camera__currentSpeed = respawn_camera__minSpeed

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
