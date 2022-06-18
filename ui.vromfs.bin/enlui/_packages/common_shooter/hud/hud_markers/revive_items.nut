import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let { sub_txt, tiny_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let faComp = require("%ui/components/faComp.nut")
let remap_nick = require("%enlSqGlob/remap_nick.nut")

let defTransform = {}
let heartColor = Color(230,120,30)
let heart = faComp("heart", {
  transform = defTransform
  fontSize = sh(1.5)
  color = heartColor
})

let unitDistanceTextBhv = [Behaviors.DistToEntity, Behaviors.DistToPriority, Behaviors.OverlayTransparency]
let playernameBhv = [Behaviors.DistToPriority, Behaviors.OverlayTransparency]
let distSize = calc_str_box("12345", tiny_txt)
let function reviveMarkerCtor(eid, info){ //info can have player name
  let distanceText = {
    data = { eid = eid }
    targetEid = eid
    rendObj = ROBJ_TEXT
    color = heartColor
    behavior = unitDistanceTextBhv
    hplace = ALIGN_CENTER
    vplace = ALIGN_CENTER
    halign = ALIGN_CENTER
    size = distSize
//    pos = unitDistanceTextPos
    markerFlags = MARKER_KEEP_SCALE
    transform = defTransform
    clampToBorder = true
  }.__update(tiny_txt)

  local playerName = ecs.obsolete_dbg_get_comp_val(info.playerItemOwner, "name")
  if (playerName!=null)
    playerName = {
      data = { eid }
      rendObj = ROBJ_TEXT text = remap_nick(playerName) color = heartColor,
      behavior = playernameBhv
    }.__update(sub_txt)
  return {
    data = {
      eid = eid //WTF? while adding eid HIDES marker?
      minDistance = 0.5
      distScaleFactor = 0.3
      clampToBorder = true
      alwaysVisible = true
//      worldPos = info?.pos
//      maxDistance = 10000
    }

    key = $"revive_player_{eid}"

    transform = defTransform
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    //pos = [0, sh(-2.0)] //distance marker offset
    flow = FLOW_VERTICAL
    children = [
      {
        flow = FLOW_HORIZONTAL
        size = SIZE_TO_CONTENT
        gap = hdpx(5)
        children = [heart, playerName]
      }
      distanceText
   ]
  }
}
return {
  reviveMarkerCtor
}
