from "%enlSqGlob/ui_library.nut" import *

let { h2_txt, body_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let { isGamepad } = require("%ui/control/active_controls.nut")
let { mkImageCompByDargKey } = require("%ui/components/gamepadImgByKey.nut")
let JB = require("%ui/control/gui_buttons.nut")
let { debounce } = require("%sqstd/timers.nut")
let { sizePosToBox, getLinkArrowMiddleCfg } = require("tutorialUtils.nut")

let borderWidth = hdpx(1)
let defMsgPadding = [hdpx(20), hdpx(40)] //to not be too close to highlighted objects.

let function mkSizeTable(box, content) {
  let { l, r, t, b } = box
  return {
    size = [r-l, b-t]
    pos = [l, t]
  }.__update(content)
}

let lightCtor = @(box, override) mkSizeTable(box, {
  rendObj = ROBJ_BOX
  borderWidth
  borderColor = 0xFFFFFFFF
  behavior = Behaviors.Button
}.__update(override))

let darkCtor = @(box) mkSizeTable(box, {
  rendObj = ROBJ_SOLID
  color = 0xC0000000
})

let hintTextStyle = body_txt.__merge({ color = 0xFFA0A0A0 })

let kbHint = {
  rendObj = ROBJ_TEXT
  text = loc("PressSpaceToContinue")
}.__update(hintTextStyle)

let gpHint = {
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  gap = hdpx(5)
  children = [
    mkImageCompByDargKey(JB.A)
    {
      rendObj = ROBJ_TEXT
      text = loc("PressToContinue")
    }.__update(hintTextStyle)
  ]
}

let nextKeyHintCtor = @(nextKeyAllowed, onNext) onNext == null ? null
  : @() {
      watch = [isGamepad, nextKeyAllowed]
      children = !nextKeyAllowed.value ? null
        : (isGamepad.value ? gpHint : kbHint)
          .__merge({ hotkeys = [[$"^Space | {JB.A}", onNext]] })
    }

let messageCtor = @(text, nextKeyAllowed, onNext, textOverride = {}) {
  padding = defMsgPadding
  gap = hdpx(20)
  flow = FLOW_VERTICAL
  halign = ALIGN_CENTER
  children = [
    { //include only because padding not correct count by calc_comp_size while in textarea.
      maxWidth = fsh(80)
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      text
      halign = ALIGN_CENTER
    }.__update(h2_txt, textOverride)
    nextKeyHintCtor(nextKeyAllowed, onNext)
  ]
}

let mkMessageCtorWithGamepadIcons = @(hotkeys) @(text, nextKeyAllowed, onNext) {
  padding = defMsgPadding
  gap = hdpx(20)
  flow = FLOW_VERTICAL
  halign = ALIGN_CENTER
  children = [
    @() {
      watch = isGamepad
      flow = FLOW_HORIZONTAL
      valign = ALIGN_CENTER
      gap = hdpx(5)
      children = (isGamepad.value ? hotkeys.map(@(h) mkImageCompByDargKey(h)).append({ size = [hdpx(10), flex()]}) : [])
        .append({  //warning disable: -unwanted-modification
          maxWidth = fsh(80)
          rendObj = ROBJ_TEXTAREA
          behavior = Behaviors.TextArea
          text
          halign = isGamepad.value ? ALIGN_LEFT : ALIGN_CENTER
        }.__update(h2_txt))
    }
    nextKeyHintCtor(nextKeyAllowed, onNext)
  ]
}

let skipTrigger = {}
let skipStateFlags = Watched(0)
let isSkipPushed = Watched(false) //update with debounce, to not change value too fast on calc comp size
skipStateFlags.subscribe(debounce(@(v) isSkipPushed((v & S_ACTIVE) != 0), 0.01))
isSkipPushed.subscribe(@(v) v ? anim_start(skipTrigger) : anim_skip(skipTrigger))

let pSize = hdpxi(40)
let mkSkipProgress = @(stepSkipDelay, skipStep, keyImg) {
  key = "skipProgress"
  size = [pSize, pSize]
  rendObj = ROBJ_PROGRESS_CIRCULAR
  image = Picture($"ui/skin#round_border.svg:{pSize}:{pSize}:K")
  fgColor = 0xFFFFFFFF
  bgColor = 0
  fValue = 0
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = keyImg
  animations = [
    { prop = AnimProp.fValue, from = 0.0, to = 1.0, duration = stepSkipDelay, trigger = skipTrigger, onFinish = skipStep }
  ]
}

let skipBtnImage = @() {
  watch = isGamepad
  children = isGamepad.value ? mkImageCompByDargKey("J:Start") : null
}
let skipBtnCtor = @(stepSkipDelay, skipStep, key) {
  key
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  gap = hdpx(10)
  children = [
    mkSkipProgress(stepSkipDelay, skipStep, skipBtnImage)
    @() {
      watch = skipStateFlags
      key = "holdToSkip"
      behavior = Behaviors.Button
      onElemState = @(sf) skipStateFlags(sf)
      rendObj = ROBJ_TEXT
      text = loc("HoldToSkip")
      color = skipStateFlags.value & S_HOVER ? 0xFFFFFFFF
        : skipStateFlags.value & S_ACTIVE ? 0xFF808080
        : 0xA0A0A0A0
      hotkeys = [["^J:Start", { description = { skip = true }}]]
    }.__update(body_txt)
  ]
  animations = [{ prop=AnimProp.opacity, from = 0, to = 1, duration = 3, play = true }]
}

let pointerSize = hdpxi(70)
let pointerAnimTime = 1.0
let pointerAnimOffset = hdpx(25)
let pointerArrow = {
  padding = pointerAnimOffset
  children = {
    size = [pointerSize, pointerSize]
    rendObj = ROBJ_IMAGE
    color = 0xFF417927
    image = Picture($"!ui/uiskin/arrow_tutor.svg:{pointerSize}:{pointerSize}:K")
    keepAspect = KEEP_ASPECT_FIT
    transform = {}
    animations = [
      { prop=AnimProp.translate, from = [0, -pointerAnimOffset], to = [0, pointerAnimOffset],
        duration = pointerAnimTime, play = true, loop = true, easing = CosineFull }
      { prop = AnimProp.scale, from = [0.85, 0.85], to = [1.0, 1.0],
        duration = pointerAnimTime, play = true, loop = true, easing = CosineFull }
    ]
  }
}

let function mkLinkArrow(boxFrom, boxTo) {
  local { pos, rotate } = getLinkArrowMiddleCfg(boxFrom, boxTo)
  let size = pointerSize + 2 * pointerAnimOffset
  pos = pos.map(@(v) v - 0.5 * size)
  return {
    box = sizePosToBox(array(2, size), pos)
    component = pointerArrow.__merge({ pos, transform = { rotate } })
  }
}

return freeze({
  //required styles
  lightCtor
  darkCtor
  messageCtor
  skipBtnCtor
  pointerArrow
  mkLinkArrow

  //components to reuse from outside
  mkSizeTable
  nextKeyHintCtor
  mkMessageCtorWithGamepadIcons
  defMsgPadding
})