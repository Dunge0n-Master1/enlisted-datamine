from "%enlSqGlob/ui_library.nut" import *

let {ceil} = require("math")
let {enemiesAvatars} = require("%ui/hud/state/human_enemies.nut")
let { watchedHeroEid } = require("%ui/hud/state/watched_hero.nut")

let unitArrowSz = [fsh(0.7), fsh(1.4)]

let unit_arrow = Picture("!ui/skin#enemy_arrow.svg:{0}:{1}:K".subst(
    ceil(unitArrowSz[0]*1.3).tointeger(), ceil(unitArrowSz[1]*1.3).tointeger()))

let mkIcon = memoize(@(fillColor){
    rendObj = ROBJ_IMAGE
    color = fillColor
    image = unit_arrow
    pos = [0, -unitArrowSz[1] * 0.25]
    size = unitArrowSz
  }
)

let function map_unit_ctor(eid, marker, _options={}) {
  if (!marker.isAlive)
    return @(){watch = watchedHeroEid}

  return function(){
    let fillColor = Color(201, 58, 61)

    return {
      key = eid
      data = {
        eid
        dirRotate = true
      }
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      transform = {}
      watch = watchedHeroEid
      children = mkIcon(fillColor)
    }
  }
}
return{
  watch = enemiesAvatars
  ctor = @(p) enemiesAvatars.value.topairs().map(@(v) map_unit_ctor(v[0], v[1], p))
}