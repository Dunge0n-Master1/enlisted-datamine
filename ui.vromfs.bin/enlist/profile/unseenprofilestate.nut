from "%enlSqGlob/ui_library.nut" import *

let { decorators, medals, wallposters } = require("%enlist/meta/profile.nut")
let { settings, onlineSettingUpdated } = require("%enlist/options/onlineSettings.nut")
let { decoratorsCfgByType } = require("decoratorState.nut")


const DECORATORS_SEEN_ID = "seen/decorators"
const MEDALS_SEEN_ID = "seen/medals"
const WALLPOSTERS_SEEN_ID = "seen/wallposters"

let seenDecorators = Computed(@() settings.value?[DECORATORS_SEEN_ID])
let seenMedals = Computed(@() settings.value?[MEDALS_SEEN_ID])
let seenWallposters = Computed(@() settings.value?[WALLPOSTERS_SEEN_ID])

let unseenDecorators = Computed(function() {
  if (!onlineSettingUpdated.value)
    return {}

  let seen = seenDecorators.value ?? {}
  return decorators.value.filter(@(d) d.guid not in seen)
})

let hasUnseenPortraits = Computed(function() {
  let cfg = decoratorsCfgByType.value?.portrait ?? {}
  return (unseenDecorators.value ?? {}).filter(@(d) d.guid in cfg).len() > 0
})

let hasUnseenNickFrames = Computed(function() {
  let cfg = decoratorsCfgByType.value?.nickFrame ?? {}
  return (unseenDecorators.value ?? {}).filter(@(d) d.guid in cfg).len() > 0
})

let hasUnseenDecorators = Computed(@()
  (unseenDecorators.value ?? {}).len() > 0)

let unseenMedals = Computed(function() {
  if (!onlineSettingUpdated.value)
    return {}

  let seen = seenMedals.value ?? {}
  return medals.value.filter(@(d) d.id not in seen)
})

let hasUnseenMedals = Computed(@()
  (unseenMedals.value ?? {}).len() > 0)

let unseenWallposters = Computed(function() {
  if (!onlineSettingUpdated.value)
    return {}

  let seen = seenWallposters.value ?? {}
  return wallposters.value.filter(@(w) w.tpl not in seen)
})

let hasUnseenWallposters = Computed(@()
  (unseenWallposters.value ?? {}).len() > 0)

let function markSeenDecorator(guid) {
  if (!(seenDecorators.value?[guid] ?? false))
    settings.mutate(function(set) {
      set[DECORATORS_SEEN_ID] <- (set?[DECORATORS_SEEN_ID] ?? {}).__merge({ [guid] = true })
    })
}

let function markSeenMedal(id) {
  if (!(seenMedals.value?[id] ?? false))
    settings.mutate(function(set) {
      set[MEDALS_SEEN_ID] <- (set?[MEDALS_SEEN_ID] ?? {}).__merge({ [id] = true })
    })
}

let function markSeenWallposter(id) {
  if (!(seenWallposters.value?[id] ?? false))
    settings.mutate(function(set) {
      set[WALLPOSTERS_SEEN_ID] <- (set?[WALLPOSTERS_SEEN_ID] ?? {}).__merge({ [id] = true })
    })
}

console_register_command(@() settings.mutate(@(v) delete v[DECORATORS_SEEN_ID]), "meta.resetSeenDecorators")
console_register_command(@() settings.mutate(@(v) delete v[MEDALS_SEEN_ID]), "meta.resetSeenMedals")
console_register_command(@() settings.mutate(@(v) delete v[WALLPOSTERS_SEEN_ID]), "meta.resetSeenWallposters")

return {
  unseenDecorators
  hasUnseenDecorators
  hasUnseenPortraits
  hasUnseenNickFrames
  markSeenDecorator

  unseenMedals
  hasUnseenMedals
  markSeenMedal

  unseenWallposters
  markSeenWallposter
  hasUnseenWallposters
}
