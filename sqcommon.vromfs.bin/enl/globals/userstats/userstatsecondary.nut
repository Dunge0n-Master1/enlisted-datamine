from "%enlSqGlob/ui_library.nut" import *

let sharedWatched = require("%dngscripts/sharedWatched.nut")

let descList = sharedWatched("userstat.GetUserStatDescList",@() {})
let stats = sharedWatched("userstat.GetStats",@() {})
let unlocks = sharedWatched("userstat.GetUnlocks",@() {})

return {
  userstatDescList = descList
  userstatStats = stats
  userstatUnlocks = unlocks
}