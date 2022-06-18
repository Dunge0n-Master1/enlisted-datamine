from "%enlSqGlob/ui_library.nut" import *

let { curArmy } = require("%enlist/soldiers/model/state.nut")
let { hasPremium } = require("%enlist/currency/premium.nut")
let { bonusesList } = require("%enlist/currency/bonuses.nut")
let { isAvailableByLimit } = require("%enlist/shop/armyShopState.nut")
let { shopItems } = require("%enlist/shop/shopItems.nut")
let { purchasesCount } = require("%enlist/meta/profile.nut")

let hasSquadsEffects = @(armyEffects) (armyEffects?.maxSquadsInBattle ?? 0) > 0
  || (armyEffects?.maxInfantrySquads ?? 0) > 0
  || (armyEffects?.maxBikeSquads ?? 0) > 0
  || (armyEffects?.maxVehicleSquads ?? 0) > 0

let sellingBonusData = Computed(function() {
  if (!hasPremium.value)
    return null

  let bonusId = bonusesList.value.findindex(@(bonus)
    bonus.armies.contains(curArmy.value) && hasSquadsEffects(bonus.armyEffects))
  if (bonusId == null)
    return null

  let res = shopItems.value.findvalue(@(shopItem)
    (shopItem?.bonusId ?? "") == bonusId)
  return isAvailableByLimit(res, purchasesCount.value) ? res : null
})

let armySlotItem = Computed(@() shopItems.value?[sellingBonusData.value?.guid])

let armySlotDiscount = Computed(@() armySlotItem.value?.discountInPercent ?? 0)

return {
  armySlotDiscount
  armySlotItem
}
