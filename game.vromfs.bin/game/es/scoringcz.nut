import "%dngscripts/ecs.nut" as ecs
let {EventZoneCaptured, EventZoneIsAboutToBeCaptured, EventZoneDecaptured, EventTeamLoseHalfScore,
       EventTeamLowScore, EventTeamLost} = require("dasevents")

let function decScore(comp, amount) {
  let curScore = comp["team__score"]
  let scoreCap = comp["team__scoreCap"]

  if (scoreCap > 0) {
    let prevScore = curScore / scoreCap.tofloat()
    let newScore = (curScore - amount) / scoreCap.tofloat()

    if (newScore <= 0.5 && prevScore > 0.5)
      ecs.g_entity_mgr.broadcastEvent(EventTeamLoseHalfScore({teamId=comp["team__id"]}))
    else if (newScore <= 0.2 && prevScore > 0.2)
      ecs.g_entity_mgr.broadcastEvent(EventTeamLowScore({teamId=comp["team__id"]}))
  }

  comp["team__score"] = max(curScore - amount, 0.0)
  if (comp["team__score"] == 0.0){
    comp["score_bleed__domBleedOn"] = false
    if (comp["team__zeroScoreFailTimer"] < 0)
      ecs.g_entity_mgr.broadcastEvent(EventTeamLost({team=comp["team__id"]}))
  }
}

let scoring_cz_comps_update = {
  comps_rw = [
    ["team__score", ecs.TYPE_FLOAT],
  ],
  comps_ro = [
    ["team__id", ecs.TYPE_INT],
    ["team__scoreCap", ecs.TYPE_FLOAT, 0.0],
    ["score_bleed__staticBleed", ecs.TYPE_FLOAT, 0.0],
    ["score_bleed__domBleed", ecs.TYPE_FLOAT, 0.0],
    ["score_bleed__domBleedOn", ecs.TYPE_BOOL, false],
    ["score_bleed__totalDomBleedMul", ecs.TYPE_FLOAT, 1.0],
    ["score_bleed__totalDomBleedOn", ecs.TYPE_BOOL, false],
    ["team__zeroScoreFailTimer", ecs.TYPE_FLOAT, -1.0],
  ]
}
let function onUpdate(dt, _eid, comp){
  if (comp["team__score"] == 0.0)
    return
  if (comp["score_bleed__staticBleed"] > 0)
    decScore(comp, dt*comp["score_bleed__staticBleed"])
  if (comp["score_bleed__domBleed"] > 0 && comp["score_bleed__domBleedOn"]) {
    local domBleed = comp["score_bleed__domBleed"]
    if (comp["score_bleed__totalDomBleedOn"])
      domBleed *= comp["score_bleed__totalDomBleedMul"]
    decScore(comp, dt*domBleed)
  }
}
ecs.register_es(
  "scoring_cz_update_es",
  { onUpdate = onUpdate },
  scoring_cz_comps_update,
  { updateInterval = 1.0, tags="server", before="team_capzone_es", after="*" }
)


let findBleedQuery = ecs.SqQuery("findBleedQuery", {
  comps_rw = [
    ["score_bleed__domBleedOn", ecs.TYPE_BOOL],
    ["score_bleed__totalDomBleedOn", ecs.TYPE_BOOL]
  ],
  comps_ro = [
    ["team__id", ecs.TYPE_INT],
    ["team__numZonesCaptured", ecs.TYPE_INT],
    ["score_bleed__domBleed", ecs.TYPE_FLOAT],
    ["score_bleed__totalDomZoneCount", ecs.TYPE_INT, -1],
    ["score_bleed__totalDomBleedMul", ecs.TYPE_FLOAT, 1.0]
  ]
})

let calcMaxZoneQuery = ecs.SqQuery("calcMaxZoneQuery", {comps_ro = [["team__numZonesCaptured", ecs.TYPE_INT], ["team__id", ecs.TYPE_INT]]})
let function onZonesCapChanged(_eid, _comp) {
  local maxZonesCap = 0
  calcMaxZoneQuery.perform(function(_eid, comp) {
    if (comp["team__numZonesCaptured"] > maxZonesCap)
      maxZonesCap = comp["team__numZonesCaptured"]
  })

  findBleedQuery.perform(function(_eid, comp) {
    comp["score_bleed__domBleedOn"] = comp["team__numZonesCaptured"] < maxZonesCap && comp["score_bleed__domBleed"] > 0
    comp["score_bleed__totalDomBleedOn"] = comp["score_bleed__totalDomZoneCount"] == maxZonesCap && comp["score_bleed__domBleed"] > 0
  })
}

ecs.register_es("team_capzone_changed_es", {
      [ecs.EventComponentChanged] = onZonesCapChanged,
  },
  {comps_track = [["team__numZonesCaptured", ecs.TYPE_INT]]},
  {tags="server"}
)

let function onZoneCaptured(evt, _eid, comp) {
  let teamId = evt.team
  if (comp["team__id"] == teamId)
    comp["team__numZonesCaptured"] += 1
}

let function onZoneDecaptured(evt, _eid, comp) {
  let teamId = evt.team
  if (comp["team__id"] == teamId)
    comp["team__numZonesCaptured"] -= 1
}

ecs.register_es("team_capzone_es", {
    [EventZoneCaptured] = onZoneCaptured,
    [EventZoneIsAboutToBeCaptured] = onZoneCaptured,
    [EventZoneDecaptured] = onZoneDecaptured,
  },
  {
    comps_rw = [["team__numZonesCaptured", ecs.TYPE_INT],],
    comps_ro = [["team__id", ecs.TYPE_INT],]
  },
  {tags="server"}
)

