import "%dngscripts/ecs.nut" as ecs
let { TEAM_UNASSIGNED } = require("team")
let {get_gun_stat_type_by_props_id, DM_MELEE, DM_PROJECTILE, DM_BACKSTAB} = require("dm")
let is_teams_friendly = require("%enlSqGlob/is_teams_friendly.nut")
let {Point3} = require("dagor.math")
let {EventPlayerKilledEntity, EventOnPlayerMineVehicleKill, EventOnPlayerMineInfantryKill} = require("dasevents")
let {addAward} = require("awards.nut")

let killSeqInfo = persist("killSeqInfo", @() {})

let function checkSequentialKill(killer_player_eid, seq_kill_time) {
  local rec = killSeqInfo?[killer_player_eid]
  if (rec) {
    ecs.clear_callback_timer(rec.timer)
    ++rec.n
  }
  else {
    rec = { n = 1, timer = null }
    killSeqInfo[killer_player_eid] <- rec
  }

  if (rec.n == 2) {
    addAward(killer_player_eid, "double_kill", { unique="multikill" })
  } else if (rec.n == 3) {
    addAward(killer_player_eid, "triple_kill", { unique="multikill" })
  } else if (rec.n >= 4) {
    addAward(killer_player_eid, "multi_kill", { kills = rec.n, unique="multikill" })
  }

  rec.timer = ecs.set_callback_timer(function() {
    killSeqInfo.rawdelete(killer_player_eid)
  }, seq_kill_time, false)
}

let victimQuery = ecs.SqQuery("victimQuery", {
  comps_ro = [
    ["reportKill", ecs.TYPE_BOOL, true],
    ["squad_member__squad", ecs.TYPE_EID, INVALID_ENTITY_ID],
    ["team", ecs.TYPE_INT, TEAM_UNASSIGNED],
    ["dm_parts__type", ecs.TYPE_STRING_LIST, null],
    ["mounted_gun__active", ecs.TYPE_BOOL, false],
    ["human_attached_gun__isAttached", ecs.TYPE_BOOL, false],
    ["transform", ecs.TYPE_MATRIX, null],
    ["isDriver", ecs.TYPE_BOOL, false],
    ["isPassenger", ecs.TYPE_BOOL, false],
  ]
})

let killerQuery = ecs.SqQuery("killerQuery", {
  comps_ro = [
    ["awards__longRangeDist", ecs.TYPE_FLOAT, 100],
    ["transform", ecs.TYPE_MATRIX, null],
  ]
})

let function onPlayerKilledEntity(evt, eid, comp) {
  let victimEid = evt.victimEid
  let killerEid = evt.killerEid

  let victim = victimQuery(victimEid, @(_, c) c) ?? {}
  if (!(victim?.reportKill ?? true))
    return

  let killerPlayerTeam = comp.team
  let isVictimInSquad = (victim?["squad_member__squad"] ?? INVALID_ENTITY_ID) != INVALID_ENTITY_ID
  let victimTeam = victim?.team ?? TEAM_UNASSIGNED

  if (victimEid == killerEid || victimTeam == TEAM_UNASSIGNED || is_teams_friendly(killerPlayerTeam, victimTeam) || !isVictimInSquad)
    return

  let gunStatName = get_gun_stat_type_by_props_id(evt.deathDesc_gunPropsId)

  let nodeType = victim?["dm_parts__type"]?[evt.deathDesc_collNodeId]
  let isActiveMountedGun = victim?["mounted_gun__active"] ?? false
  let isActiveMachingGunner = victim?["human_attached_gun__isAttached"] ?? false
  let victimPos = victim?.transform?.getcol(3) ?? Point3()
  let isVictimInCar = (victim?.isDriver ?? false) || (victim?.isPassenger ?? false)

  let killer = killerQuery(killerEid, @(_, c) c) ?? {}

  let longRangeDist = killer?["awards__longRangeDist"] ?? 100.0
  let killerPos = killer?.transform?.getcol(3) ?? Point3()

  if (evt.deathDesc_damageTypeId == DM_PROJECTILE && nodeType == "head")
    addAward(eid, "headshot")
  else if (evt.deathDesc_damageTypeId == DM_MELEE || evt.deathDesc_damageTypeId == DM_BACKSTAB)
    addAward(eid, "melee_kill")

  if (isActiveMountedGun || isActiveMachingGunner)
    addAward(eid, "machinegunner_kill")

  if (isVictimInCar)
    addAward(eid, "car_driver_kills")

  if (evt.deathDesc_damageTypeId == DM_PROJECTILE && (killerPos - victimPos).lengthSq() > longRangeDist * longRangeDist)
    addAward(eid, "long_range_kill")

  if (gunStatName != null && gunStatName != "")
    addAward(eid, gunStatName == "grenade" ? "grenade_kill" : $"{gunStatName}_kills")

  checkSequentialKill(eid, comp.sequentialKillTime)
}

ecs.register_es("kill_award_es",
  {
    [EventPlayerKilledEntity] = onPlayerKilledEntity,
  },
  {
    comps_ro = [
      ["userid", ecs.TYPE_UINT64],
      ["team", ecs.TYPE_INT, TEAM_UNASSIGNED],
      ["sequentialKillTime", ecs.TYPE_FLOAT, 10],
    ]},
    {tags="server"})

ecs.register_es("kill_awards_mine_kills",
  {
    [EventOnPlayerMineVehicleKill] = @(eid, _comp) addAward(eid, "vehicle_mine_kills"),
    [EventOnPlayerMineInfantryKill] = @(eid, _comp) addAward(eid, "infantry_mine_kills")
  }, {comps_rq = ["player"]}, {tags="server"})