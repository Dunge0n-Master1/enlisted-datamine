from "%enlSqGlob/ui_library.nut" import *

let userInfo = require("%enlSqGlob/userInfo.nut")
let { setStatsModes, refreshUserstats, setUnlocksFilter } = require("%enlSqGlob/userstats/userstat.nut")
let { lbClient, lbHandlers } = require("%enlist/leaderboard/lbStateBase.nut")
let { nestWatched } = require("%dngscripts/globalState.nut")
let { allAvailableArmies } = require("%enlist/soldiers/model/state.nut")


setUnlocksFilter({
  withUserLogs = true
})

let mainStatsModes = Computed(function() {
  let modes = []
  foreach (campaign in allAvailableArmies.value)
    foreach (armyId in campaign)
      modes.append(armyId)

  return modes.len() == 0 ? []
    : modes.append("main_game", "squads", "lone_fighter")
})

let lbStatsModes = nestWatched("lbStatsModes", [])

let allStatsModes = Computed(function() {
  let res = clone mainStatsModes.value
  if (res.len() == 0)
    return []

  foreach (m in lbStatsModes.value)
    if (!res.contains(m))
      res.append(m)

  return res
})

allStatsModes.subscribe(function(v) {
  if (v.len() == 0)
    return

  setStatsModes(v)
  refreshUserstats()
})

let function requestLbModes() {
  if (userInfo.value != null)
    lbClient.request("cmn_get_global_leaderboard_modes")
}
lbHandlers["cmn_get_global_leaderboard_modes"] <- function(result) {
  if (!result?.modes && !result?.modesEmpty){
    log("cmn_get_global_leaderboard_modes: no modes", result)
    gui_scene.resetTimeout(300, requestLbModes)
    return
  }
  let modes = [].extend(result?.modes ?? [], result?.modesEmpty ?? [])
  if (modes.len() == 0)
    log("cmn_get_global_leaderboard_modes: empty modes in the result")
  else
    lbStatsModes(modes)
}

userInfo.subscribe(@(_) requestLbModes())
if (lbStatsModes.value.len() == 0)
  requestLbModes()

return {
  lbStatsModes
  mainStatsModes
  allStatsModes
}