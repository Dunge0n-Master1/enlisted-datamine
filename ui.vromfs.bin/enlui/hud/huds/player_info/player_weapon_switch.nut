from "%enlSqGlob/ui_library.nut" import *

let {selfHealMedkits} = require("%ui/hud/state/total_medkits.nut")
let {weaponsList, fastThrowExclusive} = require("%ui/hud/state/hero_state.nut")
let weaponSlots = require("%enlSqGlob/weapon_slots.nut")
let {showWeaponList} = require("show_weapon_list_state.nut")
let { weaponWidget, weaponWidgetDefaultWidth } = require("player_weapon_widget.nut")
let getWeaponHotkeyWidget = require("player_weapon_hotkey.nut")
let { hasHeroFlask } = require("%ui/hud/state/flask.nut")

let equipItemsGap = hdpx(4)

let function equipItems() {
  let equipChildren = []
  let equipCount = (selfHealMedkits.value > 0 ? 1 : 0) +
    (hasHeroFlask.value ? 1 : 0)

  if (selfHealMedkits.value > 0 ) {
    let medkits = {name=loc("hud/medkits"), instant = true, curAmmo = selfHealMedkits.value}
    let hint = getWeaponHotkeyWidget("Inventory.UseMedkit", true)
    equipChildren.append(weaponWidget({
      weapon = medkits,
      hint,
      width = weaponWidgetDefaultWidth/equipCount - (equipCount > 1 ? equipItemsGap : 0)
    }))
  }

  if (hasHeroFlask.value) {
    let flask = {name=loc("hud/flask"), instant = true, curAmmo = 0}
    let hint = getWeaponHotkeyWidget("Inventory.UseFlask", true)
    equipChildren.append(weaponWidget({ weapon = flask, hint, width = weaponWidgetDefaultWidth/equipCount }))
  }

  return {
    flow = FLOW_HORIZONTAL
    gap = equipItemsGap
    children = equipChildren
  }
}

let function weaponItems() {
  let children = []
  let weaponHotkeys = array(4).map(@(_, i) "Human.Weapon{0}".subst(i+1))
  weaponHotkeys.append(fastThrowExclusive.value ? "Human.Throw" : "Human.GrenadeNext")
  weaponHotkeys.append("Human.SpecialItemSlot")
  foreach (idx, weapon in (weaponsList.value ?? 0)) {
    if (idx == weaponSlots.EWS_SPECIAL && weapon?.name == "")
      continue
    let hint = getWeaponHotkeyWidget(weaponHotkeys[idx],  weapon?.name!="")
    children.append(weaponWidget({ weapon, hint }))
  }

  children.append(equipItems())

  return {
    flow = FLOW_VERTICAL
    valign = ALIGN_BOTTOM
    halign = ALIGN_RIGHT
    gap = hdpx(4)
    watch = [weaponsList, selfHealMedkits, fastThrowExclusive, hasHeroFlask]
    children
  }
}


let function weaponsListComp() {
  return {
    size = SIZE_TO_CONTENT
    watch = showWeaponList
    children = showWeaponList.value ? weaponItems : null
  }
}


return {
  weaponsListComp
  weaponItems
}
