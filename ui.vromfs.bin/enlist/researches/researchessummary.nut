from "%enlSqGlob/ui_library.nut" import *

let { curArmiesList } = require("%enlist/soldiers/model/state.nut")
let effectsConfig = require("%enlist/soldiers/model/config/effectsConfig.nut")
let armyEffects = require("%enlist/soldiers/model/armyEffects.nut")

let classSlotLocksByArmy = Computed(@()
  curArmiesList.value.reduce(function(res, armyId) {
    let unlockCfg = effectsConfig.value?[armyId].slot_unlock ?? {}
    let unlockEff = armyEffects.value?[armyId].slot_unlock ?? {}
    res[armyId] <- unlockCfg.map(function(list, sClass) {
      let slotsUnlocked = unlockEff?[sClass] ?? []
      return list.filter(@(slot) slotsUnlocked.indexof(slot) == null)
    })
    return res
  }, {}))

let upgradeLocksByArmy = Computed(@()
  curArmiesList.value.reduce(function(res, armyId) {
    let upgradeCfg = effectsConfig.value?[armyId].weapon_upgrades ?? []
    let upgradeEff = armyEffects.value?[armyId].weapon_upgrades ?? []
    res[armyId] <- upgradeCfg.filter(@(tmpl) upgradeEff.indexof(tmpl) == null)
    return res
  }, {}))

let upgradeCostMultByArmy = Computed(@()
  curArmiesList.value.reduce(function(res, armyId) {
    let discountTbl = armyEffects.value?[armyId].weapon_upgrade_discount ?? {}
    res[armyId] <- discountTbl.map(@(discount) max(0.0, 1.0 - discount))
    return res
  }, {}))

let disposeCountMultByArmy = Computed(@()
  curArmiesList.value.reduce(function(res, armyId) {
    res[armyId] <- armyEffects.value?[armyId].disassemble_bonus ?? {}
    return res
  }, {}))

return {
  classSlotLocksByArmy
  upgradeLocksByArmy
  upgradeCostMultByArmy
  disposeCountMultByArmy
}