from "%enlSqGlob/ui_library.nut" import *

let { bigPadding } = require("%enlSqGlob/ui/viewConst.nut")
let { addScene, removeScene } = require("%enlist/navState.nut")
let { navHeight } = require("%enlist/mainMenu/mainmenu.style.nut")
let { squadsCfgById } = require("%enlist/soldiers/model/config/squadsConfig.nut")
let { armySquadsById } = require("%enlist/soldiers/model/state.nut")
let { mkFullScreenBack, mkBackWithImage, mkSquadBodyBig, primeDescBlock, mkPromoSquadIcon,
  mkPromoBackBtn
} = require("%enlist/soldiers/mkSquadPromo.nut")
let { btnSizeBig } = require("%enlist/soldiers/components/campaignPromoPkg.nut")
let currenciesWidgetUi = require("%enlist/currency/currenciesWidgetUi.nut")
let closeBtnBase = require("%ui/components/closeBtn.nut")
let buyShopItem = require("buyShopItem.nut")
let activatePremiumBttn = require("activatePremiumBtn.nut")
let { isTestDriveProfileInProgress, startSquadTestDrive } = require("%enlist/battleData/testDrive.nut")
let { Bordered, Purchase } = require("%ui/components/textButton.nut")
let spinner = require("%ui/components/spinner.nut")({ height = btnSizeBig[1] })
let { mkPrice } = require("%enlist/shop/mkShopItemPrice.nut")
let { offersByShopItem } = require("%enlist/offers/offersState.nut")
let { CAMPAIGN_NONE } = require("%enlist/campaigns/campaignConfig.nut")


let buySquadParams = mkWatched(persist, "buySquadParams")

let open = @(params) buySquadParams(params)

let close = @() buySquadParams(null)

let viewData = Computed(function() {
  let params = buySquadParams.value
  if (!params)
    return null

  let { armyId, squadId, shopItem } = params
  if (shopItem == null)
    return null

  let squad = armySquadsById.value?[armyId][squadId]
  if (squad != null && (squad?.expireTime ?? 0) == 0)
    return null

  let squadCfg = squadsCfgById.value?[armyId][squadId]

  return squadCfg == null ? null
    : params.__merge({
        squad
        squadCfg
      })
})

let topRightBlock = {
  size = [SIZE_TO_CONTENT, navHeight]
  hplace = ALIGN_RIGHT
  valign = ALIGN_CENTER
  flow = FLOW_HORIZONTAL
  gap = fsh(1)
  children = [
    currenciesWidgetUi
    closeBtnBase({ onClick = close })
  ]
}

let function purchaseSquadCb(shopItem, productView) {
  let offer = offersByShopItem.value?[shopItem.guid]
  buyShopItem({
    shopItem
    pOfferGuid = offer?.guid
    activatePremiumBttn
    productView
  })
  close()
}

let function mkButtonsBlock(vData) {
  let {
    shopItem, productView, armyId, squadId, isBuyDisabled = false
  } = vData

  let summary = isBuyDisabled ? null
    : mkPrice({
        shopItem,
        bgParams = {
          valign = ALIGN_TOP
          hplace = ALIGN_CENTER
        }
      })

  let purchaseBtn = isBuyDisabled ? null
    : Purchase(loc("squads/purchase"),
        @() purchaseSquadCb(shopItem, productView),
        {
          size = btnSizeBig
          margin = 0
          hotkeys = [[ "^J:Y", { description = { skip = true }} ]]
        }
      )

  return @() {
    watch = isTestDriveProfileInProgress
    gap = bigPadding
    flow = FLOW_VERTICAL
    halign = ALIGN_CENTER
    children = [
      summary
      purchaseBtn
      isTestDriveProfileInProgress.value ? spinner
        : Bordered(loc("testDrive/squad"), @() startSquadTestDrive(armyId, squadId), {
            size = btnSizeBig
            margin = 0
            hotkeys = [[ "^J:X", { description = { skip = true }} ]]
          })
      mkPromoBackBtn(close)
    ]
  }
}

let function buySquadWnd() {
  if (viewData.value == null)
    return null

  let { armyId, squadCfg, campaignGroup = CAMPAIGN_NONE } = viewData.value
  return {
    watch = viewData
    rendObj = ROBJ_BOX
    borderWidth = hdpx(1)
    size = flex()
    children = mkFullScreenBack(
      mkBackWithImage(squadCfg?.image, false, false),
      [
        mkSquadBodyBig(squadCfg.__merge({
            armyId
            isPrimeSquad = true
            hasReceived = false
            campaignGroup
          }),
          primeDescBlock(squadCfg),
          mkButtonsBlock(viewData.value))
        mkPromoSquadIcon(squadCfg?.icon, false)
        topRightBlock
      ]
    )
  }
}

viewData.subscribe(@(val) val
  ? addScene(buySquadWnd)
  : removeScene(buySquadWnd))

if (viewData.value != null)
  addScene(buySquadWnd)

return open