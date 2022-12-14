from "%enlSqGlob/ui_library.nut" import *

let {iconByGameTemplate} = require("%enlSqGlob/ui/itemsInfo.nut")
let {
  defInsideBgColor, insideBorderColor, smallPadding
} = require("%enlSqGlob/ui/viewConst.nut")
let {configs} = require("%enlist/meta/configs.nut")
let {campItemsByLink} = require("%enlist/meta/profile.nut")

let function mkAmmo(item, soldierGuid, weapData, slotType, override = {}){
  let isWeapToIncreaseAmmo = slotType == "primary"

  return function() {
    local increase = 0
    if (isWeapToIncreaseAmmo){
      let slotsItems = campItemsByLink.value?[soldierGuid]
      let itemsToIncreaseAmmo = slotsItems
        ?.reduce(@(res,slot) res.extend(slot), [])
        .map(@(s) s?.basetpl)
        .filter(@(s) s != null) ?? []
      itemsToIncreaseAmmo.each(@(item)
        increase += configs.value?.equip_ammo_increase[item] ?? 0)
    }
    let ammoInGun = weapData.bullets
    let additionalAmmo = increase > 0
      ?  max((ammoInGun * item.ammonum * increase + 0.5).tointeger(), ammoInGun)
      : 0
    let totalAmmo = ammoInGun * item.ammonum + additionalAmmo
    let ammoInBag = totalAmmo - ammoInGun

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
          text = ammoInBag > 0 ? $"{ammoInGun}/{ammoInBag}" : ammoInGun
          fontSize = hdpx(12)
        }
      ]
    }.__update(override)
  }
}

return mkAmmo