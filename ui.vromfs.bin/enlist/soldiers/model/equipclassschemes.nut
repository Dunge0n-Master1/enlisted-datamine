from "%enlSqGlob/ui_library.nut" import *

let { configs } = require("%enlist/meta/configs.nut")
let { equipSchemesByArmy } = require("%enlist/soldiers/model/all_items_templates.nut")
let { trimUpgradeSuffix } = require("%enlSqGlob/ui/itemsInfo.nut")

let equipSchemesByClass = Computed(@() configs.value?.equip_classes ?? {})

local function getEquipClasses(armyId, basetpl, itemType) {
  basetpl = trimUpgradeSuffix(basetpl)
  let classList = {}
  let classSchemes = equipSchemesByClass.value?[armyId] ?? {}
  foreach (sClass, schemeId in classSchemes) {
    let schemeList = equipSchemesByArmy.value?[armyId][schemeId] ?? {}
    foreach (scheme in schemeList) {
      let { items = [], itemTypes = [] } = scheme
      if ((itemTypes.len() == 0 && items.len() == 0)
          || itemTypes.contains(itemType)
          || items.contains(basetpl)) {
        classList[sClass] <- true
        break;
      }
    }
  }
  return classList.keys()
}

return getEquipClasses