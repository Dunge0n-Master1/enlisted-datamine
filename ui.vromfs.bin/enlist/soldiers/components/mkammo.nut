from "%enlSqGlob/ui_library.nut" import *

let { iconByGameTemplate } = require("%enlSqGlob/ui/itemsInfo.nut")
let {
  defInsideBgColor, insideBorderColor, smallPadding
} = require("%enlSqGlob/ui/viewConst.nut")
let { configs } = require("%enlist/meta/configs.nut")
let { campItemsByLink } = require("%enlist/meta/profile.nut")


let function calcAmmo(item, soldierGuid, weapData, slotType, configsVal, itemsByLink) {
  local increase = 0
  if (slotType == "primary") { // if is weapon to increase ammo
    let slotsItems = itemsByLink?[soldierGuid] ?? []
    let itemsToIncreaseAmmo = slotsItems
      .reduce(@(res,slot) res.extend(slot), [])
      .map(@(s) s?.basetpl)
      .filter(@(s) s != null) ?? []
    itemsToIncreaseAmmo.each(@(item)
      increase += configsVal?.equip_ammo_increase[item] ?? 0)
  }
  let ammoInGun = weapData.bullets
  let additionalAmmo = increase > 0
    ?  max((ammoInGun * item.ammonum * increase + 0.5).tointeger(), ammoInGun)
    : 0
  let totalAmmo = ammoInGun * item.ammonum + additionalAmmo
  let ammoInBag = totalAmmo - ammoInGun
  return { totalAmmo, ammoInBag, ammoInGun }
}


let mkAmmoSlot = @(item, soldierGuid, weapData, slotType, override = {})
  function() {
    let ammo = calcAmmo(item, soldierGuid, weapData, slotType, configs.value, campItemsByLink.value)
    return {
      watch = [configs, campItemsByLink]
      rendObj = ROBJ_BOX
      size = [hdpx(55),hdpx(45)]
      vplace = ALIGN_BOTTOM
      valign = ALIGN_CENTER
      hplace = ALIGN_RIGHT
      halign = ALIGN_CENTER
      margin = smallPadding
      flow = FLOW_VERTICAL
      fillColor = defInsideBgColor
      borderColor = insideBorderColor
      borderWidth = hdpx(1)
      children = [
        iconByGameTemplate(item.ammotemplate, {size = [hdpx(25), hdpx(25)]})
        {
          rendObj = ROBJ_TEXT
          text = ammo.ammoInBag > 0 ? $"{ammo.ammoInGun}/{ammo.ammoInBag}" : ammo.ammoInGun
          fontSize = hdpx(12)
        }
      ]
    }.__update(override)
  }


let mkAmmoInfo = @(item, soldierGuid, weapData, slotType, override = {})
  function() {
    let { color = null } = override
    let ammo = calcAmmo(item, soldierGuid, weapData, slotType, configs.value, campItemsByLink.value)
    return {
      watch = [configs, campItemsByLink]
      flow = FLOW_HORIZONTAL
      gap = smallPadding
      valign = ALIGN_CENTER
      children = [
        {
          size = [14, 14]
          rendObj = ROBJ_IMAGE
          image = Picture("!ui/skin#ammo_icon.svg:{0}:{0}:K".subst(16))
          color
        }
        {
          rendObj = ROBJ_TEXT
          text = ammo.ammoInBag > 0 ? $"{ammo.ammoInGun}/{ammo.ammoInBag}" : ammo.ammoInGun
          fontSize = hdpx(14)
          color
        }
      ]
    }.__update(override)
  }


return {
  mkAmmoSlot
  mkAmmoInfo
}
