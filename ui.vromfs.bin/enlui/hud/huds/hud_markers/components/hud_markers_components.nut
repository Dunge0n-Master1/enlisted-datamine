from "%enlSqGlob/ui_library.nut" import *

let myDefMarkColor = Color(250,250,50,250)
let forDefMarkColor = Color(180,180,250,250)
let defTransform = {}

let arrowSize = [fsh(2.5), fsh(1.2)]
let arrowPos = [0, 0]
let arrowImage = Picture("ui/skin#v_arrow")
let makeArrow = kwarg(function(yOffs = 0, pos = arrowPos, anim=null, color=null, key=null) {
  return {
    markerFlags = MARKER_ARROW
    transform = defTransform
    pos = [0, yOffs]
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    children = {
      rendObj = ROBJ_IMAGE
      image = arrowImage
      key = key ?? anim
      size = arrowSize
      color = color
      pos = pos
      animations = anim
    }
  }
})

let markSz = [fsh(2), fsh(2.6)]
//local markerDistanceTextBhv = [Behaviors.DistToPriority, Behaviors.OverlayTransparency, Behaviors.DistToEntity]
//local markerDistanceTextSize = [fsh(5), SIZE_TO_CONTENT]

let function mkPointMarkerCtor(params = {image = null, colors = {myDef = myDefMarkColor, foreignDef = forDefMarkColor}}){
  let mkIcon = @(color, customIcon) {
    rendObj = ROBJ_IMAGE
    size = params?.size ?? markSz
    pos = [0, fsh(params?.yOffs ?? 0)]
    color = color
    image = params?.image ?? customIcon
    animations = params?.animations
  }
  let mkArrow = @(color) makeArrow({color=color, yOffs=fsh(2), anim = null})
  return function(eid, marker) {
    let {byLocalPlayer=false, customIcon = null} = marker
    let color = byLocalPlayer ? params?.colors.myDef : params?.colors.foreignDef
/*
    local distanceText = null
    if (marker.showDistanceRear) {
      distanceText = {
        data = { eid = eid }
        targetEid = eid
        rendObj = ROBJ_TEXT
        color = DEFAULT_TEXT_COLOR
        behavior = markerDistanceTextBhv
        hplace = ALIGN_CENTER
        vplace = ALIGN_CENTER
        halign = ALIGN_CENTER
        size = markerDistanceTextSize
        pos = [0, sh(params?.yDistOffs ?? 0)]
        markerFlags = MARKER_KEEP_SCALE | MARKER_SHOW_ONLY_WHEN_CLAMPED
        transform = defTransform
      }
    }

*/
    return {
      data = {
        eid = eid
        minDistance = 0.7
        maxDistance = 10000
        distScaleFactor = 0.5
        clampToBorder = true
      }
      halign = ALIGN_CENTER
      valign = ALIGN_BOTTOM
      transform = defTransform
      key = eid
      sortOrder = eid

      children = [mkIcon(color, customIcon), mkArrow(color)]
    }
  }
}

return {
  mkPointMarkerCtor = mkPointMarkerCtor
  makeArrow = makeArrow
}