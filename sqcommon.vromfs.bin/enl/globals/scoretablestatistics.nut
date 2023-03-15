import "%dngscripts/ecs.nut" as ecs
let { TEAM_UNASSIGNED } = require("team")
let { INVALID_GROUP_ID, INVALID_USER_ID } = require("matching.errors")

let scorePlayerInfoComps = [
  ["name", ecs.TYPE_STRING],
  ["player_group__memberIndex", ecs.TYPE_INT, 0],
  ["groupId", ecs.TYPE_INT64, INVALID_GROUP_ID],
  ["userid", ecs.TYPE_UINT64, INVALID_USER_ID],
  ["team", ecs.TYPE_INT, TEAM_UNASSIGNED],
  ["army", ecs.TYPE_STRING],
  ["disconnected", ecs.TYPE_BOOL],
  ["possessed", ecs.TYPE_EID],
  ["decorators__nickFrame", ecs.TYPE_STRING],
  ["decorators__portrait", ecs.TYPE_STRING],
  ["player__roomOwner", ecs.TYPE_BOOL],
  ["player_info__military_rank", ecs.TYPE_INT],
  ["player_info__rating", ecs.TYPE_INT],
  ["controlled_soldier__sKind", ecs.TYPE_STRING],
  ["controlled_soldier__sClassRare", ecs.TYPE_INT],
  ["controlled_soldier__sClass", ecs.TYPE_STRING]
]

let scoringPlayerSoldiersStatsComps = [
  ["scoring_player__kills", ecs.TYPE_INT],
  ["scoring_player__tankKills", ecs.TYPE_INT],
  ["scoring_player__planeKills", ecs.TYPE_INT],
  ["scoring_player__assists", ecs.TYPE_INT],
  ["scoring_player__captures", ecs.TYPE_FLOAT],
  ["scoring_player__attackKills", ecs.TYPE_INT],
  ["scoring_player__defenseKills", ecs.TYPE_INT],
  ["scoring_player__builtStructures", ecs.TYPE_INT],
  ["scoring_player__builtGunKills", ecs.TYPE_INT],
  ["scoring_player__builtGunKillAssists", ecs.TYPE_INT],
  ["scoring_player__builtGunTankKills", ecs.TYPE_INT],
  ["scoring_player__builtGunTankKillAssists", ecs.TYPE_INT],
  ["scoring_player__builtGunPlaneKills", ecs.TYPE_INT],
  ["scoring_player__builtGunPlaneKillAssists", ecs.TYPE_INT],
  ["scoring_player__builtBarbwireActivations", ecs.TYPE_INT],
  ["scoring_player__builtCapzoneFortificationActivations", ecs.TYPE_INT],
  ["scoring_player__builtAmmoBoxRefills", ecs.TYPE_INT],
  ["scoring_player__builtMedBoxRefills", ecs.TYPE_INT],
  ["scoring_player__builtRallyPointUses", ecs.TYPE_INT],
  ["scoring_player__hostedOnSoldierSpawns", ecs.TYPE_INT],
  ["scoring_player__vehicleRepairs", ecs.TYPE_INT],
  ["scoring_player__vehicleExtinguishes", ecs.TYPE_INT],
  ["scoring_player__landings", ecs.TYPE_INT],
  ["scoring_player__reviveAssists", ecs.TYPE_INT],
  ["scoring_player__healAssists", ecs.TYPE_FLOAT],
  ["scoring_player__tankKillAssists", ecs.TYPE_INT],
  ["scoring_player__planeKillAssists", ecs.TYPE_INT],
  ["scoring_player__tankKillAssistsAsCrew", ecs.TYPE_FLOAT],
  ["scoring_player__planeKillAssistsAsCrew", ecs.TYPE_FLOAT],
  ["scoring_player__crewKillAssists", ecs.TYPE_FLOAT],
  ["scoring_player__crewTankKillAssists", ecs.TYPE_FLOAT],
  ["scoring_player__crewPlaneKillAssists", ecs.TYPE_FLOAT],
  ["scoring_player__barrageBalloonDestructions", ecs.TYPE_INT],
  ["scoring_player__enemyBuiltFortificationDestructions", ecs.TYPE_INT],
  ["scoring_player__enemyBuiltGunDestructions", ecs.TYPE_INT],
  ["scoring_player__enemyBuiltUtilityDestructions", ecs.TYPE_INT],
  ["scoring_player__meleeKills", ecs.TYPE_INT],
  ["scoring_player__explosiveKills", ecs.TYPE_INT],
  ["scoring_player__longRangeKills", ecs.TYPE_INT],
  ["scoring_player__gunGameLevelup", ecs.TYPE_INT],
  ["scoring_player__friendlyHits", ecs.TYPE_INT],
  ["scoring_player__friendlyKills", ecs.TYPE_INT],
  ["scoring_player__friendlyKillsSamePlayer2Add", ecs.TYPE_INT],
  ["scoring_player__friendlyKillsSamePlayer3Add", ecs.TYPE_INT],
  ["scoring_player__friendlyKillsSamePlayer4Add", ecs.TYPE_INT],
  ["scoring_player__friendlyKillsSamePlayer5AndMoreAdd", ecs.TYPE_INT],
  ["scoring_player__friendlyTankHits", ecs.TYPE_INT],
  ["scoring_player__friendlyTankKills", ecs.TYPE_INT],
  ["scoring_player__friendlyPlaneHits", ecs.TYPE_INT],
  ["scoring_player__friendlyPlaneKills", ecs.TYPE_INT],
]

let scoringPlayerPlayerOnlyStatsComps = [
  ["scoring_player__squadDeaths", ecs.TYPE_INT],
]

let scoringPlayerStatsComps = [].extend(
  scoringPlayerSoldiersStatsComps,
  scoringPlayerPlayerOnlyStatsComps
)

let scoreStatisticsComps = [].extend(
  scorePlayerInfoComps,
  [["scoring_player__score", ecs.TYPE_INT]],
  scoringPlayerStatsComps
)

let playerStatisticsFromComps = @(comp) comp.__merge({
  score = comp["scoring_player__score"]
  memberIndex = comp["player_group__memberIndex"]
})

return {
  scoringPlayerSoldiersStatsComps
  scoringPlayerPlayerOnlyStatsComps
  scoringPlayerStatsComps
  scorePlayerInfoComps
  scoreStatisticsComps
  playerStatisticsFromComps
}