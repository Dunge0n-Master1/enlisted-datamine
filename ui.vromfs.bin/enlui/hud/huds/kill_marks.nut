from "%enlSqGlob/ui_library.nut" import *

let dagorMath = require("dagor.math")
let {worldKillMarkSize, killMarks, worldKillMarkColor, worldDownedMarkColor} = require("%ui/hud/state/hit_marks_es.nut")

local killMarkImage
local downedMarkImage
let function updateCache(...){
  killMarkImage = {
    size = worldKillMarkSize.value
    rendObj = ROBJ_IMAGE
    color = worldKillMarkColor.value
    valign = ALIGN_CENTER
    transform = {}
    image = Picture("!ui/skin#skull.svg:{0}:{0}:K".subst(worldKillMarkSize.value[1].tointeger()))
  }
  downedMarkImage = killMarkImage.__merge({color=worldDownedMarkColor.value})
}

{
  [worldKillMarkColor, worldDownedMarkColor, worldKillMarkSize]
    .map(@(v) v.subscribe(updateCache))
}
updateCache()

let animations = [
  { prop=AnimProp.opacity, from=0.2, to=1, duration=0.3, play=true, easing=InCubic }
  { prop=AnimProp.opacity, from=1, to=0, duration=0.25, playFadeOut=true, easing=OutCubic }
  { prop = AnimProp.scale, from =[0.25, 0.25], to = [1, 1], duration = 0.3, easing = InCubic, play = true}
]

let function mkKillMark(mark){
  let pos = mark.killPos
  return pos ? {
    data = {
      minDistance = 0.1
      clampToBorder = true
      worldPos = dagorMath.Point3(pos[0], pos[1], pos[2])
    }
    animations = animations
    transform = {}
    children = mark.isKillHit ? killMarkImage : downedMarkImage
    key = mark?.id ?? {}
  } : null
}

let function killMarksComp() {
  return {
    watch = [killMarks]
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    size = [sw(100), sh(100)]
    children = killMarks.value.map(mkKillMark)
    behavior = Behaviors.Projection
  }
}

return killMarksComp
