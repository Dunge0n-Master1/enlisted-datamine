from "%enlSqGlob/ui_library.nut" import *

let {hitMarks} = require("%ui/hud/state/hit_marks_es.nut")

let markSize = [fsh(4.),fsh(4.)]
let markColor = Color(255, 255, 255, 255)
let fadeInTime = 0.5
let fadeOutTime = 0.3
let visibleTime = 0.8
let visImmunityMarks = keepref(Computed(
  @() hitMarks.value.reduce(@(res, mark) mark.isImmunityHit ? res + 1 : res, 0)))
let needShowImmunityMark = Watched(false)
let hideImmunityMark = @() needShowImmunityMark(false)
local lastVisibleImmunityMarks = visImmunityMarks.value

visImmunityMarks.subscribe(function(v) {
  let oldValue = lastVisibleImmunityMarks
  lastVisibleImmunityMarks = v

  if (v == 0) {
    needShowImmunityMark(false)
    return
  }

  if (oldValue > v)
    return

  needShowImmunityMark(true)
  gui_scene.resetTimeout(visibleTime, hideImmunityMark)
})

let immunityMark = {
  size = markSize
  rendObj = ROBJ_IMAGE
  color = markColor
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  image = Picture("!ui/skin#stand_icon.svg:{0}:{0}:K".subst(markSize[1].tointeger()))
  transform = {}
  animations = [
    { prop = AnimProp.opacity, from = 1, to = 1, duration = fadeInTime,
      play  = true, easing = InCubic }
    { prop = AnimProp.opacity, from = 1, to = 0, duration = fadeOutTime,
      easing = InCubic, playFadeOut = true }
    { prop = AnimProp.scale, from = [1, 1], to = [1.4, 1.4], duration = fadeOutTime,
      easing = InOutCubic, playFadeOut = true }
  ]
}

let immunityMarksComp = @() {
  watch = needShowImmunityMark
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = needShowImmunityMark.value
            ? immunityMark
            : null
}

return immunityMarksComp
