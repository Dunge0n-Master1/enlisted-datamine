import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let { mkWatchedSetAndStorage } = require("%ui/ec_to_watched.nut")
let {
  respawn_markers_Set,
  respawn_markers_GetWatched,
  respawn_markers_UpdateEid,
  respawn_markers_DestroyEid
} = mkWatchedSetAndStorage("respawn_markers_")
let {
  engineer_buildings_markers_Set,
  engineer_buildings_markers_GetWatched,
  engineer_buildings_markers_UpdateEid,
  engineer_buildings_markers_DestroyEid
} = mkWatchedSetAndStorage("engineer_buildings_markers_")

let is_engineer = Watched(false)

ecs.register_es("ui_check_building_tool_gun_es",
  {
    [["onChange", "onInit"]] = function (_eid, comp) {
      let currentGunEid = comp["human_weap__currentGunEid"]
      let currentPreviewId = ecs.obsolete_dbg_get_comp_val(currentGunEid, "currentPreviewId", null)
      if (currentPreviewId != null) {
        is_engineer(true)
        return
      }
      is_engineer(false)
    },
  },
  {
    comps_track = [["human_weap__currentGunEid", ecs.TYPE_EID]],
    comps_rq = ["hero"]
  }
)

ecs.register_es(
  "respawn_markers_es",
  {
    [["onInit", "onChange"]] = function(eid, comp){
        if (comp.respawnIconType != "human")
          return
        let isHidden = comp["respawn_icon__isHidden"]
        if (isHidden){
          respawn_markers_DestroyEid(eid)
          return
        }
        let isCustom = ecs.obsolete_dbg_get_comp_val(eid, "autoRespawnSelector", null) == null
        respawn_markers_UpdateEid(eid, {team = comp.team, isCustom})
    }
    onDestroy = @(eid, _comp) respawn_markers_DestroyEid(eid)
  },
  {
    comps_ro = [["team", ecs.TYPE_INT], ["respawnIconType", ecs.TYPE_STRING]],
    comps_track = [["respawn_icon__isHidden", ecs.TYPE_BOOL]]
  }
)

ecs.register_es(
  "respawn_previews_markers_es",
  {
    [["onInit"]] = function(eid, comp){
        respawn_markers_UpdateEid(eid, {team = comp.previewTeam, isCustom = true})
    }
    onDestroy = @(eid, _comp) respawn_markers_DestroyEid(eid)
  },
  {
    comps_rq = ["respawnObject", "builder_server_preview"]
    comps_ro = [["previewTeam", ecs.TYPE_INT]]
  }
)

ecs.register_es(
  "engineer_buildings_markers_ui_state",
  {
    [["onInit", "onChange"]] = function(eid, comp) {
      engineer_buildings_markers_UpdateEid(eid, {
        image = comp.building_menu__image
        showToBuilderOnly = !comp.minimap__visibleForAll
        buildByPlayer = comp.buildByPlayer
        team = comp.builder_info__team
      })
    }
    onDestroy = @(eid, _comp) engineer_buildings_markers_DestroyEid(eid)
  },
  {
    comps_track = [
      ["minimap__visibleForAll", ecs.TYPE_BOOL, false],
    ]
    comps_ro = [
      ["buildByPlayer", ecs.TYPE_EID],
      ["builder_info__team", ecs.TYPE_INT],
      ["building_menu__image", ecs.TYPE_STRING],
    ],
  }
)

return{
  respawn_markers_Set
  respawn_markers_GetWatched
  engineer_buildings_markers_Set
  engineer_buildings_markers_GetWatched
  is_engineer
}