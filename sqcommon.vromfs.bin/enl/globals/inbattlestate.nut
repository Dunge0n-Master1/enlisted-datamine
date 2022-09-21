let {globalWatched} = require("%dngscripts/globalState.nut")
let {isInBattleState, isInBattleStateUpdate} = globalWatched("isInBattleState", @() false) //userId = true

return {
  isInBattleState
  isInBattleStateUpdate
}