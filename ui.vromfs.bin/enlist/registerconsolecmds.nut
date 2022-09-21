from "%enlSqGlob/ui_library.nut" import *

let { matchingCall } = require("matchingClient.nut")
let eventbus = require("eventbus")
let checkReconnect = require("checkReconnect.nut")
let {inspectorToggle} = require("%darg/helpers/inspector.nut")
let msgbox = require("components/msgbox.nut")
let matching_api = require("matching.api")


console_register_command(@(locId) console_print($"String:{locId} is localized as:{loc(locId)}"), "ui.loc")

console_register_command(function() { msgbox.show({ text = "Test messagebox" buttons = [{ text = "Yes" action=@()vlog("Yes")} { text = "No" action = @() vlog("no")} ]})}, "ui.test_msgbox2")
console_register_command(function() { msgbox.show({
   text = "Test messagebox" buttons = [{ text = "Yes" action=@()vlog("yes")} { text = "No", action=@()vlog("No")} { text = "Cancel" action=@()vlog("Cancel")}]})}, "ui.test_msgbox3")
console_register_command(function() { msgbox.show({ text = "Test messagebox"})}, "ui.test_msgbox")

console_register_command(function(key, value) {
    matchingCall("mpresence.set_presence", console_print, {[key] = value})
  },
  "mpresence.set_presence")

console_register_command(function() {
    matchingCall("mpresence.reload_contact_list", console_print)
  },
  "mpresence.reload_contact_list")

console_register_command(function() {
    matchingCall("mpresence.notify_friend_added", console_print)
  },
  "mpresence.notify_friend_added")

console_register_command(@(message, data) eventbus.send(message, data), "eventbus.send")

console_register_command(@() inspectorToggle(), "ui.inspector_enlist")

console_register_command(@() checkReconnect(), "app.check_reconnect")

console_register_command(@() matching_api.logout(), "matching.logout")
