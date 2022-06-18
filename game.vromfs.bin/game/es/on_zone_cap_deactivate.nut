import "%dngscripts/ecs.nut" as ecs
let {TEAM_UNASSIGNED} = require("team")
let {EventZoneDeactivated, EventZoneCaptured, EventEntityActivate} = require("dasevents")
let checkZonesGroup = require("%enlSqGlob/zone_cap_group.nut").capZonesGroupMustChanged

let onZoneCapturedQuery = ecs.SqQuery("onZoneCapturedQuery", {
  comps_ro = [
    ["groupName", ecs.TYPE_STRING],
    ["deactivatable", ecs.TYPE_BOOL, true],
    ["deactivationDelay", ecs.TYPE_FLOAT, -1.0]
  ]
  comps_no = ["respbase"]
})

let onZoneCapturedRespBasesQuery = ecs.SqQuery("onZoneCapturedRespBasesQuery", {
  comps_ro = [["groupName", ecs.TYPE_STRING]]
  comps_rq = ["respbase"]
  comps_no = ["customRespawnBase"]
})

let function onZoneCaptured(evt, eid, comp) {
  let zoneEid = evt.zone
  let teamId = evt.team
  if (zoneEid != eid)
    return
  if (comp["capzone__deactivateAfterCap"]) {
    if (!checkZonesGroup(comp["capzone__checkAllZonesInGroup"], eid, teamId, comp["capzone__mustBeCapturedByTeam"], comp["groupName"]))
      return
    let groupName = comp.groupName
    let function sendEventOnCap(eid, comps) {
      if (comps.groupName == groupName && comps.deactivatable) {
        let deactive = @() ecs.g_entity_mgr.sendEvent(eid, EventEntityActivate({activate=false}))
        if (comps.deactivationDelay > 0.0) {
          ecs.g_entity_mgr.sendEvent(eid, ecs.event.EventEntityAboutToDeactivate())
          ecs.set_callback_timer(deactive, comps.deactivationDelay, false)
        }
        else
          deactive()
      }
    }
    onZoneCapturedQuery.perform(sendEventOnCap)
    let function sendEventOnCapToResp(eid, respBaseComp) {
      if (respBaseComp.groupName == groupName)
        ecs.g_entity_mgr.sendEvent(eid, EventEntityActivate({activate=false}))
    }
    let choiceAfterCap = comp["capzone__activateChoice"]?.getAll() ?? []
    let hasNextGroup = comp.capzone__activateAfterCap != ""
      || comp.capzone__activateAfterTeam1Cap != ""
      || comp.capzone__activateAfterTeam2Cap != ""
    if (hasNextGroup || choiceAfterCap.len() != 0)
      onZoneCapturedRespBasesQuery.perform(sendEventOnCapToResp)
  }
}

ecs.register_es("capzone_on_deactivate_es", {
    [EventZoneCaptured] = onZoneCaptured,
    [EventZoneDeactivated] = onZoneCaptured
  },
  {
    comps_ro = [
      ["groupName", ecs.TYPE_STRING],
      ["capzone__deactivateAfterCap", ecs.TYPE_BOOL],
      ["capzone__deactivateAfterTimeout", ecs.TYPE_FLOAT, -1.0],
      ["capzone__checkAllZonesInGroup",ecs.TYPE_BOOL, false],
      ["capzone__capTeam", ecs.TYPE_INT],
      ["capzone__mustBeCapturedByTeam", ecs.TYPE_INT, TEAM_UNASSIGNED],
      ["capzone__activateAfterCap", ecs.TYPE_STRING, ""],
      ["capzone__activateAfterTeam1Cap", ecs.TYPE_STRING, ""],
      ["capzone__activateAfterTeam2Cap", ecs.TYPE_STRING, ""],
      ["capzone__activateChoice", ecs.TYPE_OBJECT, null]
    ]
  }, {tags = "server"}
)

let function onZoneCapturedDeactGroups(evt, eid, comp) {
  let zoneEid = evt.zone
  if (zoneEid != eid)
    return
  let deactGroups = comp["capzone__deactivateGroupsAfterCap"]
  if (deactGroups.len()) {
    let function sendEventOnCap(eid, comps) {
      if (deactGroups.indexof(comps.groupName, ecs.TYPE_STRING) && comps.deactivatable)
        ecs.g_entity_mgr.sendEvent(eid, EventEntityActivate({activate=false}))
    }
    onZoneCapturedQuery.perform(sendEventOnCap)
  }
}

ecs.register_es("capzone_on_deactivate_groups_es", {
    [EventZoneCaptured] = onZoneCapturedDeactGroups,
    [EventZoneDeactivated] = onZoneCapturedDeactGroups,
  },
  {
    comps_ro = [
      ["groupName", ecs.TYPE_STRING],
      ["capzone__deactivateGroupsAfterCap", ecs.TYPE_ARRAY],
    ]
  }, {tags = "server"}
)
