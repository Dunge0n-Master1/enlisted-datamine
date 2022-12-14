require app
require DagorDataBlock
require DagorSystem
require ecs
require EnlistedActor
require game.es.events
require game.es.player_events
require game.es.player_common
require game.es.stat_bq_common
require game.events_game
require game.utils.net_utils
require GameTimers
require level
require matching
require EnlistedNet
require player
require danetlibs.native_dasevents.main.native_events

def player_allow_reconnect(plr_eid : EntityId; oldPossessed : EntityId; var specTarget : EntityId&; team : int;
                           clientNetFlags : int) : bool
  if (clientNetFlags & int(ClientNetFlags CNF_RECONNECT_FORBIDDEN)) != 0
    return false

  if (oldPossessed != INVALID_ENTITY_ID) && (oldPossessed |> get_bool("isAlive") ?? false) // possessed entity still alive?
    return true

  if (clientNetFlags & int(ClientNetFlags CNF_SPAWNED_AT_LEAST_ONCE)) == 0 // possessed entity wasn't spawned yet?
    return true

  // If spectator was active ensure that spectator target exist and alive or try to find new one
  if specTarget != INVALID_ENTITY_ID
    if specTarget |> get_bool("isAlive") ?? false
      return true
    specTarget = find_next_spec_target(team, specTarget, +1)
    if specTarget != INVALID_ENTITY_ID
      return true

  // TODO: extract game-specific logic
  let NOT_ASSIGNED_SCORING_PLACE = 0 // CRSD-specific, shouldn't be there
  if (plr_eid |> get_int("scoring_player__place") ?? NOT_ASSIGNED_SCORING_PLACE) != NOT_ASSIGNED_SCORING_PLACE // Scoring place was assigned?
    return true

  let teamEid : EntityId = get_team_eid(team)
  return teamEid |> get_bool("team__hasSpawns") ?? true

struct PlayerTemplateOverride
  templ : string
  found : bool

def find_player_override() : PlayerTemplateOverride
  var res = [[PlayerTemplateOverride templ="", found=false]]
  query() <| $ [es] (player_template__override : string)
    res.found = true
    res.templ = player_template__override
  return res

def create_player(connid : int; name : das_string; uid : uint64; group_id : int64; orig_group_id : int64; platform_uid : das_string; platform : das_string;
                  app_id : int) : EntityId
  let playerTemplOverride = find_player_override()
  let playerTemplateName : string = playerTemplOverride.found ? playerTemplOverride.templ : dgs_get_settings() |> datablock_getStr("playerTemplateName", "common_player")
  let eid : EntityId = createEntity(playerTemplateName) <| $(init)
    init |> set("connid", connid)
    init |> set("name", name)
    init |> set("userid", uid)
    init |> set("possessed", INVALID_ENTITY_ID)
    init |> set("groupId", group_id)
    init |> set("origGroupId", orig_group_id)
    init |> set("platformUid", platform_uid)
    init |> set("platform", platform)
    init |> set("appId", app_id)
  return eid

def try_reconnect_player(var newConn : IConnection?; uid : uint64) : EntityId
  if newConn == null || uid == INVALID_USER_ID
    return INVALID_ENTITY_ID
  var found_eid : EntityId = INVALID_ENTITY_ID
  find_query() <| $ [es] (var player : Player&;
                          var connid : int&;
                          eid : EntityId;
                          var killEntityTimer : uint64&;
                          var disconnected : bool&;
                          var disconnectedAtTime : float&;
                          userid : uint64 = INVALID_USER_ID)
    if userid != uid
      return false

    let newConnId = connection_getId(*newConn)
    let playerId = int(uint(eid))
    var oldConn : IConnection? = get_client_connection(connid)
    if oldConn != null // reconnect
      print("reconnect: changing already existing player {playerId} with userid={int(uid)} connection #{connid} -> #{newConnId}");
      *oldConn |> connection_setUserPtr(null)
      connid = newConnId // before destroying the old one (to avoid calling EventOnClientDisconnected)
      net_disconnect(*oldConn, DisconnectionCause DC_CONNECTION_CLOSED)
    else
      connid = newConnId
    print("reconnect for player {playerId} connid=#{newConnId} userid={int(uid)} successfull");
    query(eid) <| $ [es] (var replication : NetObject&)
      replication |> net_object_setControlledBy(newConnId)
    connection_setUserEid(*newConn, eid)
    game_timer_clear(killEntityTimer)
    assert(killEntityTimer == INVALID_TIMER_HANDLE)
    player |> resetSyncData()
    disconnected = false
    disconnectedAtTime = -1.f
    base_phys_actor_resizeSyncStates(newConnId)
    broadcastEvent([[PlayerResetQuitGameTimer]])

    found_eid = eid
    return true
  return found_eid

[es(tag=server)]
def server_create_player(evt : EventOnClientConnected)
  var conn : IConnection? = get_client_connection(evt.connid)
  var plrEid : EntityId = try_reconnect_player(conn, evt.matching)
  let reconnected : bool = (plrEid != INVALID_ENTITY_ID)
  if !reconnected
    plrEid = create_player(evt.connid, evt.userName, evt.matching, evt.groupId, evt.origGroupId, evt.platformUserId, evt.platform, evt.appId)

  sendEvent(plrEid, [[FinalizePlayerCreation matchingTeam=evt.matchingTeam, clientFlags=evt.clientFlags, reconnected=reconnected]])

[es(tag=server)]
def server_finalize_create_player(evt : FinalizePlayerCreation; eid : EntityId; possessed : EntityId; var specTarget : EntityId&;
                                  team : int; connid : int; var clientNetFlags : int&)
  var conn : IConnection? = get_client_connection(connid)
  if evt.reconnected && !player_allow_reconnect(eid, possessed, specTarget, team, clientNetFlags)
    print("Disconnect reconnecting player {int(uint(eid))} conn #{connid} as this mode does not allow to reconnect")
    if conn != null
      net_disconnect(*conn, DisconnectionCause DC_CONNECTION_CLOSED)
    return
  let flagsToKeep : int = int(ClientNetFlags CNF_SPAWNED_AT_LEAST_ONCE) | int(ClientNetFlags CNF_RECONNECT_FORBIDDEN)
  clientNetFlags = ((clientNetFlags & flagsToKeep) | int(evt.clientFlags))

  if conn != null
    verify(*conn |> setEntityInScopeAlways(eid))
    send_net_event(eid, [[SetLocalPlayerMsg]], target_entity_conn(eid))

  let canSpawnEntity : bool = is_level_loaded() && conn == null
  // Use sendEventImmediate in order to assign team to the player immediately after creation
  sendEventImmediate(eid, [[EventOnPlayerConnected wishTeam=evt.matchingTeam, reconnected=evt.reconnected, canSpawnEntity=canSpawnEntity]])

[es(on_appear, REQUIRE=player)]
def process_player_creation_event(evt : Event; eid : EntityId; connid : int = INVALID_CONNECTION_ID;
                                  canBeLocal : bool = true)
  var cliConn : IConnection? = get_client_connection(connid)
  if cliConn != null
    *cliConn |> connection_setUserEid(eid)
    broadcastEvent([[PlayerResetQuitGameTimer]]) // reset only if actual human player is connected
    base_phys_actor_resizeSyncStates(connid)
  if is_server()
    if cliConn == null // local?
      if canBeLocal && get_local_player_eid() == INVALID_ENTITY_ID
        set_local_player_eid(eid)
    else
      query(eid) <| $ [es] (var replication : NetObject&)
        replication |> net_object_setControlledBy(connid)

    // limit number of player records
    var total : int = 0
    query() <| $ [es(REQUIRE=(player, possessed))] ()
      ++total
    find_query() <| $ [es(REQUIRE=(player, possessed))] (eid : EntityId; disconnected : bool = false)
      if total > NET_MAX_PLAYERS && disconnected
        destroyEntity(eid)
        --total
      return total <= NET_MAX_PLAYERS
    sendEvent(eid, [[CmdGetUserstats]])
  else
    let sconn : IConnection? = get_server_conn()
    if sconn != null
      query(eid) <| $ [es] (var replication : NetObject&)
        replication |> net_object_setControlledBy(connection_getId(*sconn))

[es(tag=server, REQUIRE=player)]
def server_create_players_entities(evt : ServerCreatePlayersEntities; eid : EntityId; possessed : EntityId; team : int;
                                   disconnected : bool = false)
  if !disconnected && !doesEntityExist(possessed) && is_level_loaded()
    sendEvent(eid, [[CmdSpawnEntityForPlayer team=team, possessed=possessed]]);

[es(tag=server, on_event=(EventOnClientDisconnected, EventOnClientConnected), after=(server_create_player, event_on_client_disconnected))]
def connect_disconnect_log(evt : Event)
  var totalPlayers : int = 0
  var totalDisconnected : int = 0
  var totalBots : int = 0
  query() <| $ [es(REQUIRE=player)] (eid : EntityId; disconnected : bool = false)
    totalPlayers++
    totalDisconnected += disconnected ? 1 : 0
    totalBots += has(eid, "playerIsBot") ? 1 : 0

  print("{totalPlayers} players in session, {totalBots} bots, {totalDisconnected} disconnected")

[es(tag=server, on_appear)]
def set_player_room_owner_es(evt : Event; userid : uint64; var player__roomOwner : bool&)
  find_query() <| $ [es] (custom_room_info__owner : uint64)
    player__roomOwner = custom_room_info__owner == userid
    return true
