let { partition } = require("%sqstd/underscore.nut")

const WINNING_TEAM_BATTLE_HEROES_COUNT = 4
const LOSING_TEAM_BATTLE_HEROES_COUNT = 3

enum BattleHeroesAward {
  TOP_PLACE = "top_place"
  TOP_VEHICLE_SQUAD = "top_vehicle_squad"
  TOP_INFANTRY_SQUAD = "top_infantry_squad"
  TOP_KIND_RIFLE = "top_kind_rifle"
  TOP_KIND_ASSAULT = "top_kind_assault"
  TOP_KIND_MGUN = "top_kind_mgun"
  TOP_KIND_ENGINEER = "top_kind_engineer"
  TOP_KIND_FLAMETROOPER = "top_kind_flametrooper"
  TOP_KIND_PILOT_ASSAULTER = "top_kind_pilot_assaulter"
  TOP_KIND_PILOT_FIGHTER = "top_kind_pilot_fighter"
  TOP_KIND_MORTARMAN = "top_kind_mortarman"
  TOP_KIND_RADIOMAN = "top_kind_radioman"
  TOP_KIND_TANKER = "top_kind_tanker"
  TOP_KIND_ANTI_TANK = "top_kind_anti_tank"
  TOP_KIND_SNIPER = "top_kind_sniper"
  TOP_VEHICLES_DESTROYED = "top_vehicles_destroyed"
  TOP_MELEE_KILLS = "top_melee_kills"
  TOP_GRENADE_KILLS = "top_grenade_kills"
  TOP_LONG_RANGE_KILLS = "top_long_range_kills"
  TACTICIAN = "tactician"
  UNIVERSAL = "universal"
  MULTISPECIALIST = "multispecialist"
  BATTLE_HEROES_CARD = "battle_heroes_card"
  PLAYER_BATTLE_HERO = "player_battle_hero"
}

let soldierKindAwards = {
  [BattleHeroesAward.TOP_KIND_RIFLE] = true,
  [BattleHeroesAward.TOP_KIND_ASSAULT] = true,
  [BattleHeroesAward.TOP_KIND_MGUN] = true,
  [BattleHeroesAward.TOP_KIND_ENGINEER] = true,
  [BattleHeroesAward.TOP_KIND_FLAMETROOPER] = true,
  [BattleHeroesAward.TOP_KIND_PILOT_ASSAULTER] = true,
  [BattleHeroesAward.TOP_KIND_PILOT_FIGHTER] = true,
  [BattleHeroesAward.TOP_KIND_MORTARMAN] = true,
  [BattleHeroesAward.TOP_KIND_RADIOMAN] = true,
  [BattleHeroesAward.TOP_KIND_TANKER] = true,
  [BattleHeroesAward.TOP_KIND_ANTI_TANK] = true,
  [BattleHeroesAward.TOP_KIND_SNIPER] = true,
}

let soldierAwards = soldierKindAwards.__merge({
  [BattleHeroesAward.TOP_VEHICLES_DESTROYED] = true,
  [BattleHeroesAward.TOP_MELEE_KILLS] = true,
  [BattleHeroesAward.TOP_GRENADE_KILLS] = true,
  [BattleHeroesAward.TOP_LONG_RANGE_KILLS] = true,
  [BattleHeroesAward.TACTICIAN] = true,
  [BattleHeroesAward.UNIVERSAL] = true,
})

let topSquadAwards = {
  [BattleHeroesAward.TOP_VEHICLE_SQUAD] = true,
  [BattleHeroesAward.TOP_INFANTRY_SQUAD] = true,
}

let isSoldierKindAward = @(award) soldierKindAwards?[award] ?? false
let isSoldierAward = @(award) soldierAwards?[award] ?? false
let isTopSquadAward = @(award) topSquadAwards?[award] ?? false

let awardPriority = {
  // Big awards (battle hero place guaranteed)
  [BattleHeroesAward.TOP_PLACE] = 3,
  [BattleHeroesAward.TOP_VEHICLE_SQUAD] = 2,
  [BattleHeroesAward.TOP_INFANTRY_SQUAD] = 2,
  [BattleHeroesAward.UNIVERSAL] = 1,
  bigAward = 1,
  // Small awards
  [BattleHeroesAward.TOP_KIND_RIFLE] = 0,
  [BattleHeroesAward.TOP_KIND_ASSAULT] = 0,
  [BattleHeroesAward.TOP_KIND_MGUN] = 0,
  [BattleHeroesAward.TOP_KIND_ENGINEER] = 0,
  [BattleHeroesAward.TOP_KIND_FLAMETROOPER] = 0,
  [BattleHeroesAward.TOP_KIND_PILOT_ASSAULTER] = 0,
  [BattleHeroesAward.TOP_KIND_PILOT_FIGHTER] = 0,
  [BattleHeroesAward.TOP_KIND_MORTARMAN] = 0,
  [BattleHeroesAward.TOP_KIND_RADIOMAN] = 0,
  [BattleHeroesAward.TOP_KIND_TANKER] = 0,
  [BattleHeroesAward.TOP_KIND_ANTI_TANK] = 0,
  [BattleHeroesAward.TOP_KIND_SNIPER] = 0,
  [BattleHeroesAward.TOP_VEHICLES_DESTROYED] = 0,
  [BattleHeroesAward.TOP_MELEE_KILLS] = 0,
  [BattleHeroesAward.TOP_GRENADE_KILLS] = 0,
  [BattleHeroesAward.TOP_LONG_RANGE_KILLS] = 0,
  [BattleHeroesAward.TACTICIAN] = 0,
}

let isBigAward = @(award) awardPriority[award] >= awardPriority.bigAward

let requiredValueTable = {
  [BattleHeroesAward.TOP_VEHICLES_DESTROYED] = 3,
  [BattleHeroesAward.TOP_MELEE_KILLS] = 3,
  [BattleHeroesAward.TOP_GRENADE_KILLS] = 7,
  [BattleHeroesAward.TOP_LONG_RANGE_KILLS] = 5,
}

let requiredScoreTable = {
  [BattleHeroesAward.TOP_PLACE] = {
    domination    = { withBots = 0, noBots = 0 }
    invasion      = { withBots = 0, noBots = 0 }
    confrontation = { withBots = 0, noBots = 0 }
    assault       = { withBots = 0, noBots = 0 }
    destruction   = { withBots = 0, noBots = 0 }
    escort        = { withBots = 0, noBots = 0 }
    gun_game      = { withBots = 0, noBots = 0 }
    no_mode       = { withBots = 0, noBots = 0 }
  },
  [BattleHeroesAward.TOP_VEHICLE_SQUAD] = {
    domination    = { withBots = 800,  noBots = 400 }
    invasion      = { withBots = 1200, noBots = 500 }
    confrontation = { withBots = 1200, noBots = 500 }
    assault       = { withBots = 1200, noBots = 500 }
    destruction   = { withBots = 1200, noBots = 500 }
    escort        = { withBots = 1200, noBots = 500 }
    gun_game      = { withBots = 800,  noBots = 400 }
    no_mode       = { withBots = 1200, noBots = 500 }
  },
  [BattleHeroesAward.TOP_INFANTRY_SQUAD] = {
    domination    = { withBots = 800,  noBots = 400 }
    invasion      = { withBots = 1200, noBots = 500 }
    confrontation = { withBots = 1200, noBots = 500 }
    assault       = { withBots = 1200, noBots = 500 }
    destruction   = { withBots = 1200, noBots = 500 }
    escort        = { withBots = 1200, noBots = 500 }
    gun_game      = { withBots = 800, noBots =  400 }
    no_mode       = { withBots = 1200, noBots = 500 }
  },
}

let awardScoreStats = {
  [BattleHeroesAward.TACTICIAN] = {
    attackKills = true
    defenseKills = true
    captures = true
    builtStructures = true
    builtGunKills = true
    builtGunKillAssists = true
    builtGunTankKills = true
    builtGunTankKillAssists = true
    builtGunPlaneKills = true
    builtGunPlaneKillAssists = true
    builtBarbwireActivations = true
    builtCapzoneFortificationActivations = true
    builtAmmoBoxRefills = true
    builtRallyPointUses = true
  }
}

let tacticianStats = {
  statsA = ["scoring_player__captures"]
  requiredA = 2
  statsB = ["scoring_player__attackKills", "scoring_player__defenseKills"]
  requiredB = 10
  statsA2 = [
    "scoring_player__builtStructures",
    "scoring_player__builtGunKills",
    "scoring_player__builtGunKillAssists",
    "scoring_player__builtGunTankKills",
    "scoring_player__builtGunTankKillAssists",
    "scoring_player__builtGunPlaneKills",
    "scoring_player__builtGunPlaneKillAssists",
    "scoring_player__builtBarbwireActivations",
    "scoring_player__builtCapzoneFortificationActivations",
    "scoring_player__builtAmmoBoxRefills",
    "scoring_player__builtRallyPointUses",
  ]
  requiredA2 = 10
}

let requiredSoldierKindScoreTable = {
  domination    = { withBots = 300, noBots = 250 }
  invasion      = { withBots = 450, noBots = 350 }
  confrontation = { withBots = 450, noBots = 350 }
  assault       = { withBots = 450, noBots = 350 }
  destruction   = { withBots = 450, noBots = 350 }
  escort        = { withBots = 450, noBots = 350 }
  gun_game      = { withBots = 300, noBots = 250 }
  no_mode       = { withBots = 450, noBots = 350 }
}

let function getAwardBySoldierKind(kind) {
  let award = $"top_kind_{kind}"
  return (award in soldierKindAwards) ? award : null
}

let function combineMultispecialistAward(awards) {
  let [kindAwards, otherAwards] = partition(awards, isSoldierKindAward)
  return otherAwards.extend(kindAwards.len() > 1
    ? [{id=BattleHeroesAward.MULTISPECIALIST, value=kindAwards.len()}]
    : kindAwards)
}

return {
  BattleHeroesAward
  awardPriority
  requiredScoreTable
  requiredValueTable
  requiredSoldierKindScoreTable
  getAwardBySoldierKind
  isSoldierKindAward
  isSoldierAward
  isTopSquadAward
  combineMultispecialistAward
  tacticianStats
  awardScoreStats
  isBigAward
  WINNING_TEAM_BATTLE_HEROES_COUNT
  LOSING_TEAM_BATTLE_HEROES_COUNT
}