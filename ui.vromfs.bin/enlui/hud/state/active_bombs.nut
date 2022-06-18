import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let {isFriendlyFireMode} = require("%enlSqGlob/missionType.nut")
let { watchedHeroEid } = require("%ui/hud/state/watched_hero.nut")
let {TEAM_UNASSIGNED} = require("team")
let is_teams_friendly = require("%enlSqGlob/is_teams_friendly.nut")

let getBombOwnerTeamQuery = ecs.SqQuery("getBombOwnerTeamQuery", {comps_ro = [["team", ecs.TYPE_INT]]})
let getHeroTeam = @(heroEid) getBombOwnerTeamQuery.perform(heroEid, @(_eid, comp) comp["team"]) ?? TEAM_UNASSIGNED

let active_bombs = Watched({})

let function deleteBomb(eid) {
  if (eid in active_bombs.value)
    active_bombs.mutate(@(v) delete v[eid])
}

ecs.register_es(
  "active_bombs_hud_es",
  {
    [["onInit", "onChange"]] = function(eid, comp) {
      if (comp["projectile__exploded"]) {
        deleteBomb(eid)
        return
      }
      let bombOwnerEid = comp["ownerEid"]
      let heroEid = watchedHeroEid.value ?? INVALID_ENTITY_ID
      let showBombIndicatorToBombOwner =
        bombOwnerEid == heroEid
        && bombOwnerEid != INVALID_ENTITY_ID
        && heroEid != INVALID_ENTITY_ID
      let showBombIndicatorToPlayer = isFriendlyFireMode()
        || !is_teams_friendly(getHeroTeam(heroEid), getHeroTeam(bombOwnerEid))

      let showBombIndicator = showBombIndicatorToBombOwner || showBombIndicatorToPlayer
      if (showBombIndicator && comp["projectile__stopped"])
        active_bombs.mutate(@(v) v[eid] <- {maxDistance = comp["hud_marker__max_distance"]})
    }
    function onDestroy(eid, _comp) {
      deleteBomb(eid)
    }
  },
  {
    comps_ro = [
      ["ownerEid", ecs.TYPE_EID, INVALID_ENTITY_ID],
      ["hud_marker__max_distance", ecs.TYPE_FLOAT, 10.0]
    ]
    comps_track = [
      ["projectile__exploded", ecs.TYPE_BOOL],
      ["projectile__stopped", ecs.TYPE_BOOL]
    ]
    comps_rq = ["hud_bomb_marker"]
  }
)

return {
  active_bombs
}