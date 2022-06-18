from "%enlSqGlob/ui_library.nut" import *

let { rewardedSingleMissons } = require("%enlist/meta/profile.nut")
let { lastGameTutorialId } = require("%enlist/tutorial/battleTutorial.nut")
let { gameProfile } = require("%enlist/soldiers/model/config/gameProfile.nut")
let { lockedProgressCampaigns } = require("%enlist/meta/campaigns.nut")
let { curCampaign } = require("%enlist/meta/curCampaign.nut")
let sharedWatched = require("%dngscripts/sharedWatched.nut")

let singleMissionRewardId = keepref(Computed(function() {
  if (lockedProgressCampaigns.value?[curCampaign.value])
    return null
  let id = lastGameTutorialId.value
  if (id == null || (rewardedSingleMissons.value?[id].version ?? 0) >= (gameProfile.value?.tutorials[id].version ?? 0))
    return null
  return id
}))

let singleMissionRewardIdShared = sharedWatched("singleMissionRewardId", @() singleMissionRewardId.value)
singleMissionRewardIdShared(singleMissionRewardId.value)
singleMissionRewardId.subscribe(@(v) singleMissionRewardIdShared(v))

let singleMissionRewardSum = keepref(Computed(@()
  gameProfile.value?.tutorials[singleMissionRewardId.value].expSum ?? 0))

let singleMissionRewardSumShared = sharedWatched("singleMissionRewardSum", @() singleMissionRewardSum.value)
singleMissionRewardSumShared(singleMissionRewardSum.value)
singleMissionRewardSum.subscribe(@(v) singleMissionRewardSumShared(v))