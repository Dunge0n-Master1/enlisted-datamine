from "%enlSqGlob/ui_library.nut" import *

let {globalWatched} = require("%dngscripts/globalState.nut")
const US_DL = "userstat.GetUserStatDescList"
let userstatDescList = globalWatched(US_DL,@() {})[US_DL]
const US_GSK = "userstat.GetStats"
let userstatStats = globalWatched(US_GSK,@() {})[US_GSK]
const US_GU = "userstat.GetUnlocks"
let userstatUnlocks = globalWatched(US_GU,@() {})[US_GU]

return {
  userstatDescList
  userstatStats
  userstatUnlocks
}