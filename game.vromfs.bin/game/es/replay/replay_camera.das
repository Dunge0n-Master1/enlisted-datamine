require ecs
require app
require game.es.events
require game.events_game
require DagorConsole
require DagorMath
require DagorSystem
require EnlistedHuman
require Dacoll
require math
require math.base
require game.utils.team
require player
require enlisted.events_enlisted
require EnlistedCamera

[es(tag=playingReplay, REQUIRE=replayCamera)]
def spectate_on_replay(evt : ChangeReplayTarget;
                       camera__target : EntityId)
  if evt.newReplayTarget != INVALID_ENTITY_ID && has(evt.newReplayTarget, "specTarget")
    set(evt.newReplayTarget, "specTarget", camera__target)

[es(tag=playingReplay, track=(camera__active, camera__target), REQUIRE=replayCamera, after=cam_target_switcher_es)]
def replay_change_human(evt : Event;
                        eid : EntityId;
                        camera__active : bool;
                        isTpsView aka camera__isTpsView : bool;
                        camera__target : EntityId)
  if !camera__active
    return

  var prevHumanCam = INVALID_ENTITY_ID
  find_query() <| $ [es(REQUIRE=isReplayObserved)] (eid : EntityId; replay__prevHumanCam : EntityId)
    if camera__target != eid
      removeSubTemplate(eid, "replay_observed")
    prevHumanCam = replay__prevHumanCam
    return true

  var player = INVALID_ENTITY_ID
  query(camera__target) <| $ [es(REQUIRE=isReplayObserved)] (possessedByPlr : EntityId;
                                                             var watchedByPlr : EntityId&;
                                                             var bindedCamera : EntityId&;
                                                             var replay__prevHumanCam : EntityId&;
                                                             var isTpsView : bool&;
                                                             var isCameraTarget : bool&)
    watchedByPlr = camera__target
    bindedCamera = eid
    isCameraTarget = true
    isTpsView = camera__isTpsView
    replay__prevHumanCam = prevHumanCam
    player = possessedByPlr

  query(camera__target) <| $ [es(REQUIRE_NOT=isReplayObserved)] (possessedByPlr : EntityId)
    let set_camera <- @ <| (target : EntityId)
      sendEvent(eid, [[CmdSetCameraTarget target=target]])

    addSubTemplate(camera__target, "replay_observed", set_camera) <| $(var init : ComponentsInitializer)
      set(init, "watchedByPlr", camera__target)
      set(init, "bindedCamera", eid)
      set(init, "isCameraTarget", true)
      set(init, "isTpsView", camera__isTpsView)
      set(init, "replay__prevHumanCam", prevHumanCam)
    player = possessedByPlr

  query() <| $ [es(REQUIRE=replayCamera)] (eid : EntityId)
    sendEvent(eid, [[ChangeReplayTarget newReplayTarget=player]])
  //in replay check is_local for print tip
  if player |> has("is_local")
    set_local_player_eid(player)

[es(tag=playingReplay, REQUIRE=(deadEntity, watchedByPlr), before=enlisted_next_replay_target_es)]
def replay_human_death_cam_timer_es(evt : UpdateStageInfoAct;
                                    bindedCamera : EntityId;
                                    replay__deadCamTime : float;
                                    var replay__deadCamTimer : float&)
  replay__deadCamTimer += evt.dt
  if replay__deadCamTimer < replay__deadCamTime
    return

  // Reset timer with very big negative value, to bypass send event twice
  replay__deadCamTimer = -1e10
  sendEvent(bindedCamera, [[NextReplayTarget delta=1]])

[es(tag=playingReplay, no_order, REQUIRE=replayCamera)]
def catch_human_view(evt : UpdateStageInfoAct;
                     eid : EntityId;
                     camera__target : EntityId;
                     camera__active : bool)
  if camera__active && camera__target == INVALID_ENTITY_ID
    sendEvent(eid, [[NextReplayTarget delta=1]])

[es(tag=playingReplay, REQUIRE_NOT=replay__overrideTargetSelect)]
def select_next_replay_target(evt : NextReplayTarget;
                              var camera__target : EntityId&;
                              var camera__prevTarget : EntityId&)
  var humans : array<EntityId>
  query() <| $ [es] (possessedByPlr : EntityId;
                     eid : EntityId)
    if possessedByPlr != INVALID_ENTITY_ID
      push(humans, eid)
  if length(humans) == 0
    return

  sort(humans) <| $(a, b : EntityId)
    var lhsName, rhsName : string
    query(a) <| $ [es] (possessedByPlr : EntityId)
      query(possessedByPlr) <| $ [es] (name : string)
        lhsName = name
    query(b) <| $ [es] (possessedByPlr : EntityId)
      query(possessedByPlr) <| $ [es] (name : string)
        rhsName = name
    return lhsName < rhsName

  var i : int = 0
  if camera__target != INVALID_ENTITY_ID
    for playerNo in iter_range(humans)
      if camera__target == humans[playerNo]
        i = playerNo
        break

  var isTargetFound = false
  var j : int = i
  let len = length(humans)
  for _ in iter_range(humans)
    if isTargetFound
      break
    j = (j + evt.delta + len) % len
    query(humans[j]) <| $ [es] (isAlive : bool)
      if isAlive
        if camera__target != humans[j]
          camera__prevTarget = camera__target
          camera__target = humans[j]
        isTargetFound = true

  if !isTargetFound
    camera__prevTarget = camera__target
    camera__target = INVALID_ENTITY_ID


def private replay_change_camera(camera_eid : EntityId; var tm : float3x4&; var cur_camera__target : EntityId&)
  let curCam = get_cur_cam_entity()
  if curCam == camera_eid
    return
  query(curCam) <| $ [es] (var camera__target : EntityId&; transform : float3x4)
    tm = transform
    set_scene_camera_entity(camera_eid)
    cur_camera__target = camera__target
    camera__target = INVALID_ENTITY_ID

[es(tag=playingReplay, on_event=ReplaySetFpsCamera)]
def replay_fps_camera_es(evt : Event)
  find_query() <| $ [es(REQUIRE=replayCamera)] (eid : EntityId;
                                                var transform : float3x4&;
                                                var camera__target : EntityId&;
                                                isTpsView : bool = false)
    if isTpsView
      return false
    replay_change_camera(eid, transform, camera__target)
    return true

[es(tag=playingReplay, on_event=ReplaySetFreeTpsCamera)]
def replay_tps_free_camera_es(evt : Event)
  find_query() <| $ [es(REQUIRE=replay_camera__tpsFree)] (eid : EntityId;
                                                          var camera__target : EntityId&;
                                                          var transform : float3x4&)
    replay_change_camera(eid, transform, camera__target)
    return true

[es(tag=playingReplay, on_event=ReplaySetTpsCamera)]
def replay_tps_camera_es(evt : Event)
  find_query() <| $ [es(REQUIRE=replayCamera)] (eid : EntityId;
                                                var transform : float3x4&;
                                                var camera__target : EntityId&;
                                                isTpsView : bool = false)
    if !isTpsView
      return false
    replay_change_camera(eid, transform, camera__target)
    return true

[es(tag=playingReplay, on_event=ReplaySetCamera)]
def replay_set_camera_by_eid_es(evt : Event;
                                eid : EntityId;
                                var transform : float3x4&;
                                var camera__target : EntityId&)
  replay_change_camera(eid, transform, camera__target)
