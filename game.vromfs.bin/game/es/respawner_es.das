require ecs
require ecs.common
require ecs.safe
require app
require math
require math.base
require EnlistedNet
require game.utils.team
require DagorSystem
require walkerai
require EnlistedWalkerai
require DagorMath
require Dacoll
require game.es.player_events
require game.es.stat_bq_common
require enlisted.game.es.enlisted_squad_common
require game.es.ai.walker_common
require enlisted.events_enlisted
require game.events_game
require DagorRandom

def calc_enemy_score(leaderTeam; walker_agent)
  var enemyScore = 0.f
  ecs::query() <| $ [es] (ai_target : Target;
                          team : int;
                          isAlive : bool)
    if !isAlive
      return

    let maxEnemyDist = 60.f;
    let enemyCanSeeScore = 200.f;

    if is_teams_friendly(leaderTeam, team)
      return

    var dir = entity_agent_getShootFromPos(walker_agent, STANCE_STAND) - ai_target.targetPos
    var dist = length(dir)
    if dist > maxEnemyDist
      return
    dir *= safeinv(dist)
    var norm : float3
    if !traceray_normalized(ai_target.targetPos, dir, dist, norm) // it can see us
      enemyScore += enemyCanSeeScore * (1.f - dist / maxEnemyDist)
  return enemyScore

def find_best_leader(squad_eid) : EntityId
  var leaderPos = float3()
  var leaderDir = float3()
  var isValidLeader = false
  query(get_squad_leader(squad_eid)) <| $ [es] (transform : float3x4)
    isValidLeader = true
    leaderDir = transform[0]
    leaderPos = transform[3]

  var minScore = FLT_MAX
  var minDownedScore = FLT_MAX
  var bestEntity = INVALID_ENTITY_ID
  var bestDowned = INVALID_ENTITY_ID

  let curTime = get_sync_time()
  query(squad_eid) <| $ [es] (squad__allMembers : EidList)
    for squarMemberEid in squad__allMembers
      query(squarMemberEid) <| $ [es(REQUIRE_NOT=deadEntity)] (walker_agent : EntityAgent;
                                                               team : int;
                                                               isDowned : bool)
        let hitScore = cvt(curTime - walker_agent.lastHitTime, 1.f, 5.f, 100.f, 0.f)
        let distScore = isValidLeader ? length(leaderPos - walker_agent.pos) : 0.f
        let dirScore = isValidLeader ? cvt(dot(walker_agent.shootDir, leaderDir), 1.f, -1.f, 0.f, 10.f) : 0.f
        let enemyScore = calc_enemy_score(team, walker_agent)

        let totalScore = hitScore + distScore + dirScore + enemyScore
        if !isDowned
          if totalScore < minScore
            minScore = totalScore
            bestEntity = squarMemberEid
        elif totalScore < minDownedScore
          minDownedScore = totalScore
          bestDowned = squarMemberEid

  return bestEntity != INVALID_ENTITY_ID ? bestEntity : bestDowned

def respawn_to_next_soldier(soldier_eid, player_eid, squad_member__squad : EntityId;
                            at_time, respawner__invisibilityTime, respawner__invulnerabilityTime : float)
  setOptional(squad_member__squad, "squad__leader", soldier_eid) //Squad entity can be destroyed at end of session
  sendEvent(player_eid, [[CmdPossessEntity possessedEid=soldier_eid]])
  ecs::query(soldier_eid) <| $ [es] (var ai_target__invisibleTimeTo : float&;
                                     var hitpoints__invulnerableTimeTo : float&;
                                     var hitpoints__bulletInvulnerableCurDamageMult : float&;
                                     hitpoints__bulletInvulnerableStartDamage : float = 1.f)
    ai_target__invisibleTimeTo = at_time + respawner__invisibilityTime
    hitpoints__invulnerableTimeTo = at_time + respawner__invulnerabilityTime
    hitpoints__bulletInvulnerableCurDamageMult = hitpoints__bulletInvulnerableStartDamage

[es(tag=server, on_appear)]
def set_respawner_squad_on_spawn(evt : Event; eid, squad__ownerPlayer : EntityId)
  query(squad__ownerPlayer) <| $ [es] (var respawner__squad : EntityId&; var respawner__isFirstSpawn : bool&)
    respawner__squad = eid
    respawner__isFirstSpawn = false

[es(tag=server, on_disappear)]
def reset_respawner_squad_on_destroy(evt : Event; eid, squad__ownerPlayer : EntityId)
  query(squad__ownerPlayer) <| $ [es] (var respawner__squad : EntityId&)
    if respawner__squad == eid
      respawner__squad = INVALID_ENTITY_ID

[es(tag=server, on_appear)]
def respawner_init_mission_start_delay_on_creating(evt : Event;
                                                   respawner__missionStartDelay : float;
                                                   var respawner__canSpawnMinTime : float&)
  respawner__canSpawnMinTime = respawner__missionStartDelay
  query() <| $ [es] (firstPlayerConnectionTime : float)
    if firstPlayerConnectionTime >= 0.0
      respawner__canSpawnMinTime = firstPlayerConnectionTime + respawner__missionStartDelay

[es(tag=server)]
def respawner_init_mission_start_delay_on_first_connected_player(evt : EventFirstPlayerConnected;
                                                                 respawner__missionStartDelay : float;
                                                                 var respawner__canSpawnMinTime : float&)
  respawner__canSpawnMinTime = evt.time + respawner__missionStartDelay


def set_respawner_wait_number(respawner : EntityId; wait_number : int)
  set(respawner, "respawner__canRespawnWaitNumber", wait_number)

def remove_from_respawn_queue(respawner : EntityId; point : EntityId)
  set_respawner_wait_number(respawner, -1)
  query(point) <| $ [es] (var respawn_point__respawnersQueue : EidList;
                          var respawn_point__respawnersTimeouts : FloatList)
    let cnt = length(respawn_point__respawnersQueue)
    let idx = find_index(respawn_point__respawnersQueue, respawner)
    if idx >= 0
      respawn_point__respawnersQueue |> erase(idx)
      respawn_point__respawnersTimeouts |> erase(idx)
      for i in range(idx, cnt - 1)
        set_respawner_wait_number(respawn_point__respawnersQueue[i], i)

def try_add_to_respawn_queue(respawner : EntityId; group_id : int; team_id : int; time : float)
  var point = INVALID_ENTITY_ID
  find_query() <| $ [es(REQUIRE_NOT=autoRespawnSelector)] (eid : EntityId;
                                                           team : int;
                                                           selectedGroup : int;
                                                           var respawn_point__respawnersQueue : EidList;
                                                           var respawn_point__respawnersTimeouts : FloatList;
                                                           respawn_point__respawnersQueueTimeout : float = 5.f)
    if selectedGroup == group_id && team == team_id
      point = eid
      let pos = length(respawn_point__respawnersQueue)
      set_respawner_wait_number(respawner, pos)
      respawn_point__respawnersQueue |> push(respawner)
      respawn_point__respawnersTimeouts |> push(time + respawn_point__respawnersQueueTimeout)
      return true
    return false
  return point

def update_respawn_queue(respawner : EntityId; point : EntityId; time : float)
  var result : tuple<queued : int; active : bool; atTime : float; isEnemy : bool>
  result.queued  = 0
  result.active  = false
  result.atTime  = 0.f
  result.isEnemy = false
  query(point) <| $ [es] (respawn_icon__active : bool;
                          respawn_icon__activateAtTime : float;
                          respawn_icon__isEnemyAtRespawn : bool;
                          var respawn_point__respawnersQueue : EidList;
                          var respawn_point__respawnersTimeouts : FloatList;
                          respawn_point__respawnersQueueTimeout : float = 5.f)
    for i in range(0, length(respawn_point__respawnersQueue))
      if respawn_point__respawnersQueue[i] == respawner
        respawn_point__respawnersTimeouts[i] = time + respawn_point__respawnersQueueTimeout
        break

    var changed = false
    while length(respawn_point__respawnersQueue) > 0 && time > respawn_point__respawnersTimeouts[0]
      set_respawner_wait_number(respawn_point__respawnersQueue[0], -1)
      respawn_point__respawnersQueue |> erase(0)
      respawn_point__respawnersTimeouts |> erase(0)
      changed = true

    if changed
      for i in range(0, length(respawn_point__respawnersQueue))
        set_respawner_wait_number(respawn_point__respawnersQueue[i], i)

    result.queued  = length(respawn_point__respawnersQueue)
    result.active  = respawn_icon__active
    result.atTime  = respawn_icon__activateAtTime
    result.isEnemy = respawn_icon__isEnemyAtRespawn
  return result


[es(tag=server, REQUIRE=player)]
def respawner_es(info : UpdateStageInfoAct;
                 eid : EntityId;
                 team : int = TEAM_UNASSIGNED;
                 possessed : EntityId;
                 disconnected : bool = true;
                 squads__squadsCanSpawn : bool = true;
                 squads__respawnPenaltyTime : float = 0.f;
                 var respawner__respStartTime : float&;
                 var respawner__enabled : bool&;
                 var respawner__respEndTime : float&;
                 var respawner__canRespawnTime : float&;
                 var respawner__respToBot : bool&;
                 var respawner__spectatorEnabled : bool&;
                 var respawner__chosenRespawn : EntityId&;
                 var respawner__queuedAtPoint : EntityId&;
                 var respawner__queuedAtPointGroupId : int&;
                 respawner__canRespawnWaitNumber : int;
                 respawner__respTime : float;
                 respawner__respBotTime : float;
                 respawner__respRequested : bool;
                 respawner__respRequestedSquadId : int = 0;
                 respawner__respRequestedMemberId : int = 0;
                 respawner__selectNextEntityTime : float = 2.f;
                 respawner__invisibilityTime : float = 1.f;
                 respawner__invulnerabilityTime : float = 3.;
                 respawner__respBotTimeout : float = 5.f;
                 respawner__respTimeout : float = 15.f;
                 respawner__allowForceRespawn : bool = true;
                 respawner__allowBotForceRespawn : bool = true;
                 respawner__respawnGroupId : int = -1;
                 respawner__canSpawnMinTime : float = 0.0;
                 respawner__squad : EntityId = INVALID_ENTITY_ID)
  if !respawner__enabled
    return

  var isHeroAlive = false
  query(possessed) <| $ [es] (isAlive : bool)
    isHeroAlive = isAlive

  if isHeroAlive
    respawner__enabled = false
    respawner__respEndTime = -1.f
    respawner__canRespawnTime = -1.f
    return

  if respawner__respStartTime < 0.f
    respawner__respStartTime = info.curTime
    respawner__respEndTime = -1.f
    respawner__canRespawnTime = -1.f

  let spectatorWasEnabled = respawner__spectatorEnabled
  respawner__spectatorEnabled = false
  if info.curTime < respawner__respStartTime + respawner__selectNextEntityTime
    return

  let respToBot = respawner__squad != INVALID_ENTITY_ID && get_num_alive_squad_members(respawner__squad) > 0
  respawner__respToBot = respToBot

  if !respToBot
    let teamEid = get_team_eid(team)

    if (get_bool(teamEid, "team__shouldReduceBotsCount") ?? false) && has(eid, "playerIsBot")
      set(teamEid, "team__shouldReduceBotsCount", false)
      print("respawner[player: {eid}]: Kick bot player")
      destroyEntity(eid)
      return

    let teamCanSpawn = get_bool(teamEid, "team__squadsCanSpawn") ?? true
    if !squads__squadsCanSpawn || !teamCanSpawn
      respawner__respEndTime = -1.f //to hide respawn screen
      respawner__canRespawnTime = -1.f
      respawner__spectatorEnabled = true
      if !spectatorWasEnabled
        print("respawner[player: {eid}]: No respawns left. Enable spectator.")
      return

  if has(respawner__chosenRespawn, "deadEntity")
    respawner__chosenRespawn = INVALID_ENTITY_ID

  if respawner__chosenRespawn == INVALID_ENTITY_ID
    respawner__chosenRespawn = find_best_leader(respawner__squad)

  var forceRespTime = respToBot ? respawner__respBotTimeout : respawner__respTimeout
  var allowRespTime = respToBot ? respawner__respBotTime : respawner__respTime

  if !respToBot
    allowRespTime += squads__respawnPenaltyTime
    forceRespTime += squads__respawnPenaltyTime

  respawner__canRespawnTime = respawner__respStartTime + allowRespTime
  respawner__canRespawnTime = max(respawner__canRespawnTime, respawner__canSpawnMinTime)

  if !!respawner__queuedAtPoint && (!doesEntityExist(respawner__queuedAtPoint) ||
       respawner__queuedAtPointGroupId != respawner__respawnGroupId || respToBot)
    remove_from_respawn_queue(eid, respawner__queuedAtPoint)
    respawner__queuedAtPoint = INVALID_ENTITY_ID
    respawner__queuedAtPointGroupId = -1
  if !respToBot && !respawner__queuedAtPoint && respawner__respawnGroupId >= 0
    respawner__queuedAtPoint = try_add_to_respawn_queue(eid, respawner__respawnGroupId, team, info.curTime)
    respawner__queuedAtPointGroupId = !!respawner__queuedAtPoint ? respawner__respawnGroupId : -1
    if !!respawner__queuedAtPoint // if found skip to wait for valid respawner__canRespawnWaitNumber
      respawner__respEndTime = -1.f
      return

  var respawnForcedByQueue = false
  if !!respawner__queuedAtPoint
    let result = update_respawn_queue(eid, respawner__queuedAtPoint, info.curTime)
    if !result.active && result.atTime > 0.f
      respawner__canRespawnTime = max(respawner__canRespawnTime, result.atTime)
    if !result.active || result.isEnemy || respawner__canRespawnWaitNumber > 0
      respawner__respEndTime = -1.f
      return

    var alreadySpawned = false
    query(respawner__queuedAtPoint) <| $ [es] (respawn_point__lastRespawnTime : float)
      let waitForPointToDisableTime = 1.f
      if info.curTime <= respawn_point__lastRespawnTime + waitForPointToDisableTime
        alreadySpawned = true
    if alreadySpawned
      respawner__respEndTime = -1.f
      return

    if result.queued > 1
      let showSpawnButtonOverTime = 1.01f
      if info.curTime < respawner__canRespawnTime + showSpawnButtonOverTime
        respawner__respEndTime = respawner__canRespawnTime + showSpawnButtonOverTime
        return
      respawnForcedByQueue = true

  if respawner__respRequested || respawnForcedByQueue
    respawner__respEndTime = respawner__canRespawnTime
  else
    let allowForceRespawn = respToBot ? respawner__allowBotForceRespawn : respawner__allowForceRespawn
    respawner__respEndTime = allowForceRespawn ? respawner__respStartTime + forceRespTime : -1.f

  if respawner__respEndTime >= 0.f && info.curTime > respawner__respEndTime // force respawn
    if !!respawner__queuedAtPoint
      query(respawner__queuedAtPoint) <| $ [es] (var respawn_point__lastRespawnTime : float&)
        respawn_point__lastRespawnTime = info.curTime
      remove_from_respawn_queue(eid, respawner__queuedAtPoint)
      respawner__queuedAtPoint = INVALID_ENTITY_ID
      respawner__queuedAtPointGroupId = -1

    var newEid = respawner__chosenRespawn
    if !doesEntityExist(newEid)
      if respawner__squad != INVALID_ENTITY_ID
        newEid = find_best_leader(respawner__squad)
      else
        newEid = INVALID_ENTITY_ID
    print("respawner_es: force spawn entity {newEid} for player {eid} (squad {respawner__squad}), respEndTime {respawner__respEndTime}")
    if !disconnected // refuse to spawn entity for disconnected players
      if newEid != INVALID_ENTITY_ID
        print("respawner[player: {eid}]: Respawn to the next soldier in squad: {newEid}")
        respawn_to_next_soldier(newEid, eid, respawner__squad, info.curTime,
                                respawner__invisibilityTime, respawner__invulnerabilityTime)
      else
        let squadId = respawner__respRequestedSquadId
        let memberId = respawner__respRequestedMemberId
        let respawnGroupId = respawner__respawnGroupId
        print("respawner[player: {eid}]: Respawned squad: squadId={squadId}, memberId={memberId}, respawnGroupId={respawnGroupId}")
        sendEvent(eid, [[CmdSpawnSquad team=team, possessed=INVALID_ENTITY_ID, squadId=squadId, memberId=memberId, respawnGroupId=respawnGroupId]])
    else
      logwarn("respawner_es player {eid} is disconnected")
    respawner__enabled = false
    respawner__respStartTime = -1.f
    respawner__respEndTime = -1.f
    respawner__canRespawnTime = -1.f

def find_alive_squad_member_from_squad(squad_eid, exclude_eid : EntityId) : EntityId
  var aliveSquadMember = INVALID_ENTITY_ID
  ecs::find_query() <| $ [es] (eid : EntityId; squad_member__squad : ecs::EntityId; isAlive : bool)
    if squad_member__squad != squad_eid || eid == exclude_eid || !isAlive
      return false
    aliveSquadMember = eid
    return true
  return aliveSquadMember

def reset_respawner_for_player(player_eid)
  query(player_eid) <| $ [es] (var respawner__enabled : bool&;
                               var respawner__respRequested : bool&;
                               var respawner__respStartTime : float&)
    respawner__enabled = true
    respawner__respRequested = false
    respawner__respStartTime = -1.0

[es(tag=server)]
def reset_respawner_when_last_member_dies(evt : EventEntityDied; eid, squad_member__playerEid, squad_member__squad : EntityId)
  if !find_alive_squad_member_from_squad(squad_member__squad, eid)
    reset_respawner_for_player(squad_member__playerEid)

[es(tag=server)]
def reset_respawner_when_possessed_dies(evt : EventEntityDied; possessedByPlr, squad_member__playerEid : EntityId)
  if !!possessedByPlr
    reset_respawner_for_player(squad_member__playerEid)

[es(tag=server)]
def respawner_next_respawn_entity_es(evt : RequestNextRespawnEntity;
                                     respawner__enabled : bool;
                                     respawner__squad : EntityId;
                                     var respawner__chosenRespawn : EntityId&)
  if respawner__enabled && is_squad_member(respawner__squad, evt.memberEid)
    respawner__chosenRespawn = evt.memberEid

[es(tag=server, on_appear, REQUIRE=playerRespawnBase)]
def hardcore_spawn_on_player_immunity_es(evt : Event; var respbase__noSpawnImmunity : bool&)
  query() <| $ [es(REQUIRE=gamemodeFriendlyFire)] ()
    respbase__noSpawnImmunity = false

[es(tag=server)]
def respawn_req_es(evt : CmdRequestRespawn;
                   eid : EntityId;
                   var respawner__respawnGroupId : int&;
                   var respawner__respRequested : bool&;
                   var respawner__respRequestedSquadId : int&;
                   var respawner__respRequestedMemberId : int&)
  let respRequestedSquadId = evt.squadId
  let respRequestedMemberId = evt.memberId
  let respawnGroupId = evt.spawnGroup
  print("[HERO_RESPAWN] onRequestRespawn: {eid}; squadId: {respRequestedSquadId}; memberId: {respRequestedMemberId}; groupId: {respawnGroupId};")
  respawner__respRequested = true
  respawner__respRequestedSquadId = respRequestedSquadId
  respawner__respRequestedMemberId = respRequestedMemberId
  respawner__respawnGroupId = respawnGroupId

[es(tag=server)]
def respawn_cancel_req_es(evt : CmdCancelRequestRespawn;
                          eid : EntityId;
                          var respawner__respawnGroupId : int&;
                          var respawner__respRequested : bool&;
                          var respawner__respRequestedSquadId : int&;
                          var respawner__respRequestedMemberId : int&)
  let respRequestedSquadId = evt.squadId
  let respRequestedMemberId = evt.memberId
  let respawnGroupId = evt.spawnGroup
  print("[HERO_RESPAWN] onCancelRequestRespawn: {eid}; squadId: {respRequestedSquadId}; memberId: {respRequestedMemberId}; groupId: {respawnGroupId};")
  respawner__respRequested = false
  respawner__respRequestedSquadId = respRequestedSquadId
  respawner__respRequestedMemberId = respRequestedMemberId
  respawner__respawnGroupId = respawnGroupId

[es(tag=server, track=squad__isAlive, REQUIRE=squad__isAlive)]
def respawner_select_random_squad(evt : Event; squad__ownerPlayer : EntityId)
  query(squad__ownerPlayer) <| $ [es(REQUIRE=respawner__randomNextSquad)] (squads__revivePointsList : IntList; var respawner__respRequestedSquadId : int&)
    var readySquads : array<int>
    for squad, points in iter_range(squads__revivePointsList), squads__revivePointsList
      if points >= 100
        readySquads |> push(squad)

    respawner__respRequestedSquadId = readySquads?[rnd_int(0, length(readySquads) - 1)] ?? 0
