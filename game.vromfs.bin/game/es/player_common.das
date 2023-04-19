module player_common shared public

require app
require DagorDataBlock
require DagorSystem
require ecs
require game.es.events
require game.es.player_events
require game.es.stat_bq_common
require game.events_game
require game.utils.net_utils
require GameTimers
require level
require DngNet
require game.utils.team


def find_next_spec_target(team_id : int; cur_eid : EntityId; dir : int) : EntityId
  var entitiesToWatch : array<EntityId>
  query() <| $ [es(REQUIRE_NOT=deadEntity)] (eid : EntityId;
                                             isSpectatable, countAsAlive, isAlive : bool;
                                             team = TEAM_UNASSIGNED)
    if isSpectatable && countAsAlive && isAlive && (team == team_id || team_id == TEAM_UNASSIGNED)
      entitiesToWatch |> push(eid)
  let entitiesToWatchLen = length(entitiesToWatch)
  if entitiesToWatchLen < 2 || cur_eid == INVALID_ENTITY_ID
    return empty(entitiesToWatch) ? INVALID_ENTITY_ID : entitiesToWatch[0]
  entitiesToWatch |> sort() <| $(lhs, rhs)
    return uint(lhs) < uint(rhs) // i.e. don't assume that ES executes in stable order
  let curEidIdx = entitiesToWatch |> find_index(cur_eid)
  if curEidIdx == -1
    return entitiesToWatch[0]
  let newSpecTargetIdx = curEidIdx + ((dir >= 0) ? 1 : -1)
  return newSpecTargetIdx < 0 ? entitiesToWatch[entitiesToWatchLen - 1] : entitiesToWatch[newSpecTargetIdx % entitiesToWatchLen]

def send_enable_spectator_for_player(player_eid : EntityId)
  print("Send enable spectator for plr {int(uint(player_eid))}")
  send_net_event(player_eid, [[EnableSpectatorForPlayer target=INVALID_ENTITY_ID]], target_entity_conn(player_eid))

def send_enable_spectator_for_target(player_eid : EntityId; spec_target : EntityId) : void
  print("Send enable spectator for plr {int(uint(player_eid))} target {spec_target}")
  send_net_event(spec_target, [[EnableSpectatorForTarget player=player_eid]], target_entity_conn(player_eid))

def player_spawn_entity(player_eid : EntityId; team : int; possessed : EntityId)
  if is_level_loaded()
    sendEvent(player_eid, [[CmdSpawnEntityForPlayer team=team, possessed=possessed]])

def emit_hero_changed_event(new_hero : EntityId)
  print("emit_hero_changed_event {int(uint(new_hero))}")
  broadcastEvent([[EventHeroChanged eid=new_hero]])

def player_respawn_in_world_common(eid : EntityId)
  print("player_respawn_in_world_common")
  query(eid) <| $ [es] (var specTarget : EntityId&; team : int; connid : int; possessed : EntityId; var clientNetFlags : int&)
    var possessed_copy : EntityId = possessed
    if possessed_copy != INVALID_ENTITY_ID && !doesEntityExist(possessed_copy)
      possessed_copy = INVALID_ENTITY_ID
    let plr : int = int(uint(eid))
    let poss : int = int(uint(possessed_copy))
    let spec : int = int(uint(specTarget))
    print("player_respawn_default_implementation plr={plr}, conn=#{connid}, possessed={poss}, specTarget={spec}")
    if possessed_copy != INVALID_ENTITY_ID // if possessed entity exist just possess it again
      sendEvent(eid, [[PossessTargetByPlayer target=possessed_copy]])
      return
    if specTarget != INVALID_ENTITY_ID // if spectator [was] enabled -> just re-enable it back
      if !(get_bool(specTarget, "isAlive") ?? false)
        specTarget = find_next_spec_target(team, specTarget, +1)
      if specTarget != INVALID_ENTITY_ID
        clientNetFlags |= int(ClientNetFlags CNF_REPLICATE_PHYS_ACTORS) // This enables grid_scope_adder
        sendEventImmediate(eid, [[CmdAddDefaultEntitiesInNetScopeForPlayer]])
        // sending to the target, so the event will wait for the target to be replicated
        send_enable_spectator_for_target(eid, specTarget)
        return
    let never_spawned_before : bool = (0 == (clientNetFlags & int(ClientNetFlags CNF_SPAWNED_AT_LEAST_ONCE)))
    let has_team_spawns : bool = (get_bool(get_team_eid(team), "team__hasSpawns") ?? true)
    if never_spawned_before || has_team_spawns
      player_spawn_entity(eid, team, possessed_copy)
    else // shouldn't be happening (un-authorized spawn request?)
      var conn : IConnection? = get_client_connection(connid)
      logwarn("Diconnect player {int(uint(eid))} conn #{connection_getId(*conn)} as it's can't be spawn or spectate anything")
      if conn != null
        net_disconnect(*conn, DisconnectionCause DC_CONNECTION_CLOSED)

def game_params_get_timer(timerName : string; fallback : float) : float
  return dgs_get_game_params() |> datablock_get_block_by_name("timers") |> datablock_getReal(timerName, fallback)


def settings_get_timer(timerName : string; fallback : float) : float
  return dgs_get_settings() |> datablock_get_block_by_name("timers") |> datablock_getReal(timerName, fallback)
