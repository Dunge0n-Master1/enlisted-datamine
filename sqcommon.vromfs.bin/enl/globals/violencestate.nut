let { get_setting_by_blk_path } = require("settings")
let sharedWatched = require("%dngscripts/sharedWatched.nut")

let forcedViolenceState = {
  isBloodEnabled = get_setting_by_blk_path("forcedViolenceSettings/bloodEnabled"),
  isGoreEnabled = get_setting_by_blk_path("forcedViolenceSettings/goreEnabled")
}

let violenceState = sharedWatched("violenceState", @() {
  isBloodEnabled = forcedViolenceState.isBloodEnabled ?? get_setting_by_blk_path("gameplay/violence_blood") ?? true,
  isGoreEnabled = forcedViolenceState.isGoreEnabled ?? get_setting_by_blk_path("gameplay/violence_gore") ?? true
})

return {
  violenceState
  forcedViolenceState
}