module sound_utils shared

require ecs
require ecs.safe
require app
require game.utils.net_utils
require game.utils.team
require EnlistedNet
require soundHash
require soundSystem
require sound_utils_net.modules.sound_utils_net_events


def private get_desc(name : string; descs : Object; should_exist : bool) : Object const?
  let desc = descs[name] ?as Object
  if should_exist && desc == null
    sound_debug("net_sound: sound '{name}' not found in net_sound.descs {descs}")
  return desc


def private is_valid(desc : Object const?)
  return desc != null && (has(*desc, "path") || has(*desc, "hero") || has(*desc, "enemy"))


def scene_net_sound_rcptf(pos : float3; search_range : float = 100.) : array<IConnection?>
  return <- enum_connections_range_team(pos, search_range, /*team_id*/ TEAM_UNASSIGNED, false /*filter_possessd*/,
                                        /*except_possessed*/ INVALID_ENTITY_ID, /*is_player_relative*/ false)


def net_sound_rcptf(target : EntityId; pos : float3; name : string; descs : Object; filter_possessd : bool; should_exist : bool) : array<IConnection?>
  let desc = get_desc(name, descs, should_exist)
  if is_valid(desc)
    let toPlayer = (*desc).toPlayer ?? false
    if toPlayer
      return <- target_entity_conn(target)
    else
      let toTeam : bool = (*desc).toTeam ?? false
      let searchRange : float = *desc |> get_float("range") ?? 0.f
      let team : int = toTeam ? target |> get_int("team") ?? TEAM_UNASSIGNED : TEAM_UNASSIGNED;
      if !toTeam || team != TEAM_UNASSIGNED
        return <- enum_connections_range_team(pos, searchRange, team, filter_possessd, target, true)
  return <- [[array<IConnection?>]]


def play_net_sound_pos(target : EntityId; name : string; pos : float3; param : float = 0.; filter_possessd : bool = false; should_exist : bool = true)
  query(target) <| $ [es] ([[shared_comp]] net_sound__descs : Object)
    send_net_event(target, [[CmdPlayNetSoundPos hash=sound_hash(name), pos=pos, param=param, time=get_sync_time()]],
      net_sound_rcptf(target, pos, name, net_sound__descs, filter_possessd, should_exist))


def play_net_sound(target : EntityId; name : string; param : float = 0.; filter_possessd : bool = false; should_exist : bool = true)
  query(target) <| $ [es] ([[shared_comp]] net_sound__descs : Object; transform : float3x4)
    send_net_event(target, [[CmdPlayNetSound hash=sound_hash(name), param=param, time=get_sync_time()]],
      net_sound_rcptf(target, transform[3], name, net_sound__descs, filter_possessd, should_exist))


def play_net_sound_simple(target : EntityId; name : string; should_exist : bool = true)
  query(target) <| $ [es] ([[shared_comp]] net_sound__descs : Object)
    let desc = get_desc(name, net_sound__descs, should_exist)
    if is_valid(desc)
      let searchRange : float = *desc |> get_float("range") ?? 20.
      send_net_event(target, [[CmdPlayNetSoundSimple hash=sound_hash(name), time=get_sync_time()]],
                     target_entity_pos_range(target, searchRange, /*is_player_relative*/ true))


def play_scene_net_sound(name : string; pos : float3; should_exist : bool = true)
  query() <| $ [es(REQUIRE=sceneNetSounds)] (eid : EntityId; [[shared_comp]] net_sound__descs : Object)
    let desc = get_desc(name, net_sound__descs, should_exist)
    if is_valid(desc)
      let searchRange : float = *desc |> get_float("range") ?? 100.
      send_net_event(eid, [[CmdPlayNetSoundPos hash=sound_hash(name), pos=pos, param=0., time=get_sync_time()]],
        scene_net_sound_rcptf(pos, searchRange))


def play_net_sound_from_any_source(target : EntityId; name : string; should_exist : bool = true)
  var numSounds = 0
  query() <| $ [es(REQUIRE=anySourceNetSounds)] ([[shared_comp]] net_sound__descs : Object)
    if is_valid(get_desc(name, net_sound__descs, false))
      ++numSounds
      if numSounds == 1
        query(target) <| $ [es] (transform : float3x4)
          send_net_event(target, [[CmdPlayNetSoundFromAnySource hash=sound_hash(name), time=get_sync_time()]],
            net_sound_rcptf(target, transform[3], name, net_sound__descs, false, true))
  if numSounds > 1
    sound_debug("net_sound: more than one sound with name '{name}' found")
  elif numSounds == 0 && should_exist
    sound_debug("net_sound: sound with name '{name}' not found")
