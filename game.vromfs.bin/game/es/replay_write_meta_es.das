require ecs
require app
require net
require EnlistedNet
require rapidjson
require game.events_game
require enlisted.events_enlisted

[es(tag=recordingReplay, on_appear, REQUIRE=human)]
def set_first_respawn_time_es(evt : Event)
  query() <| $ [es] (replay__startAt : float;
                     var replay__firstHumanSpawnTime : float&;
                     var replay__isFirstHumanSpawned : bool&)
    if !replay__isFirstHumanSpawned
      replay__isFirstHumanSpawned = true
      replay__firstHumanSpawnTime = floor(get_sync_time() - replay__startAt)

[es(tag=recordingReplay, on_event=EventLevelLoaded)]
def replay_recording_create_meta(evt : Event)
  createEntity("replay_meta_record") <| $(var init)
    init |> set("replay__startAt", get_sync_time())
    init |> set("mission__startTime", int64(get_clock()))

[es(tag=recordingReplay)]
def replay_write_meta_es(var evt : EventOnWriteReplayMetaInfo&)
  assume obj = evt.replayMeta
  SetObject(obj) <| $(var item : JsonValue#)
    query() <| $ [es] (mission_name : string; mission_type : string)
      item |> AddMember("mission_name", mission_name, obj)
      item |> AddMember("mission_type", mission_type, obj)

    query() <| $ [es] (mission__startTime : int64;
                       replay__firstHumanSpawnTime : float;
                       replay__startAt : float)
      item |> AddMember("start_timestamp", mission__startTime, obj)
      item |> AddMember("first_human_spawn_time", replay__firstHumanSpawnTime, obj)
      item |> AddMember("total_play_time", get_sync_time() - replay__firstHumanSpawnTime - replay__startAt, obj)
      item |> AddMember("replay__startAt", replay__startAt, obj)
    item |> AddMember("end_timestamp", int64(get_clock()), obj)
    item |> AddMember("session_id", get_session_id(), obj)

    item |> AddMember("circuit", get_circuit_name(), obj)
    item |> AddMember("game", get_game_name(), obj)
    item |> AddMember("exe_version", get_exe_version_str(), obj)
    item |> AddMember("protocol_version", int(NET_PROTO_VERSION), obj)
    item |> AddMember("dasevent_net_version", get_dasevent_net_version(), obj)

    get_matching_invite_data() |> FindMember("mode_info", JsonType kObjectType) <| $(mode_info)
      let digestGroup = mode_info |> json_get_or("digestGroup", "")
      if digestGroup != ""
        item |> AddMember("digestGroup", digestGroup, obj)

      let difficulty = mode_info |> json_get_or("difficulty", "")
      if difficulty != ""
        item |> AddMember("difficulty", difficulty, obj)

    using(JsonType kArrayType) <| $(var players : JsonValue#)
      query() <| $ [es(REQUIRE=player, REQUIRE_NOT=playerIsBot)] (team : int; name : string; userid : uint64)
        using(JsonType kObjectType) <| $(var player : JsonValue#)
          player |> AddMember("team", team, obj)
          player |> AddMember("name", name, obj)
          player |> AddMember("userid", userid, obj)
          players |> PushBack(player, obj)
      item |> AddMember("players", players, obj)

  obj |> json_stringify_pretty() <| $(data)
    print("replay meta: {data}")
