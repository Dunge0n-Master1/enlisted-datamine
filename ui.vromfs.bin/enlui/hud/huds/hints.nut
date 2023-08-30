from "%enlSqGlob/ui_library.nut" import *

let {fontHeading2} = require("%enlSqGlob/ui/fontsStyle.nut")
let { hints } = require("%ui/hud/state/eventlog.nut")

let defTextAnims = [
  { prop=AnimProp.scale, from=[1,0], to=[1,1], duration=0.33, play=true, easing=OutCubic }
]

let defHintCtor = @(hint) {
  size = [flex(), SIZE_TO_CONTENT]
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  halign = ALIGN_CENTER
  text = hint?.text

  sound = "attachSound" in hint ? { attach = { name = hint.attachSound }} : {}

  key = hint
  transform = { pivot = [0, 1] }
  animations = defTextAnims
}.__update(fontHeading2)

let hintsRoot = @() {
  watch = hints.events
  size   = [sh(100), SIZE_TO_CONTENT]
  flow   = FLOW_VERTICAL
  halign = ALIGN_CENTER
  valign = ALIGN_TOP

  children = hints.events.value.map(@(hint) hint?.ctor(hint) ?? defHintCtor(hint))
}

return hintsRoot
