require ecs
require app
require game.es.events
require game.events_game
require game.utils.hero
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
require game.es.player_common

[es(tag=playingReplay, REQUIRE=(deadEntity, watchedByPlr), before=enlisted_next_replay_target_es)]
def replay_human_death_cam_timer_es(evt : UpdateStageInfoAct;
                                    squad_member__squad : EntityId;
                                    squad_member__memberIdx : int;
                                    replay__deadCamTime : float;
                                    squad_member__playerEid : EntityId;
                                    var replay__deadCamTimer : float&)
  var catchPossessEntity = false
  query(squad_member__playerEid) <| $ [es] (replay_player__catchPossessEntity : bool)
    catchPossessEntity = replay_player__catchPossessEntity

  if catchPossessEntity
    return

  replay__deadCamTimer += evt.dt
  if replay__deadCamTimer < replay__deadCamTime
    return

  var delta = 1
  assume memberIdx = squad_member__memberIdx
  query(squad_member__squad) <| $ [es] (squad__allMembers : EidList)
    var idx = length(squad__allMembers) - 1
    while idx >= 0
      let eid = squad__allMembers[idx]
      if idx < memberIdx
        delta = -1 // no one is not alive in "forward direction take someone "behind us"
      elif !has(eid, "deadEntity") && idx != memberIdx
        break
      idx--
  // Reset timer with very big negative value, to bypass send event twice
  replay__deadCamTimer = -1e10
  sendEvent(get_cur_cam_entity(), [[NextReplayTarget delta=delta]])

[es(tag=playingReplay, on_event=EventEntityDestroyed, REQUIRE=watchedByPlr)]
def on_watched_player_destroyes_es(evt : Event)
  sendEvent(get_cur_cam_entity(), [[NextReplayTarget delta=1]])

[es(tag=playingReplay, no_order, REQUIRE=replayCamera)]
def catch_human_view(evt : UpdateStageInfoAct;
                     camera__target : EntityId;
                     camera__active : bool)
  if camera__active && camera__target == INVALID_ENTITY_ID
    find_query() <| $ [es(REQUIRE_NOT=playerIsBot)] (eid : EntityId; disconnected : bool; possessed : EntityId)
      if disconnected || possessed == INVALID_ENTITY_ID || has(possessed, "deadEntity")
        return false
      sendEvent(eid, [[SetReplayTarget]])
      return true


def private replay_change_camera(camera_eid : EntityId; var tm : float3x4&; var cur_camera__target : EntityId&)
  let curCam = get_cur_cam_entity()
  if curCam == camera_eid
    return
  query(curCam) <| $ [es] (var camera__target : EntityId&; transform : float3x4)
    tm = transform
    set_scene_camera_entity(camera_eid)
    cur_camera__target = camera__target
    camera__target = INVALID_ENTITY_ID
    sendEvent(camera_eid, [[CmdSetCameraTarget target=get_watched_entity()]])

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

[es(tag=playingReplay, on_event=ReplaySetOperatorCamera)]
def replay_set_operator_camera_es(evt : Event)
  find_query() <| $ [es(REQUIRE=replay_camera__operator)] (eid : EntityId;
                                                           var transform : float3x4&;
                                                           var camera__target : EntityId&)
    replay_change_camera(eid, transform, camera__target)
    return true

[es(tag=playingReplay, on_event=ReplaySetCamera)]
def replay_set_camera_by_eid_es(evt : Event;
                                eid : EntityId;
                                var transform : float3x4&;
                                var camera__target : EntityId&)
  replay_change_camera(eid, transform, camera__target)
