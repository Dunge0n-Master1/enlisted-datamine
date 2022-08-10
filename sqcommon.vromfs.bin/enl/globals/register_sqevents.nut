let {registerUnicastEvent, registerBroadcastEvent } = require("%dngscripts/ecs.nut")
let {broadcastEvents={}, unicastEvents={}} = require("%enlSqGlob/defsqevents.nut")

return {
  broadcastEvents = {
    EventSquadMembersStats = { list = [/*squadEid, guid, eid, stat, amount*/] }
    CmdUpdateSquadPOI = null,
    EventOnBattleResult = {stats = {guid = {}}}
  }.__update(broadcastEvents).each(registerBroadcastEvent)

  unicastEvents = {
    CmdDevSquadsData = {}
    CmdTutorialSquadsData = {}
    CmdProfileJwtData = {} //here is table of anything
    CmdGetMySquadsData = {}
    CmdSetMySquadsData = {}
    CmdGetBattleResult = {},
    AFKShowWarning = null,
    AFKShowDisconnectWarning = null,
    CmdSelectBuildingType = { index = 0 },
    EventOnSquadStats = {},
    CmdTutorialHint = { event = "", unique = "", text = "", hotkey = "", ttl = 15}

    CmdRequestRespawn = {squadId = 0, memberId = 0, spawnGroup = 0},
    CmdCancelRequestRespawn = {squadId = 0, memberId = 0},
  }.__update(unicastEvents).each(registerUnicastEvent)
}
