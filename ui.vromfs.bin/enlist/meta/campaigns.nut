from "%enlSqGlob/ui_library.nut" import *

let { isPlatformRelevant } = require("%dngscripts/platform.nut")
let { configs } = require("%enlist/meta/configs.nut")
let { purchasesCount } = require("%enlist/meta/servProfile.nut")
let { maxVersionStr, maxVersionInt } = require("%enlSqGlob/client_version.nut")
let { check_version } = require("%sqstd/version_compare.nut")

let unlocks = Computed(function() {
  let { shop_items = {}, locked_campaigns = [], locked_progress_campaigns = [] } = configs.value
  let res = { open = {}, progress = {} }
  foreach (camp in locked_campaigns)
    res.open[camp] <- []
  foreach (camp in locked_progress_campaigns)
    res.progress[camp] <- []

  foreach (id, item in shop_items) {
    foreach (camp in item?.campaigns ?? [])
      if (camp in res.open)
        res.open[camp].append(id)
    foreach (camp in item?.campaignsProgress ?? [])
      if (camp in res.progress)
        res.progress[camp].append(id)
  }

  return res
})

let isUnlocked = @(campUnlocks, purchases)
  campUnlocks == null || campUnlocks.findindex(@(id) (purchases?[id].amount ?? 0) > 0) != null

let nullIfFitVersion = @(reqVersion, versionInt, versionStr) //FIXME: better to make new function to check version with int parameter
  reqVersion == "" || versionInt == 0 || check_version(reqVersion, versionStr)
    ? null
    : reqVersion

let hiddenCampaigns = Computed(@() (configs.value?.gameProfile.hideByPlatformCampaigns ?? {})
  .map(isPlatformRelevant)
  .filter(@(v) v))

let campaignsInfo = Computed(function() {
  let unlocked = []
  let locked = {}
  let lockedProgress = {}
  local { availableCampaigns = [], campaigns = {}, reqVersion = "" } = configs.value?.gameProfile
  availableCampaigns = availableCampaigns.filter(@(c) c not in hiddenCampaigns.value)
  reqVersion = nullIfFitVersion(reqVersion, maxVersionInt.value, maxVersionStr.value)
  let purchases = purchasesCount.value
  let { open, progress } = unlocks.value

  foreach (camp in availableCampaigns) {
    if (!isUnlocked(open?[camp], purchases))
      locked[camp] <- { reqPurchase = open[camp] }
    else {
      let reqVersionC = reqVersion
        ?? nullIfFitVersion(campaigns?[camp].reqVersion ?? "", maxVersionInt.value, maxVersionStr.value)
      if (reqVersionC == null)
        unlocked.append(camp)
      else
        locked[camp] <- { reqVersion = reqVersionC }
    }

    if (!isUnlocked(progress?[camp], purchases))
      lockedProgress[camp] <- progress[camp]
  }

  return { unlocked, locked, lockedProgress }
})

return {
  lockedCampaigns   = Computed(@() campaignsInfo.value.locked)
  unlockedCampaigns = Computed(@() campaignsInfo.value.unlocked)
  lockedProgressCampaigns = Computed(@() campaignsInfo.value.lockedProgress)
  visibleCampaigns = Computed(@() (configs.value?.gameProfile.visibleCampaigns ?? []))
}