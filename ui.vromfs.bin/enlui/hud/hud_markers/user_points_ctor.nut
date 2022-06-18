from "%enlSqGlob/ui_library.nut" import *

let { mkPointMarkerCtor } = require("%ui/hud/huds/hud_markers/components/hud_markers_components.nut")

//!!!COLOR BELOW ARE CHECKED TO BE REASONABLE FOR COLORBLIND PPL
let myMainUserMarkColor = Color(250,250,50,250)
let forMainUserMarkColor = Color(180,180,250,250)
let forEnemyMarkColor = Color(255,115,83,250)
let myEnemyMarkColor = Color(251,24,34,250)
//!!!COLOR ABOVE ARE CHECKED TO BE REASONABLE FOR COLORBLIND PPL

let markSz = [fsh(2), fsh(2.6)].map(@(v) v.tointeger())
let vehicleMarkSz = [fsh(3), fsh(3)].map(@(v) v.tointeger())
let buildingMarkSz = vehicleMarkSz
let main_user_mark = Picture("!ui/skin#map_pin.svg:{0}:{1}:K".subst(markSz[0],markSz[1]))
let enemy_user_mark = Picture("!ui/skin#unit_inner.svg:{0}:{1}:K".subst(markSz[0],markSz[1]))


let ctorByType = {
  main_user_point = mkPointMarkerCtor({
    image = main_user_mark
    colors = {myDef =  myMainUserMarkColor, foreignDef = forMainUserMarkColor}
  })

  enemy_user_point = mkPointMarkerCtor({
    image = enemy_user_mark
    colors = {myDef = myEnemyMarkColor , foreignDef = forEnemyMarkColor}
    yOffs = -1
    animations = [{ prop=AnimProp.color, from=myEnemyMarkColor, to=Color(255,200,200), duration=0.7, play=true, loop=true, easing=Blink }]
  })

  enemy_vehicle_user_point =  mkPointMarkerCtor({
    size = vehicleMarkSz
    colors = {myDef = myEnemyMarkColor , foreignDef = forEnemyMarkColor}
    yOffs = -1
  })

  enemy_building_user_point = mkPointMarkerCtor({
    image = null
    size = buildingMarkSz
    colors = {myDef = myEnemyMarkColor , foreignDef = forEnemyMarkColor}
    valign = ALIGN_CENTER
  })
}

return {
  function user_point_ctor(eid, info) {
    return ctorByType?[info.type](eid, info)
  }
}
