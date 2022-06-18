from "%enlSqGlob/ui_library.nut" import *

let nswitchAccount = require("nswitch.account")
let contactsListWndBaseShow = require("contactsListWndCommon.nut")
let userInfo = require("%enlSqGlob/userInfo.nut")

let function inviteButton() {
  return {
      behavior = Behaviors.Button
      onClick = function() {
                  let payload = $"type:t='invitation'\ninviter_id:t='{userInfo.value.userIdStr}'"
                  nswitchAccount.inviteFriend(loc("contacts/inviteFriendMessage"), payload)
                }
      hotkeys = [["^J:Y", {description=loc("contacts/inviteFriend")}]]
  }
}

return @(p) contactsListWndBaseShow(p.__merge({
  additionalChild = inviteButton
}))