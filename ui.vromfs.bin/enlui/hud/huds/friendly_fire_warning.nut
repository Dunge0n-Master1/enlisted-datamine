from "%enlSqGlob/ui_library.nut" import *

let {fontBody} = require("%enlSqGlob/ui/fontsStyle.nut")
let {HUD_TIPS_FAIL_TEXT_COLOR} = require("%ui/hud/style.nut")
let {friendlyFirePenalty} = require("%ui/hud/state/friendly_fire_warnings_state.nut")

let ANIM_TRIGGER = "animFrienldyFireWarning"

let tipBack = {
  rendObj = ROBJ_WORLD_BLUR
  padding = hdpx(2)
  size = SIZE_TO_CONTENT
  valign = ALIGN_CENTER
  flow = FLOW_HORIZONTAL
  transform = { pivot = [0.5, 0.5] }
}

let text_hint = @(text) {
  rendObj = ROBJ_TEXT
  margin = hdpx(2)
  text
  fontSize = fontBody.fontSize
  color = HUD_TIPS_FAIL_TEXT_COLOR
  transform = {}
}

let mkWarning = @(value)
  tipBack.__merge({
    children = [
      text_hint("{0}: ".subst(loc("hud/friendly_fire_penalty_warning", "Damage to friendly units")))
      text_hint($"{value}").__update({
        animations=[{ prop=AnimProp.scale, from=[1.4,1.4], to=[1,1], duration=0.3, play=true, easing=OutQuintic, trigger=ANIM_TRIGGER}]
      })
    ]
  })

friendlyFirePenalty.subscribe(@(_) anim_start(ANIM_TRIGGER))

return function () {
  return {
    watch = friendlyFirePenalty
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    hplace = ALIGN_CENTER
    vplace = ALIGN_BOTTOM
    flow = FLOW_VERTICAL
    gap = hdpx(5)

    children = friendlyFirePenalty.value < 0
      ? mkWarning(friendlyFirePenalty.value)
      : null
  }
}
