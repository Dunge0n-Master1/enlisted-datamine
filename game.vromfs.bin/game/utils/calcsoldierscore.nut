let { scoreSquads, scoreAlone } = require("%enlSqGlob/expScoringValues.nut")

let calcScore = @(stats, isNoBots) (isNoBots ? scoreAlone : scoreSquads)
  .reduce(@(sum, score, key) sum + score * (stats?[key] ?? 0), 0).tointeger()

return calcScore