from "%enlSqGlob/ui_library.nut" import *

let buySquadWindow = require("buySquadWindow.nut")
let buyShopItem = require("buyShopItem.nut")
let shopItemFreemiumMsgBox = require("%enlist/shop/shopItemFreemiumMsgBox.nut")
let activatePremiumBttn = require("activatePremiumBtn.nut")
let viewShopItemsScene = require("viewShopItemsScene.nut")
let checkLootRestriction = require("hasLootRestriction.nut")

let { curArmyData } = require("%enlist/soldiers/model/state.nut")
let { CAMPAIGN_NONE, needFreemiumStatus } = require("%enlist/campaigns/campaignConfig.nut")
let { allItemTemplates } = require("%enlist/soldiers/model/all_items_templates.nut")
let { shopItemContentCtor, purchaseIsPossible } = require("armyShopState.nut")
let {
  shopItemLockedMsgBox, mkMsgBoxView, mkShopItemInfoBlock, mkProductView
} = require("shopPkg.nut")


let function shopItemClick(shopItem) {
  let { guid = "", level = 0 } = curArmyData.value
  let { requirements = null, curShopItemPrice = null, squads = [] } = shopItem
  let { armyLevel = 0, campaignGroup = CAMPAIGN_NONE } = requirements

  if (campaignGroup != CAMPAIGN_NONE && needFreemiumStatus.value)
    shopItemFreemiumMsgBox()
  else if (armyLevel > level)
    shopItemLockedMsgBox(armyLevel)
  else if (!purchaseIsPossible.value)
    return

  let countWatched = Watched(1)
  let crateContent = shopItemContentCtor(shopItem)
  let hasItemContent = crateContent == null ? false
    : (crateContent.value?.content.items ?? {}).len() > 0

  let productView = mkMsgBoxView(shopItem, crateContent, countWatched)

  let isBuyingWithGold = curShopItemPrice?.currencyId == "EnlistedGold"
  let squad = squads.findvalue(@(s) s.armyId == guid) ?? squads?[0]
  if (squad != null && isBuyingWithGold) {
    buySquadWindow({
      shopItem
      productView
      armyId = squad.armyId
      squadId = squad.id
    })
    return
  }

  let description = mkShopItemInfoBlock(crateContent)
  let buyItemActionCb = @() buyShopItem({
    shopItem
    activatePremiumBttn
    productView
    description
    viewBtnCb = hasItemContent ? @() viewShopItemsScene(shopItem) : null
    countWatched
  })
  let itemView = mkProductView(shopItem, allItemTemplates, crateContent)
  checkLootRestriction(buyItemActionCb, { itemView, description }, crateContent)
}

return shopItemClick
