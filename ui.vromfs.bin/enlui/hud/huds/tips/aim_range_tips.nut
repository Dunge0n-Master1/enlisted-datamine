import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let { body_txt, sub_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let {isAiming} = require("%ui/hud/huds/crosshair_state_es.nut")
let showPlayerHuds = require("%ui/hud/state/showPlayerHuds.nut")
let {inPlane, isDriver, isGunner} = require("%ui/hud/state/vehicle_state.nut")
let {tipCmp} = require("%ui/hud/huds/tips/tipComponent.nut")
let { currentGunEid } = require("%ui/hud/state/hero_weapons.nut")

let entityAimRangePreset = Watched(0)
let aimRangeValues = Watched([])

let tipColor = Color(100,140,200,110)
let inactiveColor = Color(50,50,50,25)
let activeColor = Color(200,200,200,110)

let tipIncreaseAim = tipCmp({
  inputId = "Human.SightNext"
  text = loc("tips/increase_aim_range")
  textColor = tipColor
})

let tipDecreaseAim = tipCmp({
  inputId = "Human.SightPrev"
  text = loc("tips/decrease_aim_range")
  textColor = tipColor
})

ecs.register_es("aim_range_preset",{
  [["onChange"]] = function(eid,comp){
    if (eid == currentGunEid.value)
      entityAimRangePreset(comp["weap__current_sight_preset"])
  }
}, {comps_track=[["weap__current_sight_preset", ecs.TYPE_INT]]})

let aimRangePresetQuery = ecs.SqQuery("get_aim_range_preset",
  { comps_ro = [["weap__current_sight_preset", ecs.TYPE_INT]] })

let aimRangePresetsQuery = ecs.SqQuery("get_aim_range_presets",
  { comps_ro = [["sightPresets", ecs.TYPE_ARRAY]] })

  currentGunEid.subscribe(function(eid) {
  local preset = 0
  aimRangePresetQuery.perform(eid, @(_, comp) preset = comp["weap__current_sight_preset"])
  aimRangeValues(aimRangePresetsQuery(currentGunEid.value, @(_, comp) comp.sightPresets.getAll()))
  entityAimRangePreset(preset)
})

let canShowTip = Computed(@() showPlayerHuds.value && isAiming.value && !inPlane.value
                                  && !isDriver.value && !isGunner.value)

let needTip = Computed(@() canShowTip.value && aimRangeValues.value != null)

let function swithAimBtnTip (){
  return {
    watch = needTip
    size = SIZE_TO_CONTENT
    flow = FLOW_VERTICAL
    children = needTip.value ? [tipIncreaseAim, tipDecreaseAim] : null
  }
}

let function aimRangeValuesTip(){
  let res = {
    watch = [needTip, entityAimRangePreset, currentGunEid]
    size = SIZE_TO_CONTENT
    flow = FLOW_VERTICAL
    animations = [{prop = AnimProp.opacity, from = 0, to = 0,
                   duration = 0.1, play = true}]
  }

  if (!needTip.value)
    return res

  return res.__update({
      children = (aimRangeValues.value ?? []).map(@(item, idx)
        tipCmp({
          text = loc(item.loc)
          textColor = entityAimRangePreset.value == idx ? activeColor : inactiveColor
        }.__update(entityAimRangePreset.value == idx ? body_txt : sub_txt))
      )
    })
  }

return {
  swithAimBtnTip
  aimRangeValuesTip
}
