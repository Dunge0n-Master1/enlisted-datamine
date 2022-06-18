let {
  awardPriority, WINNING_TEAM_BATTLE_HEROES_COUNT, LOSING_TEAM_BATTLE_HEROES_COUNT
} = require("%enlSqGlob/ui/battleHeroesAwards.nut")

let compareAwards = @(a, b) (awardPriority[a.award] <=> awardPriority[b.award]) || (a.score <=> b.score)

let function getBattleHeroForPlayer(playerAwards, playerEid) {
  let soldier = playerAwards.reduce(@(a, b) compareAwards(a, b) > 0 ? a : b).soldier
  return {
    playerEid
    soldier
    awards = playerAwards.map(@(a) a.award)
  }
}

let function pickHeroes(heroByPlayer, scoreIndex, count) {
  return heroByPlayer.map(@(v, eid) {
    eid
    priority = v.awards.map(@(a) awardPriority[a]).reduce(@(a,b) a > b ? a : b)
    scoreIndex = scoreIndex?[eid] ?? 0
  })
  .values()
  .sort(@(a,b) (b.priority <=> a.priority) || (a.scoreIndex <=> b.scoreIndex))
  .slice(0, count)
  .map(@(v) [v.eid, heroByPlayer[v.eid]])
  .totable()
}

let function calcBattleHeroes(playersAwards, playersScoreIndex, isWinningTeam) {
  let playerHeroes = playersAwards.map(getBattleHeroForPlayer)
  let teamHeroCount = isWinningTeam ? WINNING_TEAM_BATTLE_HEROES_COUNT : LOSING_TEAM_BATTLE_HEROES_COUNT
  return pickHeroes(playerHeroes, playersScoreIndex, teamHeroCount)
}

return calcBattleHeroes