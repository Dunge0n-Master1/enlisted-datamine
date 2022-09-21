from "%enlSqGlob/ui_library.nut" import *

let { premium } = require("%enlist/meta/servProfile.nut")
let serverTime = require("%enlSqGlob/userstats/serverTime.nut")
let { gameProfile } = require("%enlist/soldiers/model/config/gameProfile.nut")

let premiumEndTime = Computed(@() (premium.value?.premium_data.endsAtMs ?? 0) / 1000)

let hasPremium = Computed(@() premiumEndTime.value > serverTime.value)

let premiumBonusesFields = {
  premiumExpMul = 0.0
  maxSquadsInBattle = 0
  maxInfantrySquads = 0
  maxBikeSquads = 0
  maxVehicleSquads = 0
  soldiersReserve = 0
}.map(@(def, key) Computed(@() gameProfile.value?.premiumBonuses[key] ?? def))

let premiumActiveTime = Computed(@()
  max(premiumEndTime.value - serverTime.value, 0))

console_register_command(@() console_print(premiumActiveTime.value), "meta.showPremiumLeft")

return {
  hasPremium
  premiumEndTime
  premiumActiveTime
}.__update(premiumBonusesFields)
