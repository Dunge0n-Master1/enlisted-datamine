import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let { mkWatchedSetAndStorage } = require("%ui/ec_to_watched.nut")

let {
  useful_box_markers_Set,
  useful_box_markers_GetWatched,
  useful_box_markers_UpdateEid,
  useful_box_markers_DestroyEid
} = mkWatchedSetAndStorage("useful_box_markers_")

ecs.register_es(
  "useful_boxes_markers_es",
  {
    onInit = function(_, eid, comp){
      useful_box_markers_UpdateEid(eid, {
        team = comp.team
        image = comp.hud_icon__image
        offsetY = comp.hud_icon__offsetY
        opacityRangeX = comp.hud_icon__opacityRangeX
        opacityRangeY = comp.hud_icon__opacityRangeY
        size = comp.hud_icon__size
        minDistance = comp.hud_icon__minDistance
        maxDistance = comp.hud_icon__maxDistance
        opacityCenterRelativeDist = comp.hud_icon__opacityCenterRelativeDist
        opacityCenterMinMult = comp.hud_icon__opacityCenterMinMult
      })
    }
    onDestroy = @(_, eid, __) useful_box_markers_DestroyEid(eid)
  },
  {
    comps_rq = ["transform", "buildByPlayer"]
    comps_ro = [
      ["hud_icon__image", ecs.TYPE_STRING],
      ["hud_icon__offsetY", ecs.TYPE_FLOAT, null],
      ["hud_icon__opacityRangeX", ecs.TYPE_POINT2, null],
      ["hud_icon__opacityRangeY", ecs.TYPE_POINT2, null],
      ["hud_icon__size", ecs.TYPE_POINT2, null],
      ["hud_icon__minDistance", ecs.TYPE_FLOAT, null],
      ["hud_icon__maxDistance", ecs.TYPE_FLOAT, null],
      ["hud_icon__opacityCenterRelativeDist", ecs.TYPE_FLOAT, null],
      ["hud_icon__opacityCenterMinMult", ecs.TYPE_FLOAT, null],
      ["team", ecs.TYPE_INT],
    ]
  }
)

ecs.register_es(
  "empty_useful_boxes_destroy_markers_es",
  {
    onChange = function(eid, comp){
      let isEmpty = comp.useful_box__useCount <= 0
      if (isEmpty)
        useful_box_markers_DestroyEid(eid)
    }
  },
  {
    comps_rq = ["transform", "buildByPlayer"]
    comps_track=[["useful_box__useCount", ecs.TYPE_INT]]
  }
)

return {
  useful_box_markers_Set
  useful_box_markers_GetWatched
}
