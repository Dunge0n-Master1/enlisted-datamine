from "%enlSqGlob/ui_library.nut" import *

let { settings } = require("%enlist/options/onlineSettings.nut")

const SEEN_ID = "seen/gamemodes"

let seenGamemodes = Computed(@() settings.value?[SEEN_ID])

let function markSeenGamemode(gamemodeId) {
  settings.mutate(function(set) {
    let saved = clone (set?[SEEN_ID] ?? {})
    saved[gamemodeId] <- true
    set[SEEN_ID] <- saved
  })
}

console_register_command(@() settings.mutate(@(s) delete s[SEEN_ID]), "meta.resetSeenGamemodes")

return {
  seenGamemodes
  markSeenGamemode
}
