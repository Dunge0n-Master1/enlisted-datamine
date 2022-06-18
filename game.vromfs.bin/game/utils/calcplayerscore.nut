let { expSquads, expAlone } = require("%enlSqGlob/expScoringValues.nut")

let calcScore = @(comp, isNoBots) (isNoBots ? expAlone : expSquads)
  .reduce(@(sum, score, key) sum + score * (comp?[$"scoring_player__{key}"] ?? 0), 0).tointeger()

return calcScore