from "%enlSqGlob/ui_library.nut" import *

let {subscribe_to_presence_update_events, set_presence, DeviceType} = require("%xboxLib/impl/presence.nut")
let {get_title_id} = require("%xboxLib/impl/app.nut")
let logX = require("%enlSqGlob/library_logs.nut").with_prefix("[XBOX PRESENCE] ")
let { isInBattleState } = require("%enlSqGlob/inBattleState.nut")
let { updatePresences } = require("%enlist/contacts/contactPresence.nut")
let { console2uid } = require("%enlist/contacts/consoleUidsRemap.nut")


let presenceStatuses = {
  ONLINE = "online"
  IN_GAME = "in_game"
}


let presenceStatus = Computed(function () {
    if (isInBattleState.value)
      return presenceStatuses.IN_GAME
    return presenceStatuses.ONLINE
  }
)


presenceStatus.subscribe(function(presence) {
  logX($"Set user presence: {presence}")
  set_presence(presence, function(success) {
    logX($"Set user presence succeeded: {success}")
  })
})


let function on_presences_update(success, presences) {
  if (!success) {
    logX("Failed to update presences for users")
    return
  }

  let updPresences = {}
  foreach (data in presences) {
    let xuid = data.xuid.tostring()
    if (xuid not in console2uid.value)
      continue

    updPresences[console2uid.value[xuid]] <- { online = false }

    if (!data?.activeDevices.len())
      continue

    foreach (actDev in data.activeDevices) {
      if (actDev.type == DeviceType.XboxOne || actDev.type == DeviceType.Scarlett) {
        if ("activeTitles" not in actDev) {
          updPresences[console2uid.value[xuid]].online = true
          break
        }

        foreach (actTitle in actDev.activeTitles)
          if (actTitle.titleId == get_title_id()) {
            updPresences[console2uid.value[xuid]].online = true
            break
          }
      }
    }
  }

  logX("Update presences:", updPresences)
  updatePresences(updPresences)
}


subscribe_to_presence_update_events(on_presences_update)