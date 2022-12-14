from "%enlSqGlob/ui_library.nut" import *

let { forcedMinimalHud } = require("%ui/hud/state/hudGameModes.nut")
let {selfHealMedkits} = require("%ui/hud/state/total_medkits.nut")
let {needDisplayHealTip} = require("%ui/hud/state/health_state.nut")
let {get_time_msec} = require("dagor.time")
let uiTime = require("%ui/hud/state/ui_time.nut").curTimePerSec
let {tipCmp} = require("%ui/hud/huds/tips/tipComponent.nut")

let color0 = Color(200,40,40,110)
let color1 = Color(200,200,40,180)
const stopAnimateAfter = 15
const hideAfter = 25

let showedMedTipAtTime = mkWatched(persist, "showedMedTipAtTime", 0)

needDisplayHealTip.subscribe(function(need) {
  if (need)
    showedMedTipAtTime((get_time_msec()/1000).tointeger())
  else
    showedMedTipAtTime(0)
})

let trigger = {}
let function mkTip(loc_text) {
  return tipCmp({
    inputId = "Inventory.UseMedkit"
    text = loc(loc_text)
    sound = {
      attach = {name="ui/need_reload", vol=0.1}
    }
    textColor = Color(200,40,40,110)
    transform = {pivot=[0,0.5]}
    animations = [{ prop=AnimProp.translate, from=[sw(50),0], to=[0,0], duration=0.5, play=true, easing=InBack}]
    textAnims = [
      { prop=AnimProp.color, from=color0, to=color1, duration=1.0, play=true, loop=true, easing=CosineFull, trigger = trigger}
      { prop=AnimProp.scale, from=[1,1], to=[1.0, 1.1], duration=3.0, play=true, loop=true, easing=CosineFull, trigger = trigger}
    ]
  })
}

let medkitTip = mkTip("tips/need_medkit")
let revivePerkTip = mkTip("tips/need_revive_perk")
let function htip(){
  return {
    size = SIZE_TO_CONTENT
    watch = [showedMedTipAtTime, uiTime, needDisplayHealTip, forcedMinimalHud]
    children = (showedMedTipAtTime.value > uiTime.value - hideAfter)
      ? (needDisplayHealTip.value
          ? !forcedMinimalHud.value ? medkitTip : null
          : revivePerkTip
        )
      : null
  }
}

local oldTotal = 0
selfHealMedkits.subscribe(function(v){
  if (v > oldTotal)
    anim_start(trigger)
  oldTotal = v
})
uiTime.subscribe(function(time){
  if (!needDisplayHealTip.value)
    return
  if (showedMedTipAtTime.value + stopAnimateAfter < time)
    anim_skip(trigger)
  else
    anim_start(trigger)
})

return function() {
  return {
    watch = [needDisplayHealTip]
    size = SIZE_TO_CONTENT
    children = !needDisplayHealTip.value ? null : htip
  }
}
