let { get_setting_by_blk_path } = require("settings")
let {globalWatched} = require("%dngscripts/globalState.nut")

let disableMenu = get_setting_by_blk_path("disableMenu") ?? false
let {isInBattleState, isInBattleStateUpdate} = globalWatched("isInBattleState", @() disableMenu)

return {
  isInBattleState
  isInBattleStateUpdate
}