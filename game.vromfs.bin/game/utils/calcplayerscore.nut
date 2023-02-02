let { expSquads, expAlone } = require("%enlSqGlob/expScoringValues.nut")
let { round } = require("math")

let calcScore = @(comp, isNoBots) round((isNoBots ? expAlone : expSquads)
  .reduce(@(sum, score, key) sum + score * (comp?[$"scoring_player__{key}"] ?? 0), 0))

return calcScore