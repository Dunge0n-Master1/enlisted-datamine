import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let { mkFrameIncrementObservable } = require("%ui/ec_to_watched.nut")
let {bombSites, bombSitesSetKeyVal, bombSitesDeleteKey} = mkFrameIncrementObservable({}, "bombSites")

ecs.register_es("bomb_sites_ui_state_es",
  {
    [["onInit", "onChange"]] = @(_, eid, comp) bombSitesSetKeyVal(eid, {
        eid
        active = comp["active"]
        isBombPlanted = comp["bomb_site__isBombPlanted"]
        operator = comp["bomb_site__operator"]
        timeToPlant = comp["bomb_site__timeToPlant"]
        timeToResetPlant = comp["bomb_site__timeToResetPlant"]
        timeToDefuse = comp["bomb_site__timeToDefuse"]
        timeToExplosion = comp["bomb_site.timeToExplosion"]
        plantedTimeEnd = comp["bomb_site__plantedTimeEnd"]
        resetTimeEnd = comp["bomb_site__resetTimeEnd"]
        defusedTimeEnd = comp["bomb_site__defusedTimeEnd"]
        plantingTeam = comp["bomb_site.plantingTeam"]
        explosionTimeEnd = comp["bomb_site.explosionTimeEnd"]
        plantProgressPausedAt = comp["bomb_site.plantProgressPausedAt"]
        defuseProgressPausedAt = comp["bomb_site.defuseProgressPausedAt"]
        explosionTimerPausedAtTime = comp["bomb_site.explosionTimerPausedAtTime"]
        icon = comp["bomb_site.icon"]
        iconOffsetY = comp["bomb_site.iconOffsetY"]
      }),
    onDestroy = @(_, eid, __) bombSitesDeleteKey(eid)
  },
  {
    comps_ro = [
      ["bomb_site__timeToPlant", ecs.TYPE_FLOAT],
      ["bomb_site__timeToResetPlant", ecs.TYPE_FLOAT],
      ["bomb_site__timeToDefuse", ecs.TYPE_FLOAT],
      ["bomb_site.timeToExplosion", ecs.TYPE_FLOAT],
      ["bomb_site.plantingTeam", ecs.TYPE_INT],
      ["bomb_site.icon", ecs.TYPE_STRING, ""],
      ["bomb_site.iconOffsetY", ecs.TYPE_FLOAT, 0.0],
    ],
    comps_track = [
      ["bomb_site__operator", ecs.TYPE_EID],
      ["bomb_site__isBombPlanted", ecs.TYPE_BOOL],
      ["bomb_site__plantedTimeEnd", ecs.TYPE_FLOAT],
      ["bomb_site__resetTimeEnd", ecs.TYPE_FLOAT],
      ["bomb_site__defusedTimeEnd", ecs.TYPE_FLOAT],
      ["bomb_site.explosionTimeEnd", ecs.TYPE_FLOAT],
      ["bomb_site.plantProgressPausedAt", ecs.TYPE_FLOAT],
      ["bomb_site.defuseProgressPausedAt", ecs.TYPE_FLOAT],
      ["bomb_site.explosionTimerPausedAtTime", ecs.TYPE_FLOAT],
      ["active", ecs.TYPE_BOOL, true],
    ],
  },
  { tags="gameClient" }
)

return bombSites