from "%enlSqGlob/ui_library.nut" import *

let buySquadWindow = require("buySquadWindow.nut")
let buyShopItem = require("buyShopItem.nut")
let activatePremiumBttn = require("activatePremiumBtn.nut")
let viewShopItemsScene = require("viewShopItemsScene.nut")
let { allItemTemplates } = require("%enlist/soldiers/model/all_items_templates.nut")
let { shopItemContentCtor, curArmyShopFolder, purchaseIsPossible, setCurArmyShopPath
} = require("armyShopState.nut")
let { shopItemLockedMsgBox, mkShopItemUsage, mkDynamicProductView, mkProductView
} = require("shopPkg.nut")
let checkLootRestriction = require("hasLootRestriction.nut")
let { curArmyData } = require("%enlist/soldiers/model/state.nut")
let { needFreemiumStatus } = require("%enlist/campaigns/freemiumState.nut")
let shopItemFreemiumMsgBox = require("%enlist/shop/shopItemFreemiumMsgBox.nut")

let function shopItemAction(shopItem, curLevel, personalOffer = null) {
  let { armyLevel = 0, isFreemium = false } = shopItem?.requirements
  let { guid = "" } = curArmyData.value
  let { squads = [] } = shopItem
  let squad = squads.findvalue(@(s) s.armyId == guid) ?? squads?[0]
  let isBuyingWithGold = shopItem?.curShopItemPrice.currencyId == "EnlistedGold"

  let crateContent = shopItemContentCtor(shopItem)
  let hasItemContent = crateContent == null ? false
    : (crateContent.value?.content.items ?? {}).len() > 0
  let { x = 0, y = 0 } = crateContent?.value.content.itemsAmount
  let { soldierRareMax = -1, soldierTierMin = -1, items = {} } = crateContent?.value.content
  let isLootBox = x != y || soldierRareMax != soldierTierMin || items.len() > 1
  if ((shopItem?.offerContainer ?? "") != "")
    setCurArmyShopPath((clone curArmyShopFolder.value.path).append(shopItem))
  else if (isFreemium && needFreemiumStatus.value)
    shopItemFreemiumMsgBox()
  else if (armyLevel > curLevel)
    shopItemLockedMsgBox(armyLevel)
  else if (purchaseIsPossible.value) {
    let description = mkShopItemUsage(crateContent, allItemTemplates)
    let productView = mkDynamicProductView(shopItem.guid, allItemTemplates, crateContent)
    if (squad != null && isBuyingWithGold)
      buySquadWindow({
        shopItem
        productView
        armyId = squad.armyId
        squadId = squad.id
        pOfferGuid = personalOffer?.guid
      })
    else {
      let buyItemAction = @() buyShopItem({
        shopItem
        activatePremiumBttn
        productView
        description
        viewBtnCb = hasItemContent ? @() viewShopItemsScene(shopItem) : null
        pOfferGuid = personalOffer?.guid
      })
      if (!isLootBox)
        buyItemAction()
      else
        checkLootRestriction(
            buyItemAction,
            {
              itemView = mkProductView(shopItem, allItemTemplates, crateContent)
              description
            }
          )
    }
  }
}

return shopItemAction
