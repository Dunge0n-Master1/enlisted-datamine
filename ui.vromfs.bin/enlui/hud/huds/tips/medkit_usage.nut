from "%enlSqGlob/ui_library.nut" import *

let timeStates = require("%ui/hud/state/time_state.nut")
let {curTime} = timeStates
let {medkitEndTime, medkitStartTime} = require("%ui/hud/state/entity_use_state.nut")
let { format } = require("string")

let picSz = hdpx(30)
let picProgress = Picture("ui/skin#round_border.svg:{0}:{0}:K".subst(picSz.tointeger()))

let bg ={rendObj = ROBJ_VECTOR_CANVAS color = Color(90,90,90,50) fillColor = Color(0,0,0,90) size=[picSz,picSz] commands=[[VECTOR_ELLIPSE, 50, 50, 100, 100]]}

let fgColor = Color(64,255,150)
let bgColor = Color(128,128,128)

let progress = @() {
  pos = [0, hdpx(120)]
  size = [picSz,picSz]
  children = [
    bg
    @(){
      rendObj = ROBJ_TEXT
      watch = [medkitEndTime, curTime]
      text = format("%.1f", max(medkitEndTime.value - curTime.value, 0.0))
      hplace=ALIGN_CENTER
      vplace = ALIGN_CENTER
    }
    @(){
      size = [picSz*2,picSz*2]
      rendObj = ROBJ_PROGRESS_CIRCULAR
      hplace=ALIGN_CENTER vplace = ALIGN_CENTER
      image = picProgress
      watch = [medkitStartTime, medkitEndTime, curTime]
      fgColor = fgColor
      bgColor = bgColor
      fValue = (curTime.value - medkitStartTime.value) / max(0.1, medkitEndTime.value - medkitStartTime.value)
    }
  ]
}
let showMedkitUsage = Computed(@() medkitEndTime.value > timeStates.curTime.value)
return function() {
  return {
    watch = showMedkitUsage
    children = showMedkitUsage.value ? progress : null
  }
}
