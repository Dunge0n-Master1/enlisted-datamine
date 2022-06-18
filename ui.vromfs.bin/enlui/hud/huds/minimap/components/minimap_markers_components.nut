from "%enlSqGlob/ui_library.nut" import *

let {CmdDeleteMapUserPoint, sendNetEvent} = require("dasevents")
let markSz = [fsh(2), fsh(2.6)]

let function mkPointMarkerCtor(params = {image = null, colors = {myHover = Color(250,250,180,250), myDef = Color(250,250,50,250), foreignHover = Color(220,220,250,250), foreignDef = Color(180,180,250,250)}}){
  return function(eid, marker, options) {
    let {byLocalPlayer=false, customIcon = null} = marker

    let pin = watchElemState(function(sf) {
      local color
      if (byLocalPlayer) {
        color = (sf & S_HOVER) ? params?.colors.myHover : params?.colors.myDef
      } else {
        color = (sf & S_HOVER) ? params?.colors.foreignHover : params?.colors.foreignDef
      }

      return {
        size = params?.size ?? markSz
        rendObj = ROBJ_IMAGE
        color = color
        image = params?.image ?? customIcon
        behavior = options?.isInteractive && byLocalPlayer ? Behaviors.Button : null
        onClick = byLocalPlayer ? @()sendNetEvent(eid, CmdDeleteMapUserPoint()) : null
      }
    })

    let icon = {
      size = [0, SIZE_TO_CONTENT]
      pos = [-hdpx(12), 0]
      halign = ALIGN_CENTER
      valign = params?.valign ?? ALIGN_BOTTOM
      transform = options?.transform
      children = pin
    }

    return {
      key = eid
      data = {
        eid = eid
        clampToBorder = true
      }
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      transform = {}

      children = [icon]
    }
  }
}

return {
  mkPointMarkerCtor
}