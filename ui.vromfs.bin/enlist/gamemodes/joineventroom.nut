from "%enlSqGlob/ui_library.nut" import *
let { OK, error_string } = require("matching.errors")
let { removeMsgboxByUid, showWithCloseButton, showMsgbox
} = require("%enlist/components/msgbox.nut")
let { joinRoom } = require("%enlist/state/roomState.nut")
let { squadId } = require("%enlist/squad/squadState.nut")
let { selRoom } = require("eventRoomsListState.nut")
let getMissionInfo = require("getMissionInfo.nut")
let { unlockedCampaigns } = require("%enlist/meta/campaigns.nut")
let textInput = require("%ui/components/textInput.nut")
let userInfo = require("%enlSqGlob/userInfo.nut")
let { bigPadding } = require("%enlSqGlob/ui/viewConst.nut")

local roomParams = Watched({})
let passwordMsgBoxUid = "room-password"

let function joinCb(response) {
  let err = response.error
  if (err != OK) {
    let errStr = error_string(err)
    if (errStr == "SERVER_ERROR_ROOM_PASSWORD_MISMATCH")
      roomParams.mutate(@(v) v["isRetry"] <- true)
    else
      showMsgbox({
        text = loc("msgbox/failedJoinRoom", { error = loc($"error/{errStr}", errStr) })
      })
  }
  else {
    roomParams({})
    removeMsgboxByUid(passwordMsgBoxUid)
  }
}

let function getLockedCampaign(room) {
  let { campaigns = [], scenes = [] } = room
  return campaigns.findvalue(@(c) !unlockedCampaigns.value.contains(c))
    ?? scenes.findvalue(@(s) !unlockedCampaigns.value.contains(getMissionInfo(s).campaign))
}

let passwordHint = {
  size = [flex(), SIZE_TO_CONTENT]
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  text = loc("options/password/hint")
  halign = ALIGN_CENTER
}

let function showPasswordMsgbox(params){
  let roomPassword = Watched("")
  let function tryToJoinRoom(){
    params["password"] <- roomPassword.value
    joinRoom(params, true, joinCb)
  }
  let passwordInput = {
    size = [sw(20), SIZE_TO_CONTENT]
    children = textInput(roomPassword, {
      placeholder = loc("enter_pass")
      maxChars = 16
      password = true
      onReturn = tryToJoinRoom
      onAttach = @(elem) set_kb_focus(elem)
      onEscape = function(){
        set_kb_focus(null)
        removeMsgboxByUid(passwordMsgBoxUid)
      }
    })
  }

  showWithCloseButton({
    uid = passwordMsgBoxUid
    size = [flex(), SIZE_TO_CONTENT]
    text = params?.isRetry ?? false ? loc("lobby/invalidPass") : loc("lobby/enterPass")
    children = {
      flow = FLOW_VERTICAL
      gap = bigPadding
      children = [
        passwordInput
        passwordHint
      ]
    }
    buttons = [
      {
        text = loc("Proceed")
        action = tryToJoinRoom
        customStyle = {
          hotkeys = [[ "^J:Y", { description = { skip = true } } ]]
        }
      }
      {
        text = loc("Cancel")
      }
    ]
  })
}

roomParams.subscribe(@(v) v.len() > 0 ? showPasswordMsgbox(v): null)

let function joinSelEventRoom() {
  let room = selRoom.value
  if (room == null)
    return
  roomParams({})
  let campaign = getLockedCampaign(room)
  if (campaign != null)
    return showMsgbox({ text = loc("msg/cantJoinHasLockedCampaign",
      { campaign = loc($"{campaign}/full") }) })

  let params = { roomId = room.roomId.tointeger() }
  if (squadId.value != null)
    params.member <- { public = { squadId = squadId.value } }
  if (!(room?.hasPassword ?? false) || room?.creatorId == userInfo.value.userId) {
    joinRoom(params, true, joinCb)
  }

  else
    roomParams(params)
}

return {
  joinSelEventRoom
}