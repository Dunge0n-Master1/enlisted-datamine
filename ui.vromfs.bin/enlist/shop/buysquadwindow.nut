from "%enlSqGlob/ui_library.nut" import *

let { bigPadding, accentTitleTxtColor } = require("%enlSqGlob/ui/viewConst.nut")
let { addScene, removeScene } = require("%enlist/navState.nut")
let { navHeight } = require("%enlist/mainMenu/mainmenu.style.nut")
let { squadsCfgById } = require("%enlist/soldiers/model/config/squadsConfig.nut")
let { armySquadsById } = require("%enlist/soldiers/model/state.nut")
let { mkFullScreenBack, mkBackWithImage, mkSquadBodyBig, primeDescBlock, mkPromoSquadIcon,
  mkPromoBackBtn
} = require("%enlist/soldiers/mkSquadPromo.nut")
let { btnSizeBig } = require("%enlist/soldiers/components/campaignPromoPkg.nut")
let colorize = require("%ui/components/colorize.nut")
let currenciesWidgetUi = require("%enlist/currency/currenciesWidgetUi.nut")
let closeBtnBase = require("%ui/components/closeBtn.nut")
let buyShopItem = require("buyShopItem.nut")
let activatePremiumBttn = require("activatePremiumBtn.nut")
let { isTestDriveProfileInProgress, startSquadTestDrive } = require("%enlist/battleData/testDrive.nut")
let { Bordered, Purchase } = require("%ui/components/textButton.nut")
let spinner = require("%ui/components/spinner.nut")({ height = btnSizeBig[1] })
let { mkPrice } = require("%enlist/shop/mkShopItemPrice.nut")
let {
  allActiveOffers, curOfferIdx, isSpecOffersOpened
} = require("%enlist/offers/offersState.nut")
let { showMsgbox } = require("%enlist/components/msgbox.nut")


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
  if (squad != null)
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

let hasOfferContainsSquad = @(offer, id, armyId) (offer?.shopItem.squads ?? [])
  .findvalue(@(s) s.id == id && s.armyId == armyId) != null

let function purchaseSquadCb(shopItem, productView) {
  let offers = allActiveOffers.value ?? []
  local alternativeOfferIdx = -1
  foreach (squad in shopItem?.squads ?? []) {
    foreach (idx, offer in offers)
      if (hasOfferContainsSquad(offer, squad.id, squad.armyId)) {
        alternativeOfferIdx = idx
        break
      }
    if (alternativeOfferIdx >= 0)
      break
  }

  let action = @() buyShopItem({
    shopItem
    activatePremiumBttn
    productView
  })

  if (alternativeOfferIdx < 0)
    action()
  else {
    let offer = offers[alternativeOfferIdx]
    let offerName = colorize(accentTitleTxtColor, offer.widgetTxt)
    let discount = colorize(accentTitleTxtColor, offer.discountInPercent)
    showMsgbox({
      text = loc("alternativeOffer", { offerName, discount })
      buttons = [
        { text = loc("btn/buy"), action }
        {
          text = loc("btn/openOffer")
          action = function() {
            curOfferIdx(0)
            isSpecOffersOpened(true)
          }
        }
      ]
    })
  }

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

  let { armyId, squadCfg, isFreemium = false } = viewData.value
  return {
    watch = viewData
    rendObj = ROBJ_BOX
    borderWidth = hdpx(1)
    size = flex()
    children = mkFullScreenBack(
      mkBackWithImage(squadCfg?.image, false, false),
      [
        mkSquadBodyBig(squadCfg.__merge({
            armyId, isPrimeSquad = true, hasReceived = false, isFreemium }),
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