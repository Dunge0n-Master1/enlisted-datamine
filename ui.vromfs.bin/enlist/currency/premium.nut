from "%enlSqGlob/ui_library.nut" import *

let { premium } = require("%enlist/meta/servProfile.nut")
let serverTime = require("%enlSqGlob/userstats/serverTime.nut")

let premiumEndTime = Computed(@() (premium.value?.premium_data.endsAtMs ?? 0) / 1000)

let hasPremium = Computed(@() premiumEndTime.value > serverTime.value)

let premiumActiveTime = Computed(@()
  max(premiumEndTime.value - serverTime.value, 0))

console_register_command(@() console_print(premiumActiveTime.value), "meta.showPremiumLeft")

return {
  hasPremium
  premiumEndTime
  premiumActiveTime
}
