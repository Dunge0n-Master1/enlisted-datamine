from "%enlSqGlob/ui_library.nut" import *

let { settings, onlineSettingUpdated } = require("%enlist/options/onlineSettings.nut")

const SEEN_ID = "seen/gamemodes"

enum SeenMarks {
  NOT_SEEN = 0
  OPENED = 1
  SEEN = 2
}

let getSeenStatus = @(val) val == true || val == SeenMarks.SEEN ? SeenMarks.SEEN
  : val == SeenMarks.OPENED ? SeenMarks.OPENED
  : SeenMarks.NOT_SEEN

let seenGamemodes = Computed(function() {
  if (!onlineSettingUpdated.value)
    return null

  let seen = {}
  let opened = {}
  foreach(key, seenData in settings.value?[SEEN_ID] ?? {}) {
    if (getSeenStatus(seenData) != SeenMarks.NOT_SEEN)
      opened[key] <- true
    if (getSeenStatus(seenData) == SeenMarks.SEEN)
      seen[key] <- true
  }
  return { seen, opened }
})

let function markSeenGamemode(gamemodeId) {
  if (getSeenStatus(settings.value?[SEEN_ID][gamemodeId]) != SeenMarks.SEEN)
    settings.mutate(function(set) {
      let saved = clone (set?[SEEN_ID] ?? {})
      saved[gamemodeId] <- SeenMarks.SEEN
      set[SEEN_ID] <- saved
    })
}

let function markOpenedGamemodes(gamemodeIds) {
  if (gamemodeIds.len() > 0)
    settings.mutate(function(set) {
      let saved = clone (set?[SEEN_ID] ?? {})
      foreach (gamemodeId in gamemodeIds)
        saved[gamemodeId] <- SeenMarks.OPENED
      set[SEEN_ID] <- saved
    })
}

console_register_command(@() settings.mutate(@(s) delete s[SEEN_ID]), "meta.resetSeenGamemodes")

return {
  seenGamemodes
  markSeenGamemode
  markOpenedGamemodes
}
