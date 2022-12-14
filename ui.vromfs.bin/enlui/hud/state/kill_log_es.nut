import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let {localPlayerEid, localPlayerTeam, localPlayerGroupMembers} = require("%ui/hud/state/local_player.nut")
let { controlledHeroEid } = require("%ui/hud/state/controlled_hero.nut")
let is_teams_friendly = require("%enlSqGlob/is_teams_friendly.nut")
let awardsLog = require("%ui/hud/state/eventlog.nut").awards
let EventLogState = require("%ui/hud/state/eventlog_state.nut")
let { setIntervalForUpdateFunc } = require("%ui/helpers/timers.nut")
let { forcedMinimalHud } = require("%ui/hud/state/hudGameModes.nut")
let { minimalistHud } = require("%ui/hud/state/hudOptionsState.nut")
let getFramedNickByEid = require("%ui/hud/state/getFramedNickByEid.nut")
let { remap_others } = require("%enlSqGlob/remap_nick.nut")
let {EventKillReport} = require("dasevents")

let showKillLog = Computed (@() !minimalistHud.value && !forcedMinimalHud.value)

let function collapseByFunc(lastev, event){
  if (lastev?.killer.player_eid != event?.killer.player_eid
      || event?.damageType != lastev?.damageType
      || event?.victim.player_eid != lastev?.victim.player_eid)
    return false
  return true
}
let killLogState = EventLogState({id = "killLogState", collapseByFunc})

setIntervalForUpdateFunc(0.45, @(dt) killLogState.update(dt))

let deathsLog = EventLogState({id = "deathsLogState", maxActiveEvents=3, ttl=10})

setIntervalForUpdateFunc(0.45, @(dt) deathsLog.update(dt))


let function killEventText(victim, killer) {
  if (victim.isHero) {
    if (killer.vehicle) {
      let killerName = ecs.obsolete_dbg_get_comp_val(killer.eid, "item__name", "")
      return loc(killerName)
    }
    return (killer.isHero) ? loc("log/local_player_suicide") : killer.name
  }

  let victimName = victim.name ?? (
    victim?.inMyTeam
      ? victim.inMySquad ? loc("log/squadmate") : loc("log/teammate")
      : null
  )

  return (victimName != null)
    ? loc("log/eliminated", {user = victimName})
    : victim.inMyTeam
      ? loc("log/eliminated_teammate")
      : loc("log/eliminated_enemy")
}

let getAwardForKill = @(victim, killer, scoreId) {
  text = killEventText(victim, killer)
  type = "kill"
  groupKey = $"kill_{victim?.name}"
  scoreId
}

let function onReportKill(evt, _eid, _comp) {
  let heroEid     = controlledHeroEid.value
  let myTeam      = localPlayerTeam.value
  let locPlayer   = localPlayerEid.value

  let victimInMySquad = evt.victimPlayer == locPlayer
  let victimInMyTeam = is_teams_friendly(myTeam, evt.victimTeam)
  let victimInMyGroup = !victimInMySquad && evt.victimPlayer in localPlayerGroupMembers.value
  let victim = {
    eid = evt.victim
    player_eid = evt.victimPlayer
    inMyTeam = victimInMyTeam
    inMySquad = victimInMySquad
    inMyGroup = victimInMyGroup
    isHero = evt.victim == heroEid
    name = evt.isVictimVehicle ? loc(evt.victimName, "")
      : !victimInMySquad && evt.victimPlayer != ecs.INVALID_ENTITY_ID ? getFramedNickByEid(evt.victimPlayer)
      : remap_others(evt.victimName)
    rank = evt.victimRank
  }
  let killer = {
    eid = evt.killer
    player_eid = evt.killerPlayer
    vehicle = evt.isKillerVehicle
    inMyTeam = is_teams_friendly(myTeam, evt.killerTeam)
    inMySquad = evt.killerPlayer == locPlayer
    inMyGroup = evt.killerPlayer != locPlayer && evt.killerPlayer in localPlayerGroupMembers.value
    isHero = evt.killer == heroEid
    name = evt.killerPlayer != ecs.INVALID_ENTITY_ID ? getFramedNickByEid(evt.killerPlayer)
      :remap_others(evt.killerName)
    rank = evt.killerRank
  }

  if (showKillLog.value) {
    killLogState.pushEvent({
      event = "kill"
      gunName = evt.gunName
      isHeadshot = evt.isHeadshot
      damageType = evt.damageType
      victim = victim
      killer = killer
      ttl = [evt.victim, evt.killer].indexof(heroEid) != null ? 8 : 5
    })

    if (evt.killer == heroEid) {
      let award = {awardData = getAwardForKill(victim, killer, evt.scoreId)}
      awardsLog.pushEvent(award)
    }
  }

  if (evt.victim == heroEid && heroEid != evt.killer && evt.killer != ecs.INVALID_ENTITY_ID)
    deathsLog.pushEvent({
      event = "death",
      name=killer.name,
      inMyTeam=killer.inMyTeam,
      ttl=7
    })
}

let function clearDeathLog(){
  deathsLog.events.mutate(@(v) v.clear())
}

controlledHeroEid.subscribe(@(_v) gui_scene.resetTimeout(1, clearDeathLog))
ecs.register_es("ui_kill_report_es", {
    [EventKillReport] = onReportKill
  }, {}
)

local num = 0
console_register_command(function() {
  num+=1
  deathsLog.pushEvent({
    name = $"test name {num}",
    inMyTeam = false,
    ttl=7,
    event = "death"
  })
}, "ui.death_event")

return {
  deathsLog
  killLogState
}