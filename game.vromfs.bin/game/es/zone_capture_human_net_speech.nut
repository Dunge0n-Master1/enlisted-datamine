import "%dngscripts/ecs.nut" as ecs
let {CmdRequestHumanSpeech} = require("speechevents")
let is_teams_friendly = require("%enlSqGlob/is_teams_friendly.nut")
let { is_point_in_capzone } = require("ecs.utils")
let {EventZoneStartCapture, EventZoneStartDecapture} = require("dasevents")

let function onZoneStartCapture(evt, eid, comp) {
  if (evt.team == comp["team"] && is_point_in_capzone(comp["transform"].getcol(3), evt.eid, 1.))
    ecs.g_entity_mgr.sendEvent(eid, CmdRequestHumanSpeech("startCapture", 1.))
}

let function onZoneStartDecapture(evt, eid, comp) {
  let zoneEid = evt.eid
  let zoneTeam = evt.team
  if (is_teams_friendly(zoneTeam, comp["team"]))
    return
  let humanTm = comp["transform"]
  if (!is_point_in_capzone(humanTm.getcol(3), evt.eid, 1.)) {
    let zoneTm = ecs.obsolete_dbg_get_comp_val(zoneEid, "transform")
    if (!zoneTm || ((zoneTm.getcol(3) - humanTm.getcol(3)) * humanTm.getcol(0) < 0.) ||
        !is_point_in_capzone(humanTm.getcol(3), evt.eid, comp["human_net_speech__decaptureZoneScale"]))
      return
  }
  ecs.g_entity_mgr.sendEvent(eid, CmdRequestHumanSpeech("enemyStartCapture", 1.))
}

ecs.register_es("zone_capture_human_net_speech_es",
  {
    [EventZoneStartCapture] = onZoneStartCapture,
    [EventZoneStartDecapture] = onZoneStartDecapture,
  },
  {
    comps_ro = [
      ["transform", ecs.TYPE_MATRIX],
      ["team", ecs.TYPE_INT],
      ["human_net_speech__decaptureZoneScale", ecs.TYPE_FLOAT],
    ]
  }, {tags = "server"}
)
