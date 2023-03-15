from "%enlSqGlob/ui_library.nut" import *

let msgbox = require("%enlist/components/msgbox.nut")
let { unlocksSorted, unlockProgress, emptyProgress
} = require("%enlSqGlob/userstats/unlocksState.nut")
let { userstatStats } = require("%enlSqGlob/userstats/userstat.nut")
let { curCampaign } = require("%enlist/meta/curCampaign.nut")
let { isPlatformRelevant } = require("%dngscripts/platform.nut")

let debugOverrideTime = mkWatched(persist, "debugOverrideTime", null)

let getNextUnlock = @(unlockName, unlocks)
  unlocks.findvalue(@(u) (u?.requirement ?? "") == unlockName)

let unlocksData = Computed(function() {
  let events = {}
  let forcedUrl = []

  foreach (unlock in unlocksSorted.value) {
    local {
      force_open_url = "", promote_squads = null, promote_campaign = null, platforms = null,
      event_unlock = false, event_group = null
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
      forcedUrl.append({
        url = force_open_url
        image = unlock?.meta.image
        title = title != "" ? title : loc("eventWidget/specialOffer")
      })
      continue
    }

    if (event_unlock && event_group == null)
      event_group = "events" // backward compatibility with single 'events' unlock
    if (event_group == null)
      continue

    local event = events?[event_group]
    if (event == null) {
      let stat = userstatStats.value?.stats[event_group]
      event = {
        group = event_group
        start = debugOverrideTime.value?.start ?? stat?["$startedAt"] ?? 0
        end = debugOverrideTime.value?.end ?? stat?["$endsAt"] ?? 0
        unlocks = []
        squads = []
      }
      events[event_group] <- event
    }
    if (promote_squads != null)
      event.squads.extend(typeof promote_squads == "array"
        ? promote_squads
        : [promote_squads])
    else
      event.unlocks.append(unlock)
  }

  let progress = unlockProgress.value
  foreach (event in events) {
    let { unlocks } = event
    let startUnlocks = unlocks.filter(@(u) (u?.requirement ?? "") == "")
      .sort(@(a,b) a?.meta.taskListPlace == null ? 1
        : b?.meta.taskListPlace == null ? -1
        : a.meta.taskListPlace <=> b.meta.taskListPlace)
    let targetUnlocks = []
    foreach (unlock in startUnlocks) {
      local step = 1
      targetUnlocks.append(unlock.__merge({ step }, progress?[unlock.name] ?? emptyProgress))
      local nextUnlock = getNextUnlock(unlock.name, unlocks)
      while (nextUnlock != null) {
        step++
        targetUnlocks.append(nextUnlock.__merge({ step }, progress?[nextUnlock.name] ?? emptyProgress))
        nextUnlock = getNextUnlock(nextUnlock.name, unlocks)
      }
    }
    local totalSteps = 1
    for (local i = targetUnlocks.len() - 1; i >= 0; i--) {
      let { step } = targetUnlocks[i]
      totalSteps = max(totalSteps, step)
      targetUnlocks[i].totalSteps <- totalSteps
      if (step == 1)
        totalSteps = 1
    }
    event.unlocks <- targetUnlocks
  }

  return {
    events
    forcedUrl
  }
})

let showNotActiveTaskMsgbox = @()
  msgbox.show({ text = loc("unlocks/eventUnlockNotActiveYet") })

console_register_command(@() debugOverrideTime(null), "meta.eventPromoTimeReset")
console_register_command(@(start, end) debugOverrideTime({ start, end }), "meta.eventPromoSetTime")

return {
  eventForcedUrl = Computed(@() unlocksData.value.forcedUrl)
  specialEvents = Computed(@() unlocksData.value.events)
  showNotActiveTaskMsgbox
}
