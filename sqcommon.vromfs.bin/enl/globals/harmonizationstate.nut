from "frp" import Computed

let { get_setting_by_blk_path } = require("settings")
let { globalWatched } = require("%dngscripts/globalState.nut")


// harmonizationRequired can only be set by the game settings. If it is enabled, no matter the player's settings
// harmonization will be enabled. If it is not enabled, player can turn it on\off with harmonizationEnabled

let harmonizationRequired = get_setting_by_blk_path("harmonizationRequired") ?? false

let { harmonizationState, harmonizationStateUpdate } = globalWatched("harmonizationState",
  @() get_setting_by_blk_path("harmonizationEnabled") ?? false)

let isHarmonizationEnabled = Computed(@() harmonizationRequired || harmonizationState.value)

return {
  isHarmonizationEnabled
  harmonizationRequired
  harmonizationState
  harmonizationStateUpdate
}