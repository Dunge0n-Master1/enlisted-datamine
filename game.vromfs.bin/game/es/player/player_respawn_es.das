require app
require DagorSystem
require ecs
require DngActor
require DngHuman
require game.events_game
require game.es.player_common
require game.es.player_events
require game.utils.net_utils
require game.utils.team
require GameTimers
require HumanPhys
require level
require math.base
require DngNet
require player
require replay

let DEFAULT_NO_PLAYERS_TIMEOUT : float = 60.f

def have_connected_players() : bool
  return find_query() <| $ [es(REQUIRE=player)] (connid : int)
    return connid != INVALID_CONNECTION_ID

[es(on_event=PlayerStartQuitGameTimer)]
def player_start_quit_game_timer(evt : Event; var server_no_players_timer__handle : uint64&)
  if have_connected_players()
    return
  let exitTimeout : float = settings_get_timer("noPlayersExitTimeoutSec", DEFAULT_NO_PLAYERS_TIMEOUT)
  if exitTimeout >= 0.f
    print("player_start_quit_game_timer {exitTimeout}")
    let timeoutCb <- @ <| ()
      exit_game("no players in session after {exitTimeout}")
    game_timer_clear(server_no_players_timer__handle)
    server_no_players_timer__handle = game_timer_set(timeoutCb, exitTimeout)

[es(on_event=PlayerResetQuitGameTimer)]
def player_reset_quit_game_timer(evt : Event; var server_no_players_timer__handle : uint64&)
  game_timer_clear(server_no_players_timer__handle)

[es(on_event=EventLevelLoaded)]
def player_on_level_loaded(evt : Event)
  let player_eid : EntityId = get_local_player_eid()
  if player_eid != INVALID_ENTITY_ID
    sendEventImmediate(player_eid, [[PlayerRequestRespawnInWorld]])
  else
    // expected situation in replay, not expected in network (SetLocalPlayerMsg is not received yet?)
    if !is_server() && !is_replay_playing()
      logerr("level loaded without local player")
    else
      logwarn("level loaded without local player")
    if is_server() && !have_connected_players()
      broadcastEvent([[PlayerStartQuitGameTimer]])

def set_net_object_controlled_by(eid : EntityId; connid : int) : void
  query(eid) <| $ [es] (var replication : NetObject&)
    replication |> net_object_setControlledBy(connid)

[es(tag=server, REQUIRE=player)]
def event_on_client_disconnected(evt : EventOnClientDisconnected; eid : EntityId; possessed : EntityId;
                                 var disconnected : bool&; var disconnectedAtTime : float&; var connid : int&;
                                 var respawner__spectatorEnabled : bool?; team : int)
  if connid != evt.connid
    return
  var conn : IConnection? = get_client_connection(connid)
  if conn != null
    connection_setUserPtr(*conn, null)

  connid = INVALID_CONNECTION_ID
  disconnected = true
  disconnectedAtTime = get_sync_time()
  set_net_object_controlled_by(eid, INVALID_CONNECTION_ID)

  query(possessed) <| $ [es(REQUIRE=human_net_phys)] (var human_net_phys : HumanActor?)
    human_net_phys.phys.appliedCT |> human_control_state_set_neutral_ctrl()
    human_net_phys.phys |> human_control_state_clear_unaproved_ctrl()

  if respawner__spectatorEnabled != null
    *respawner__spectatorEnabled = false // Don't enable spectator if possessed entity died

  if team != TEAM_UNASSIGNED
    broadcastEvent([[EventTeamMemberLeave eid=eid, team=team]])
  // No players left?
  if !have_connected_players()
    print("no players left")
    broadcastEvent([[PlayerStartQuitGameTimer]])

[es(on_disappear, tag=server, REQUIRE=player)]
def destroy_possessed_entity(evt : Event; eid : EntityId; possessed : EntityId; team : int)
  destroyEntity(possessed)
  broadcastEvent([[EventTeamMemberLeave eid=eid, team=team]])

[es(track=possessed, REQUIRE=player)]
def set_possessed_by(evt : Event;
                     eid : EntityId;
                     possessed : EntityId;
                     var controlled_soldier__sKind : das_string&;
                     var controlled_soldier__sClass : das_string&;
                     var controlled_soldier__sClassRare : int&)
  query(possessed) <| $ [es] (var possessedByPlr : EntityId&;
                              soldier__sKind : das_string const?;
                              soldier__sClass : das_string const?;
                              soldier__sClassRare : int)
    possessedByPlr = eid
    if (!is_server())
      return

    controlled_soldier__sKind := soldier__sKind != null ? string(*soldier__sKind) : ""
    controlled_soldier__sClass := soldier__sClass != null ? string(*soldier__sClass) : ""
    controlled_soldier__sClassRare = soldier__sClassRare

[es(tag=server, REQUIRE=player)]
def server_tps_view_switch(evt : RequestCamSwitch; possessed : EntityId)
  query(possessed) <| $ [es] (var isTpsView : bool&)
    isTpsView = evt.isTpsView

[es(on_event=SetLocalPlayerMsg, tag=gameClient, REQUIRE=player)]
def set_local_player(evt : Event; eid : EntityId)
  print("SetLocalPlayerMsg to player {int(uint(eid))}");
  if is_replay_playing() // don't try possess hero in replay
    return ;
  set_local_player_eid(eid)
  if is_level_loaded() // unlikely event when level is loaded before 'SetLocalPlayerMsg' received
    sendEventImmediate(get_local_player_eid(), [[PlayerRequestRespawnInWorld]])

[es(on_disappear, REQUIRE=player)]
def player_destroyed(evt : Event; eid : EntityId; connid : int; var killEntityTimer : uint64&)
  if get_local_player_eid() == eid // player is local
    set_local_player_eid(INVALID_ENTITY_ID)
  var conn : IConnection? = ((connid != INVALID_CONNECTION_ID) ? get_client_connection(connid) : null);
  if conn != null
    connection_setUserPtr(*conn, null)
  game_timer_clear(killEntityTimer)

def get_replication(eid : EntityId) : NetObject?
  var result : NetObject? = null
  query(eid) <| $ [es(trust_access)] (var replication : NetObject?)
    result = replication
  return result

[es(tag=server, REQUIRE=player)]
def player_possess(evt : PossessTargetByPlayer; eid : EntityId; connid : int; is_local : bool;
                   var possessed : EntityId&; var specTarget : EntityId&; var clientNetFlags : int&)
  let neid = evt.target
  verify(neid == INVALID_ENTITY_ID || doesEntityExist(neid))

  let oldPossessed : EntityId = possessed

  var actor : BasePhysActor? = get_phys_actor(neid)
  var oldActor : BasePhysActor? = null
  if oldPossessed != INVALID_ENTITY_ID && oldPossessed != neid
    oldActor = get_phys_actor(oldPossessed)

  if !has(eid, "playerIsBot")
    sendEvent(neid, [[CmdSetSimplifiedPhys is_simplified=false]])
    if oldPossessed != neid
      sendEvent(oldPossessed, [[CmdSetSimplifiedPhys is_simplified=true]])

  print("player_possess {int(uint(eid))}: conn=#{connid} {int(uint(oldPossessed))} -> {int(uint(neid))}")

  setOptional(oldPossessed, "possessedByPlr", INVALID_ENTITY_ID)
  possessed = neid
  setOptional(neid, "possessedByPlr", eid)

  var clientConn : IConnection? = get_client_connection(connid)
  if is_local
    pass
  elif clientConn != null
    if oldPossessed != INVALID_ENTITY_ID && oldPossessed != neid
      print("Unpossess old hero {int(uint(oldPossessed))}")
      send_net_event(oldPossessed, [[PossessHero possess=false]], target_entity_conn(oldPossessed)) // (might fail on reconnect)
    set_net_object_controlled_by(oldPossessed, INVALID_CONNECTION_ID)

    var netObj : NetObject? = get_replication(neid)

    if netObj != null
      net_object_setControlledBy(*netObj, connection_getId(*clientConn))
      setEntityInScopeAlways(*clientConn, neid)
      print("Possess new hero {int(uint(neid))}")
      send_net_event(neid, [[PossessHero possess=true]], target_entity_conn(neid))
      if 0 == (clientNetFlags & int(ClientNetFlags CNF_REPLICATE_PHYS_ACTORS))
        sendEventImmediate(eid, [[CmdAddDefaultEntitiesInNetScopeForPlayer]])
      clientNetFlags |= int(ClientNetFlags CNF_REPLICATE_PHYS_ACTORS)
      clientNetFlags |= int(ClientNetFlags CNF_SPAWNED_AT_LEAST_ONCE)
      specTarget = INVALID_ENTITY_ID
    elif specTarget == INVALID_ENTITY_ID
      send_enable_spectator_for_player(eid)
    else
      pass // assume that spectator is already enabled
    if oldActor != null
      *oldActor |> base_phys_actor_setRoleAndTickrateType(NetRole ROLE_LOCALLY_CONTROLLED_AUTHORITY, PhysTickRateType LowFreq)
    if netObj != null && actor != null
      *actor |> base_phys_actor_setRoleAndTickrateType(NetRole ROLE_REMOTELY_CONTROLLED_AUTHORITY, PhysTickRateType Normal)
  else
    logwarn("player_possess no connection for player {int(uint(eid))}"); // could be if player disconnected for example

[es(tag=server, REQUIRE=player)]
def possess_entity(evt : CmdPossessEntity; eid : EntityId)
  sendEvent(eid, [[PossessTargetByPlayer target=evt.possessedEid]])
