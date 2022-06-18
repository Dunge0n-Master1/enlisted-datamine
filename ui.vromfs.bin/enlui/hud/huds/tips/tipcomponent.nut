from "%enlSqGlob/ui_library.nut" import *

let {body_txt} = require("%enlSqGlob/ui/fonts_style.nut")
let {HUD_TIPS_FG} = require("%ui/hud/style.nut")
let { controlHudHint, mkHasBinding } = require("%ui/components/controlHudHint.nut")

let function text_hint(text, params={}) {
  let res = {
    rendObj = ROBJ_TEXT
    margin = hdpx(2)
    text
    color = params?.textColor ?? HUD_TIPS_FG
    font = params?.font ?? body_txt?.font
    fontSize = params?.fontSize ?? body_txt.fontSize
    transform = {pivot=[0.1,0.5]}
    animations = params?.textAnims ?? []
  }
  if (text instanceof Watched)
    return @() res.__update({ watch = text, text = text.value })
  return res
}

let defTipAnimations = [
  { prop=AnimProp.scale, from=[0,1], to=[1,1], duration=0.25, play=true, easing=OutCubic }
  { prop=AnimProp.opacity, from=0, to=1, duration=0.15, play=true, easing=OutCubic }
  { prop=AnimProp.scale, from=[1,1], to=[0,1], duration=0.25, playFadeOut=true, easing=OutCubic }
  { prop=AnimProp.opacity, from=1, to=0, duration=0.25, playFadeOut=true, easing=OutCubic }
]

let function mkInputHintBlock(inputId, addChild = null) {
  if (inputId == null)
    return null
  let hasBinding = mkHasBinding(inputId)
  let inputHint = controlHudHint(inputId)
  return @() {
    watch = hasBinding
    flow = FLOW_HORIZONTAL
    children = hasBinding.value ? [inputHint, addChild] : null
  }
}

let padding = { size = [fsh(1), 0] }

let tipBack = {
  rendObj = ROBJ_WORLD_BLUR
  padding = hdpx(2)
  valign = ALIGN_CENTER
  flow = FLOW_HORIZONTAL
  transform = { pivot = [0.5, 0.5] }
}

let function tipCmp(params) {
  local {
    text = null, inputId = null, extraCmp = params?.text ? padding : null,
    size = SIZE_TO_CONTENT, animations = defTipAnimations
  } = params
  if (text == null && inputId == null)
    return null

  animations = [].extend(animations).extend(params?.extraAnimations ?? [])
  let textCmp = text != null ? text_hint(text, params) : null
  let inputHintBlock = mkInputHintBlock(inputId, textCmp ? padding : null)
  return tipBack.__merge({
    size
    animations
    children = [
      inputHintBlock
      textCmp
      extraCmp
    ]
  }).__update(params?.style ?? {})
}

let function tipText(params) {
  let { text = null, size = SIZE_TO_CONTENT, animations = defTipAnimations } = params
  if (text == null)
    return null

  return tipBack.__merge({
    size
    animations
    children = text_hint(text, params)
  }).__update(params?.style ?? {})
}

let function tipAlternate(params) {
  let { textsInputs = [], size = SIZE_TO_CONTENT, animations = defTipAnimations } = params
  let watch = textsInputs.map(@(data) mkHasBinding(data.inputId))
  return function() {
    let res = { watch }
    let idx = watch.findindex(@(w) w.value)
    if (idx == null)
      return res

    let { text = null, inputId = null } = textsInputs[idx]
    if (text == null && inputId == null)
      return res

    let textCmp = text != null ? text_hint(text, params) : null
    let inputHintBlock = mkInputHintBlock(inputId, textCmp ? padding : null)
    return res.__update(tipBack, {
      size
      animations
      children = [
        inputHintBlock
        textCmp
      ]
    }, params?.style ?? {})
  }
}

return {
  tipCmp
  tipText
  tipAlternate
  mkInputHintBlock
  defTipAnimations
}
