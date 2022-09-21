from "%enlSqGlob/ui_library.nut" import *

let { is_sony, is_xbox } = require("%dngscripts/platform.nut")

local uid2console = Watched(@() {})
local console2uid = Watched(@() {})

// inverse mapping to have fast lookup uid->uid
local updateUids = @(...) null

if (is_xbox) {
  let { xboxUids, xboxUidsUpdate, xbox2uid, uid2xbox } = require("%enlist/xbox/contacts/xboxContactsState.nut")
  uid2console = uid2xbox
  console2uid = xbox2uid

  updateUids = function(xbox2UidNewList) {
    let res = clone xboxUids.value
    res.xbox2uid = res.xbox2uid.__merge(xbox2UidNewList)
    let newUid2xbox = {}
    foreach (k,v in xbox2UidNewList)
      newUid2xbox[v] <- k
    res.uid2xbox = res.uid2xbox.__merge(newUid2xbox)
    xboxUidsUpdate(res)
  }
}
else if (is_sony) {
  let { uid2psn, psn2uid, psnUids, psnUidsUpdate } = require("%enlist/ps4/psn_state.nut")
  uid2console = uid2psn
  console2uid = psn2uid

  updateUids = function(psn2UidNewList) {
    let res = clone psnUids.value
    res.psn2uid = res.psn2uid.__merge(psn2UidNewList)
    let newUid2psn = {}
    foreach (k,v in psn2UidNewList)
      newUid2psn[v] <- k
    res.uid2psn = res.uid2psn.__merge(newUid2psn)
    psnUidsUpdate(res)
  }
}

return {
  uid2console
  console2uid
  updateUids
}