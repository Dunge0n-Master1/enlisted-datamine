import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let {body_txt} = require("%enlSqGlob/ui/fonts_style.nut")
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

let cannotDigAtPosTip = @(lastDigResult) tipCmp({
  text = loc(lastDigResult == CanTerraformCheckResult.NearByObjects
             ? "hint/cannotDigAtPosNearByObjects"
             : "hint/cannotDigAtPos")
}.__update(body_txt))

return @() {
  watch = [curWeaponWeapType, lastDigResult]
  children = curWeaponWeapType.value == "melee" && lastDigResult.value != CanTerraformCheckResult.Successful
           ? cannotDigAtPosTip(lastDigResult.value)
           : null
}