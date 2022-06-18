from "%enlSqGlob/ui_library.nut" import *

let { h2_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let faComp = require("%ui/components/faComp.nut")
let {Inactive, statusIconBg, Active} = require("%ui/style/colors.nut")
let cursors = require("%ui/style/cursors.nut")
let {buttonSound} = require("%ui/style/sounds.nut")
let tooltipBox = require("%ui/style/tooltipBox.nut")

let function tooltipTextArea(text) {
  return tooltipBox({
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      maxWidth = hdpx(500)
      color = Color(180, 180, 180, 120)
      text
    }
  )
}

let buttonIcon = @(iconId, iconOverride = {}) faComp(iconId,{
  size = flex()
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  margin = [hdpx(1), 0, 0, hdpx(2)]
  color = Inactive
  fontSize = hdpx(21)
}.__update(iconOverride))

let DEFAULT_BUTTON_PARAMS = {
  onClick = null
  selected = null
  iconId = "question"
  key = null
  animations = null
  tooltipText = null
  needBlink = false
  blinkAnimationId = ""
}

let headupTooltip = @(tooltip) tooltipTextArea(loc(tooltip))

local btnHgt = calc_comp_size({size=SIZE_TO_CONTENT children={margin = [fsh(1), 0] size=[0, fontH(100)] rendObj=ROBJ_TEXT}.__update(h2_txt)})[1]

return function(params = DEFAULT_BUTTON_PARAMS, iconOverride = {}) {
  params = DEFAULT_BUTTON_PARAMS.__merge(params)
  return watchElemState(@(sf) {
    rendObj = ROBJ_WORLD_BLUR_PANEL
    size = [btnHgt, btnHgt]

    behavior = Behaviors.Button
    onClick = params.onClick
    onHover = params.tooltipText
                ? @(on) cursors.setTooltip(on ? headupTooltip(params.tooltipText) : null)
                : null
    color = (sf & S_HOVER) ? statusIconBg : Color(240, 240, 240, 255)
    sound = buttonSound
    children = @() {
      size = flex()
      watch = params.selected
      key = params.key
      animations = params.animations
      transform = { pivot=[0.5, 0.5] }
      valign = ALIGN_CENTER
      children = [
        buttonIcon(params.iconId, params?.selected.value
          ? { color = Active, fontFx = FFT_GLOW }.__update(iconOverride)
          : { color = (sf & S_HOVER) ? Active : Inactive }.__update(iconOverride)
        )
        params.needBlink
          ? {
              size = flex()
              rendObj = ROBJ_SOLID
              transform = {}
              opacity = 0
              animations = [
                { trigger = params.blinkAnimationId
                  prop = AnimProp.opacity, from = 0, to = 0.35, duration = 1.2,
                  play = true, loop = true, easing = Blink
                }
              ]
            }
          : null
      ]
    }
  })
}