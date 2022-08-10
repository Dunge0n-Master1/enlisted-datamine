from "%enlSqGlob/ui_library.nut" import *

let {selfHealMedkits} = require("%ui/hud/state/total_medkits.nut")
let {fastThrowExclusive, weaponSlots, EWS_NUM } = require("%ui/hud/state/hero_weapons.nut")
let { weaponWidget, weaponWidgetDefaultWidth } = require("player_weapon_widget.nut")
let getWeaponHotkeyWidget = require("player_weapon_hotkey.nut")
let { hasHeroFlask, heroFlaskInfo } = require("%ui/hud/state/flask.nut")
let { hasHeroBinocular, binocularInfo } = require("%ui/hud/state/binocular.nut")

let equipItemsGap = hdpx(4)
let weaponHotkeys = array(4).map(@(_, i) "Human.Weapon{0}".subst(i+1))
weaponHotkeys.append(fastThrowExclusive.value ? "Human.Throw" : "Human.GrenadeNext")
weaponHotkeys.append("Human.SpecialItemSlot")

let mainWeapons = function(){
  let children = array(EWS_NUM)
  foreach (idx, weaponState in (weaponSlots ?? [])) {
    if (idx not in children)
      continue
    let hint = getWeaponHotkeyWidget(weaponHotkeys[idx], weaponState!= null)
    children[idx] = weaponWidget({weaponState, idx, hint })
  }
  return children
}()

let binocularWidget = weaponWidget({ weaponState = binocularInfo, hint = getWeaponHotkeyWidget("Human.UseBinocular", true), doMemoize=true})

let flaskHint = getWeaponHotkeyWidget("Inventory.UseFlask", true)

let function weaponItems() {
  let children = clone mainWeapons

  if (hasHeroBinocular.value) {
    children.append(binocularWidget)
  }

  let equipChildren = []
  let equipCount = (selfHealMedkits.value > 0 ? 1 : 0) +
    (hasHeroFlask.value ? 1 : 0)

  if (selfHealMedkits.value > 0 ) {
    let medkits = {name=loc("hud/medkits"), curAmmo = selfHealMedkits.value}
    let hint = getWeaponHotkeyWidget("Inventory.UseMedkit", true)
    equipChildren.append(weaponWidget({
      weapon = medkits,
      hint,
      width = weaponWidgetDefaultWidth/equipCount - (equipCount > 1 ? equipItemsGap : 0)
    }))
  }
  if (hasHeroFlask.value) {
    equipChildren.append(weaponWidget({ weaponState = heroFlaskInfo, hint = flaskHint, width = weaponWidgetDefaultWidth/equipCount }))
  }

  children.append({
    flow = FLOW_HORIZONTAL
    gap = equipItemsGap
    children = equipChildren
  })
  return {
    flow = FLOW_VERTICAL
    valign = ALIGN_BOTTOM
    halign = ALIGN_RIGHT
    gap = hdpx(4)
    watch = [
      selfHealMedkits,
      fastThrowExclusive,
      hasHeroFlask,
      hasHeroBinocular,
    ]
    children
  }
}


return {
  weaponItems
}
