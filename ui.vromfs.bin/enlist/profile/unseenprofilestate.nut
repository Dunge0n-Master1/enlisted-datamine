from "%enlSqGlob/ui_library.nut" import *

let { decorators, medals, wallposters } = require("%enlist/meta/profile.nut")
let { settings, onlineSettingUpdated } = require("%enlist/options/onlineSettings.nut")
let { decoratorsCfgByType } = require("decoratorState.nut")


enum SeenMarks {
  NOT_SEEN = 0
  OPENED = 1
  SEEN = 2
}

const DECORATORS_SEEN_ID = "seen/decorators1"
const MEDALS_SEEN_ID = "seen/medals1"
const WALLPOSTERS_SEEN_ID = "seen/wallposters1"

let compatibility = {
  ["seen/decorators"] = DECORATORS_SEEN_ID,
  ["seen/medals"] = MEDALS_SEEN_ID,
  ["seen/wallposters"] = WALLPOSTERS_SEEN_ID
}

let function applyCompatibility() {
  let settingsData = settings.value
  foreach (oldKey, newKey in compatibility) {
    if (oldKey not in settingsData)
      continue

    let seenData = settingsData[oldKey]
    let res = {}
    foreach (key, val in seenData) {
      let newVal = type(val) == "bool" ? SeenMarks.SEEN
        : type(val) == "integer" ? val
        : null
      if (newVal != null)
        res[key] <- newVal
    }
    settings.mutate(function(set) {
      set[newKey] <- res
      delete set[oldKey]
    })
  }
}

// compatibility from 10/08/2022
settings.subscribe(function(v) {
  foreach (oldKey, _newKey in compatibility)
    if (oldKey in v) {
      gui_scene.resetTimeout(0.1, applyCompatibility)
      break
    }
})

let getSeenStatus = @(val) val == null ? SeenMarks.NOT_SEEN : val

let seenDecorators = Computed(function() {
  if (!onlineSettingUpdated.value)
    return null

  let res = { opened = {}, seen = {} }
  foreach(key, seenData in settings.value?[DECORATORS_SEEN_ID] ?? {}) {
    if (getSeenStatus(seenData) != SeenMarks.NOT_SEEN)
      res.opened[key] <- true
    if (getSeenStatus(seenData) == SeenMarks.SEEN)
      res.seen[key] <- true
  }
  let allDecor = decorators.value
  let unopened = allDecor.filter(@(d) d.guid not in res.opened)
  let unseen = allDecor.filter(@(d) d.guid not in res.seen)
  return res.__update({ unopened, unseen })
})

let hasUnseenPortraits = Computed(function() {
  let cfg = decoratorsCfgByType.value?.portrait ?? {}
  return (seenDecorators.value?.unseen ?? {}).filter(@(d) d.guid in cfg).len() > 0
})

let hasUnseenNickFrames = Computed(function() {
  let cfg = decoratorsCfgByType.value?.nickFrame ?? {}
  return (seenDecorators.value?.unseen ?? {}).filter(@(d) d.guid in cfg).len() > 0
})

let unopenedPortraits = Computed(function() {
  let cfg = decoratorsCfgByType.value?.portrait ?? {}
  return (seenDecorators.value?.unopened ?? {}).filter(@(d) d.guid in cfg).keys()
})

let unopenedNickFrames = Computed(function() {
  let cfg = decoratorsCfgByType.value?.nickFrame ?? {}
  return (seenDecorators.value?.unopened ?? {}).filter(@(d) d.guid in cfg).keys()
})

let hasUnopenedDecorators = Computed(@()
  (seenDecorators.value?.unopened ?? {}).len() > 0)

let hasUnseenDecorators = Computed(@()
  (seenDecorators.value?.unseen ?? {}).len() > 0)


let seenMedals = Computed(function() {
  if (!onlineSettingUpdated.value)
    return null

  let res = { opened = {}, seen = {} }
  foreach(key, seenData in settings.value?[MEDALS_SEEN_ID] ?? {}) {
    if (getSeenStatus(seenData) != SeenMarks.NOT_SEEN)
      res.opened[key] <- true
    if (getSeenStatus(seenData) == SeenMarks.SEEN)
      res.seen[key] <- true
  }
  let allMedalIds = {}
  foreach (m in medals.value)
    allMedalIds[m.id] <- true

  let unopened = allMedalIds.filter(@(_v, id) id not in res.opened)
  let unseen = allMedalIds.filter(@(_v, id) id not in res.seen)
  return res.__update({ unopened, unseen })
})

let hasUnseenMedals = Computed(@()
  (seenMedals.value?.unseen ?? {}).len() > 0)

let hasUnopenedMedals = Computed(@()
  (seenMedals.value?.unopened ?? {}).len() > 0)


let seenWallposters = Computed(function() {
  if (!onlineSettingUpdated.value)
    return null

  let res = { opened = {}, seen = {} }
  foreach(key, seenData in settings.value?[WALLPOSTERS_SEEN_ID] ?? {}) {
    if (getSeenStatus(seenData) != SeenMarks.NOT_SEEN)
      res.opened[key] <- true
    if (getSeenStatus(seenData) == SeenMarks.SEEN)
      res.seen[key] <- true
  }

  let allWallposterTpls = {}
  foreach (w in wallposters.value)
    allWallposterTpls[w.tpl] <- true

  let unopened = allWallposterTpls.filter(@(_v, tpl) tpl not in res.opened)
  let unseen = allWallposterTpls.filter(@(_v, tpl) tpl not in res.seen)
  return res.__update({ unopened, unseen })
})

let hasUnseenWallposters = Computed(@()
  (seenWallposters.value?.unseen ?? {}).len() > 0)

let hasUnopenedWallposters = Computed(@()
  (seenWallposters.value?.unopened ?? {}).len() > 0)


let function markSeenDecorator(guid) {
  if (guid not in (seenDecorators.value?.seen ?? {}))
    settings.mutate(function(set) {
      set[DECORATORS_SEEN_ID] <- (set?[DECORATORS_SEEN_ID] ?? {})
        .__merge({ [guid] = SeenMarks.SEEN })
    })
}

let function markDecoratorsOpened(guids) {
  if (guids.len() > 0)
    settings.mutate(function(set) {
      let saved = clone (set?[DECORATORS_SEEN_ID] ?? {})
      foreach(guid in guids)
        saved[guid] <- SeenMarks.OPENED
      set[DECORATORS_SEEN_ID] <- saved
    })
}

let function markSeenMedal(id) {
  if (id not in (seenMedals.value?.seen ?? {}))
    settings.mutate(function(set) {
      set[MEDALS_SEEN_ID] <- (set?[MEDALS_SEEN_ID] ?? {})
        .__merge({ [id] = SeenMarks.SEEN })
    })
}

let function markMedalsOpened(ids) {
  if (ids.len() > 0)
    settings.mutate(function(set) {
      let saved = clone (set?[MEDALS_SEEN_ID] ?? {})
      foreach(id in ids)
        saved[id] <- SeenMarks.OPENED
      set[MEDALS_SEEN_ID] <- saved
    })
}

let function markSeenWallposter(id) {
  if (id not in (seenWallposters.value?.seen ?? {}))
    settings.mutate(function(set) {
      set[WALLPOSTERS_SEEN_ID] <- (set?[WALLPOSTERS_SEEN_ID] ?? {})
        .__merge({ [id] = SeenMarks.SEEN })
    })
}

let function markWallpostersOpened(ids) {
  if (ids.len() > 0)
    settings.mutate(function(set) {
      let saved = clone (set?[WALLPOSTERS_SEEN_ID] ?? {})
      foreach(id in ids)
        saved[id] <- SeenMarks.OPENED
      set[WALLPOSTERS_SEEN_ID] <- saved
    })
}

console_register_command(@() settings.mutate(@(v) delete v[DECORATORS_SEEN_ID]), "meta.resetSeenDecorators")
console_register_command(@() settings.mutate(@(v) delete v[MEDALS_SEEN_ID]), "meta.resetSeenMedals")
console_register_command(@() settings.mutate(@(v) delete v[WALLPOSTERS_SEEN_ID]), "meta.resetSeenWallposters")

return {
  seenDecorators
  unopenedPortraits
  unopenedNickFrames
  hasUnopenedDecorators
  hasUnseenDecorators
  hasUnseenPortraits
  hasUnseenNickFrames
  markSeenDecorator
  markDecoratorsOpened

  seenMedals
  hasUnopenedMedals
  hasUnseenMedals
  markSeenMedal
  markMedalsOpened

  seenWallposters
  markSeenWallposter
  markWallpostersOpened
  hasUnseenWallposters
  hasUnopenedWallposters
}
