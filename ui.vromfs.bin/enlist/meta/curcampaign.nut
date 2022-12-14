from "%enlSqGlob/ui_library.nut" import *

let {mkOnlineSaveData} = require("%enlSqGlob/mkOnlineSaveData.nut")
let { squadLeaderState, isInSquad, isSquadLeader } = require("%enlist/squad/squadState.nut")
let { unlockedCampaigns, visibleCampaigns, lockedProgressCampaigns } = require("campaigns.nut")

let curCampaignStorage = mkOnlineSaveData("curCampaign")
let setCurCampaign = curCampaignStorage.setValue
let curCampaignStored = curCampaignStorage.watch
let roomCampaign = mkWatched(persist, "roomCampaign", null)
let campaignOverride = mkWatched(persist, "campaignOverride", []) //squad leader campaign still will be more important
let topCampaignOverride = Computed(@() campaignOverride.value?[campaignOverride.value.len() - 1].campaign)

let selectedCampaign = Computed(function() {
  let campaign = roomCampaign.value ?? topCampaignOverride.value ?? curCampaignStored.value
  let visibCampaigns = visibleCampaigns.value
  let availCampaigns = unlockedCampaigns.value
  return visibCampaigns.contains(campaign) && availCampaigns.contains(campaign) ? campaign : null
})

let curCampaign = Computed(@()
  (roomCampaign.value != null
      || isSquadLeader.value
      || !unlockedCampaigns.value.contains(squadLeaderState.value?.curCampaign)
    ? null
    : squadLeaderState.value?.curCampaign)
  ?? selectedCampaign.value
  ?? unlockedCampaigns.value?[0])

let function addCurCampaignOverride(id, campaign) {
  let cfg = campaignOverride.value.findvalue(@(c) c.id == id)
  if (cfg == null)
    campaignOverride.mutate(@(o) o.append({ id, campaign }))
  else if (campaign != cfg.campaign)
    campaignOverride.mutate(function(_) { cfg.campaign = campaign })
}

let function removeCurCampaignOverride(id) {
  let idx = campaignOverride.value.findindex(@(c) c.id == id)
  if (idx != null)
    campaignOverride.mutate(@(o) o.remove(idx))
}

return {
  curCampaignStored
  selectedCampaign
  setCurCampaign
  setRoomCampaign = @(campaign) roomCampaign(campaign)
  curCampaign
  canChangeCampaign = Computed(@() !isInSquad.value || isSquadLeader.value)
  isCurCampaignProgressUnlocked = Computed(@() curCampaign.value not in lockedProgressCampaigns.value)
  addCurCampaignOverride
  removeCurCampaignOverride
}
