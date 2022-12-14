from "%enlSqGlob/ui_library.nut" import *

let Rand = require("%sqstd/rand.nut")
let { round_by_value } = require("%sqstd/math.nut")
let { visibleCampaigns } = require("%enlist/meta/campaigns.nut")
let { gameProfile } = require("%enlist/soldiers/model/config/gameProfile.nut")
let { rankUnlock } = require("%enlist/profile/rankState.nut")

const TOTAL_KILLS_RAND = 0.4
const KILL_RAND = 0.3
const STATS_RAND = 0.3

let baseStats = {
  battles = 0.01
  kills = 0.1
  deaths = 0.06
  victories = 0.006
  defeats = 0.004
  battle_time = 6.0
}

let killWeights = {
  rifle_kills = 0.25
  submachine_gun_kills = 0.2
  machine_gun_kills = 0.14
  grenade_kills = 0.05
  kills_using_tank = 0.05
  kills_using_aircraft = 0.05
  artillery_kills = 0.02
  flamethrower_kills = 0.01
  pistol_kills = 0.05
  mortar_kills = 0.01
  melee_kills = 0.1
  launcher_kills = 0.01
  tank_kills = 0.05
  aircraft_kills = 0.01
}

let function makeBotData(botData){
  let { name, rank } = botData.player
  let seed = "".concat(name, rank).hash()
  let rand = Rand(seed)

  let curRating = rankUnlock.value.findvalue(@(v) v.index == rank).progress
  let nextRating = rankUnlock.value.findvalue(@(v) v.index == rank + 1).progress
  let rating = rand.rint(curRating, nextRating - 1) * 100
  botData.player.rating = rating
  let res = {}
  let main_game = {}

  let campArmies = []
  let campaigns = visibleCampaigns.value
  let campaignsCfg = gameProfile.value?.campaigns
  let baseKills = baseStats["kills"] * rating
  foreach (camp in campaigns)
    campArmies.extend((campaignsCfg?[camp].armies ?? []).map(@(a) a.id))
  campArmies.sort()
  foreach (army in campArmies){
    let armyData = {}
    let baseArmyKills = rand.rint(
      baseKills * (1.0 - TOTAL_KILLS_RAND), baseKills * (1.0 + TOTAL_KILLS_RAND))
    local armyKills = 0
    killWeights.keys().sort().each(function(killType){
      let killWeight = killWeights[killType]
      let r = rand.rfloat(killWeight*(1.0 - KILL_RAND), killWeight*(1.0 + KILL_RAND))
      let kills = round_by_value(baseArmyKills * r, 1).tointeger()
      armyData[killType] <- kills
      main_game[killType] <- kills + (main_game?[killType] ?? 0)
      armyKills += kills
    })
    armyData["kills"] <- armyKills
    baseStats.keys().sort().each(function(stat){
      let baseStatVal = baseStats[stat] * rating
      local statVal = rand.rint(baseStatVal*(1.0-STATS_RAND), baseStatVal*(1.0+STATS_RAND))
      if (stat == "battles")
        statVal = max(1, statVal)
      armyData[stat] <- statVal
      main_game[stat] <- statVal + (main_game?[stat] ?? 0)
    })
    res[army] <- armyData
  }
  res.__update({main_game})
  return botData.__merge({stats = { ["global"] = res}})
}

return makeBotData