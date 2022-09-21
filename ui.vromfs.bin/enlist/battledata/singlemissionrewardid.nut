from "%enlSqGlob/ui_library.nut" import *

let { rewardedSingleMissons } = require("%enlist/meta/profile.nut")
let { lastGameTutorialId } = require("%enlist/tutorial/battleTutorial.nut")
let { gameProfile } = require("%enlist/soldiers/model/config/gameProfile.nut")
let { lockedProgressCampaigns } = require("%enlist/meta/campaigns.nut")
let { curCampaign } = require("%enlist/meta/curCampaign.nut")
let { singleMissionRewardIdUpdate, singleMissionRewardSumUpdate } = require("%enlSqGlob/singleMissionRewardState.nut")

let singleMissionRewardIdInt = keepref(Computed(function() {
  if (lockedProgressCampaigns.value?[curCampaign.value])
    return null
  let id = lastGameTutorialId.value
  if (id == null || (rewardedSingleMissons.value?[id].version ?? 0) >= (gameProfile.value?.tutorials[id].version ?? 0))
    return null
  return id
}))

singleMissionRewardIdInt.subscribe(@(v) singleMissionRewardIdUpdate(v))

let singleMissionRewardSumInt = keepref(Computed(@()
  gameProfile.value?.tutorials[singleMissionRewardIdInt.value].expSum ?? 0))

singleMissionRewardSumInt.subscribe(@(v) singleMissionRewardSumUpdate(v))