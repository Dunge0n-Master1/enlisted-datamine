require ecs
require app
require ecs.safe
require DagorSystem

def private construct_new_stats(guid : string; var parent : Object&)
  using() <| $(var stats : Object)
    stats |> set("spawns", 0)
    stats |> set("killed", 0)  //suicide does not count
    stats |> set("kills", 0)
    stats |> set("attackKills", 0)
    stats |> set("defenseKills", 0)
    stats |> set("tankKills", 0)
    stats |> set("planeKills", 0)
    stats |> set("aiPlaneKills", 0)
    stats |> set("assists", 0)
    stats |> set("tankKillAssists", 0)
    stats |> set("planeKillAssists", 0)
    stats |> set("aiPlaneKillAssists", 0)
    stats |> set("captures", 0.0)
    stats |> set("crewKillAssists", 0.0)
    stats |> set("crewTankKillAssists", 0.0)
    stats |> set("crewPlaneKillAssists", 0.0)
    stats |> set("crewAiPlaneKillAssists", 0.0)
    stats |> set("tankKillAssistsAsCrew", 0.0)
    stats |> set("planeKillAssistsAsCrew", 0.0)
    stats |> set("aiPlaneKillAssistsAsCrew", 0.0)
    stats |> set("builtStructures", 0)
    stats |> set("builtGunKills", 0)
    stats |> set("builtGunKillAssists", 0)
    stats |> set("builtGunTankKills", 0)
    stats |> set("builtGunTankKillAssists", 0)
    stats |> set("builtGunPlaneKills", 0)
    stats |> set("builtGunAiPlaneKills", 0)
    stats |> set("builtGunPlaneKillAssists", 0)
    stats |> set("builtGunAiPlaneKillAssists", 0)
    stats |> set("builtBarbwireActivations", 0)
    stats |> set("builtCapzoneFortificationActivations", 0)
    stats |> set("builtAmmoBoxRefills", 0)
    stats |> set("builtMedBoxRefills", 0)
    stats |> set("builtRallyPointUses", 0)
    stats |> set("hostedOnSoldierSpawns", 0)
    stats |> set("vehicleRepairs", 0)
    stats |> set("vehicleExtinguishes", 0)
    stats |> set("landings", 0)
    stats |> set("reviveAssists", 0)
    stats |> set("healAssists", 0.0)
    stats |> set("barrageBalloonDestructions", 0)
    stats |> set("enemyBuiltFortificationDestructions", 0)
    stats |> set("enemyBuiltGunDestructions", 0)
    stats |> set("enemyBuiltUtilityDestructions", 0)
    stats |> set("friendlyHits", 0)
    stats |> set("friendlyKills", 0)
    stats |> set("friendlyKillsSamePlayer2Add", 0)
    stats |> set("friendlyKillsSamePlayer3Add", 0)
    stats |> set("friendlyKillsSamePlayer4Add", 0)
    stats |> set("friendlyKillsSamePlayer5AndMoreAdd", 0)
    stats |> set("friendlyTankHits", 0)
    stats |> set("friendlyTankKills", 0)
    stats |> set("friendlyPlaneHits", 0)
    stats |> set("friendlyPlaneKills", 0)
    stats |> set("meleeKills", 0)
    stats |> set("explosiveKills", 0)
    stats |> set("longRangeKills", 0)
    stats |> set("bestOneLifeInfantryKills", 0)
    stats |> set("bestOneLifeInfantryKillsWithCrew", 0)
    stats |> set("bestOneLifeVehicleKills", 0)
    stats |> set("bestOneLifeVehicleKillsWithCrew", 0)
    stats |> set("bestOneLifeParatrooperKills", 0)
    stats |> set("contributionToVictory", 0)
    stats |> set("gunGameLevelup", 0)
    stats |> set("time", 0.0)
    stats |> set("spawnTime", -1.0)
    stats |> set("score", 0)
    stats |> set("previousLifeScore", 0.0)
    stats |> set("squadId", -1)
    set(parent, guid, stats)

def private set_squad_time(is_alive : bool; squad_id : string; var squad_stats : Object&)
  var squadStat = (squad_stats[squad_id] ?as Object)
  if squadStat == null
    logerr("squad stat isn't inited for '{squad_id}'")
    return

  if is_alive
    set(*squadStat, "spawnTime", get_sync_time())
  else
    let spawnTime = (squadStat?.spawnTime ?? -1.)
    if spawnTime > 0.
      set(*squadStat, "time", (squadStat?.time ?? 0.) + get_sync_time() - spawnTime)
    set(*squadStat, "spawnTime", -1.)

[es(tag=server, on_appear)]
def squad_stat_init_es(evt : Event; squad__squadProfileId : string; squad__ownerPlayer : EntityId)
  query(squad__ownerPlayer) <| $ [es] (var squadStats : Object&)
    if !has(squadStats, squad__squadProfileId)
      using() <| $(var empty : Object)
        squadStats |> set(squad__squadProfileId, empty)

[es(tag=server, track=disconnected, after=squad_stat_init_es)]
def squad_stat_on_player_disconnected_es(evt : Event; respawner__squad : EntityId; disconnected : bool; var squadStats : Object&)
  query(respawner__squad) <| $ [es] (squad__squadProfileId : string)
    set_squad_time(!disconnected, squad__squadProfileId, squadStats)

[es(tag=server, on_event=(CmdGetBattleResult, EventTeamRoundResult), before=(send_battle_result_es, get_battle_result_es))]
def squad_stat_on_round_result_es(evt : Event; squad__squadProfileId : string; squad__ownerPlayer : EntityId)
  query(squad__ownerPlayer) <| $ [es] (var squadStats : Object&)
    set_squad_time(false/*is_alive*/, squad__squadProfileId, squadStats)

[es(tag=server, on_appear, track=squad__isAlive, after=squad_stat_init_es)]
def squad_stat_on_die_es(evt : Event;
                         squad__squadProfileId : string;
                         squad__ownerPlayer : EntityId;
                         squad__isAlive : bool)
  query(squad__ownerPlayer) <| $ [es] (var squadStats : Object&)
    set_squad_time(squad__isAlive, squad__squadProfileId, squadStats)

[es(tag=server, on_event=EventEntityCreated)]
def squad_stats_es(evt : Event; guid : string; squad_member__squad : EntityId; squad_member__playerEid : EntityId)
  if guid == ""
    return

  query(squad_member__playerEid) <| $ [es] (var soldierStats : Object&)
    if soldierStats[guid] == null
      construct_new_stats(guid, soldierStats)

    var stats = (*soldierStats[guid]) as Object
    *(*stats?.spawns as int) += 1
    *(*stats?.spawnTime as float) = get_sync_time()
    query(squad_member__squad) <| $ [es] (squad__id : int)
      *(*stats?.squadId as int) = squad__id

  debug("[BattleReward] onMemberCreated {squad_member__playerEid} <{guid}>")
