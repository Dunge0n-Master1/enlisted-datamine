let function updateStatsForExpCalc(s, _isNoBots = false) {
  s.score <- 100
  s.awardScore <- 100
}

let function calcExpReward(soldiersStats, armyData, _armiesState, _connectedTime, _awards, _battleHero) {
  let squadsExp = {}
  foreach (squad in armyData?.squads ?? []) {
    let squadId = squad?.squadId
    if (squadId != null && (squad?.squad ?? []).findvalue(@(s) s.guid in soldiersStats) != null)
      squadsExp[squadId] <- { exp = 0 }
  }
  return {
    baseExp = 0
    armyExp = 0
    squadsExp = squadsExp
    soldiersExp = soldiersStats.map(@(_) { exp = 0 })
  }
}

let isBattleHeroMultApplied = @(...) false
let shouldApplyBoosters = @(...) false

return {
  calcExpReward
  updateStatsForExpCalc
  isBattleHeroMultApplied
  shouldApplyBoosters
}