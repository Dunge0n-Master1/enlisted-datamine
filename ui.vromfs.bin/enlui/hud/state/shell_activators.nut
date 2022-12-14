import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let {isFriendlyFireMode} = require("%enlSqGlob/missionType.nut")
let { watchedHeroEid, watchedTeam } = require("%ui/hud/state/watched_hero.nut")
let is_teams_friendly = require("%enlSqGlob/is_teams_friendly.nut")

let { mkWatchedSetAndStorage } = require("%ui/ec_to_watched.nut")

let {
  shell_activators_Set,
  shell_activators_GetWatched,
  shell_activators_UpdateEid,
  shell_activators_DestroyEid
} = mkWatchedSetAndStorage("shell_activators_")

let { getTeam } = require("get_team.nut")

ecs.register_es(
  "spawn_shell_activator_hud_es",
  {
    onInit = function(eid, comp) {
      let activatorOwnerEid = comp.ownerEid
      let heroEid = watchedHeroEid.value ?? ecs.INVALID_ENTITY_ID
      let showActivatorIndicator = activatorOwnerEid == heroEid || isFriendlyFireMode()
        || !is_teams_friendly(watchedTeam.value, getTeam(activatorOwnerEid))

      if (showActivatorIndicator)
        shell_activators_UpdateEid(eid, {maxDistance = comp.hud_marker__max_distance,
                                         icon = comp.hud_marker__icon})
    }
    onDestroy = @(_, eid, __) shell_activators_DestroyEid(eid)
  },
  {
    comps_ro = [
      ["ownerEid", ecs.TYPE_EID, ecs.INVALID_ENTITY_ID],
      ["hud_marker__max_distance", ecs.TYPE_FLOAT, 10.0],
      ["hud_marker__icon", ecs.TYPE_STRING, "killlog/kill_explosion.svg"]
    ]
    comps_rq = ["on_create__spawnActivatedShellBlk"]
  }
)

return {
  shell_activators_Set, shell_activators_GetWatched
}