from "%enlSqGlob/ui_library.nut" import *
let fontFxFactor = min(hdpx(48), 64)
let fontSize = hdpx(21)
let fontFxColor = Color(0, 0, 0, 60)

return function teammateName(eid, name, color){
  if ((name ?? "") == "")
    return null
  return {
    rendObj = ROBJ_TEXT
    color
    text = name
    markerFlags = MARKER_KEEP_SCALE
    data = { eid }
    fontFx = FFT_BLUR
    fontFxColor
    fontFxFactor
    fontSize
    behavior = Behaviors.DistToPriority
    transform = {}
  }
}