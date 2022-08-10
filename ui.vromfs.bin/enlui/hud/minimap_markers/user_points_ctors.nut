from "%enlSqGlob/ui_library.nut" import *

let { CmdDeleteMapUserPoint, sendNetEvent } = require("dasevents")
let { user_points_by_type } = require("%ui/hud/state/user_points.nut")

let markSz = [fsh(2), fsh(2.6)].map(@(v) v.tointeger())
let enMarkSz = [fsh(0.9), fsh(1.4)].map(@(v) v.tointeger())

let main_user_mark = Picture("!ui/skin#map_pin.svg:{0}:{1}:K".subst(markSz[0],markSz[1]))
let enemy_user_mark = Picture("!ui/skin#unit_inner.svg:{0}:{1}:K".subst(enMarkSz[0],enMarkSz[1]))
let vehicleIconSize = [fsh(1.4), fsh(1.4)].map(@(v) v.tointeger())

let mkPointMarkerCtor = kwarg(function(image = null, size=markSz, valign=null, colors = {myHover = Color(250,250,180,250), myDef = Color(250,250,50,250), foreignHover = Color(220,220,250,250), foreignDef = Color(180,180,250,250)}) {
  return function(eid, marker, options) {
    let {byLocalPlayer=false, customIcon = null} = marker
    let pin = watchElemState(function(sf) {
      local color
      if (byLocalPlayer) {
        color = (sf & S_HOVER) ? colors.myHover : colors.myDef
      }
      else {
        color = (sf & S_HOVER) ? colors.foreignHover : colors.foreignDef
      }

      return {
        size
        rendObj = ROBJ_IMAGE
        color = color
        image = image ?? customIcon
        behavior = options?.isInteractive && byLocalPlayer ? Behaviors.Button : null
        onClick = byLocalPlayer ? @()sendNetEvent(eid, CmdDeleteMapUserPoint()) : null
      }
    })

    let icon = {
      size = [0, SIZE_TO_CONTENT]
      pos = [-hdpx(12), 0]
      halign = ALIGN_CENTER
      valign = valign ?? ALIGN_BOTTOM
      transform = options?.transform
      children = pin
    }

    return {
      key = eid
      data = {
        eid
        clampToBorder = true
      }
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      transform = {}

      children = icon
    }
  }
})

let ctors_by_type = {
  enemy_vehicle_user_point = mkPointMarkerCtor({
    colors = {myHover = Color(250,200,200,250), myDef = Color(250,50,50,250), foreignHover = Color(220,180,180,250), foreignDef = Color(200,50,50,250)}
    size = vehicleIconSize
  })

  enemy_building_user_point = mkPointMarkerCtor({
    colors = {myHover = Color(250,200,200,250), myDef = Color(250,50,50,250), foreignHover = Color(220,180,180,250), foreignDef = Color(200,50,50,250)}
    valign = ALIGN_CENTER
    size = [fsh(1.75), fsh(1.75)]
  })
  main_user_point = mkPointMarkerCtor({
    image = main_user_mark,
    colors = {myHover = Color(250,250,180,250), myDef = Color(250,250,50,250), foreignHover = Color(220,220,250,250), foreignDef = Color(180,180,250,250)}
  })

  enemy_user_point = mkPointMarkerCtor({
    image = enemy_user_mark,
    colors = {myHover = Color(250,200,200,250), myDef = Color(250,50,50,250), foreignHover = Color(220,180,180,250), foreignDef = Color(200,50,50,250)}
    size = enMarkSz
  })

  item_user_point = mkPointMarkerCtor({
    image = enemy_user_mark,
    colors = {myHover = Color(250,250,180,250), myDef = Color(250,250,50,250), foreignHover = Color(220,220,250,250), foreignDef = Color(180,180,250,250)}
    size = [fsh(0.75), fsh(0.75)]
  })
}

return [
  "enemy_building_user_point"
  "enemy_vehicle_user_point"
  "main_user_point"
  "enemy_user_point"
  "item_user_point"
].reduce(function(res, typ) {
    let watch = user_points_by_type[typ]

    res[$"{typ}_markers"] <- {
      watch
      ctor = function(p) {
        let c = memoize(@(eid) ctors_by_type[typ](eid, watch.value[eid], p))
        return watch.value.keys().map(c)
      }
    }
    return res
  },
{})

