from "ui_library.nut" import *

let { is_xbox, is_sony } = require("%dngscripts/platform.nut")
let {INVALID_USER_ID} = require("matching.errors")
let { consoleCompare } = require("platformUtils.nut")
let userInfo = require("%enlSqGlob/userInfo.nut")

let eventBusSend = require("eventbus").send

local showUserInfo = @(userId) log($"[USER INFO] Try to open {userId} profile on wrong platform")
local canShowUserInfo = @(...) false

if (is_xbox) {
  showUserInfo = @(userId) eventBusSend("showXboxUserInfo", {userId})
  canShowUserInfo = @(userId, name) (userId ?? INVALID_USER_ID) != INVALID_USER_ID
    && userInfo.value?.userId != userId
    && consoleCompare.xbox.isFromPlatform(name)
}
else if (is_sony) {
  showUserInfo = @(userId) eventBusSend("showPsnUserInfo", {userId})
  canShowUserInfo = @(userId, name) (userId ?? INVALID_USER_ID) != INVALID_USER_ID
    && userInfo.value?.userId != userId
    && consoleCompare.psn.isFromPlatform(name)
}

return {
  showUserInfo
  canShowUserInfo
}