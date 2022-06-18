import "%dngscripts/ecs.nut" as ecs
let {TEAM_UNASSIGNED} = require("team")
let is_teams_friendly = require("%enlSqGlob/is_teams_friendly.nut")
let {EventPlayerPossessedEntityDied} = require("dasevents")

let function modifyAfkTime(eid, change) {
  local afkTime = ecs.obsolete_dbg_get_comp_val(eid, "player_activity__afkTime", 0.0)
  afkTime = max(0, afkTime + change)
  ecs.obsolete_dbg_set_comp_val(eid, "player_activity__afkTime", afkTime)
}

let findActiveZone = ecs.SqQuery("findActiveZone", {comps_ro = [ ["active", ecs.TYPE_BOOL]], comps_rq=["capzone"]},"active")
let function capzoneActivity(eid) {
  let peid = ecs.obsolete_dbg_get_comp_val(eid, "possessed", INVALID_ENTITY_ID)
  let team = ecs.obsolete_dbg_get_comp_val(eid, "team")
  let tm = ecs.obsolete_dbg_get_comp_val(peid, "transform")

  let pos = tm.getcol(3)
  local minDistance = -1
  local isCapturedByTeam = false
  local isCapturedByPlayer = false

  let zones = []
  findActiveZone.perform(function(eid, _comp) {
      zones.append(eid)
    })

  foreach (zoneEid in zones) {
    let zoneTm = ecs.obsolete_dbg_get_comp_val(zoneEid, "transform")
    if (!zoneTm)
      continue
    let zonePos = zoneTm.getcol(3)
    let teamCapturingZone =
      ecs.obsolete_dbg_get_comp_val(zoneEid, "capzone__curTeamCapturingZone", TEAM_UNASSIGNED)
    let zoneRadius = ecs.obsolete_dbg_get_comp_val(zoneEid, "sphere_zone__radius", 0)
    let distance = max(0, (pos - zonePos).length() - zoneRadius)

    if (teamCapturingZone == team)
      isCapturedByTeam = true
    if (distance == 0)
      isCapturedByPlayer = true
    if (minDistance == -1 || distance < minDistance)
      minDistance = distance
  }

  let mults = {
    maxZoneDistance          = 50.0
    zoneDistanceMult         = 0.5
    capturedZoneDistanceMult = 2.0
    zonePlayerCaptureMult    = 3.5
  }
  foreach (name, defValue in mults)
    mults[name] = ecs.obsolete_dbg_get_comp_val(peid, $"player_activity__{name}", defValue)


  local activity = 0.0
  if (minDistance != -1) {
    let mult = mults.zoneDistanceMult + (isCapturedByTeam ? mults.capturedZoneDistanceMult : 0)
    activity += mult * clamp(1.0 - (minDistance / mults.maxZoneDistance), 0.0, 1.0)
  }
  if (minDistance == 0)
    activity += mults.zonePlayerCaptureMult

  return activity
}


let function onUpdate(dt, eid, _comp){
  let peid = ecs.obsolete_dbg_get_comp_val(eid, "possessed", INVALID_ENTITY_ID)
  if (peid == INVALID_ENTITY_ID)
    return

  let isEnabled = ecs.obsolete_dbg_get_comp_val(peid, "player_activity__enabled", false)
  if (!isEnabled)
    return

  local afkMultiplier = 0.0
  afkMultiplier += 1
  afkMultiplier -= capzoneActivity(eid)

  modifyAfkTime(eid, dt * afkMultiplier)
}

let function onPlayerEntityDied(evt, eid, _comp) {
  let victimEid = evt.victimEid
  let killerEid = evt.killerEid

  if (ecs.obsolete_dbg_get_comp_val(victimEid, "player_activity__enabled", false))
    modifyAfkTime(eid, -ecs.obsolete_dbg_get_comp_val(victimEid, "player_activity__deathActivity", 3.0))

  if (ecs.obsolete_dbg_get_comp_val(killerEid, "player_activity__enabled", false)) {
    let isOpponent = !is_teams_friendly(ecs.obsolete_dbg_get_comp_val(killerEid, "team", TEAM_UNASSIGNED), ecs.obsolete_dbg_get_comp_val(victimEid, "team", TEAM_UNASSIGNED))
    if (isOpponent)
      modifyAfkTime(eid, -ecs.obsolete_dbg_get_comp_val(killerEid, "player_activity__killActivity", 8.0))
  }
}

let comps = {
  comps_rw = [ ["player_activity__afkTime", ecs.TYPE_FLOAT] ],
  comps_ro = [ ["team", ecs.TYPE_INT] ]
}

ecs.register_es("player_activity",
  {
    onUpdate = onUpdate,
    [EventPlayerPossessedEntityDied] = onPlayerEntityDied
  },
  comps,
  { updateInterval=1.0, tags="server", after="*", before="*" }
)
