from "%enlSqGlob/ui_library.nut" import *

return function teammateName(eid, name, color){
  if ((name ?? "") == "")
    return null
  return {
    rendObj = ROBJ_TEXT
    color
    text = name
    markerFlags = MARKER_KEEP_SCALE
    data = { eid = eid }
    fontFx = FFT_BLUR
    fontFxColor = Color(0, 0, 0, 60)
    fontFxFactor = min(hdpx(48), 64)
    fontSize = hdpx(21)
    behavior = [Behaviors.DistToPriority]
    transform = {}
  }
}