let { get_setting_by_blk_path } = require("settings")
let { globalWatched } = require("%dngscripts/globalState.nut")

let forcedViolenceState = {
  isBloodEnabled = get_setting_by_blk_path("forcedViolenceSettings/bloodEnabled"),
  isGoreEnabled = get_setting_by_blk_path("forcedViolenceSettings/goreEnabled")
}

let {violenceState, violenceStateUpdate} = globalWatched("violenceState", @() {
  isBloodEnabled = forcedViolenceState.isBloodEnabled ?? get_setting_by_blk_path("gameplay/violence_blood") ?? true,
  isGoreEnabled = forcedViolenceState.isGoreEnabled ?? get_setting_by_blk_path("gameplay/violence_gore") ?? true
})

return {
  violenceState
  violenceStateUpdate
  forcedViolenceState
}