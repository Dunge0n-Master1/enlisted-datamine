import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let { TEAM_UNASSIGNED } = require("team")
let {localPlayerEid, localPlayerTeam, localPlayerGroupMembers} = require("%ui/hud/state/local_player.nut")
let { controlledHeroEid } = require("%ui/hud/state/controlled_hero.nut")
let is_teams_friendly = require("%enlSqGlob/is_teams_friendly.nut")
let awardsLog = require("%ui/hud/state/eventlog.nut").awards
let EventLogState = require("%ui/hud/state/eventlog_state.nut")
let { setIntervalForUpdateFunc } = require("%ui/helpers/timers.nut")
let { forcedMinimalHud } = require("%ui/hud/state/hudGameModes.nut")
let { minimalistHud } = require("%ui/hud/state/hudOptionsState.nut")
let getFramedNickByEid = require("%ui/hud/state/getFramedNickByEid.nut")
let remap_nick = require("%enlSqGlob/remap_nick.nut")

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

let teamKills = mkWatched(persist, "teamKills", 0)

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

let getAwardForKill = @(victim, killer) {
  text = killEventText(victim, killer)
  type = "kill"
  groupKey = $"kill_{victim?.name}"
  scoreId = victim?.scoreId
}

let function onReportKill(evt, _eid, _comp) {
  let data = evt.data
  local victim = data.victim
  local killer = data.killer

  let heroEid     = controlledHeroEid.value
  let myTeam      = localPlayerTeam.value
  let locPlayer   = localPlayerEid.value
  let initialVictimPlayer = victim.player_eid

  let victimInMySquad = victim.player_eid == locPlayer
  let victimPlayer = victimInMySquad ? INVALID_ENTITY_ID : victim.player_eid
  let victimInMyTeam = is_teams_friendly(myTeam, victim.team)
  victim = victim.__merge({
    inMyTeam = victimInMyTeam
    inMySquad = victimInMySquad
    inMyGroup = victimPlayer in localPlayerGroupMembers.value
    isHero = victim.eid==heroEid
    player_eid = victimPlayer
    isDowned = false // TODO: pass it in msg itself
    isAlive = false
    name = victim?.vehicle ? loc(victim?.name, "")
      : victimPlayer != INVALID_ENTITY_ID ? getFramedNickByEid(victimPlayer)
      : remap_nick(victim?.name)
  })
  killer = killer.__merge({
    inMyTeam = is_teams_friendly(myTeam, killer.team ?? TEAM_UNASSIGNED)
    inMySquad = killer.player_eid==locPlayer
    inMyGroup = killer.player_eid != localPlayerEid.value && killer.player_eid in localPlayerGroupMembers.value
    isHero = killer.eid==heroEid
    name = killer.player_eid != INVALID_ENTITY_ID ? getFramedNickByEid(killer.player_eid)
      : remap_nick(killer?.name)
  })
  let event = data.__merge({
    event = "kill"
    text = null
    myTeamScores = !victimInMyTeam
    victim = victim
    killer = killer
    ttl = [victim.eid, killer.eid].indexof(heroEid)!=null ? 8 : 5
  })

  if (showKillLog.value) {
    killLogState.pushEvent(event)

    if (killer.eid == heroEid) {
      let award = {awardData = getAwardForKill(victim, killer)}
      awardsLog.pushEvent(award)
    }
  }
  if (is_teams_friendly(myTeam, victim.team ?? TEAM_UNASSIGNED)
      && initialVictimPlayer != locPlayer
      && killer.player_eid == locPlayer
    ) {
    teamKills(teamKills.value+1)
    return
  }
  if ( initialVictimPlayer != locPlayer ){
    return
  }
  if (victim.eid!=heroEid || heroEid==killer.eid)
    return

  deathsLog.pushEvent(event.__merge({ttl=7, event = "death"}))
}

let function clearDeathLog(){
  deathsLog.events.mutate(@(v) v.clear())
}

controlledHeroEid.subscribe(@(_v) gui_scene.resetTimeout(1, clearDeathLog))
ecs.register_es("ui_kill_report_es", {
    [ecs.sqEvents.EventKillReport] = onReportKill
  },
  {comps_rq=["msg_sink"]}
)

local num = 0
console_register_command(function() {
  num+=1
  deathsLog.pushEvent({
    event = {event = "death"}, killer = {name = $"test name {num}"}, text = "sample event"
  })
}, "ui.death_event")

console_register_command(@() teamKills(teamKills.value+1), "ui.show_teamkill_warn")

let showTeamKillsWarning = Watched(false)
let hideTKwarn = @() showTeamKillsWarning(false)

teamKills.subscribe(function(_){
  showTeamKillsWarning(true)
  gui_scene.resetTimeout(10, hideTKwarn)
})

return {
  deathsLog
  teamKills
  showTeamKillsWarning
  killLogState
}