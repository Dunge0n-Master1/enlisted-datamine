from "%enlSqGlob/ui_library.nut" import *

let { sub_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let {tipCmp} = require("%ui/hud/huds/tips/tipComponent.nut")
let {inVehicle} = require("%ui/hud/state/vehicle_state.nut")
let {showBigMap} = require("%ui/hud/menus/big_map.nut")
let {heroSquadNumAliveMembers, heroSquadOrderType, hasPersonalOrder} = require("%ui/hud/state/hero_squad.nut")
let {SquadOrder} = require("%enlSqGlob/dasenums.nut")
let { watchedHeroSquadMembers, isPersonalContextCommandMode } = require("%ui/hud/state/squad_members.nut")

let hasAnySquadmatePersonalOrder = @(members)
  members.findvalue(@(m) m.isAlive && m.isPersonalOrder) != null

let tipLocId = Computed(@()
  showBigMap.value || inVehicle.value || heroSquadNumAliveMembers.value <= 1 ? null
    : (isPersonalContextCommandMode.value && hasAnySquadmatePersonalOrder(watchedHeroSquadMembers.value))
      ? "squad_orders/cancel_personal_order"
    : (heroSquadOrderType.value != SquadOrder.ESO_FOLLOW_ME || hasPersonalOrder.value)
      ? "squad_orders/cancel_all_orders"
    : null
)

return function() {
  return {
    watch = tipLocId
    children = tipLocId.value == null
      ? null
      : tipCmp({
        text = loc(tipLocId.value),
        inputId = "Human.CancelContextCommand"
      }.__update(sub_txt))
  }
}
