from "%enlSqGlob/ui_library.nut" import *

let sClassesCfg = require("%enlist/soldiers/model/config/sClassesConfig.nut")
let armyEffects = require("%enlist/soldiers/model/armyEffects.nut")
let { curArmy } = require("%enlist/soldiers/model/state.nut")

let TRAINING_ORDER = "soldier_order"
let trainingPrices = Computed(@() sClassesCfg.value.reduce(function(res, cfgClass, sClass) {
  let { upgradeOrdersRequire = [] } = cfgClass
  if (upgradeOrdersRequire.len() > 0)
    res[sClass] <- upgradeOrdersRequire
  return res
}, {}))

let function getTrainingPrice(sClass, sTier, pricesTable, steps = 1) {
  let prices = pricesTable?[sClass] ?? []
  return (prices?[min(sTier, prices.len() - 1)] ?? 1) * steps
}

let maxTrainByClass = Computed(@() armyEffects.value?[curArmy.value].class_training ?? {})

return {
  TRAINING_ORDER
  trainingPrices
  getTrainingPrice
  maxTrainByClass
}
