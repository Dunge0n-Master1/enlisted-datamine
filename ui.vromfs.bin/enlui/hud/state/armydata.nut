import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let eventbus = require("eventbus")
let { CmdSetMySquadsData, mkCmdDevSquadsData, mkCmdGetMySquadsData, mkCmdTutorialSquadsData, mkCmdProfileJwtData } = require("%enlSqGlob/sqevents.nut")
let { localPlayerTeamArmies } = require("%ui/hud/state/teams.nut")
let { localPlayerEid } = require("%ui/hud/state/local_player.nut")
let { isTutorial } = require("%ui/hud/tutorial/state/tutorial_state.nut")
let { customProfilePath } = require("%ui/hud/state/custom_profile.nut")
let { get_setting_by_blk_path } = require("settings")
let { has_network } = require("net")
let { client_request_unicast_net_sqevent } = require("ecs.netevent")
let { isReplay } = require("%ui/hud/state/replay_state.nut")
let logAd = require("%enlSqGlob/library_logs.nut").with_prefix("[ARMY_DATA] ")

let { app_is_offline_mode } = require("app")
let isSandbox = app_is_offline_mode()
let devArmiesData = isSandbox ? require_optional("%enlSqGlob/data/sandbox_profile.nut") ?? {}
                              : require_optional("%enlisted_pkg_dev/game/data/dev_profile_full.nut") ?? {}

let armiesData = mkWatched(persist, "armiesData")
let armyId = mkWatched(persist, "armyId", "")

eventbus.subscribe("updateArmiesData", function(data) {
  logAd("Received army data from profile server")
  armiesData(data)
})

let profilesMap = {
  real      = @(armies, playerEid) eventbus.send("requestArmiesData", { armies, playerEid })
  dev       = @(_armies, playerEid) ecs.client_send_event(playerEid, mkCmdDevSquadsData({jwt=""})) // Non empty event payload table as otherwise 'fromconnid' won't be added
  tutorial  = @(_armies, playerEid) ecs.client_send_event(playerEid, mkCmdTutorialSquadsData({jwt=""}))
  custom    = @(_armies, playerEid) ecs.client_send_event(playerEid, mkCmdProfileJwtData({jwt=""}))
}

let disableMenu = Computed(@() get_setting_by_blk_path("disableMenu") ?? false)
let profileType = Computed(@() customProfilePath.value ? "custom"
  : isTutorial.value ? "tutorial" : disableMenu.value ? "dev" : "real")
let requestArmiesData = Computed(@() profilesMap?[profileType.value])

let playerArmiesReceivedQuery = ecs.SqQuery("playerArmiesReceivedQuery",
  { comps_ro = [["isArmiesReceived", ecs.TYPE_BOOL]] })
let isArmiesReceived = @(playerEid) playerArmiesReceivedQuery(playerEid, @(_, comp) comp.isArmiesReceived) ?? false

let function requestMySquadsDataFromDedicated() {
  logAd("Request army data from dedicated")
  let playerEid = localPlayerEid.value
  if (has_network())
    client_request_unicast_net_sqevent(playerEid, mkCmdGetMySquadsData({ a = false })) // non empty payload to get "fromconnid"
  else
    ecs.g_entity_mgr.sendEvent(playerEid, mkCmdGetMySquadsData({}))
}

let function calcArmies(...) {
  let teamArmies = localPlayerTeamArmies.value
  let playerEid = localPlayerEid.value
  let requestCb = requestArmiesData.value

  logAd($"Try to calc armies teamArmies.len()={teamArmies.len()}; playerEid={playerEid}")
  if (teamArmies.len() == 0 || playerEid == ecs.INVALID_ENTITY_ID || requestCb == null)
    return

  if (isArmiesReceived(playerEid))
    requestMySquadsDataFromDedicated()
  else {
    logAd($"Request army data from profile server. Profile type = {profileType.value}")
    requestCb(teamArmies, playerEid)
  }
}
foreach (w in [localPlayerTeamArmies, localPlayerEid, requestArmiesData])
  w.subscribe(calcArmies)

let function onSetMySquadsData(evt, _eid, comp) {
  if (!comp.is_local)
    return
  logAd("Received army data from dedicated")
  armiesData(evt.data)
}

ecs.register_es("player_army_id_es",
  {
    [["onInit", "onChange"]] = @(_eid,comp) comp.is_local ? armyId(comp.army) : null,
    [CmdSetMySquadsData] = onSetMySquadsData
  },
  {
    comps_track = [["is_local", ecs.TYPE_BOOL], ["army", ecs.TYPE_STRING]]
    comps_rq = ["player"]
  })

console_register_command(requestMySquadsDataFromDedicated, "debug.updateArmyDataFromDedicated")

return Computed(@() isReplay.value ? {} : armiesData.value?[armyId.value] ?? devArmiesData?[armyId.value] ?? {})
