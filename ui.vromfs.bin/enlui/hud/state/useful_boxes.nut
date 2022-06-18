import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let {localPlayerTeam} = require("%ui/hud/state/local_player.nut")
let is_teams_friendly = require("%enlSqGlob/is_teams_friendly.nut")
let useful_box_markers = Watched({})

let function deleteEid(eid){
  if (eid in useful_box_markers.value)
    useful_box_markers.mutate(@(v) delete v[eid])
}

ecs.register_es(
  "useful_boxes_markers_es",
  {
    onInit = function(eid, comp){
      let isFriendly = is_teams_friendly(comp.team, localPlayerTeam.value)
      if (!isFriendly)
        deleteEid(eid)
      else
        useful_box_markers.mutate(@(v) v[eid] <- {
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
    onDestroy = @(eid, _) deleteEid(eid)
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
        deleteEid(eid)
    }
  },
  {
    comps_rq = ["transform", "buildByPlayer"]
    comps_track=[["useful_box__useCount", ecs.TYPE_INT]]
  }
)

return useful_box_markers
