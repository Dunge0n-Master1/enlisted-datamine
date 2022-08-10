from "%enlSqGlob/ui_library.nut" import *

let {
  settings, onlineSettingUpdated
} = require("%enlist/options/onlineSettings.nut")
let { soldiersByArmies } = require("%enlist/meta/profile.nut")
let { curArmy } = require("state.nut")

const SEEN_ID = "seen/soldiers"

let seen = Computed(@() settings.value?[SEEN_ID])

let unseen = Computed(@() onlineSettingUpdated.value
  ? soldiersByArmies.value.map(function(list, armyId) {
      let seenSoldiers = seen.value?[armyId] ?? {}
      return list.reduce(function(res, soldier) {
        let guid = soldier.guid
        if (!(guid in seenSoldiers))
          res[guid] <- true
        return res
      }, {})
    })
  : {})

let unseenCurrent = Computed(@() unseen.value?[curArmy.value] ?? {})

let function markSeen(armyId, soldierGuid) {
  if (!(seen.value?[armyId][soldierGuid] ?? false))
    settings.mutate(function(set) {
      let saved = clone (set?[SEEN_ID] ?? {})
      let armySaved = clone (saved?[armyId] ?? {})
      armySaved[soldierGuid] <- true
      saved[armyId] <- armySaved
      set[SEEN_ID] <- saved
    })
}

let function markUnseen(armyId, soldierGuid) {
  if (seen.value?[armyId][soldierGuid] ?? false)
    settings.mutate(function(set) {
      let saved = clone (set?[SEEN_ID] ?? {})
      let armySaved = clone (saved?[armyId] ?? {})
      delete armySaved[soldierGuid]
      saved[armyId] <- armySaved
      set[SEEN_ID] <- saved
    })
}

console_register_command(function() {
  settings.mutate(function(s) {
    if (SEEN_ID in s)
      delete s[SEEN_ID]
  })
}, "meta.resetSeenSoldiers")

return {
  unseenSoldiers = unseenCurrent
  markSoldierSeen = markSeen
  markSoldierUnseen = markUnseen
}
