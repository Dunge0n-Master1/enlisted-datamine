from "%enlSqGlob/ui_library.nut" import *

let msgbox = require("%enlist/components/msgbox.nut")
let { unlocksSorted, unlockProgress, emptyProgress
} = require("%enlSqGlob/userstats/unlocksState.nut")
let { userstatStats } = require("%enlSqGlob/userstats/userstat.nut")
let { curCampaign } = require("%enlist/meta/curCampaign.nut")
let { isPlatformRelevant } = require("%dngscripts/platform.nut")

let debugOverrideTime = mkWatched(persist, "debugOverrideTime", null)

let unlockOfferTime = Computed(function() {
  let tbl = userstatStats.value?.stats.events
  return {
    start = debugOverrideTime.value?.start ?? tbl?["$startedAt"] ?? 0
    end = debugOverrideTime.value?.end ?? tbl?["$endsAt"] ?? 0
  }
})

console_register_command(@() debugOverrideTime(null), "meta.eventPromoTimeReset")
console_register_command(@(start, end) debugOverrideTime({ start, end }), "meta.eventPromoSetTime")
console_register_command(@() console_print("interval:", unlockOfferTime.value), "meta.eventPromoGetTime")

let getNextUnlock = @(unlockName, unlocks)
  unlocks.findvalue(@(u) (u?.requirement ?? "") == unlockName)

let unlocksMeta = Computed(function() {
  let res = {
    forcedUrl = []
    promoteSquads = []
  }

  foreach (unlock in unlocksSorted.value) {
    let {
      force_open_url = "", promote_squads = null, promote_campaign = null, platforms = null
    } = unlock?.meta

    if (platforms != null
        && !isPlatformRelevant(typeof platforms == "array" ? platforms : [platforms]))
      continue

    if (promote_campaign != null) {
      let promoCamp = typeof promote_campaign == "array" ? promote_campaign : [promote_campaign]
      if (promoCamp.len() != 0 && !promoCamp.contains(curCampaign.value))
        continue
    }

    if (force_open_url != "") {
      let title = unlock?.localization.name ?? ""
      res.forcedUrl.append({
        url = force_open_url
        image = unlock?.meta.image
        title = title != "" ? title : loc("eventWidget/specialOffer")
      })
    }

    if (promote_squads != null)
      res.promoteSquads.extend(typeof promote_squads == "array"
        ? promote_squads
        : [promote_squads])
  }
  return res
})

let eventForcedUrl = Computed(@() unlocksMeta.value.forcedUrl)

let squadsPromotion = Computed(@() unlocksMeta.value.promoteSquads)

let eventUnlocks = Computed(function() {
  let progresses = unlockProgress.value
  let unlocks = unlocksSorted.value.filter(@(u) u?.meta.event_unlock ?? false)
  let startUnlocks = unlocks.filter(@(u) (u?.requirement ?? "") == "")
    .sort(@(a,b) a?.meta.taskListPlace == null ? 1
      : b?.meta.taskListPlace == null ? -1
      : a.meta.taskListPlace <=> b.meta.taskListPlace)
  let res = []
  foreach (unlock in startUnlocks) {
    local step = 1
    res.append(unlock.__merge({ step }, progresses?[unlock.name] ?? emptyProgress))
    local nextUnlock = getNextUnlock(unlock.name, unlocks)
    while (nextUnlock != null) {
      step++
      res.append(nextUnlock.__merge({ step }, progresses?[nextUnlock.name] ?? emptyProgress))
      nextUnlock = getNextUnlock(nextUnlock.name, unlocks)
    }
  }

  local totalSteps = 1
  for (local i = res.len() - 1; i >= 0; i--) {
    let { step } = res[i]
    totalSteps = max(totalSteps, step)
    res[i].totalSteps <- totalSteps
    if (step == 1)
      totalSteps = 1
  }
  return res
})

let hasReward = Computed(@() eventUnlocks.value.findvalue(@(r) r.hasReward) != null)

let showNotActiveTaskMsgbox = @()
  msgbox.show({ text = loc("unlocks/eventUnlockNotActiveYet") })

return {
  eventForcedUrl
  squadsPromotion
  unlockOfferTime
  eventUnlocks
  hasReward
  showNotActiveTaskMsgbox
}
