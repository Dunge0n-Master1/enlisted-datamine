let {friendsXuids, mutedXuids, bannedXuids} = require("%xboxLib/relationships.nut")
let {xboxApprovedUids, xboxBlockedUids, xboxMutedUids, friendsUids} = require("%enlist/contacts/contactsWatchLists.nut")
let {console2uid} = require("%enlist/contacts/consoleUidsRemap.nut")
let userIds = require("%xboxLib/userIds.nut")


let function get_uids(xuids) {
  local result = {}
  foreach (xuid in xuids) {
    let strxuid = xuid.tostring()
    if (strxuid in console2uid.value) {
      result[console2uid.value[strxuid]] <- true
    }
  }
  return result
}


friendsXuids.subscribe(function(v) {
  let uids = get_uids(v)
  xboxApprovedUids.update(uids)
})


mutedXuids.subscribe(function(v) {
  let uids = get_uids(v)
  xboxMutedUids.update(uids)
})


bannedXuids.subscribe(function(v) {
  let uids = get_uids(v)
  xboxBlockedUids.update(uids)
})


friendsUids.subscribe(function(v) {
  userIds.friendsUids.update(v)
})