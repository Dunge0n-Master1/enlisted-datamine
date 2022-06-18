from "%enlSqGlob/ui_library.nut" import *

let {mkPointMarkerCtor} = require("components/minimap_markers_components.nut")

let markSz = [fsh(2), fsh(2.6)].map(@(v) v.tointeger())
let enMarkSz = [fsh(0.9), fsh(1.4)].map(@(v) v.tointeger())

let main_user_mark = Picture("!ui/skin#map_pin.svg:{0}:{1}:K".subst(markSz[0],markSz[1]))
let enemy_user_mark = Picture("!ui/skin#unit_inner.svg:{0}:{1}:K".subst(enMarkSz[0],enMarkSz[1]))
let user_points_ctors = {
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

  enemy_building_user_point = mkPointMarkerCtor({
    colors = {myHover = Color(250,200,200,250), myDef = Color(250,50,50,250), foreignHover = Color(220,180,180,250), foreignDef = Color(200,50,50,250)}
    valign = ALIGN_CENTER
    size = [fsh(1.75), fsh(1.75)]
  })
}

let mkUserPoints = @(ctors, state) {
  watch = state
  function ctor(p) {
    let res = []
    foreach(eid, info in state.value)
      res.append(ctors?[info.type](eid, info, p))
    return res
  }
}

return {
  user_points_ctors
  mkUserPoints
}