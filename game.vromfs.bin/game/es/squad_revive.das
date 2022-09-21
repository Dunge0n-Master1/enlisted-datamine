require ecs
require ecs.safe
require DagorSystem
require enlisted.events_enlisted
require game.events_game
require game.es.damage_type_common

def update_revive_squads_points_on_squad_death(squad_eid : EntityId; player_eid : EntityId)
  query(player_eid) <| $ [es] (squads__revivePointsAfterDeath : int;
                               squads__revivePointsPerSquad : int;
                               var squads__revivePointsList : Array&)
    let squadsCount = length(squads__revivePointsList)
    for squadRevivePoints in squads__revivePointsList
      squadRevivePoints |> set(min((squadRevivePoints ?? 0) + squads__revivePointsPerSquad, 100))

    print("[SPAWN] Heal all squads by {squads__revivePointsPerSquad}. Player: {player_eid}")

    let squadIdx = get_int(squad_eid, "squad__id") ?? -1
    if squadIdx >= 0 && squadIdx < squadsCount
      squads__revivePointsList[squadIdx] |> set(squads__revivePointsAfterDeath)
      print("[SPAWN] Squad {squadIdx}({squad_eid}) is dead; Player: {player_eid}")
    else
      logerr("Squad {squadIdx} does not exist. There are only {squadsCount} squads.")

    sendEvent(player_eid, [[RequestCheckTeamSpawnDefeat]])

def validate_soldier_revive_points(player_eid : EntityId;
                                   squad_idx : int;
                                   soldier_idx : int;
                                   points : Array;
                                   heal : Array;
                                   after_death : Array)
  assume squadPoints = points?[squad_idx] ?as Array
  let squadPointsLen = squadPoints != null ? length(*squadPoints) : 0
  if squad_idx < 0 || squad_idx >= length(points)
    logerr("Squad {squad_idx} does not exist in soldier_revive_points__points for player {player_eid}. There are only {length(points)} squads.")
  elif squad_idx >= length(heal)
    logerr("Squad {squad_idx} does not exist in soldier_revive_points__healPerSquadmate for player {player_eid}. There are only {length(heal)} squads.")
  elif soldier_idx < 0 || soldier_idx >= squadPointsLen
    logerr("soldier_revive_points__points has no respawn points for soldier {soldier_idx} in squad {squad_idx} for player {player_eid}. Total: {squadPointsLen}.")
  elif squad_idx >= length(after_death)
    logerr("Squad {squad_idx} does not exist in soldier_revive_points__afterDeath for player {player_eid}. There are only {length(after_death)} squads.")
  else
    return true
  return false


[es(tag=server)]
def squad_revive_es(evt : EventEntityDied;
                    eid aka victim_eid : EntityId;
                    squad_member__squad : EntityId;
                    squad_member__playerEid : EntityId;
                    hitpoints__lastOffenderPlayer : EntityId = INVALID_ENTITY_ID)
  assume offender = evt.offender
  assume damageType = evt.damageType
  assume victimSquadEid = squad_member__squad
  assume victimPlayerEid = squad_member__playerEid
  assume offenderPlayerEid = hitpoints__lastOffenderPlayer

  if !doesEntityExist(victimSquadEid)
    return

  query(victimSquadEid) <| $ [es] (squad__allMembers : EidList; var squad__isAlive : bool&)
    var aliveSquadMembers = 0
    if !squad__isAlive
      return
    for memberEid in squad__allMembers
      query(memberEid) <| $ [es] (isAlive : bool) // tag deadEntity is not applied yet
        if isAlive
          ++aliveSquadMembers

    let damageName = DAMAGE_TYPE_NAMES?[damageType] ?? "{damageType}"
    print("[SPAWN] Soldier is dead {victim_eid} player <{victimPlayerEid}>: Damage: {damageName} Squad: {victimSquadEid}; Offender: {offender} <{offenderPlayerEid}>; Left: {aliveSquadMembers}")

    if aliveSquadMembers == 0
      squad__isAlive = false
      update_revive_squads_points_on_squad_death(victimSquadEid, victimPlayerEid)

[es(tag=server)]
def soldier_revive_es(evt : EventEntityDied;
                      soldier__id : int;
                      squad_member__squad : EntityId;
                      squad_member__playerEid : EntityId)
  let victimSquadEid = squad_member__squad
  let victimPlayerEid = squad_member__playerEid
  let squadIdx = get_int(victimSquadEid, "squad__id") ?? -1
  let soldierIdx = soldier__id

  query(victimPlayerEid) <| $ [es] (soldier_revive_points__healPerSquadmate : Array;
                                    soldier_revive_points__afterDeath : Array;
                                    var soldier_revive_points__points : Array&)
    assume revivePointsBySquad = soldier_revive_points__points
    assume healBySquad = soldier_revive_points__healPerSquadmate
    assume pointsAfterDeath = soldier_revive_points__afterDeath

    if !validate_soldier_revive_points(victimPlayerEid, squadIdx, soldierIdx, revivePointsBySquad, healBySquad, pointsAfterDeath)
      return

    assume revivePoints = *(revivePointsBySquad[squadIdx] as Array)
    let heal = healBySquad[squadIdx] ?? 0

    for curPoints in revivePoints
      curPoints |> set(min(curPoints ?? 0 + heal, 100))
    print("[SPAWN] Heal all soldiers by {heal}. Player: {victimPlayerEid}")

    revivePoints[soldierIdx] |> set(pointsAfterDeath[squadIdx] ?? 0)

    var soldiersCanSpawn = false
    for curPoints in revivePoints
      if (curPoints ?? 0) >= 100
        soldiersCanSpawn = true
    if !soldiersCanSpawn
      sendEvent(victimPlayerEid, [[RequestCheckTeamSpawnDefeat]])
