require app
require DagorDataBlock
require debug.logerr_once
require ecs
require game.es.events
require game.es.player_common
require game.es.player_events
require game.es.stat_bq_common
require game.events_game
require game.utils.net_utils
require game.utils.team
require GameTimers
require matching
require EnlistedNet
require player

let DEF_SPECTATE_TIME : float = 5.f

[es(tag=server)]
def player_spectate_target_es(evt : EventSpectateTarget; eid : EntityId; connid : int; team : int = TEAM_UNASSIGNED;
                              userid : uint64 = INVALID_USER_ID; var clientNetFlags : int&)
  let reqSpecTarget : EntityId = evt.target_eid
  let playerTeam : int = team
  var specTarget : EntityId? = getRW_Eid(eid, "specTarget")
  assert(specTarget != null)
  if reqSpecTarget == *specTarget
    return
  var validReqSpecTarget : bool = !has_network() || ((clientNetFlags & int(ClientNetFlags CNF_DEVELOPER)) != 0)
  // Client's valid spec target might die while this request was in flight, try to find new one if this happened
  query(reqSpecTarget) <| $ [es(REQUIRE_NOT=deadEntity)] (isSpectatable : bool; countAsAlive : bool; team : int = TEAM_UNASSIGNED)
    if isSpectatable && countAsAlive && (have_active_teammates(INVALID_ENTITY_ID, playerTeam, /*include_bots*/ true) ? playerTeam == team : true)
      validReqSpecTarget = true
  let prevSpecTarget : EntityId = *specTarget
  *specTarget = validReqSpecTarget ? reqSpecTarget : find_next_spec_target(playerTeam, *specTarget, +1)
  let playerId : int = int(uint(eid))
  let action : string = validReqSpecTarget ? "selected" : "was assigned"
  let prevTargetId : int = int(uint(prevSpecTarget))
  let prevTargetName : string = getEntityTemplateName(prevSpecTarget)
  let targetId : int = int(uint(*specTarget))
  let targetName : string = getEntityTemplateName(*specTarget)
  print("Player {playerId} conn #{connid} userid={int(userid)} {action} specTarget {prevTargetId}<{prevTargetName}> -> {targetId}<{targetName}>")
  if 0 == (clientNetFlags & int(ClientNetFlags CNF_REPLICATE_PHYS_ACTORS))
    clientNetFlags |= int(ClientNetFlags CNF_REPLICATE_PHYS_ACTORS)
    sendEventImmediate(eid, [[CmdAddDefaultEntitiesInNetScopeForPlayer]])

[es(on_event=CmdAddDefaultEntitiesInNetScopeForPlayer)]
def add_default_entities_es(evt : Event; eid : EntityId; connid : int)
  let conn : IConnection? = get_client_connection(connid)
  if conn == null
    return

  let lookingAt : LookingAt = player_get_looking_at(eid)
  var cameraFound : bool = lookingAt.pos != null
  var lookDir : float3 = lookingAt.dir ?? float3(1.0, 0.0, 0.0)
  var lookPos : float3 = lookingAt.pos ?? float3(0.0, 0.0, 0.0)

  if !cameraFound
    cameraFound = find_query() <| $ [es(REQUIRE=camera_view)] (transform : float3x4; camera__active : bool = true)
      if camera__active
        lookPos = transform[3]
        lookDir = transform[0]
        return true
      return false
  if !cameraFound
    logerr_once("No active camera found, entities will be added in net scope at {lookPos}")
  broadcastEventImmediate([[CmdAddDefaultEntitiesInNetScope connid=connection_getId(*conn), viewPos=lookPos, viewFwd=lookDir]])

def start_spectator_timer(hero : EntityId; possessedByPlr : EntityId) : void
  query(possessedByPlr) <| $ [es] (connid : int; var specTarget : EntityId&; team : int = TEAM_UNASSIGNED; userid : uint64 = INVALID_USER_ID)
    if !is_server() || userid == INVALID_USER_ID // enable spectator for human (non-bot) player
      return

    let spectateTime : float = game_params_get_timer("enableSpectatorAfterTimeSec", DEF_SPECTATE_TIME)
    if spectateTime < 0.f
      return

    if !(get_bool(get_team_eid(team), "team__hasSpawns") ?? true)
      // Set specTarget right away (before timer) to be able reconnect later (as spectator)
      specTarget = find_next_spec_target(team, INVALID_ENTITY_ID, +1)
      let spectatecb <- @ <| ()
        // specTarget may be already dead at this point, thus sending the event to the player
        send_enable_spectator_for_player(possessedByPlr)
      game_timer_set(spectatecb, spectateTime) // Fire & forget timer
    elif connid != INVALID_CONNECTION_ID || possessedByPlr == get_local_player_eid()
      let spectatecb <- @ <| ()
        query(possessedByPlr) <| $ [es] (possessed : EntityId; respawner__spectatorEnabled : bool = true)
          if possessed != hero
            return
          if respawner__spectatorEnabled
            send_enable_spectator_for_player(possessedByPlr)
      game_timer_set(spectatecb, spectateTime) // Fire & forget timer

[es(tag=server, track=respawner__spectatorEnabled)]
def player_spectator_activated_es(evt : Event; eid : EntityId; possessed : EntityId;
                                  respawner__enabled : bool; respawner__spectatorEnabled : bool)
  if respawner__enabled && respawner__spectatorEnabled
    start_spectator_timer(possessed, eid)

[es(tag=server, on_event=EventPlayerPossessedEntityDied)]  // TODO: move to common_shooter
def player_spectator_on_death_es(evt : Event;
                                 eid, possessed : EntityId;
                                 waitingForRespawn = false;
                                 waitingForRespawnSpectatorEnabled = false)
  if !waitingForRespawn || waitingForRespawnSpectatorEnabled
    start_spectator_timer(possessed, eid)


[es(tag=server, before=player_spectate_target_es)]
def player_spectators_count_change(evt : EventSpectateTarget; specTarget : EntityId)
  if specTarget != evt.target_eid
    query(specTarget) <| $ [es] (var spectatorsCount : int&)
      spectatorsCount = max(0, spectatorsCount - 1)
    query(evt.target_eid) <| $ [es] (var spectatorsCount : int&)
      spectatorsCount += 1


[es(tag=server)]
def player_spectators_count_change_on_disconnect(evt : EventOnClientDisconnected; connid : int; specTarget : EntityId)
  if evt.connid == connid
    query(specTarget) <| $ [es] (var spectatorsCount : int&)
      spectatorsCount = max(0, spectatorsCount - 1)


[es(tag=server)]
def player_spectators_count_change_on_connect(evt : EventOnClientConnected; connid : int; specTarget : EntityId)
  if evt.connid == connid
    query(specTarget) <| $ [es] (var spectatorsCount : int&)
      spectatorsCount += 1
