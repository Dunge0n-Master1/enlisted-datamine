require ecs
require ecs.safe
require ecs.common
require DagorSystem
require enlisted.events_enlisted
require game.events_game
require game.es.damage_type_common

def update_revive_squads_points_on_squad_death(squad_eid : EntityId; player_eid : EntityId)
  query(player_eid) <| $ [es] (squads__revivePointsAfterDeath : int;
                               squads__revivePointsPerSquad : int;
                               var squads__revivePointsList : IntList&)
    let squadsCount = length(squads__revivePointsList)
    for squadRevivePoints in squads__revivePointsList
      squadRevivePoints = min(squadRevivePoints + squads__revivePointsPerSquad, 100)

    print("[SPAWN] Heal all squads by {squads__revivePointsPerSquad}. Player: {player_eid}")

    let squadFound = query(squad_eid) <| $ [es] (squad__id : int; squad__revivePointsAfterDeath : int = -1)
      if squad__id >= 0 && squad__id < squadsCount
        let revivePoints = squad__revivePointsAfterDeath >= 0 ? squad__revivePointsAfterDeath : squads__revivePointsAfterDeath
        squads__revivePointsList[squad__id] = revivePoints
        print("[SPAWN] Squad {squad__id}({squad_eid}) is dead; Player: {player_eid}")
      else
        logerr("Squad {squad__id} of player {player_eid} does not exist. There are only {squadsCount} squads.")
    if !squadFound
      logerr("Entity for squad {squad_eid} of player {player_eid} does not exist. Cannot apply revive points.")

    sendEvent(player_eid, [[RequestCheckTeamSpawnDefeat]])

def validate_soldier_revive_points(player_eid : EntityId;
                                   squad_idx : int;
                                   soldier_idx : int;
                                   points : Array;
                                   heal : IntList;
                                   after_death : IntList)
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

  query(victimSquadEid) <| $ [es] (squad__allMembers : EidList; squad__disableSquadRotation : bool; var squad__isAlive : bool&)
    var aliveSquadMembers = 0
    if !squad__isAlive
      return
    for memberEid in squad__allMembers
      query(memberEid) <| $ [es] (isAlive : bool) // tag deadEntity is not applied yet
        if isAlive
          ++aliveSquadMembers

    let damageName = DAMAGE_TYPE_NAMES?[damageType] ?? "{damageType}"
    print("[SPAWN] Soldier is dead {victim_eid} player <{victimPlayerEid}>: Damage: {damageName} Squad: {victimSquadEid}; Offender: {offender} <{offenderPlayerEid}>; Left: {aliveSquadMembers}")

    if aliveSquadMembers == 0 && !squad__disableSquadRotation
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

  query(victimPlayerEid) <| $ [es] (soldier_revive_points__healPerSquadmate : IntList;
                                    soldier_revive_points__afterDeath : IntList;
                                    var soldier_revive_points__points : Array&)
    assume revivePointsBySquad = soldier_revive_points__points
    assume healBySquad = soldier_revive_points__healPerSquadmate
    assume pointsAfterDeath = soldier_revive_points__afterDeath

    if !validate_soldier_revive_points(victimPlayerEid, squadIdx, soldierIdx, revivePointsBySquad, healBySquad, pointsAfterDeath)
      return

    assume revivePoints = *(revivePointsBySquad[squadIdx] as Array)
    let heal = healBySquad[squadIdx]

    for curPoints in revivePoints
      curPoints |> set(min(curPoints ?? 0 + heal, 100))
    print("[SPAWN] Heal all soldiers by {heal}. Player: {victimPlayerEid}")

    revivePoints[soldierIdx] |> set(pointsAfterDeath[squadIdx])

    var soldiersCanSpawn = false
    for curPoints in revivePoints
      if (curPoints ?? 0) >= 100
        soldiersCanSpawn = true
    if !soldiersCanSpawn
      sendEvent(victimPlayerEid, [[RequestCheckTeamSpawnDefeat]])

def get_respawns_to_full_restore(data : Object; count : int)
  return data["{count}"] ?? data.default ?? 1

def get_revive_points_heal(respawns_to_full_restore : int)
  return respawns_to_full_restore > 0 ? int(ceil(100.0 / float(respawns_to_full_restore))) : 100

[es(tag=server, on_appear, track=isArmiesReceived)]
def init_squad_revive_points(evt : Event;
                             eid : EntityId;
                             isArmiesReceived : bool;
                             armies : Object;
                             army : string;
                             squads__respawnsToFullRestoreSquadBySquadsCount : Object;
                             var squads__revivePointsList : IntList&;
                             var squads__revivePointsPerSquad : int&)
  if !isArmiesReceived
    return
  assume squads = (armies[army] ?as Object)?.squads ?as Array
  if squads == null
    return
  let squadCount = length(*squads)

  squads__revivePointsList |> resize(squadCount)
  for pts in squads__revivePointsList
    pts = 100

  var rotationSquadsCount = squadCount
  for squad in *squads
    let squadObj = squad as Object
    if squadObj?.curVehicle != null || squadObj?.disableSquadRotation != null
      rotationSquadsCount -= 1

  let respawnsToFullRestore = get_respawns_to_full_restore(squads__respawnsToFullRestoreSquadBySquadsCount, rotationSquadsCount)
  squads__revivePointsPerSquad = get_revive_points_heal(respawnsToFullRestore)
  print("Non-vehicle squads count is {rotationSquadsCount}. Set {squads__revivePointsPerSquad} revive points per squad for player {eid}.")


[es(tag=server, on_appear, track=isArmiesReceived)]
def soldier_revive_points_init_es(evt : Event;
                                  isArmiesReceived : bool;
                                  armies : Object;
                                  army : string;
                                  soldier_revive_points__respawnsToRestoreByCount : Object;
                                  var soldier_revive_points__points : Array&;
                                  var soldier_revive_points__healPerSquadmate : IntList&;
                                  var soldier_revive_points__afterDeath : IntList&)
  if !isArmiesReceived
    return
  assume squads = (armies[army] ?as Object)?.squads ?as Array
  if squads == null
    return

  let squadsCount = length(*squads)

  soldier_revive_points__points |> clear()
  soldier_revive_points__healPerSquadmate |> clear()
  soldier_revive_points__afterDeath |> clear()

  for i in range(squadsCount)
    let squad = squads?[i] ?as Object

    let squadMembers = squad?.squad ?as Array
    let soldiersInSquad = squadMembers != null ? length(*squadMembers) : 0
    push_to_array(soldier_revive_points__points) <| $(var soldierPoints : Array)
      for _p in range(soldiersInSquad)
        soldierPoints |> push(100)
    let respawnsToRestoreSoldier = get_respawns_to_full_restore(soldier_revive_points__respawnsToRestoreByCount, soldiersInSquad)
    soldier_revive_points__healPerSquadmate |> push(get_revive_points_heal(respawnsToRestoreSoldier))
    let revivePointsAfterDeath = respawnsToRestoreSoldier == 0 ? 100 : 0
    let isVehicleSquad = squad?.curVehicle != null
    soldier_revive_points__afterDeath |> push(isVehicleSquad ? 100 : revivePointsAfterDeath)
