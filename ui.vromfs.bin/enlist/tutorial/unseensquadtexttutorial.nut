from "%enlSqGlob/ui_library.nut" import *

let { settings, onlineSettingUpdated } = require("%enlist/options/onlineSettings.nut")
let { tutorials } = require("%enlist/tutorial/squadTextTutorialPresentation.nut")

const TUTORIALS_SQUAD_SEEN = "seen/squadTutorial"

let squadTutorialSeen = Computed(@() settings.value?[TUTORIALS_SQUAD_SEEN] ?? {})

let unseenSquadTutorials = Computed(function() {
  if (!onlineSettingUpdated.value)
    return {}

  let seen = squadTutorialSeen.value
  let res = {}
  foreach (squadId in tutorials.keys()){
    if (squadId not in seen)
      res[squadId] <- true
  }
  return res
})


let function markSeenSquadTutorial(guid) {
  if (!(squadTutorialSeen.value?[guid] ?? false))
    settings.mutate(function(set) {
      set[TUTORIALS_SQUAD_SEEN] <- (set?[TUTORIALS_SQUAD_SEEN] ?? {}).__merge({ [guid] = true })
    })
}

console_register_command(function() {
  settings.mutate(function(s) {
    if (TUTORIALS_SQUAD_SEEN in s)
      delete s[TUTORIALS_SQUAD_SEEN]
  })
}, "meta.resetSeenSquadTutorials")

return {
  unseenSquadTutorials
  markSeenSquadTutorial
}