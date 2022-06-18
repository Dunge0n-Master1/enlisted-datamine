import "%dngscripts/ecs.nut" as ecs
let {TEAM_UNASSIGNED} = require("team")
let activateGroup = require("%scripts/game/utils/activate_group.nut")
let selectRandom = require("%scripts/game/utils/random_list_selection.nut")
let checkZonesGroup = require("%enlSqGlob/zone_cap_group.nut").capZonesGroupMustChanged
let {EventZoneCaptured, EventZoneDeactivated, EventZoneIsAboutToBeCaptured, EventEntityActivate} = require("dasevents")

let function onZoneCaptured(evt, eid, comp) {
  let zoneEid = evt.zone
  let teamId = evt.team
  if (zoneEid != eid || !checkZonesGroup(comp["capzone__checkAllZonesInGroup"], eid,
       teamId, comp["capzone__mustBeCapturedByTeam"], comp["groupName"]))
    return
  let defGroupName = comp["capzone__activateAfterCap"]
  let paramName = $"capzone__activateAfterTeam{teamId}Cap"
  let groupName = ecs.obsolete_dbg_get_comp_val(eid, paramName, defGroupName)
  print($"searching for {groupName} to activate from param {paramName}")
  activateGroup(groupName)
}

let findCapzoneQuery = ecs.SqQuery("findCapzoneQuery", {comps_ro = [["groupName", ecs.TYPE_STRING]] comps_rq=["capzone"]})
let findBattleAreaQuery = ecs.SqQuery("findCapzoneQuery", {comps_ro = [["groupName", ecs.TYPE_STRING]] comps_rq=["battle_area"]})
let findRespawnBasesQuery = ecs.SqQuery("findRespawnBasesQuery", {
  comps_ro = [["groupName", ecs.TYPE_STRING], ["team", ecs.TYPE_INT]]
  comps_rq=["respbase"]
  comps_no=["autoSetRespawnGroup", "temporaryRespawnbase"]
})

let function onZoneIsAboutToBeCaptured(evt, eid, comp) {
  let zoneEid = evt.zone
  let teamId = evt.team
  if (zoneEid != eid || !checkZonesGroup(comp["capzone__checkAllZonesInGroup"], eid,
       teamId, comp["capzone__mustBeCapturedByTeam"], comp["groupName"]))
    return
  let defGroupName = comp["capzone__activateAfterCap"]
  let paramName = $"capzone__activateAfterTeam{teamId}Cap"
  let groupName = ecs.obsolete_dbg_get_comp_val(eid, paramName, defGroupName)

  print($"searching capzone for {groupName} to activate from param {paramName}")

  let function activate(eid, comp) {
    if (comp.groupName == groupName)
      ecs.g_entity_mgr.sendEvent(eid, EventEntityActivate({activate=true}))
  }
  findCapzoneQuery(activate)
  findBattleAreaQuery(activate)

  let function enemyRespawnActivator(eid, respComps) {
    if (respComps.team != teamId){
      if (respComps.groupName == groupName)
        ecs.g_entity_mgr.sendEvent(eid, EventEntityActivate({activate=true}))
      else if (respComps.groupName == comp.groupName)
        ecs.g_entity_mgr.sendEvent(eid, EventEntityActivate({activate=false}))
    }
  }
  let choiceAfterCap = comp["capzone__activateChoice"]?.getAll() ?? []
  if (groupName != "" || choiceAfterCap.len() != 0)
    findRespawnBasesQuery(enemyRespawnActivator)
}

ecs.register_es("capzone_on_activate_es", {
  [EventZoneCaptured] = onZoneCaptured,
  [EventZoneIsAboutToBeCaptured] = onZoneIsAboutToBeCaptured,
  [EventZoneDeactivated] = onZoneCaptured,
}, {comps_ro = [["capzone__activateAfterCap", ecs.TYPE_STRING], ["capzone__activateChoice", ecs.TYPE_OBJECT, null],
                ["groupName", ecs.TYPE_STRING], ["capzone__checkAllZonesInGroup", ecs.TYPE_BOOL, false],
                ["capzone__mustBeCapturedByTeam", ecs.TYPE_INT, TEAM_UNASSIGNED]]}, {tags="server"})

let function onZoneCapturedMultiple(evt, eid, comp) {
  let zoneEid = evt.zone
  let teamId = evt.team
  if (zoneEid != eid || !checkZonesGroup(comp["capzone__checkAllZonesInGroup"], eid,
       teamId, comp["capzone__mustBeCapturedByTeam"], comp["groupName"]))
    return
  let choice = comp["capzone__activateChoiceAfterCap"]
  let teams = choice["team"]
  let nextGroup = selectRandom(teams[teamId.tostring()].getAll())
  if (nextGroup != null)
    activateGroup(nextGroup)
}

ecs.register_es("capzone_on_activate_multiple_es",
  {
    [EventZoneCaptured] = onZoneCapturedMultiple,
    [EventZoneDeactivated] = onZoneCapturedMultiple,
  },
  {
    comps_ro = [ ["capzone__activateChoiceAfterCap", ecs.TYPE_OBJECT],["capzone__activateAfterCap", ecs.TYPE_STRING],
                 ["capzone__checkAllZonesInGroup", ecs.TYPE_BOOL, false], ["groupName", ecs.TYPE_STRING],
                 ["capzone__mustBeCapturedByTeam", ecs.TYPE_INT, TEAM_UNASSIGNED]]
  },
  {tags="server"}
)


