import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let { playerEvents } = require("%ui/hud/state/eventlog.nut")
let { localPlayerTeam, localPlayerEid } = require("%ui/hud/state/local_player.nut")
let { TEAM0_TEXT_COLOR, TEAM1_TEXT_COLOR } = require("%ui/hud/style.nut")
let { EventGunGameLevelReached = null, EventGunGameNewLeader = null } = require("dasevents")

// FIXME: quickfix to remove loggerrs about non existant EventGunGameLevelReached event
// remove this later
if (EventGunGameLevelReached == null || EventGunGameNewLeader == null)
  return

let showMsg = @(text, color) playerEvents.pushEvent({ text, color, ttl = 4 })

let getColorByTeam = @(other_team) other_team == localPlayerTeam.value ? TEAM0_TEXT_COLOR : TEAM1_TEXT_COLOR

let getPlayerNameAndTeamQuery = ecs.SqQuery("getPlayerNameAndTeamQuery", { comps_ro = ["name", "team"] })
let getPlayerNameQuery = ecs.SqQuery("getPlayerNameQuery", { comps_ro = ["name"] })

ecs.register_es("gun_game_level_reached_hint", {
  [EventGunGameLevelReached] = function(evt, _eid, _comp) {
    getPlayerNameAndTeamQuery(evt.playerEid, function(_eid, comp) {
      showMsg(loc("gun_game/levelReached",
        { name = comp.name, level = evt.level + 1 }), getColorByTeam(comp.team))
    })
  }
}, {}, { tags = "gameClient" })

ecs.register_es("gun_game_leader_change_hint", {
  [EventGunGameNewLeader] = function(evt, _eid, _comp) {
    getPlayerNameAndTeamQuery(evt.newLeaderPlayerEid, function(_eid, comp) {
      // first kill
      if (evt.oldLeaderPlayerEid == ecs.INVALID_ENTITY_ID)
        if (evt.newLeaderPlayerEid != localPlayerEid.value)
          showMsg(loc("gun_game/firstLeadTaken", { name = comp.name }), getColorByTeam(comp.team))
        else
          showMsg(loc("gun_game/firstLeadTakenSelf"), getColorByTeam(comp.team))
      else if (evt.oldLeaderPlayerEid == localPlayerEid.value)
        showMsg(loc("gun_game/leaderTakenFromUs", { name = comp.name }), getColorByTeam(comp.team))
      else if (evt.newLeaderPlayerEid == localPlayerEid.value) {
        let oldLeaderName = getPlayerNameQuery(evt.oldLeaderPlayerEid, @(_eid, comp) comp.name)
        showMsg(loc("gun_game/leaderTakenByUs", { name = oldLeaderName }), getColorByTeam(comp.team))
      }
      else
        showMsg(loc("gun_game/leaderTaken", { name = comp.name }), getColorByTeam(comp.team))
    })
  }
}, {}, { tags = "gameClient" })
