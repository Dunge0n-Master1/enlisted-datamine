let {registerUnicastEvent, registerBroadcastEvent } = require("%dngscripts/ecs.nut")
let {broadcastEvents={}, unicastEvents={}} = require("%enlSqGlob/defsqevents.nut")

return {
  broadcastEvents = {
    EventSquadMembersStats = { list = [/*squadEid, guid, eid, stat, amount*/] }
    EventOnBattleResult = {stats = {guid = {}}}
  }.__update(broadcastEvents).each(registerBroadcastEvent)

  unicastEvents = {
    CmdDevSquadsData = {}
    CmdTutorialSquadsData = {}
    CmdProfileJwtData = {} //here is table of anything
    CmdGetMySquadsData = {}
    CmdSetMySquadsData = {}
    CmdSelectBuildingType = { index = 0 },
    EventOnSquadStats = {},
    CmdTutorialHint = { event = "", unique = "", text = "", hotkey = "", ttl = 15}

  }.__update(unicastEvents).each(registerUnicastEvent)
}
