from "%enlSqGlob/ui_library.nut" import *

let { startsWith } = require("%sqstd/string.nut")
let { h2_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let mkHeader = require("%enlist/components/mkHeader.nut")
let closeBtnBase = require("%ui/components/closeBtn.nut")
let mkItemWithMods = require("%enlist/soldiers/mkItemWithMods.nut")
let buyShopItem = require("buyShopItem.nut")
let activatePremiumBttn = require("activatePremiumBtn.nut")
let { PrimaryFlat, Flat } = require("%ui/components/textButton.nut")
let {
  mkShopItemView, shopItemLockedMsgBox, mkShopItemImg, mkLevelLockLine, mkShopItemPriceLine,
  mkShopItemInfoBlock
} = require("shopPkg.nut")
let { makeVertScroll } = require("%ui/components/scrollbar.nut")
let { allItemTemplates } = require("%enlist/soldiers/model/all_items_templates.nut")
let { safeAreaBorders } = require("%enlist/options/safeAreaState.nut")
let { curArmyData } = require("%enlist/soldiers/model/state.nut")
let { shopItemContentCtor, purchaseIsPossible } = require("armyShopState.nut")
let { mkShopItem } = require("%enlist/soldiers/model/items_list_lib.nut")
let { mkDetailsInfo, detailsStatusTier } = require("%enlist/soldiers/components/itemDetailsComp.nut")
let { blur, mkVehicleDetails, mkUpgrades } = require("%enlist/soldiers/components/itemDetailsPkg.nut")
let { sceneWithCameraAdd, sceneWithCameraRemove
} = require("%enlist/sceneWithCamera.nut")
let { bigPadding, smallPadding, blurBgColor, blurBgFillColor, unitSize, detailsHeaderColor
} = require("%enlSqGlob/ui/viewConst.nut")
let { curSelectedItem } = require("%enlist/showState.nut")
let { getItemName } = require("%enlSqGlob/ui/itemsInfo.nut")
let { makeCrateToolTip } = require("%enlist/items/crateInfo.nut")
let { CAMPAIGN_NONE, needFreemiumStatus } = require("%enlist/campaigns/campaignConfig.nut")
let shopItemFreemiumMsgBox = require("%enlist/shop/shopItemFreemiumMsgBox.nut")
let checkLootRestriction = require("hasLootRestriction.nut")

let shopItem = mkWatched(persist, "shopItem", null)
let selectedKey = Computed(@() curSelectedItem.value?.basetpl)
let isSelectedVehicle = Computed(@() curSelectedItem.value?.itemtype == "vehicle")

let shopItemWidth = 9.0 * unitSize
let shopItemHeight = 6.0 * unitSize

let function mkShopItemContent(sItem) {
  let crateContentWatch = shopItemContentCtor(sItem)
  return crateContentWatch == null ? null
    : function() {
        let { armyId, content } = crateContentWatch.value
        let templates = allItemTemplates.value?[armyId]

        let crateItems = (content?.items ?? {}).keys()
          .map(function(templateId) {
            let template = templates?[templateId]
            return template == null ? null : mkShopItem(templateId, template, armyId)
          })
          .filter(@(item) item != null)
          .sort(@(a,b) (a?.tier ?? 0) <=> (b?.tier ?? 0))

        let res = { watch = [crateContentWatch, allItemTemplates] }
        if (crateItems.len() == 0)
          return res

        return res.__update({
          size = [SIZE_TO_CONTENT, flex()]
          padding = [bigPadding, bigPadding]
          rendObj = ROBJ_WORLD_BLUR_PANEL
          color = blurBgColor
          fillColor = blurBgFillColor
          onAttach = @() curSelectedItem(crateItems[0])
          onDetach = @() curSelectedItem(null)
          xmbNode = XmbContainer({
            canFocus = @() false
            scrollSpeed = 5.0
            isViewport = true
          })
          children = makeVertScroll(
            wrap(crateItems
              .map(@(item) mkItemWithMods({
                item
                selectedKey
                selectKey = item?.basetpl
                isXmb = true
                canDrag = false
                itemSize = [shopItemWidth, 2.0 * unitSize]
                onClickCb = @(_) curSelectedItem(item)
                hideStatus = true
                isAvailable = true
              })),
              {
                width = shopItemWidth
                hGap = smallPadding
                vGap = smallPadding
                hplace = ALIGN_CENTER
              }
            ),
            {
              size = [SIZE_TO_CONTENT, flex()]
              needReservePlace = false
            })
        })
      }
}

let function purchaseBtnUi() {
  let shopItemData = shopItem.value
  let { offerContainer = "", requirements = {} } = shopItemData
  if (offerContainer.len() > 0)
    return null

  let { armyLevel = 0, campaignGroup = CAMPAIGN_NONE } = requirements
  let { level = 0 } = curArmyData.value
  let btnCtor = armyLevel > level ? Flat : PrimaryFlat
  let crateContent = shopItemContentCtor(shopItemData)
  return {
    watch = [curArmyData, shopItem, purchaseIsPossible]
    rendObj = ROBJ_BOX
    borderWidth = hdpx(1)
    size = [flex(), SIZE_TO_CONTENT]
    children = !purchaseIsPossible.value ? null
      : btnCtor(loc("btn/buy"),
          function() {
            if (campaignGroup != CAMPAIGN_NONE && needFreemiumStatus.value)
              return shopItemFreemiumMsgBox(@() shopItem(null))

            if (armyLevel > level)
              return shopItemLockedMsgBox(armyLevel, @() shopItem(null))

            shopItem(null)
            checkLootRestriction(
              @() buyShopItem({
                shopItem = shopItemData
                activatePremiumBttn
                productView = mkShopItemImg(shopItemData.image, {
                  size = [fsh(40), fsh(24)]
                })
                description = mkShopItemInfoBlock(crateContent)
              }),
              {
                itemView = mkShopItemImg(shopItemData.image, {
                  size = [fsh(40), fsh(24)]
                })
              },
              crateContent
            )
          },
          {
            margin = 0
            minWidth = pw(100)
          }
      )
  }
}

let vehicleDetails = @() {
  watch = curSelectedItem
  flow = FLOW_VERTICAL
  halign = ALIGN_RIGHT
  children = [
    blur({
      children = {
        rendObj = ROBJ_TEXT
        color = detailsHeaderColor
        text = getItemName(curSelectedItem.value)
      }.__update(h2_txt)
    })
    detailsStatusTier(curSelectedItem.value)
    mkVehicleDetails(curSelectedItem.value, true)
    mkUpgrades(curSelectedItem.value)
  ]
}

let function mkShopItemInfo(item) {
  let crateContent = shopItemContentCtor(item)
  return makeCrateToolTip(crateContent, "", [flex(), SIZE_TO_CONTENT])
}

let mkCrateContent = @(sItem) function() {
  let crateContentWatch = shopItemContentCtor(sItem)
  return {
    watch = [crateContentWatch, curSelectedItem]
    size = [flex(), SIZE_TO_CONTENT]
    rendObj = ROBJ_WORLD_BLUR_PANEL
    color = blurBgColor
    fillColor = blurBgFillColor
    padding = bigPadding
    children = mkShopItemInfoBlock(crateContentWatch)
  }
}

let shopItemsScene = @() {
  watch = [safeAreaBorders, shopItem]
  size = [sw(100), sh(100)]
  flow = FLOW_VERTICAL
  padding = safeAreaBorders.value
  behavior = Behaviors.MenuCameraControl
  children = [
    mkHeader({
      // FIXME: Need to add some parameter to shop item to determine starter pack
      textLocId = startsWith(shopItem.value?.guid, "starter_pack")
        ? "shop/content"
        : "shop/possibleContent"
      closeButton = closeBtnBase({ onClick = @() shopItem(null) })
    })
    {
      size = flex()
      children = [
        {
          size = [SIZE_TO_CONTENT, flex()]
          flow = FLOW_VERTICAL
          gap = smallPadding
          children = [
            function() {
              let res = { watch = [shopItem, curArmyData] }
              if (shopItem.value == null)
                return res
              let { armyLevel = 0 } = shopItem.value?.requirements
              let { level = 0 } = curArmyData.value
              return res.__update({
                size = [flex(), shopItemHeight]
                flow = FLOW_VERTICAL
                children = [
                  mkShopItemView({ shopItem = shopItem.value, isLocked = armyLevel > level })
                  armyLevel > level ? mkLevelLockLine(armyLevel)
                    : mkShopItemPriceLine(shopItem.value)
                ]
              })
            }
            mkCrateContent(shopItem.value)
            mkShopItemContent(shopItem.value)
            mkShopItemInfo(shopItem.value)
            purchaseBtnUi
          ]
        }
        @() {
          watch = isSelectedVehicle
          size = flex()
          halign = ALIGN_RIGHT
          valign = ALIGN_BOTTOM
          children = isSelectedVehicle.value
            ? vehicleDetails
            : mkDetailsInfo(curSelectedItem)
        }
      ]
    }
  ]
}

shopItem.subscribe(function(val) {
  if (val == null) {
    sceneWithCameraRemove(shopItemsScene)
    return
  }
  sceneWithCameraAdd(shopItemsScene, "new_items")
})

if (shopItem.value != null)
  sceneWithCameraAdd(shopItemsScene, "new_items")

return @(val) shopItem(val)
