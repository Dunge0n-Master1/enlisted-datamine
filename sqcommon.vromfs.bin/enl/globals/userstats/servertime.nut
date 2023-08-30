from "%enlSqGlob/ui_library.nut" import *
let { nestWatched } = require("%dngscripts/globalState.nut")

let serverTime = nestWatched("userstat.time", 0)

console_register_command(@() console_print($"serverTime: {serverTime.value}"), "stat.time")

return serverTime