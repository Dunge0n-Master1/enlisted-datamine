from "%enlSqGlob/ui_library.nut" import *

let { forcedMinimalHud } = require("%ui/hud/state/hudGameModes.nut")
let {selfHealMedkits, selfReviveMedkits} = require("%ui/hud/state/total_medkits.nut")
let {hp, maxHp, isAlive, isDowned, isHealContinuousInput} = require("%ui/hud/state/health_state.nut")
let {isUnderWater, isSwimming} = require("%ui/hud/state/hero_water_state.nut")
let {isBurning} = require("%ui/hud/state/burning_state_es.nut")
let {canSelfReviveByHealing} = require("%ui/hud/state/downed_state.nut")
let isFreeFall = require("%ui/hud/state/free_fall_state.nut")
let {isParachuteOpened} = require("%ui/hud/state/parachute_state.nut")
let {get_time_msec} = require("dagor.time")
let {medkitEndTime} = require("%ui/hud/state/entity_use_state.nut")
let timeState = require("%ui/hud/state/time_state.nut")
let uiTime = require("%ui/hud/state/ui_time.nut").curTimePerSec
let {tipCmp} = require("%ui/hud/huds/tips/tipComponent.nut")
let {hasRepairKit, hasExtinguisher, canMaintainVehicle, isRepairRequired, isExtinguishRequired} = require("%ui/hud/state/vehicle_maintenance_state.nut")

let color0 = Color(200,40,40,110)
let color1 = Color(200,200,40,180)
const stopAnimateAfter = 15
const hideAfter = 25

let needUseMed = Computed(function() {
  let ctime = timeState.curTime.value
  let needSelfHeal = !isDowned.value && selfHealMedkits.value > 0 && (hp.value > 0 && maxHp.value > 0 && (hp.value / maxHp.value < 0.85))
  let needSelfRevive = isDowned.value && (canSelfReviveByHealing.value && selfReviveMedkits.value > 0)
  return !isUnderWater.value && !isSwimming.value && isHealContinuousInput.value &&
    (needSelfHeal || needSelfRevive) && isAlive.value && (medkitEndTime.value < ctime) && !isBurning.value
})

let extinguishAvailable = Computed(@() canMaintainVehicle.value && hasExtinguisher.value && isExtinguishRequired.value)
let repairAvailable = Computed(@() canMaintainVehicle.value && hasRepairKit.value && isRepairRequired.value)
let canHeal = Computed(@() !extinguishAvailable.value && !repairAvailable.value && !isFreeFall.value && !isParachuteOpened.value)
let needMedTip = Computed(@() canHeal.value && needUseMed.value)

let showedMedTipAtTime = mkWatched(persist, "showedMedTipAtTime", 0)

needMedTip.subscribe(function(need) {
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
    watch = [showedMedTipAtTime, uiTime, needUseMed, forcedMinimalHud]
    children = (showedMedTipAtTime.value > uiTime.value - hideAfter)
      ? (needUseMed.value
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
  if (!needMedTip.value)
    return
  if (showedMedTipAtTime.value + stopAnimateAfter < time)
    anim_skip(trigger)
  else
    anim_start(trigger)
})

return function() {
  return {
    watch = [needMedTip]
    size = SIZE_TO_CONTENT
    children = !needMedTip.value ? null : htip
  }
}
