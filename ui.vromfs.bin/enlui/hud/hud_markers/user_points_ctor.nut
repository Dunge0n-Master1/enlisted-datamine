from "%enlSqGlob/ui_library.nut" import *

let { user_points_by_type } = require("%ui/hud/state/user_points.nut")
let { makeArrow } = require("%ui/hud/hud_markers/components/hud_markers_components.nut")

//!!!COLOR BELOW ARE CHECKED TO BE REASONABLE FOR COLORBLIND PPL
let myMainUserMarkColor = Color(250,250,50,250)
let forMainUserMarkColor = Color(180,180,250,250)
let forEnemyMarkColor = Color(255,115,83,250)
let myEnemyMarkColor = Color(251,24,34,250)
//!!!COLOR ABOVE ARE CHECKED TO BE REASONABLE FOR COLORBLIND PPL

let myDefMarkColor = Color(250,250,50,250)
let forDefMarkColor = Color(180,180,250,250)

let markSz = [fsh(2), fsh(2.6)].map(@(v) v.tointeger())
let vehicleMarkSz = [fsh(3), fsh(3)].map(@(v) v.tointeger())
let buildingMarkSz = vehicleMarkSz
let main_user_mark = Picture("!ui/skin#map_pin.svg:{0}:{1}:K".subst(markSz[0],markSz[1]))
let enemy_user_mark = Picture("!ui/skin#unit_inner.svg:{0}:{1}:K".subst(markSz[0],markSz[1]))


let mkArrow = memoize(@(color) makeArrow({color, yOffs=fsh(2), anim = null}))

let defTransform = {}

let mkPointMarkerCtor = kwarg(function(image = null, myColor = myDefMarkColor, foreignColor = forDefMarkColor, yOffs=0, size=null, animations=null) {
  let mkIcon = memoize(@(ico, color) freeze({
    rendObj = ROBJ_IMAGE
    size =size ?? markSz
    pos = [0, sh(yOffs)]
    color
    image = ico
    animations
  }))
  return function(eid, data) {
    let {byLocalPlayer=false, customIcon = null} = data
    let color = byLocalPlayer ? myColor : foreignColor
    return {
      data = {
        eid
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

      children = [mkIcon(image ?? customIcon, color), mkArrow(color)]
    }
  }
})
let ctor_by_type = {
  enemy_user_point = mkPointMarkerCtor({
    image = enemy_user_mark,
    myColor = myEnemyMarkColor,
    foreignColor = forEnemyMarkColor,
    yOffs = -1,
    size = markSz,
    animations = [{ prop=AnimProp.color, from=myEnemyMarkColor, to=Color(255,200,200), duration=0.7, play=true, loop=true, easing=Blink }]
  })
  main_user_point = mkPointMarkerCtor({image = main_user_mark, myColor = myMainUserMarkColor, foreignColor = forMainUserMarkColor})
  enemy_vehicle_user_point = mkPointMarkerCtor({myColor = myEnemyMarkColor, foreignColor = forEnemyMarkColor, yOffs=-1, size=vehicleMarkSz})
  enemy_building_user_point = mkPointMarkerCtor({myColor = myEnemyMarkColor, foreignColor = forEnemyMarkColor, size = buildingMarkSz})
}
return [
  "main_user_point",
  "enemy_user_point",
  "enemy_vehicle_user_point",
  "enemy_building_user_point"
].reduce(function(res, typ){
    let watch = user_points_by_type[typ]
    let c = memoize(@(eid) ctor_by_type[typ](eid, watch.value[eid]))
    res[$"{typ}_ctor"] <- { watch, ctor = @() watch.value.keys().map(c) }
    return res
  },
  {}
)
