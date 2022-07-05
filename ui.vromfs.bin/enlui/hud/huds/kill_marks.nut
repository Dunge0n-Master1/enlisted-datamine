from "%enlSqGlob/ui_library.nut" import *

let dagorMath = require("dagor.math")
let {
  worldKillMarkSize, killMarks, worldKillMarkColor, worldDownedMarkColor
} = require("%ui/hud/state/hit_marks_es.nut")

let mkAnimations = @() [
  { prop=AnimProp.opacity, from=0.2, to=1, duration=0.3, play=true, easing=InCubic }
  { prop=AnimProp.opacity, from=1, to=0, duration=2.7, delay = 0.3, play=true , easing=InCubic }
  {
    prop = AnimProp.translate,
    from=[0, 0], to=[0, -hdpx(3 * worldKillMarkSize.value[1])],
    duration=3.0,
    play=true,
    easing=OutCubic
  }
  {
    prop = AnimProp.scale,
    from =[0.25, 0.25], to = [1, 1],
    duration = 0.3,
    easing = InCubic,
    play = true
  }
]

local killMarkImage
local downedMarkImage
let function updateCache(...){
  killMarkImage = {
    size = worldKillMarkSize.value
    rendObj = ROBJ_IMAGE
    color = worldKillMarkColor.value
    valign = ALIGN_CENTER
    transform = {}
    animations = mkAnimations()
    image = Picture("!ui/skin#skull.svg:{0}:{1}:K"
      .subst(worldKillMarkSize.value[0].tointeger(), worldKillMarkSize.value[1].tointeger()))
  }
  downedMarkImage = killMarkImage.__merge({color=worldDownedMarkColor.value})
}

{
  [worldKillMarkColor, worldDownedMarkColor, worldKillMarkSize]
    .map(@(v) v.subscribe(updateCache))
}
updateCache()

let function mkKillMark(mark){
  let pos = mark.killPos
  return pos ? {
    data = {
      minDistance = 0.1
      clampToBorder = true
      worldPos = dagorMath.Point3(pos[0], pos[1], pos[2])
    }
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
