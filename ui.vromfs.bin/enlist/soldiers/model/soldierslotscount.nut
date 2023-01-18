from "%enlSqGlob/ui_library.nut" import *

let { configs } = require("%enlist/meta/configs.nut")
let { perksData, getTotalPerkValue } = require("soldierPerks.nut")
let { curCampSoldiers } = require("state.nut")
let { slotsIncrease } = require("%enlist/meta/profile.nut")
let perksList = require("%enlist/meta/perks/perksList.nut")
let { perksStatsCfg } = require("%enlist/meta/perks/perksStats.nut")

let slotTypeToPerk = Computed(@() configs.value?.perks.slotCountPerks ?? {})

let function soldierSlotsCount(soldierGuid, equipScheme) {
  let baseSlots = equipScheme.map(@(s) s?.listSize ?? 0)
    .filter(@(s) s > 0)
  if (baseSlots.len() == 0)
    return Watched({})
  return Computed(function() {
    let perks = perksData.value?[soldierGuid]
    local modSlots = baseSlots.map(@(val, slotType) slotType in slotTypeToPerk.value
      ? val + getTotalPerkValue(perksList.value, perksStatsCfg.value,
                                perks, slotTypeToPerk.value?[slotType]).tointeger()
      : val)
    let soldier = curCampSoldiers.value?[soldierGuid]
    if (soldier != null) {
      let incByItems = slotsIncrease.value?[soldierGuid]
      modSlots = modSlots.map(@(val, slotType) val + (incByItems?[slotType] ?? 0))
    }
    return modSlots
  })
}

return soldierSlotsCount