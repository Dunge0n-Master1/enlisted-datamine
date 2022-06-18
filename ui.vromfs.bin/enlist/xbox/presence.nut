from "%enlSqGlob/ui_library.nut" import *

let xp = require("%xboxLib/impl/presence.nut")
let app = require("%xboxLib/impl/app.nut")
let logX = require("%sqstd/log.nut")().with_prefix("[XBOX PRESENCE] ")
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
  xp.set_presence(presence, function(success) {
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
      if (actDev.type == xp.DeviceType.XboxOne || actDev.type == xp.DeviceType.Scarlett) {
        if ("activeTitles" not in actDev) {
          updPresences[console2uid.value[xuid]].online = true
          break
        }

        foreach (actTitle in actDev.activeTitles)
          if (actTitle.titleId == app.get_title_id()) {
            updPresences[console2uid.value[xuid]].online = true
            break
          }
      }
    }
  }

  logX("Update presences:", updPresences)
  updatePresences(updPresences)
}

let update_presences_for_users = @(xuids) xp.retrieve_presences_for_users(xuids, on_presences_update)

let function on_device_change_event(xuid, dev_type, logged_in) {
  logX($"on_device_change_event: {xuid}, {dev_type}, {logged_in}")
  update_presences_for_users([xuid])
}


let function on_title_change_event(xuid, title_id, title_state) {
  logX($"on_title_change_event: {xuid}, {title_id}, {title_state}")
  update_presences_for_users([xuid])
}


xp.subscribe_to_device_change_events(on_device_change_event)
xp.subscribe_to_title_change_events(on_title_change_event)


return {
  update_presences_for_users
}
