from "%enlSqGlob/ui_library.nut" import *

let buySquadWindow = require("buySquadWindow.nut")
let buyShopItem = require("buyShopItem.nut")
let activatePremiumBttn = require("activatePremiumBtn.nut")
let viewShopItemsScene = require("viewShopItemsScene.nut")
let { allItemTemplates } = require("%enlist/soldiers/model/all_items_templates.nut")
let { shopItemContentCtor, curArmyShopFolder, purchaseIsPossible, setCurArmyShopPath
} = require("armyShopState.nut")
let { shopItemLockedMsgBox, mkShopItemInfoBlock, mkMsgBoxView, mkProductView
} = require("shopPkg.nut")
let checkLootRestriction = require("hasLootRestriction.nut")
let { curArmyData } = require("%enlist/soldiers/model/state.nut")
let { CAMPAIGN_NONE, needFreemiumStatus } = require("%enlist/campaigns/campaignConfig.nut")
let shopItemFreemiumMsgBox = require("%enlist/shop/shopItemFreemiumMsgBox.nut")

let function shopItemAction(shopItem, curLevel) {
  let { armyLevel = 0, campaignGroup = CAMPAIGN_NONE } = shopItem?.requirements
  let { guid = "" } = curArmyData.value
  let { squads = [] } = shopItem
  let squad = squads.findvalue(@(s) s.armyId == guid) ?? squads?[0]
  let isBuyingWithGold = shopItem?.curShopItemPrice.currencyId == "EnlistedGold"
  let countWatched = Watched(1)
  let crateContent = shopItemContentCtor(shopItem)
  let hasItemContent = crateContent == null ? false
    : (crateContent.value?.content.items ?? {}).len() > 0

  if ((shopItem?.offerContainer ?? "") != "")
    setCurArmyShopPath((clone curArmyShopFolder.value.path).append(shopItem))
  else if (campaignGroup != CAMPAIGN_NONE && needFreemiumStatus.value)
    shopItemFreemiumMsgBox()
  else if (armyLevel > curLevel)
    shopItemLockedMsgBox(armyLevel)
  else if (purchaseIsPossible.value) {
    let description = mkShopItemInfoBlock(crateContent)
    let productView = mkMsgBoxView(shopItem, crateContent, countWatched)
    if (squad != null && isBuyingWithGold)
      buySquadWindow({
        shopItem
        productView
        armyId = squad.armyId
        squadId = squad.id
      })
    else {
      let buyItemAction = @() buyShopItem({
        shopItem
        activatePremiumBttn
        productView
        description
        viewBtnCb = hasItemContent ? @() viewShopItemsScene(shopItem) : null
        countWatched
      })
      checkLootRestriction(buyItemAction,
        {
          itemView = mkProductView(shopItem, allItemTemplates, crateContent)
          description
        },
        crateContent)
    }
  }
}

return shopItemAction
