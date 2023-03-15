import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/library_logs.nut" import *

let {CmdDevSquadsData, mkCmdSetMySquadsData,
  CmdTutorialSquadsData, CmdProfileJwtData, CmdGetMySquadsData} = require("%enlSqGlob/sqevents.nut")
let {TEAM_UNASSIGNED} = require("team")
let {logerr} = require("dagor.debug")
let { loadJson } = require("%sqstd/json.nut")
let {find_human_player_by_connid, find_local_player, get_team_eid} = require("%dngscripts/common_queries.nut")
let {INVALID_CONNECTION_ID, has_network, get_sync_time} = require("net")
let {CmdSpawnSquad, EventPlayerProfileChanged} = require("dasevents")
let debug = require("%enlSqGlob/library_logs.nut").with_prefix("[CLIENT PROFILE] ")
let { kick_player = @(...) null } = require_optional("dedicated")
let {INVALID_USER_ID} = require("matching.errors")
let {profilePublicKey} = require("%enlSqGlob/data/profile_pubkey.nut")
let {get_circuit, app_is_offline_mode} = require("app")
let {get_setting_by_blk_path} = require("settings")
let {get_can_use_respawnbase_type} = require("das.respawn")
let decode_jwt = require("jwt").decode
let profiles = require("%enlSqGlob/data/all_tutorial_profiles.nut")
let { applyModsToArmies, applyPerks } = require("%scripts/game/utils/profile_init.nut")


let function validateArmies(armies, playerArmy) {
  if (!armies) {
    debug("validateArmies: armies is absent")
    return false
  }

  if (armies.len() == 0) {
    debug("validateArmies: armies is empty")
    return false
  }

  if (playerArmy == null) {
    debug("validateArmies: not found army allowed for team")
    return false
  }

  let army = armies?[playerArmy] ?? {}
  if (army.len() == 0) {
    let availableArmies = ", ".join(armies.keys())
    debug($"validateArmies: army is absent in army {playerArmy}. Available armies: {availableArmies}")
    return false
  }

  let squads = army?.squads ?? []
  if (squads.len() == 0) {
    debug($"validateArmies: squads is absent in army {playerArmy}")
    return false
  }

  foreach (idx, squad in squads) {
    if (squad?.squad == null) {
      debug($"validateArmies: squad is absent in {idx}")
      return false
    }
  }

  return true
}

let function unpackArmiesFromJwt(_userid, jwt) {
  if (typeof jwt != "array")
    return null
  let token = "".join(jwt)
  let res   = decode_jwt(token, profilePublicKey)
  if ("error" in res) {
    let resError = res["error"]
    debug($"Could not decode profile jwt: {resError}. Fallback to default profile. Token:")
    debug(token)
  } else {
    return res?.payload.armies
  }
  return null
}

let function updateProfileImpl(evt, eid, comp, getArmiesCb) {
  let net = has_network()
  let senderEid = net ? find_human_player_by_connid(evt.data?.fromconnid ?? INVALID_CONNECTION_ID) : find_local_player()
  if (senderEid != eid)
    return
  if (comp.isArmiesReceived) {
    logerr("Try to apply player profile second time")
    return
  }

  let armies = getArmiesCb()
  let teamEid = comp.team != TEAM_UNASSIGNED ? get_team_eid(comp.team) : ecs.INVALID_ENTITY_ID
  let teamArmies = ecs.obsolete_dbg_get_comp_val(teamEid, "team__armies")?.getAll() ?? []
  let playerArmy = teamArmies.findvalue(@(a) a in armies)
  debug($"Received profile: team = {comp.team}; army = {playerArmy}; player = {eid};")

  if (!validateArmies(armies, playerArmy)) {
    logerr($"Corrupted profile or bad armies. See log for details.")
    debug($"userid = {comp.userid}; playerArmy = {playerArmy};")
    debug($"Team allowed armies = ")
    debugTableData(teamArmies)
    debug($"Profile = ")
    debugTableData(armies)
    kick_player(comp.userid, $"The profile is corrupted!")
    return
  }

  applyModsToArmies(armies)

  comp.allAvailablePerks <- applyPerks(armies)

  comp.army = playerArmy
  comp.armies = armies
  comp.isArmiesReceived = true

  let curTime = get_sync_time()

  debug($"Received squad data when player {eid} army is {playerArmy}")
  comp.armiesReceivedTime = curTime
  comp.armiesReceivedTeam = comp.team

  let army = comp.armies[playerArmy]
  let squadsCount = army.squads.len()
  comp.squads__count = squadsCount

  if (army?.isFakeSquads ?? false)
    debug($"Received fake armies for player {eid}. Experience will not be counted.")

  comp["squads__respawnTypeList"] = array(squadsCount, "")
  for (local i = 0; i < squadsCount; ++i) {
    let gametemplate = army?.squads?[i]?.curVehicle.gametemplate ?? army.squads[i]?[0].gametemplate
    let respType = get_can_use_respawnbase_type(gametemplate)?.canUseRespawnbaseType ?? "human"
    comp["squads__respawnTypeList"][i] = respType
  }

  let delayedSpawnSquad = comp.delayedSpawnSquad.getAll()
  comp.delayedSpawnSquad = []

  let wallPosters = army?.wallPosters ?? []
  local wallPostersCount = army?.wallPostersCount ?? 0
  if (wallPosters.len() == 0)
    wallPostersCount = 0

  comp["wallPosters__maxCount"] = wallPostersCount
  comp["wallPosters"] = array(wallPosters.len()).map(@(_, i) {
    template = wallPosters[i].template
  })

  comp["decorators__portrait"] = army?.decorators.portrait ?? ""
  comp["decorators__nickFrame"] = army?.decorators.nickFrame ?? ""

  ecs.set_callback_timer(function() {
      foreach (d in delayedSpawnSquad) {
        debug($"Send delayed CmdSpawnSquad for player {eid}")
        ecs.g_entity_mgr.sendEvent(eid, CmdSpawnSquad(d.__merge({respawnGroupId = -1})))
      }
    },
    0.1, false)

  ecs.g_entity_mgr.sendEvent(eid, EventPlayerProfileChanged())
}

let playerComps = {
  comps_rw = [
    ["team", ecs.TYPE_INT],
    ["armiesReceivedTime", ecs.TYPE_FLOAT],
    ["armiesReceivedTeam", ecs.TYPE_INT],
    ["delayedSpawnSquad", ecs.TYPE_ARRAY],
    ["armies", ecs.TYPE_OBJECT],
    ["squads__count", ecs.TYPE_INT],
    ["isArmiesReceived", ecs.TYPE_BOOL],
    ["army", ecs.TYPE_STRING],
    ["squads__respawnTypeList", ecs.TYPE_ARRAY],
    ["squads__firstSpawnDelayByType", ecs.TYPE_OBJECT],
    ["wallPosters__maxCount", ecs.TYPE_INT],
    ["wallPosters", ecs.TYPE_ARRAY],
    ["allAvailablePerks", ecs.TYPE_OBJECT],
    ["decorators__nickFrame", ecs.TYPE_STRING],
    ["decorators__portrait", ecs.TYPE_STRING],
  ]
  comps_ro = [
    ["userid", ecs.TYPE_UINT64],
    ["squads__respawnsToFullRestoreSquadBySquadsCount", ecs.TYPE_OBJECT]
  ]
}

ecs.register_es("client_profile_dev_es", {
  [CmdDevSquadsData] = function(evt, eid, comp) {
    // This is paranoid checks now.
    // dev_profile_full.nut has been removed from production dedicated vroms
    let isSandbox = app_is_offline_mode()
    let disableMenu = get_setting_by_blk_path("disableMenu") ?? false
    let disableNetwork = get_setting_by_blk_path("debug")?.disableNetwork ?? false
    let isDevProfileAllowed = isSandbox || disableMenu || disableNetwork || ["moon",""].indexof(get_circuit()) != null
    if (isDevProfileAllowed) {
      let devArmies = isSandbox ? require_optional("%enlSqGlob/data/sandbox_profile.nut")
                                : require_optional("%enlisted_pkg_dev/game/data/dev_profile_full.nut")
      updateProfileImpl(evt, eid, comp, @() devArmies)
    }
  },
}, playerComps, {tags = "server"})

let is_tutorialQuery = ecs.SqQuery("is_tutorialQuery",  {comps_rq = ["isTutorial"]})
let getTutorialProfileQuery = ecs.SqQuery("getTutorialProfileQuery", {comps_ro=[["tutorial__profile", ecs.TYPE_STRING]]})
ecs.register_es("client_profile_tutorial_es", {
  [CmdTutorialSquadsData] = function(evt, eid, comp) {
    let isTutorial = (is_tutorialQuery.perform(@(eid, _comp) eid) ?? ecs.INVALID_ENTITY_ID) != ecs.INVALID_ENTITY_ID
    if (isTutorial) {
      let id = getTutorialProfileQuery.perform(@(_, comp) comp["tutorial__profile"]) ?? "def"
      updateProfileImpl(evt, eid, comp, @() profiles?[id] ?? {})
    }
    else
      logerr("Tutorial profile enable only in tutorial map!")
  },
}, playerComps, {tags = "server"})

let getCustomProfileQuery = ecs.SqQuery("getCustomProfileQuery", {comps_ro=[["customProfile", ecs.TYPE_STRING]]})
ecs.register_es("client_profile_jwt_es", {
  [CmdProfileJwtData] = function(evt, eid, comp) {
    let customProfile = getCustomProfileQuery(@(_eid, comp) comp["customProfile"])
    let porfileCb = customProfile ? @() loadJson(customProfile) : @() unpackArmiesFromJwt(comp.userid, evt.data?.jwt)
    updateProfileImpl(evt, eid, comp, porfileCb)
  },
}, playerComps, {tags = "server"})

let function stopTimerInt(eid, reason, do_logerr=false) {
  debug($"Stop wait profile timer: {reason}")
  ecs.recreateEntityWithTemplates({eid, removeTemplates=["wait_profile_timer"]})
  if (do_logerr)
    logerr("Stop wait profile timer")
}

let stopTimer = @(eid, reason) stopTimerInt(eid, reason)
let stopTimerLogerr = @(eid, reason) stopTimerInt(eid, reason, true)

let function checkProfile(_dt, eid, comp) {
  let connectedAtTime = comp.connectedAtTime
  if (connectedAtTime < 0.0) {
    debug($"Player {eid} ({comp.userid}) created but not connected yet. Wait for connection")
    return
  }

  if (comp.disconnected)
    return stopTimer(eid, $"Player {eid} ({comp.userid}) has been disconnected")

  if (comp.armiesReceivedTime >= 0.0)
    return stopTimer(eid, $"The profile is received for player {eid} ({comp.userid})")

  let profileWaitTimeout = comp.profileWaitTimeout
  let curWaitTime = get_sync_time() - connectedAtTime
  debug($"Wait profile for {eid} ({comp.userid}) {curWaitTime}/{profileWaitTimeout}")

  if (curWaitTime > profileWaitTimeout) {
    kick_player(comp.userid, $"The profile is not received during time {curWaitTime}")
    stopTimerLogerr(eid, $"The profile is missed for player {eid} ({comp.userid}) by timeout!")
  }
}

let function attachCheckProfile(eid, comp) {
  if (comp.userid != INVALID_USER_ID && has_network())
    ecs.recreateEntityWithTemplates({eid, addTemplates=["wait_profile_timer"]})
}

ecs.register_es("client_profile_attach_wait_profile_es", {onInit = attachCheckProfile}, {comps_ro=[["userid", ecs.TYPE_UINT64]], comps_rq=["player"]}, {tags="server"})

ecs.register_es("client_profile_timeout_es", {
  onInit = @(eid, comp) debug($"Start wait pofile timer fo player {eid} ({comp.userid}).")
  onUpdate = checkProfile,
},
{
  comps_ro=[["userid", ecs.TYPE_UINT64], ["connectedAtTime", ecs.TYPE_FLOAT], ["profileWaitTimeout", ecs.TYPE_FLOAT], ["armiesReceivedTime", ecs.TYPE_FLOAT], ["disconnected", ecs.TYPE_BOOL]]
  comps_rq=["wait_profile_timer"]
},
{ tags="server", updateInterval=2.0, after="*" })

let function onGetMySquadsData(evt, eid, comp) {
  let net = has_network()
  let senderEid = net ? find_human_player_by_connid(evt.data?.fromconnid ?? INVALID_CONNECTION_ID) : find_local_player()
  if (senderEid != eid)
    return
  if (!comp.isArmiesReceived) {
    logerr("Try to get player profile when it not received on server")
    return
  }

  log($"Send squads data to player by request. PlayerEid = {eid}")
  ecs.server_send_event(eid, mkCmdSetMySquadsData(comp.armies), [comp.connid])
}

ecs.register_es("client_profile_requested_es",
  { [CmdGetMySquadsData] = onGetMySquadsData },
  { comps_ro = [
      ["connid", ecs.TYPE_INT],
      ["armies", ecs.TYPE_OBJECT],
      ["isArmiesReceived", ecs.TYPE_BOOL],
    ]
  },
  { tags = "server" })
