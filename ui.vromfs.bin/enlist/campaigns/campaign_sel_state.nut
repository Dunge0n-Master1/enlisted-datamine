from "%enlSqGlob/ui_library.nut" import *

let { unlockedCampaigns, visibleCampaigns } = require("%enlist/meta/campaigns.nut")
let { canChangeCampaign } = require("%enlist/meta/curCampaign.nut")

let hasCampaignSelection = Computed(function() {
  if (!canChangeCampaign.value)
    return false
  local count = 0
  foreach (c in visibleCampaigns.value) {
    if (unlockedCampaigns.value.contains(c))
      ++count
  }
  return count > 1
})

return {
  hasCampaignSelection
}