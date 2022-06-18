import "%dngscripts/ecs.nut" as ecs
let {EventZoneCaptured, EventZoneIsAboutToBeCaptured, EventTeamLost} = require("dasevents")
let checkZonesGroup = require("%enlSqGlob/zone_cap_group.nut").allZonesInGroupCapturedByTeam
let {TEAM_UNASSIGNED} = require("team")

let onZoneCapQuery = ecs.SqQuery("onZoneCapQuery", {comps_ro = [["team__id", ecs.TYPE_INT], ["team__score", ecs.TYPE_FLOAT], ["team__scoreCap", ecs.TYPE_FLOAT]]})
let function onZoneCaptured(evt, _eid, comp) {
  let teamId = evt.team
  let teamCapPen = comp["team__capturePenalty"]
  let capPen = ecs.obsolete_dbg_get_comp_val(evt.zone, "capzone__capPenalty", teamCapPen)
  let checkAllZonesInGroup = ecs.obsolete_dbg_get_comp_val(evt.zone, "capzone__checkAllZonesInGroup", false)
  let zonesMustBeCapturedByTeam = ecs.obsolete_dbg_get_comp_val(evt.zone, "capzone__mustBeCapturedByTeam", TEAM_UNASSIGNED)
  let zoneGroupName = ecs.obsolete_dbg_get_comp_val(evt.zone, "groupName", -1)
  if (checkAllZonesInGroup && (teamId != zonesMustBeCapturedByTeam || !checkZonesGroup(evt.zone, teamId, zoneGroupName)))
    return
  if (comp["team__id"] != teamId && capPen != 0) {
    if (capPen >= comp["team__score"]) {
      comp["team__score"] = 0
      ecs.g_entity_mgr.broadcastEvent(EventTeamLost({team=comp["team__id"]}))
    }
    else
      comp["team__score"] -= capPen
  }

  let capReward = ecs.obsolete_dbg_get_comp_val(evt.zone, "capzone__capReward", 0.0)
  if (comp["team__id"] == teamId && capReward != 0) {
    let capRewardPartCap = ecs.obsolete_dbg_get_comp_val(evt.zone, "capzone__capRewardPartCap", 10000.0)
    local minEnemyTeamTicketsPart = 1.0
    onZoneCapQuery.perform(
        function(_eid, comp) {
          let part = comp["team__score"] / comp["team__scoreCap"]
          minEnemyTeamTicketsPart = min(part, minEnemyTeamTicketsPart)
        },"ne(team__id,{0})".subst(teamId))
    let scoreCap = max(comp.team__minScoreCap, comp["team__scoreCap"] * min(1.0, minEnemyTeamTicketsPart * capRewardPartCap))
    comp["team__score"] = comp["team__score"] + max(min(capReward, scoreCap - comp["team__score"]), 0.0)
  }
}

ecs.register_es("team_on_cap_es",
  {
    [EventZoneCaptured] = onZoneCaptured,
    [EventZoneIsAboutToBeCaptured] = onZoneCaptured,
  },
  {
    comps_rw = [
      ["team__score", ecs.TYPE_FLOAT],
    ]

    comps_ro = [
      ["team__id", ecs.TYPE_INT],
      ["team__capturePenalty", ecs.TYPE_FLOAT],
      ["team__scoreCap", ecs.TYPE_FLOAT, 0],
      ["team__minScoreCap", ecs.TYPE_FLOAT, 0],
    ]
  },
  {tags = "server"}
)


