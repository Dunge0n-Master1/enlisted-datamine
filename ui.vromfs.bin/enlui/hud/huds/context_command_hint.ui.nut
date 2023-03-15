import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let { sub_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let {tipCmp} = require("%ui/hud/huds/tips/tipComponent.nut")
let contextCommandState = require("%ui/hud/state/contextCommandState.nut")
let { ContextCommand } = require("%enlSqGlob/dasenums.nut")
let engineersInSquad = require("%ui/hud/state/engineers_in_squad.nut")

return function () {
  local tip = null
  let orderType = contextCommandState.orderType.value
  let orderUseEntity = contextCommandState.orderUseEntity.value
  local text = null;
  switch (orderType) {
    case ContextCommand.ECC_DEFEND_POINT:
      if (orderUseEntity != ecs.INVALID_ENTITY_ID) {
        let capZoneTag = ecs.obsolete_dbg_get_comp_val(orderUseEntity, "capzone")
        if (capZoneTag != null) {
          let zoneName = loc(ecs.obsolete_dbg_get_comp_val(orderUseEntity, "capzone__caption", ""), "")
          if (zoneName.len() != 0) {
            let zoneTitle = ecs.obsolete_dbg_get_comp_val(orderUseEntity, "capzone__title", "")
            text = loc("hud/control_zone_name", {tag = zoneTitle, name = zoneName})
          } else
            text = loc("hud/control_zone")
        } else // vehicle
          text = loc("squad_orders/control_vehicle")
      } else {
        text = loc("squad_orders/defend_point")
      }
      break
    case ContextCommand.ECC_CANCEL:
      text = loc("squad_orders/cancel_order")
      break
    case ContextCommand.ECC_REVIVE:
      text = loc("squad_orders/revive_me")
      break
    case ContextCommand.ECC_BRING_AMMO:
      text=loc("squad_orders/bring_ammo")
      break
    case ContextCommand.ECC_ATTACK_TARGET:
      text=loc("squad_orders/attack_target")
      break
    case ContextCommand.ECC_BUILD:
      let isPreview = ecs.obsolete_dbg_get_comp_val(orderUseEntity, "builder_preview") != null
      text = engineersInSquad.value > 1
        ? loc(isPreview ? "squad_orders/build" : "squad_orders/dismantle")
        : null
      break
    case ContextCommand.ECC_PLANT_BOMB:
      text=loc("squad_orders/plant_bomb")
      break
    case ContextCommand.ECC_DEFUSE_BOMB:
      text=loc("squad_orders/defuse_bomb")
      break
  }

  if (text != null) {
    tip = tipCmp({
      text,
      inputId = "Human.ContextCommand",
    }.__update(sub_txt))
  }

  return {
    watch = [
      contextCommandState.orderType
      contextCommandState.orderUseEntity
      engineersInSquad
    ]

    children = tip
  }
}
