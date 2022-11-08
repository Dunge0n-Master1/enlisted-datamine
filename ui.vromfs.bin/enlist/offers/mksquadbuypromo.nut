from "%enlSqGlob/ui_library.nut" import *

let { BtnBdNormal, borderColor } = require("%ui/style/colors.nut")
let { unitSize } = require("%enlSqGlob/ui/viewConst.nut")
let { allItemTemplates } = require("%enlist/soldiers/model/all_items_templates.nut")
let { curArmyShopItems, shopItemContentCtor } = require("%enlist/shop/armyShopState.nut")
let { mkShopItemView, mkShopItemPriceLine, mkShopItemInfoBlock
} = require("%enlist/shop/shopPkg.nut")
let buyShopItem = require("%enlist/shop/buyShopItem.nut")
let buySquadWindow = require("%enlist/shop/buySquadWindow.nut")

let CARD_MAX_WIDTH = fsh(80)
let shopItemHeight = 6.0 * unitSize
let cardSquadPreviewSize = [fsh(60), fsh(30)]

let hoverBox = @(sf, maxWidth) {
  size = flex()
  maxWidth
  rendObj = ROBJ_BOX
  borderWidth = sf & S_HOVER ? hdpx(4) : hdpx(1)
  borderColor = borderColor(sf, false)
}

let mkProductView = @(shopItem, crateContent = null) {
  rendObj = ROBJ_SOLID
  size = cardSquadPreviewSize
  padding = hdpx(1)
  color = BtnBdNormal
  clipChildren = true
  children = mkShopItemView({
    shopItem
    crateContent
    itemTemplates = allItemTemplates
  })
}

let function onSquadBuy(shopItem) {
  let crateContent = shopItemContentCtor(shopItem)
  let productView = mkProductView(shopItem, crateContent)

  let { price = 0 } = shopItem?.curShopItemPrice
  if (price > 0) {
    let squad = shopItem?.squads[0]
    buySquadWindow({
      shopItem
      productView
      armyId = squad?.armyId
      squadId = squad?.id
    })
  } else {
    let description = mkShopItemInfoBlock(crateContent)
    buyShopItem({
      shopItem
      productView
      description
    })
  }
}

let mkBuyButton = @(shopItem) watchElemState(@(sf) {
  size = [flex(), shopItemHeight]
  behavior = Behaviors.Button
  onClick = @() onSquadBuy(shopItem)
  children = [
    {
      size = flex()
      flow = FLOW_VERTICAL
      children = [
        mkShopItemView({ shopItem })
        mkShopItemPriceLine(shopItem)
      ]
    }
    hoverBox(sf, CARD_MAX_WIDTH)
  ]
})

let mkSquadBuyPromo = @(squadId, override = {}) function() {
  let res = { watch = curArmyShopItems }
  let shopItems = curArmyShopItems.value.filter(@(sItem)
    (sItem?.squads ?? []).findindex(@(squad) squad.id == squadId) != null)
  if (shopItems.len() == 0)
    return res

  return res.__update({
    size = [fsh(50), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    gap = fsh(1.5)
    children = shopItems.map(mkBuyButton)
  }, override)
}

return mkSquadBuyPromo