from "%enlSqGlob/ui_library.nut" import *

let {
  settings, onlineSettingUpdated
} = require("%enlist/options/onlineSettings.nut")
let { unlockedCampaigns, lockedCampaigns, lockedProgressCampaigns } = require("%enlist/meta/campaigns.nut")
let { curCampaign, curCampaignStored } = require("%enlist/meta/curCampaign.nut")

const SEEN_ID = "seen/campaigns"

let UNSEEN = 0
let WAS_SEEN_LOCKED = 1
let WAS_SEEN_UNLOCKED = 2
let WAS_SEEN_PROGRESS_LOCKED = 3

let seen = Computed(@() (settings.value?[SEEN_ID] ?? {})
  .map(@(v) type(v) == "integer" ? v : WAS_SEEN_UNLOCKED)) //compatibility with previous save format

let currentStatus = Computed(function () {
  let curStatus = {}

  foreach (campaignId in unlockedCampaigns.value)
    curStatus[campaignId] <- WAS_SEEN_UNLOCKED

  curStatus.__update(
    lockedProgressCampaigns.value.map(@(_) WAS_SEEN_PROGRESS_LOCKED)
    lockedCampaigns.value.map(@(_) WAS_SEEN_LOCKED)
  )

  return curStatus
})

let unseenCampaigns = Computed(function() {
  let res = {}

  if (!onlineSettingUpdated.value)
    return res

  let savedStatus = seen.value ?? {}

  foreach (campaignId, status in currentStatus.value)
    if ((savedStatus?[campaignId] ?? UNSEEN) != status)
      res[campaignId] <- true

  if (curCampaign.value in res)
    delete res[curCampaign.value]
  return res
})

let function markSeenCampaign(campaignId) {
  let status = currentStatus.value?[campaignId] ?? UNSEEN

  if ((seen.value?[campaignId] ?? UNSEEN) == status)
    return

  settings.mutate(function(set) {
    set[SEEN_ID] <- (set?[SEEN_ID] ?? {}).__merge({ [campaignId] = status })
  })
}

local prevCampaign = curCampaignStored.value
curCampaignStored.subscribe(function(camp) {
  if (unlockedCampaigns.value.contains(prevCampaign))
    markSeenCampaign(prevCampaign)
  if (unlockedCampaigns.value.contains(camp))
    markSeenCampaign(camp)
  prevCampaign = camp
})

console_register_command(function() {
  settings.mutate(function(s) {
    if (SEEN_ID in s)
      delete s[SEEN_ID]
  })
}, "meta.resetSeenCampaign")

return {
  unseenCampaigns
  markSeenCampaign
}
