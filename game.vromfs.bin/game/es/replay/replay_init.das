require ecs
require app
require EnlistedCamera
require DagorDataBlock
require DagorSystem
require replay
require rapidjson

[es(tag=playingReplay, on_event=EventLevelLoaded)]
def camera_replay_init_es(evt : Event)
  let camEid = create_camera_by_name("replay_camera", INVALID_ENTITY_ID, null, uint(CreateCameraFlags CCF_SET_ENTITY))
  set_scene_camera_entity(camEid)

[es(tag=playingReplay, on_event=EventLevelLoaded)]
def replay_init_es(evt : Event)
  createEntity("replay_meta")
  createEntity("replay_input")

[es(tag=playingReplay, on_appear)]
def replay_create_cameras(evt : Event; replay_cameras : StringList)
  for cam in replay_cameras
    createEntity(string(cam)) <| $(var init : ComponentsInitializer)
      init |> set("camera__active", false)
      init |> set("camera__target", INVALID_ENTITY_ID)

[es(tag=playingReplay, on_appear, REQUIRE=replayCamera)]
def replay_camera_set_static_position_es(evt : Event; camera__target : EntityId; var transform aka replay_transform : float3x4&)
  if !!camera__target
    return

  find_query() <| $ [es(REQUIRE=initialCamTag)] (transform : float3x4)
    replay_transform = transform
    return true

[es(tag=playingReplay, after=(replay_speed_change_es, change_replay_speed_es))]
def replay_set_current_time_es(evt : UpdateStageInfoAct;
                               var replay__curTime : float&;
                               var replay__speed : float&)
  replay__curTime = evt.curTime
  replay__speed = get_timespeed()

[es(tag=playingReplay, on_appear)]
def replay_read_meta_es(evt : Event;
                        var replay__playTime : float&;
                        var replay__startAt : float&;
                        var replay__firstHumanSpawnTime : float&)
  replay__playTime = get_currently_playing_replay_meta_info() |> json_get_or("total_play_time", 0.)
  replay__firstHumanSpawnTime = get_currently_playing_replay_meta_info() |> json_get_or("first_human_spawn_time", 0.)
  replay__startAt = get_currently_playing_replay_meta_info() |> json_get_or("replay__startAt", 0.)

[es(tag=playingReplay, on_appear, after=replay_read_meta_es)]
def replay_acceleration_to_first_human_spawn_es(evt : Event; replay__firstHumanSpawnTime : float)
  createEntity("replay_acceleration_to") <| $(var init)
    init |> set("replay__accelerationTime", replay__firstHumanSpawnTime)
