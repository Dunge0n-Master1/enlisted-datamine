from "%enlSqGlob/ui_library.nut" import *

let { settings, onlineSettingUpdated } = require("%enlist/options/onlineSettings.nut")
let { eventGameModes } = require("eventModesState.nut")
let serverTime = require("%enlSqGlob/userstats/serverTime.nut")

const SEEN_ID = "seen/events"

let DAY = 24 * 3600
let SEEN_TIMEOUT = 14 * DAY

let seen = Computed(@() (settings.value?[SEEN_ID] ?? {}))

let curEventsQueueId = Computed(@() eventGameModes.value.map(@(v) v.queue.queueId))

let unseenEvents = Computed(function() {
  let res = []
  if (!onlineSettingUpdated.value)
    return res

  return curEventsQueueId.value.filter(@(id) id not in seen.value)
})

let function markSeenEvent(queueId) {
  if (!onlineSettingUpdated.value || queueId == null)
    return

  if (queueId in seen.value)
    return

  settings.mutate(function(set) {
    set[SEEN_ID] <- (set?[SEEN_ID] ?? {}).__merge({ [queueId] = serverTime.value })
  })
}

let function checkSavedEvents(events) {
  if (!onlineSettingUpdated.value)
    return

  settings.mutate(function(set) {
    let res = set?[SEEN_ID] ?? {}
    foreach (queueId, savedTime in seen.value) {
      let diffTime = serverTime.value - savedTime
      if (diffTime >= SEEN_TIMEOUT && !events.contains(queueId)) {
        if (queueId in res)
          res[queueId] <- serverTime.value
      }
    }
    set[SEEN_ID] <- res
  })
}

let function markAllSeenEvents () {
  if (!onlineSettingUpdated.value)
    return

  settings.mutate(function(set) {
    let res = set?[SEEN_ID] ?? {}
    foreach (queueId in curEventsQueueId.value) {
      if (queueId not in seen.value)
        res[queueId] <- serverTime.value
    }
    set[SEEN_ID] <- res
  })
}

checkSavedEvents(curEventsQueueId.value)
curEventsQueueId.subscribe(checkSavedEvents)

console_register_command(function() {
  settings.mutate(function(s) {
    if (SEEN_ID in s)
      delete s[SEEN_ID]
  })
}, "events.resetSeenEvents")

return {
  unseenEvents
  markSeenEvent
  markAllSeenEvents
}