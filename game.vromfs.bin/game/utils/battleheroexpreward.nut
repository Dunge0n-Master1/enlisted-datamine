let { isSoldierAward, isTopSquadAward } = require("%enlSqGlob/ui/battleHeroesAwards.nut")

let armyExpMultByAwardCount = [1.2, 1.3, 1.4, 1.5]

const TOP_VEHICLE_OR_INFANTRY_SQUAD_MULT = 1.5
const PLAYER_IS_BATTLE_HERO_SQUAD_MULT = 1.2
let squadExpMultByAwardCount = [1.2, 1.3]
let squadExpMultByAwardCountPlayerIsBattleHero = [1.4, 1.5]

const PLAYER_IS_BATTLE_HERO_SOLDIER_MULT = 1.2
let soldierExpMultByAwardCount = [1.3, 1.4]
let soldierExpMultByAwardCountPlayerIsBattleHero = [1.4, 1.5]
const TOP_VEHICLE_OR_INFANTRY_SQUAD_SOLDIER_MULT = 1.4
const SOLDIER_IS_BATTLE_HERO_SOLDIER_MULT = 1.5

let getExpMul = @(list, index) list?[min(index, list.len() - 1)] ?? 1.0

let getArmyExpBattleHeroMult = @(awards, battleHero)
  (battleHero == null || awards.len() < 1) ? 1.0 : getExpMul(armyExpMultByAwardCount, awards.len() - 1)

let function getSquadExpBattleHeroMult(squadId, awards, battleHero) {
  if (squadId == null)
    return 1.0
  let squadAwards = awards.filter(@(a) a?.soldier.squadId == squadId).map(@(a) a.award)
  let isPlayerBattleHero = battleHero != null
  local expMul = isPlayerBattleHero ? PLAYER_IS_BATTLE_HERO_SQUAD_MULT : 1.0
  if (squadAwards.findindex(isTopSquadAward) != null)
    expMul = max(expMul, TOP_VEHICLE_OR_INFANTRY_SQUAD_MULT)
  let awardCount = squadAwards.filter(isSoldierAward).len()
  let expMulByAwardCount = isPlayerBattleHero ? squadExpMultByAwardCountPlayerIsBattleHero : squadExpMultByAwardCount
  expMul = max(expMul, getExpMul(expMulByAwardCount, awardCount - 1))
  return expMul
}

let function getSoldierExpBattleHeroMult(guid, squadId, isVehicleSquad, awards, battleHero) {
  if (guid == null)
    return 1.0
  let playerIsBattleHero = battleHero != null
  local expMul = playerIsBattleHero ? PLAYER_IS_BATTLE_HERO_SOLDIER_MULT : 1.0

  if (guid == battleHero?.soldier.guid)
    expMul = max(expMul, SOLDIER_IS_BATTLE_HERO_SOLDIER_MULT)

  let squadAwards = squadId != null ? awards.filter(@(a) a?.soldier.squadId == squadId).map(@(a) a.award) : []
  let soldierAwardsCount = awards.filter(@(a) guid == a.soldier.guid).len()

  if (squadAwards.findindex(isTopSquadAward) != null)
    expMul = max(expMul, TOP_VEHICLE_OR_INFANTRY_SQUAD_SOLDIER_MULT)

  let expMulByAwardCount = playerIsBattleHero ? soldierExpMultByAwardCountPlayerIsBattleHero : soldierExpMultByAwardCount
  expMul = max(expMul, getExpMul(expMulByAwardCount, soldierAwardsCount - 1))
  if (isVehicleSquad) {
    let squadSoldiersAwardsCount = squadAwards.filter(isSoldierAward).len()
    expMul = max(expMul, getExpMul(expMulByAwardCount, squadSoldiersAwardsCount - 1))
  }

  return expMul
}

return {
  getArmyExpBattleHeroMult
  getSquadExpBattleHeroMult
  getSoldierExpBattleHeroMult
}