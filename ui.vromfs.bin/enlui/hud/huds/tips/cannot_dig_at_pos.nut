import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let {body_txt} = require("%enlSqGlob/ui/fonts_style.nut")
let {tipCmp} = require("%ui/hud/huds/tips/tipComponent.nut")
let {curWeapon} = require("%ui/hud/state/hero_state.nut")
let {EventOnDig} = require("dasevents")

let needShowTip = Watched(false)
let showTip = Computed(
  @() curWeapon.value?.weapType == "melee" && needShowTip.value
)
let hideTip = @() needShowTip(false)

const TIP_SHOW_TIME = 5

ecs.register_es("on_event_dig_es",
  {
    [EventOnDig] = function(evt, _eid, _comp) {
      if (evt.isSuccessful){
        needShowTip(false)
        return
      }

      gui_scene.resetTimeout(TIP_SHOW_TIME, hideTip)
      needShowTip(true)
    }
  },
  { comps_rq=["watchedByPlr"] }
)

let cannotDigAtPosTip = tipCmp({
  text = loc("hint/cannotDigAtPos")
}.__update(body_txt))

return @() {
  watch = showTip
  children = showTip.value ? cannotDigAtPosTip : null
}