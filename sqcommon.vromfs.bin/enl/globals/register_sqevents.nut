let {registerUnicastEvent, registerBroadcastEvent } = require("%dngscripts/ecs.nut")
let {broadcastEvents={}, unicastEvents={}} = require("%enlSqGlob/defsqevents.nut")

let killReport = {
//player_and_playerpossesed
  victim_eid = 0
  victim_team = -1
  victim_squad = -1
  victim_player_eid = 0
  victim_name = ""
  //player_and_playerpossesed
  killer_eid = 0
  killer_team = -1
  killer_squad = -1
  killer_player_eid = 0
  killer_name = ""
  nodeType=0, damageType=0, gunName=""
}

return {
  broadcastEvents = {
    EventSquadMembersStats = { list = [/*squadEid, guid, eid, stat, amount*/] }
    CmdUpdateSquadPOI = null,
    EventOnBattleResult = {stats = {guid = {}}}
    EventZoneHalfCaptured = {eid=-1, team=-1},
    EventTeamStartDecapture = {eid=-1, team=-1},
    EventTeamEndDecapture = {eid=-1, team=-1},
  }.__update(broadcastEvents).each(registerBroadcastEvent)

  unicastEvents = {
    EventKillReport = killReport,
    CmdDevSquadsData = {}
    CmdTutorialSquadsData = {}
    CmdProfileJwtData = {} //here is table of anything
    CmdGetMySquadsData = {}
    CmdSetMySquadsData = {}
    CmdSquadSoldiersInfoChange = { soldiers = "", army = "", section = "" },
    CmdGetBattleResult = {},
    AFKShowWarning = null,
    AFKShowDisconnectWarning = null,
    CmdSelectBuildingType = { index = 0 },
    EventPlayerSquadFinishedCapturing = null,
    EventOnPlayerWipedOutInfantrySquad = null,
    EventOnBarbwireDamageAward = {},
    EventOnCapzoneFortificationAward = {},
    EventOnSquadStats = {},
    CmdTutorialHint = { event = "", unique = "", text = "", hotkey = "", ttl = 15}
    RequestForgiveFriendlyFire = { eid = 0 }

    CmdRequestRespawn = {squadId = 0, memberId = 0, spawnGroup = 0},
    CmdCancelRequestRespawn = {squadId = 0, memberId = 0},
  }.__update(unicastEvents).each(registerUnicastEvent)
}
