from "%enlSqGlob/ui_library.nut" import *

let {fontBody} = require("%enlSqGlob/ui/fontsStyle.nut")
let {isDowned, isAlive} = require("%ui/hud/state/health_state.nut")
let {isSpectator} = require("%ui/hud/state/spectator_state.nut")
let {downedEndTime} = require("%ui/hud/state/downed_state.nut")
let {medkitEndTime, medkitStartTime} = require("%ui/hud/state/entity_use_state.nut")
let {curTime} = require("%ui/hud/state/time_state.nut")
let { format } = require("string")

let color0 = Color(200,40,40,110)
let color1 = Color(200,200,40,180)
let overlapTipWithHeal = 1.0
let isInDowned = Computed(@() isDowned.value && isAlive.value)

let animColor = [
  { prop=AnimProp.color, from=color0, to=color1, duration=1.0, play=true, loop=true, easing=CosineFull }
  { prop=AnimProp.scale, from=[1,1], to=[1.0, 1.1], duration=3.0, play=true, loop=true, easing=CosineFull }
]
let animAppear = [{ prop=AnimProp.translate, from=[sw(50),0], to=[0,0], duration=0.5, play=true, easing=InBack }]

let pivot = {pivot=[0,0.5]}
let tip = {
  rendObj = ROBJ_WORLD_BLUR
  padding = hdpx(2)
  size = [SIZE_TO_CONTENT,SIZE_TO_CONTENT]
  valign = ALIGN_CENTER
  transform = pivot
  animations = animAppear
  flow = FLOW_HORIZONTAL
  children = [
    @(){
      rendObj = ROBJ_TEXT
      text = loc(isSpectator.value ? "tips/spectator_downed_tip" : "tips/downed_tip", {
        timeLeft = format("%d", max(downedEndTime.value - curTime.value, 0.0))
      })
      color = color0
      transform = pivot
      watch = [downedEndTime, curTime, isSpectator]
      animations = animColor
    }.__update(fontBody)
  ]
}
let function mkTip(){//try to avoid subscribe on timechange - to safe performance and clear profiler
  let needTip = Computed(@()
      (downedEndTime.value > curTime.value) && ((medkitEndTime.value < curTime.value) || (medkitStartTime.value + overlapTipWithHeal > curTime.value)))
  return @(){
    watch = needTip
    size = SIZE_TO_CONTENT
    children = needTip.value ? tip : null
  }
}
return function() {
  return {
    watch = isInDowned
    size = SIZE_TO_CONTENT
    children = !isInDowned.value ? null : mkTip()
  }
}

