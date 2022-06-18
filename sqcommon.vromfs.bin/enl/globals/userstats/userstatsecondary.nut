from "%enlSqGlob/ui_library.nut" import *

let sharedWatched = require("%dngscripts/sharedWatched.nut")
let eventbus = require("eventbus")
let time = require("serverTime.nut")

let descList = sharedWatched("userstat.GetUserStatDescList",@() {})
let stats = sharedWatched("userstat.GetStats",@() {})
let unlocks = sharedWatched("userstat.GetUnlocks",@() {})

let cmdList = {}
foreach (name in ["setLastSeenCmd", "refreshStats", "forceRefreshUnlocks"]) {
  let cmd = name
  cmdList[cmd] <- @(p = null) eventbus.send("userstat.cmd", {cmd, p})
}

let notImplemented = @(...) assert(0, "Not implemeneted in UI VM")
return {
  isSecondaryUserstat = true

  userstatDescList = descList
  userstatStats = stats
  userstatUnlocks = unlocks
  userstatTime = time
  userstatExecutors = {}

  //not implemented in UI VM:
  getUserstatsSum = @(_tableName, _statName) 0

  receiveUnlockRewards = notImplemented
  rerollUnlock         = notImplemented
  selectUnlockRewards  = notImplemented
  setLastSeenUnlocksCmd = cmdList.setLastSeenCmd
  refreshUserstats = cmdList.refreshStats
  buyUnlock = notImplemented
  setLastSeenUnlocks = cmdList.setLastSeenCmd
}.__update(cmdList)