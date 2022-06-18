import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let {isFriendlyFireMode} = require("%enlSqGlob/missionType.nut")
let { watchedHeroEid } = require("%ui/hud/state/watched_hero.nut")
let { localPlayerTeam } = require("%ui/hud/state/local_player.nut")
let {TEAM_UNASSIGNED} = require("team")
let is_teams_friendly = require("%enlSqGlob/is_teams_friendly.nut")

let getOwnerTeamQuery = ecs.SqQuery("getOwnerTeamQuery", {comps_ro = [["team", ecs.TYPE_INT]]})
let getOwnerTeam = @(ownerEid) getOwnerTeamQuery.perform(ownerEid, @(_eid, comp) comp["team"]) ?? TEAM_UNASSIGNED

let shell_activators = Watched({})

let function deleteActivator(eid) {
  if (eid in shell_activators.value)
    shell_activators.mutate(@(v) delete v[eid])
}

ecs.register_es(
  "spawn_shell_activator_hud_es",
  {
    onInit = function(eid, comp) {
      let activatorOwnerEid = comp.ownerEid
      let heroEid = watchedHeroEid.value ?? INVALID_ENTITY_ID
      let showActivatorIndicator = activatorOwnerEid == heroEid || isFriendlyFireMode()
        || !is_teams_friendly(localPlayerTeam.value, getOwnerTeam(activatorOwnerEid))

      if (showActivatorIndicator)
        shell_activators.mutate(@(v) v[eid] <- {maxDistance = comp.hud_marker__max_distance,
                                                icon = comp.hud_marker__icon})
    }
    onDestroy = @(eid,_) deleteActivator(eid)
  },
  {
    comps_ro = [
      ["ownerEid", ecs.TYPE_EID, INVALID_ENTITY_ID],
      ["hud_marker__max_distance", ecs.TYPE_FLOAT, 10.0],
      ["hud_marker__icon", ecs.TYPE_STRING, "killlog/kill_explosion.svg"]
    ]
    comps_rq = ["on_create__spawnActivatedShellBlk"]
  }
)

return {
  shell_activators
}