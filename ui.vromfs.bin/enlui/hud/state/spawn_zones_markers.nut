import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let { mkWatchedSetAndStorage, MK_COMBINED_STATE } = require("%ui/ec_to_watched.nut")

let {
  spawnZonesGetWatched,
  spawnZonesUpdateEid,
  spawnZonesDestroyEid,
  spawnZonesState
} = mkWatchedSetAndStorage("spawnZones", MK_COMBINED_STATE)

ecs.register_es("spawn_zones_markers",
  {
    [["onInit", "onChange"]] = function(eid,comp){
      if (comp["respawn_icon__isHidden"]){
        spawnZonesDestroyEid(eid)
        return
      }
      let isCustom = ecs.obsolete_dbg_get_comp_val(eid, "autoRespawnSelector", null) == null
      spawnZonesUpdateEid(eid, {
                                  iconType = comp.respawnIconType,
                                  selectedGroup = comp.selectedGroup,
                                  forTeam = comp.team,
                                  isCustom,
                                  iconIndex = comp["respawn_icon__iconIndex"],
                                  additiveAngle = comp["respawn_icon__additiveAngle"],
                                  isActive = comp["respawn_icon__active"],
                                  isPlayerSpawn = comp["respawn_icon__isPlayerSpawn"]
                                  activateAtTime = comp["respawn_icon__activateAtTime"],
                                  enemyAtRespawn = comp["respawn_icon__isEnemyAtRespawn"]
                                }
                              )
    }

    function onDestroy(_evt, eid, _comp){
      spawnZonesDestroyEid(eid)
    }
  },
  {
    comps_ro = [
      ["respawnIconType", ecs.TYPE_STRING],
      ["selectedGroup", ecs.TYPE_INT],
      ["team", ecs.TYPE_INT]
    ]
    comps_track = [
      ["respawn_icon__iconIndex", ecs.TYPE_INT],
      ["respawn_icon__additiveAngle", ecs.TYPE_FLOAT],
      ["respawn_icon__active", ecs.TYPE_BOOL],
      ["respawn_icon__isHidden", ecs.TYPE_BOOL],
      ["respawn_icon__activateAtTime", ecs.TYPE_FLOAT],
      ["respawn_icon__isEnemyAtRespawn", ecs.TYPE_BOOL],
      ["respawn_icon__isPlayerSpawn", ecs.TYPE_BOOL]
    ]
  }
)

return {spawnZonesGetWatched, spawnZonesState}