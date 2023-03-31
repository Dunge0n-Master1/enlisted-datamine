import "%dngscripts/ecs.nut" as ecs
let { scoringPlayerStatsComps } = require ("%enlSqGlob/scoreTableStatistics.nut")
let calcScoringPlayerScore = require("%scripts/game/utils/calcPlayerScore.nut")

let noBotsModeQuery = ecs.SqQuery("noBotsModeQuery", {comps_rq=["noBotsMode"]})
let isNoBotsMode = @() noBotsModeQuery.perform(@(...) true) ?? false

ecs.register_es("enlisted_player_score_es",
{
  [["onInit", "onChange"]] = @(_, comp) comp.scoring_player__score = calcScoringPlayerScore(comp, isNoBotsMode())
},
{
  comps_rw = [
    ["scoring_player__score", ecs.TYPE_INT],
  ]
  comps_track = scoringPlayerStatsComps
}, {tags="server", before="send_userstats_es"})
