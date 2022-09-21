let { globalWatched } = require("%dngscripts/globalState.nut")

let { singleMissionRewardId, singleMissionRewardIdUpdate } = globalWatched("singleMissionRewardId")
let { singleMissionRewardSum, singleMissionRewardSumUpdate } = globalWatched("singleMissionRewardSum", @() 0)

return {
  singleMissionRewardId, singleMissionRewardIdUpdate,
  singleMissionRewardSum, singleMissionRewardSumUpdate
}