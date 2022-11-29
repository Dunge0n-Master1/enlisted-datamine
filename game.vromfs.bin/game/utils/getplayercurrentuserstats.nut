import "%dngscripts/ecs.nut" as ecs
let {TEAM_UNASSIGNED} = require("team")
let {INVALID_GROUP_ID} = require("matching.errors")
let abs = require("math").abs

let function getScorePlaceStats(roundResult, team, score) {
  let stats = {}
  roundResult.scoreStats?[team]?.each(function(requiredScore, stat) {
    if (score >= requiredScore)
      stats[stat] <- 1
  })
  return stats
}

let groupScoreQuery = ecs.SqQuery("groupScoreQuery", {
  comps_rq = ["player"]
  comps_ro = [["groupId", ecs.TYPE_INT64], ["scoring_player__score", ecs.TYPE_INT], ["scoring_player__battleTime", ecs.TYPE_FLOAT]]
})
let function getGroupStats(groupId) {
  if (groupId == null || groupId == INVALID_GROUP_ID)
    return {}
  local score = 0
  local time = 0
  local scorePerMin = 0.0
  groupScoreQuery(function(_, comp) {
    if (comp.groupId == groupId) {
      score += comp.scoring_player__score
      time += comp.scoring_player__battleTime.tointeger()
      scorePerMin += comp.scoring_player__score / max(comp.scoring_player__battleTime, 300.0) * 60.0
    }
  })
  return {
    groupScore = score
    groupScorePerMin = scorePerMin
    groupTime = time
  }
}

let function isTeamWon(roundResult, team) {
  return team != TEAM_UNASSIGNED && (roundResult.team == team) == roundResult.isWon
}
let isGameWithDeveloperQuery = ecs.SqQuery("isGameWithDeveloperQuery", { comps_rq = ["gameWithDeveloper"] })
let isGameWithDeveloper = @() isGameWithDeveloperQuery(@(...) true) ?? false

let function addStatValue(stats, value, addName) {
  if (value > 0)
    stats[addName] <- value
}

let function addStat(stats, comp, name, addName) {
  addStatValue(stats, comp[name], addName)
}

let playerUserstatComps = [
  ["groupId", ecs.TYPE_INT64, null],
  ["team", ecs.TYPE_INT, TEAM_UNASSIGNED],
  ["userstats", ecs.TYPE_OBJECT, null],
  ["userstats__bestWeaponKillStreak", ecs.TYPE_OBJECT, null],
  ["userstatsFilter", ecs.TYPE_SHARED_OBJECT, null],
  ["scoring_player__isGameFinished", ecs.TYPE_BOOL, true],
  ["scoring_player__kills", ecs.TYPE_INT, 0],
  ["scoring_player__killsByPlayer", ecs.TYPE_INT, 0],
  ["scoring_player__bestPossessedInfantryKillstreak", ecs.TYPE_INT, 0],
  ["scoring_player__tankKills", ecs.TYPE_INT, 0],
  ["scoring_player__planeKills", ecs.TYPE_INT, 0],
  ["scoring_player__battleTime", ecs.TYPE_FLOAT, 0.0],
  ["scoring_player__soldierDeaths", ecs.TYPE_INT, 0],
  ["scoring_player__squadDeaths", ecs.TYPE_INT, 0],
  ["scoring_player__assists", ecs.TYPE_INT, 0],
  ["scoring_player__attackKills", ecs.TYPE_INT, 0],
  ["scoring_player__defenseKills", ecs.TYPE_INT, 0],
  ["scoring_player__builtAmmoBoxRefills", ecs.TYPE_INT, 0],
  ["scoring_player__builtRallyPointUses", ecs.TYPE_INT, 0],
  ["scoring_player__builtGunKills", ecs.TYPE_INT, 0],
  ["scoring_player__builtGunKillAssists", ecs.TYPE_INT, 0],
  ["scoring_player__builtGunTankKills", ecs.TYPE_INT, 0],
  ["scoring_player__builtGunTankKillAssists", ecs.TYPE_INT, 0],
  ["scoring_player__builtGunPlaneKills", ecs.TYPE_INT, 0],
  ["scoring_player__builtGunPlaneKillAssists", ecs.TYPE_INT, 0],
  ["scoring_player__builtBarbwireActivations", ecs.TYPE_INT, 0],
  ["scoring_player__builtCapzoneFortificationActivations", ecs.TYPE_INT, 0],
  ["scoring_player__enemyBuiltFortificationDestructions", ecs.TYPE_INT, 0],
  ["scoring_player__enemyBuiltGunDestructions", ecs.TYPE_INT, 0],
  ["scoring_player__enemyBuiltUtilityDestructions", ecs.TYPE_INT, 0],
  ["scoring_player__friendlyFirePenalty", ecs.TYPE_INT, 0],
  ["squads__spawnCount", ecs.TYPE_INT, 0],
  ["scoring_player__score", ecs.TYPE_INT, 0],
  ["scoring_player__isBattleHero", ecs.TYPE_BOOL, false],
]

let getEngineerBuildingUsages = @(comp)
  comp["scoring_player__builtAmmoBoxRefills"]
  + comp["scoring_player__builtRallyPointUses"]
  + comp["scoring_player__builtGunKills"]
  + comp["scoring_player__builtGunKillAssists"]
  + comp["scoring_player__builtGunTankKills"]
  + comp["scoring_player__builtGunTankKillAssists"]
  + comp["scoring_player__builtGunPlaneKills"]
  + comp["scoring_player__builtGunPlaneKillAssists"]
  + comp["scoring_player__builtBarbwireActivations"]
  + comp["scoring_player__builtCapzoneFortificationActivations"]

let getBuildingDestroyed = @(comp)
  comp["scoring_player__enemyBuiltFortificationDestructions"]
  + comp["scoring_player__enemyBuiltGunDestructions"]
  + comp["scoring_player__enemyBuiltUtilityDestructions"]

let function getPlayerCurrentUserstats(comp, roundResult = null) {
  local stats = {}

  stats.__update(comp?.userstats?.getAll() ?? {})
  stats.__update(comp?["userstats__bestWeaponKillStreak"]?.getAll() ?? {})
  addStat(stats, comp, "scoring_player__score", "battle_score")
  addStat(stats, comp, "scoring_player__attackKills", "kills_while_attacking_point")
  addStat(stats, comp, "scoring_player__defenseKills", "kills_while_defending_point")
  addStat(stats, comp, "scoring_player__kills", "kills")
  addStat(stats, comp, "scoring_player__killsByPlayer", "kills_by_player")
  addStat(stats, comp, "scoring_player__bestPossessedInfantryKillstreak", "best_possessed_infantry_killstreak")
  if (comp.scoring_player__bestPossessedInfantryKillstreak >= 10)
    addStatValue(stats, 1, "best_possessed_infantry_killstreak_10")
  addStat(stats, comp, "scoring_player__tankKills", "tank_kills")
  addStat(stats, comp, "scoring_player__planeKills", "aircraft_kills")
  addStat(stats, comp, "scoring_player__soldierDeaths", "deaths")
  addStat(stats, comp, "scoring_player__squadDeaths", "squad_deaths")
  addStat(stats, comp, "scoring_player__assists", "assists")
  addStat(stats, comp, "squads__spawnCount", "friendly_fire_squad_spawns")
  addStat(stats, comp, "scoring_player__builtRallyPointUses", "engineer_rally_point_usage")
  addStat(stats, comp, "scoring_player__builtAmmoBoxRefills", "engineer_ammo_box_usage")
  addStatValue(stats, abs(comp["scoring_player__friendlyFirePenalty"]), "friendly_fire_score")
  addStatValue(stats, getEngineerBuildingUsages(comp), "engineer_building_usage")
  addStatValue(stats, getBuildingDestroyed(comp), "fortification_destoyed")
  addStatValue(stats, comp["scoring_player__battleTime"].tointeger(), "battle_time")
  if (roundResult != null) {
    let isGameFinished = comp["scoring_player__isGameFinished"]
    let isVictory = isTeamWon(roundResult, comp.team)
    if (isGameFinished) {
      addStatValue(stats, 1, "battles")
      addStatValue(stats, 1, isVictory ? "victories" : "defeats")
      if (comp.scoring_player__isBattleHero)
        addStatValue(stats, 1, isVictory ? "hero_wins" : "hero_loses")
      if (isGameWithDeveloper())
        addStatValue(stats, 1, "game_with_developers")
    } else {
      addStatValue(stats, 1, "early_quits")
      addStatValue(stats, 1, isVictory ? "victories_early_quit" : "defeats_early_quit")
      if (comp.scoring_player__isBattleHero)
        addStatValue(stats, 1, isVictory ? "hero_wins_deserted" : "hero_loses_deserted")
    }
    stats.__update(getScorePlaceStats(roundResult, comp.team, comp["scoring_player__score"]))
    let {
      groupScore = comp.scoring_player__score,
      groupTime = comp.scoring_player__battleTime,
      groupScorePerMin = comp.scoring_player__score / max(comp.scoring_player__battleTime, 300.0) * 60.0
    } = getGroupStats(comp?.groupId)
    addStatValue(stats, groupScore, "battle_group_battle_score")
    addStatValue(stats, groupTime.tointeger(), "battle_group_battle_time")
    addStatValue(stats, groupScorePerMin.tointeger(), "battle_group_sum_score_per_minute")
  }

  if (comp.userstatsFilter != null)
    stats = stats.filter(@(_,stat) stat in comp.userstatsFilter)

  return stats
}

return {
  playerUserstatComps
  getPlayerCurrentUserstats
}