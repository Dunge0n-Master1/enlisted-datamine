from "%enlSqGlob/ui_library.nut" import *

let sharedWatched = require("%dngscripts/sharedWatched.nut")
let serverTime = sharedWatched("userstat.time", @() 0)

console_register_command(@() console_print($"serverTime: {serverTime.value}"), "stat.time")

return serverTime