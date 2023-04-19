import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let { localPlayerEid } = require("%ui/hud/state/local_player.nut")
let { sendNetEvent, CmdOpenSupplyMenu, CmdCloseSupplyMenu, RequestApplySupplyScheme } = require("dasevents")
let paratroopersSupplySlots = require("%ui/hud/state/paratroopers_supply_slots.nut")
let mkPieItemCtor = require("%ui/hud/components/paratroopers_supply_menu_item_ctor.nut")

let radius = Watched(hdpx(365))
let elemSize = Computed(@() [(radius.value*0.35).tointeger(),(radius.value*0.35).tointeger()] )
let showSupplyMenu = mkWatched(persist, "showSupplyMenu", false)

let selectedSupplyMenuItemIdx = Watched(null)
let selectedBox = Watched(ecs.INVALID_ENTITY_ID)
let selectScheme = @(index) sendNetEvent(localPlayerEid.value, RequestApplySupplyScheme({boxEid=selectedBox.value, index}))

let mkMenuItem = @(slot, index) {
  action = @() selectScheme(index)
  text = slot?.text != null ? loc(slot?.text) : index
  ctor = mkPieItemCtor(slot)
}

let squadSupplyMenuItems = Computed(@() paratroopersSupplySlots.value.map(mkMenuItem))

ecs.register_es("paratroopers_supply_menu_ui_control",
  {
    [CmdOpenSupplyMenu] = function(evt, _eid, _comp) {
      showSupplyMenu(true)
      selectedBox(evt.boxEid)
    },
    [CmdCloseSupplyMenu] = function(evt, _eid, _comp) {
      showSupplyMenu(false)
      if (!evt.needApplyPreset) {
        selectedSupplyMenuItemIdx(null)
      }
    }
  },
  { comps_rq = ["localPlayer"] },
  { tags = "ui" })

return {
  squadSupplyMenuItems
  showSupplyMenu
  selectedSupplyMenuItemIdx
  radius
  elemSize
}
