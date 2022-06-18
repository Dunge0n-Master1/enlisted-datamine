from "%enlSqGlob/ui_library.nut" import *

let {Active, TextActive, TextHighlight, TextDefault} = require("%ui/style/colors.nut")
let fontIconButton = require("%ui/components/fontIconButton.nut")

let function buildContactsButton(selected = Watched(false), onClick = @() null,
    children = null, symbol = "users", enabled = Watched(true)
) {
  if (onClick == null)
    onClick = @() selected(!selected.value)
  return function() {
    let iconParams = selected.value ? { fontFx = FFT_GLOW, fontFxColor = Active } : {}
    let iconColor = @(sf) selected.value ? Active
      : sf & S_ACTIVE ? TextActive
      : sf & S_HOVER ? TextHighlight
      : TextDefault
    return {
      watch = [selected, enabled]
      size = SIZE_TO_CONTENT
      children = enabled.value
        ? [
            fontIconButton(symbol, { onClick, fontSize = hdpx(30), iconParams, iconColor })
            { pos = [hdpx(5), 0], size = flex(), halign = ALIGN_RIGHT, children }
          ]
        : null
    }
  }
}
return kwarg(buildContactsButton)