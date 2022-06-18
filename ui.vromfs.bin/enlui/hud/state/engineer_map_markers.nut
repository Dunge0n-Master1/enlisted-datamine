import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let respawn_markers = Watched({})
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

let function deleteRespawnHudMarker(eid){
  if (eid in respawn_markers.value)
    respawn_markers.mutate(function(v) {
      delete v[eid]
    })
}

let function createRespawnMarker(eid, team, custom){
  respawn_markers.mutate(@(v) v[eid] <- {custom, team})
}

ecs.register_es(
  "respawn_markers_es",
  {
    [["onInit", "onChange"]] = function(eid, comp){
        if (comp.respawnIconType != "human")
          return
        let isHidden = comp["respawn_icon__isHidden"]
        if (isHidden){
          deleteRespawnHudMarker(eid)
          return
        }
        let isCustom = ecs.obsolete_dbg_get_comp_val(eid, "autoRespawnSelector", null) == null
        createRespawnMarker(eid, comp.team, isCustom)
    }
    onDestroy = @(eid, _comp) deleteRespawnHudMarker(eid)
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
        createRespawnMarker(eid, comp.previewTeam, true)
    }
    onDestroy = @(eid, _comp) deleteRespawnHudMarker(eid)
  },
  {
    comps_rq = ["respawnObject", "builder_server_preview"]
    comps_ro = [["previewTeam", ecs.TYPE_INT]]
  }
)

return{
  respawn_markers = respawn_markers
  is_engineer = is_engineer
}