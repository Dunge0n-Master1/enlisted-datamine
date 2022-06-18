from "%enlSqGlob/ui_library.nut" import *

let { is_sony, is_xbox } = require("%dngscripts/platform.nut")

local uid2console = Watched(@() {})
local console2uid = Watched(@() {})

// inverse mapping to have fast lookup uid->uid
local updateUids = @(...) null

if (is_xbox) {
  let { xboxUids, xbox2uid, uid2xbox } = require("%enlist/xbox/contacts/xboxContactsState.nut")
  uid2console = uid2xbox
  console2uid = xbox2uid

  updateUids = @(xbox2UidNewList) xboxUids.mutate(function(list) {
    list.xbox2uid.__update(xbox2UidNewList)
    xbox2UidNewList.each(@(v, k) list.uid2xbox[v] <- k)
  })
}
else if (is_sony) {
  let { uid2psn, psn2uid, psnUids } = require("%enlist/ps4/state.nut")
  uid2console = uid2psn
  console2uid = psn2uid

  updateUids = @(psn2UidNewList) psnUids.mutate(function(list) {
    list.psn2uid.__update(psn2UidNewList)
    psn2UidNewList.each(@(v, k) list.uid2psn[v] <- k)
  })
}

return {
  uid2console
  console2uid
  updateUids
}