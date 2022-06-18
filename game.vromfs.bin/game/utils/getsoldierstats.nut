import "%dngscripts/ecs.nut" as ecs
let { get_sync_time } = require("net")
let { isDebugDebriefingMode } = require("%enlSqGlob/wipFeatures.nut")
let { updateStatsForExpCalc } = require_optional("dedicated") == null && !isDebugDebriefingMode
  ? require("%scripts/game/utils/calcExpRewardSingle.nut")
  : require("%dedicated/calcExpReward.nut")

let getFinalizedSingleSpawnStats = @(dataList, time) dataList.map(@(data)
  data.__merge(
    data.spawnTime >= 0
      ? { time = data.time + time - data.spawnTime, spawnTime = -1 }
      : {}
  ))

let getSoldierStatsQuery = ecs.SqQuery("getSoldierStatsQuery", { comps_ro = [["soldierStats", ecs.TYPE_OBJECT]] })

let function getSoldierStats(isNoBots) {
  let time = get_sync_time()
  let data = {}
  getSoldierStatsQuery(function(playerEid, comp) {
    let playerData = getFinalizedSingleSpawnStats(comp.soldierStats.getAll(), time)
    playerData.each(@(v) updateStatsForExpCalc(v, isNoBots))
    data[playerEid] <- playerData
  })
  return data
}

return getSoldierStats