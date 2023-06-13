from "%enlSqGlob/ui_library.nut" import *

let { logerr } = require("dagor.debug")
let msgbox = require("%enlist/components/msgbox.nut")
let { addPopup, removePopup } = require("%enlSqGlob/ui/popup/popupsState.nut")
let { nestWatched } = require("%dngscripts/globalState.nut")

let isMailboxVisible  = nestWatched("isMailboxVisible", false)
let inbox = nestWatched("inbox", [])
let unreadNum = Computed(@() inbox.value.reduce(@(res, notify) notify.isRead ? res : res + 1, 0))
let counter = persist("counter", @() { last = 0 })
let hasUnread = Computed(@() unreadNum.value > 0)

let getPopupId = @(notify) $"mailbox_{notify.id}"

enum InvitationsStyle {
  PRIMARY = "primary"
  TO_BATTLE = "toBattle"
}

enum InvitationsTypes {
  TO_FRIEND = "friendInvitation"
  TO_SQUAD = "squadInvitation"
  SQUAD_REMOVE = "squadRemove"
  FRIEND_REMOVE = "friendRemove"
}

let subscriptions = {}
let function subscribeGroup(actionsGroup, actions) {
  if (actionsGroup in subscriptions || actionsGroup == "") {
    logerr($"Mailbox already has subscriptions on actionsGroup {actionsGroup}")
    return
  }
  subscriptions[actionsGroup] <- actions
}

let function removeNotifyById(id) {
  let idx = inbox.value.findindex(@(n) n.id == id)
  if (idx != null) {
    removePopup(getPopupId(inbox.value[idx]))
    inbox.mutate(@(value) value.remove(idx))
  }
}

let function removeNotify(notify) {
  removePopup(getPopupId(notify))
  let idx = inbox.value.indexof(notify)
  if (idx != null)
    inbox.mutate(@(value) value.remove(idx))
}

let function onNotifyShow(notify) {
  if (!inbox.value.contains(notify))
    return
  let onShow = subscriptions?[notify.actionsGroup].onShow ?? removeNotify
  onShow(notify)
}

let function onNotifyRemove(notify) {
  if (!inbox.value.contains(notify))
    return

  let onRemove = subscriptions?[notify.actionsGroup].onRemove
  onRemove?(notify)
  removeNotify(notify)
}

let function clearAll() {
  let list = clone inbox.value
  foreach (notify in list) {
    let onRemove = subscriptions?[notify.actionsGroup].onRemove
    onRemove?(notify)
  }
  inbox(inbox.value.filter(@(n) !list.contains(n)))
}

let showPopup = @(notify)
  addPopup({ id = getPopupId(notify), text = notify.text, onClick = @() onNotifyShow(notify) })

let NOTIFICATION_PARAMS = {
  id = null //string
  text = ""
  actionsGroup = ""
  isRead = false
  needPopup = false
  styleId = ""
}
local function pushNotification(notify = NOTIFICATION_PARAMS) {
  notify = NOTIFICATION_PARAMS.__merge(notify)

  if (notify.id != null)
    removeNotifyById(notify.id)
  else
    notify.id = "_{0}".subst(counter.last++)

  inbox.mutate(@(v) v.append(notify))
  if (notify.needPopup)
    showPopup(notify)
}

let function markReadAll() {
  if (hasUnread.value)
    inbox.mutate(@(v) v.each(@(notify) notify.isRead = true))
}

console_register_command(
  function(text){
    counter.last++
    pushNotification({
      id = "m_{0}".subst(counter.last)
      text = text,
      onShow = @(...) msgbox.show({text=text, buttons = [ {text = loc("Yes"), action = @() removeNotifyById("m_{0}".subst(counter.last)) }]}),
    })
  },
  "mailbox.push"
)

return {
  inbox
  hasUnread
  unreadNum
  pushNotification
  removeNotifyById
  removeNotify
  markReadAll
  clearAll
  isMailboxVisible

  subscribeGroup
  onNotifyRemove
  onNotifyShow
  InvitationsStyle
  InvitationsTypes
}
