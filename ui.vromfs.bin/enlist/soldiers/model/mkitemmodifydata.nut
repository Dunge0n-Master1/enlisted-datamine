from "%enlSqGlob/ui_library.nut" import *

let { itemUpgrades, itemDisposes, getModifyConfig } = require("config/itemsModifyConfig.nut")
let { ceil } = require("%sqstd/math.nut")
let { getModifyItemGuid } = require("selectItemState.nut")
let { getLinkedArmyName, isObjLinkedToAnyOfObjects } = require("%enlSqGlob/ui/metalink.nut")
let { upgradeLocksByArmy, upgradeCostMultByArmy, disposeCountMultByArmy
} = require("%enlist/researches/researchesSummary.nut")
let { maxCampaignLevel, armyItemCountByTpl } = require("state.nut")
let { allItemTemplates, findItemTemplate } = require("all_items_templates.nut")
let { disabledSectionsData } = require("%enlist/mainMenu/disabledSections.nut")
let { trimUpgradeSuffix } = require("%enlSqGlob/ui/itemsInfo.nut")
let { curUpgradeDiscount } = require("%enlist/campaigns/campaignConfig.nut")
let { curCampSoldiers } = require("%enlist/soldiers/model/state.nut")

const MODIFY_ITEM_REQ_LVL = 3

let canModifyItems = Computed(@() maxCampaignLevel.value >= MODIFY_ITEM_REQ_LVL
  && !(disabledSectionsData.value?.LOGISTICS ?? false))

let canUpgrade = @(item)
   (item?.guid ?? "") != "" && (item?.upgradeitem ?? "") != ""

let mkItemUpgradeData = function(item){
  if (!canUpgrade(item))
    return Computed(@() { isUpgradable = false })

  let { basetpl = "", tier = 0, upgradeitem = "" } = item
  let itemBaseTpl = trimUpgradeSuffix(basetpl)
  let armyId = getLinkedArmyName(item)
  return Computed(function() {

    let res = {
      isUpgradable = false
      isResearchRequired = false
      armyId
      hasEnoughOrders = false
      upgradeMult = null
      itemBaseTpl
      upgradeitem
      iGuid = null
      priceOptions = []
    }

    if (!canModifyItems.value)
      return res

    let itemType = findItemTemplate(allItemTemplates, armyId, itemBaseTpl).itemtype
    let upgrades = getModifyConfig(itemUpgrades.value, tier, itemType)
    if (upgrades == null)
      return res

    let lockedUpgrades = upgradeLocksByArmy.value?[armyId] ?? []
    if (lockedUpgrades.indexof(upgradeitem) != null)
      return res.__update({ isUpgradable = true, isResearchRequired = true })

    let iGuid = getModifyItemGuid(item, true)
    local upgradeMult = upgradeCostMultByArmy.value?[armyId][itemBaseTpl] ?? 1.0
    upgradeMult *= 1.0 - curUpgradeDiscount.value
    local canBuy = false

    foreach (orderTpl, price in upgrades) {
      local orderReq = price.count
      if (!price?.isFixedPrice)
        orderReq = ceil(orderReq * upgradeMult).tointeger()
      let ordersInStock = armyItemCountByTpl.value?[orderTpl] ?? 0
      let hasEnoughOrders = orderReq > 0 && ordersInStock >= orderReq
      canBuy = canBuy || hasEnoughOrders
      res.priceOptions.append({ orderTpl, orderReq, ordersInStock, hasEnoughOrders })
    }
    if (res.priceOptions.len() > 0)
      res.__update({
        hasEnoughOrders = canBuy,
        isUpgradable = true,
        iGuid, itemBaseTpl, upgradeMult
      })
    return res
  })
}

let canDispose = @(item) (item?.guid ?? "") != ""
  && !(item?.isFixed ?? false)
  && (item?.sign ?? 0) == 0
  && (item?.upgradesId ?? "") != ""

let mkItemDisposeData = function(item) {
  if (!canDispose(item))
    return Computed(@() { isDisposable = false })

  let { basetpl = "", tier = 0 } = item
  let itemBaseTpl = trimUpgradeSuffix(basetpl)
  let armyId = getLinkedArmyName(item)
  return Computed(function() {
    let res = {
      isDisposable = false
      isDestructible = false
      isRecyclable = false
      armyId
      orderCount = 0
      orderTpl = ""
      disposeMult = null
      itemBaseTpl
      guids = null
    }
    if (!canModifyItems.value)
      return res

    let itemType = findItemTemplate(allItemTemplates, armyId, itemBaseTpl).itemtype
    local disposes = getModifyConfig(itemDisposes.value, tier, itemType)
    if (disposes == null)
      return res

    disposes = disposes.values()[0] // TODO suggest multiple selection instead of first price

    let { isDestructible = false, count = 0 } = disposes
    if (!isDestructible && itemBaseTpl == basetpl)
      return res

    local disposeMult = 1.0 + (disposeCountMultByArmy.value?[armyId][itemBaseTpl] ?? 0.0)
    disposeMult *= 1.0 - curUpgradeDiscount.value
    let orderCount = ceil(count * disposeMult).tointeger()
    let orderTpl = disposes.itemTpl
    return res.__update({
      isDisposable = true,
      isRecyclable = orderCount <= 0,
      guids = isObjLinkedToAnyOfObjects(item, curCampSoldiers.value ?? {}) ? null
        : item?.guids ?? [item?.guid]
      isDestructible, itemBaseTpl, disposeMult, orderTpl, orderCount
    })
  })
}

return {
  canModifyItems
  mkItemUpgradeData
  mkItemDisposeData
}