let sharedWatched = require("%dngscripts/sharedWatched.nut")
let isInBattleState = sharedWatched("isInBattleState", @() false) //userId = true

return {
  isInBattleState
}