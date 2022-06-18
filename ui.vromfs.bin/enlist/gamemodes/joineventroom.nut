from "%enlSqGlob/ui_library.nut" import *
let { OK, error_string } = require("matching.errors")
let { showMsgbox } = require("%enlist/components/msgbox.nut")
let { joinRoom } = require("%enlist/state/roomState.nut")
let { squadId } = require("%enlist/squad/squadState.nut")
let { selRoom } = require("eventRoomsListState.nut")
let getMissionInfo = require("getMissionInfo.nut")
let { unlockedCampaigns } = require("%enlist/meta/campaigns.nut")


let function joinCb(response) {
  let err = response.error
  if (err != OK) {
    let errStr = error_string(err)
    showMsgbox({ text = loc("msgbox/failedJoinRoom", {
      error = loc($"error/{errStr}", errStr)
    }) })
  }
}

let function getLockedCampaign(room) {
  let { campaigns = [], scenes = [] } = room
  return campaigns.findvalue(@(c) !unlockedCampaigns.value.contains(c))
    ?? scenes.findvalue(@(s) !unlockedCampaigns.value.contains(getMissionInfo(s).campaign))
}

let function joinSelEventRoom() {
  let room = selRoom.value
  if (room == null)
    return
  let campaign = getLockedCampaign(room)
  if (campaign != null)
    return showMsgbox({ text = loc("msg/cantJoinHasLockedCampaign", { campaign = loc($"{campaign}/full") }) })

  let params = { roomId = room.roomId.tointeger() }
  if (squadId.value != null)
    params.member <- { public = { squadId = squadId.value } }
  joinRoom(params, true, joinCb)
}

return {
  joinSelEventRoom
}