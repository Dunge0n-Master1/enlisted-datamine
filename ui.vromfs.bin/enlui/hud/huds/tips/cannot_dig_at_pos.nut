import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let {fontBody} = require("%enlSqGlob/ui/fontsStyle.nut")
let {CanTerraformCheckResult} = require("%enlSqGlob/dasenums.nut")
let {tipCmp} = require("%ui/hud/huds/tips/tipComponent.nut")
let {curWeaponWeapType} = require("%ui/hud/state/hero_weapons.nut")
let {EventOnDig} = require("dasevents")

let lastDigResult = Watched(CanTerraformCheckResult.Successful)
let hideTip = @() lastDigResult(CanTerraformCheckResult.Successful)

const TIP_SHOW_TIME = 5

ecs.register_es("on_event_dig_es",
  {
    [EventOnDig] = function(evt, _eid, _comp) {
      if (evt.canTerraformCheckResult != CanTerraformCheckResult.Successful) {
        gui_scene.resetTimeout(TIP_SHOW_TIME, hideTip)
      }
      lastDigResult(evt.canTerraformCheckResult)
    }
  },
  { comps_rq=["watchedByPlr"] }
)

let cannotDigAtPosTip = @(last_dig_result) tipCmp({
  text = loc(last_dig_result == CanTerraformCheckResult.NearByObjects ? "hint/cannotDigAtPosNearByObjects" :
             last_dig_result == CanTerraformCheckResult.NearByBuildingPreview ? "hint/cannotDigAtPosNearByBuildingPreview"
             : "hint/cannotDigAtPos")
}.__update(fontBody))

return @() {
  watch = [curWeaponWeapType, lastDigResult]
  children = curWeaponWeapType.value == "melee" && lastDigResult.value != CanTerraformCheckResult.Successful
           ? cannotDigAtPosTip(lastDigResult.value)
           : null
}