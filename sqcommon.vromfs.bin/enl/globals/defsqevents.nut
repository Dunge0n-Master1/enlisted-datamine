return {
  broadcastEvents = {
    EventStreamerModeToggle = null
  }

  unicastEvents = {
    EventSqDedicatedPermissions = {},
    CmdPsnExternalMatchId = {match_id=""}
    CmdChatMessage = {mode="team", text="", qmsg=null, sound=null},
    EventSqChatMessage = {team = "", name="", sender=0, text="", qmsg=null, sound=null},
    EventTeamItemHint = null,
    EventEntityAboutToDeactivate = null,
    EventBotSpawned = {eid=0},

    EventStartCameraTracks = null,
    EventStopCameraTracks = null,

    CmdSetMarkMain = null,
    CmdSetMarkEnemy = null,

    CmdTrackHeroVehicle = null,
    CmdTrackVehicleWithWatched = null,

    EventRebuiltInventory = null,//workaround for non updating inventory
    CmdEnableDedicatedLogger = { on = true },
    EventOnSpawnError = {reason=""},

    CmdAddAward = {award=0},

    CmdHeroLogExEvent = { _event = "", _key = "" },
    EventTurretAmmoDepleted = null,
  }
}
