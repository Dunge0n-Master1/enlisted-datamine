from "%enlSqGlob/ui_library.nut" import *

let faComp = require("%ui/components/faComp.nut")
let { sub_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let {
  smallOffset, bigPadding, smallPadding, activeTxtColor, discountBgColor
} = require("%enlSqGlob/ui/viewConst.nut")

let { addScene, removeScene } = require("%enlist/navState.nut")
let { navHeight } = require("%enlist/mainMenu/mainmenu.style.nut")
let { squadsCfgById } = require("%enlist/soldiers/model/config/squadsConfig.nut")
let { armySquadsById, curUnlockedSquads } = require("%enlist/soldiers/model/state.nut")
let { mkFullScreenBack, mkBackWithImage, mkSquadBodyBig, primeDescBlock, mkPromoSquadIcon,
  mkPromoBackBtn
} = require("%enlist/soldiers/mkSquadPromo.nut")
let { btnSizeBig } = require("%enlist/soldiers/components/campaignPromoPkg.nut")
let mkCountdownTimer = require("%enlSqGlob/ui/mkCountdownTimer.nut")
let currenciesWidgetUi = require("%enlist/currency/currenciesWidgetUi.nut")
let closeBtnBase = require("%ui/components/closeBtn.nut")
let buyShopItem = require("buyShopItem.nut")
let { purchaseMsgBox } = require("%enlist/currency/purchaseMsgBox.nut")
let activatePremiumBttn = require("activatePremiumBtn.nut")
let { isTestDriveProfileInProgress, startSquadTestDrive } = require("%enlist/battleData/testDrive.nut")
let { Bordered, Purchase, PrimaryFlat } = require("%ui/components/textButton.nut")
let spinner = require("%ui/components/spinner.nut")({ height = btnSizeBig[1] })
let { mkPrice } = require("%enlist/shop/mkShopItemPrice.nut")
let { offersByShopItem } = require("%enlist/offers/offersState.nut")
let { CAMPAIGN_NONE } = require("%enlist/campaigns/campaignConfig.nut")
let { rentSquadsConfig, rentSquad } = require("%enlist/shop/rentState.nut")
let { canRentSquad } = require("%enlist/featureFlags.nut")
let { mkHeaderFlag, primeFlagStyle } = require("%enlSqGlob/ui/mkHeaderFlag.nut")
let { txt } = require("%enlSqGlob/ui/defcomps.nut")
let { secondsToHoursLoc } = require("%ui/helpers/time.nut")
let { wallpostersCfg } = require("%enlist/profile/wallpostersState.nut")
let { mkWallposterImg } = require("%enlist/profile/wallpostersPkg.nut")


let defTxtStyle = { color = activeTxtColor }.__update(sub_txt)

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
  let offer = offersByShopItem.value?[shopItem.guid]

  return squadCfg == null ? null
    : params.__merge({
        squad
        squadCfg
        offer
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

let function rentSquadCb(productView, rentOptions, armyId, squadId) {
  if (rentOptions.len() == 0)
    return

  let bestOption = rentOptions
    .reduce(@(r, o) o.price > r.price ? o : r, rentOptions[0])
  let { price, rentTime } = bestOption
  purchaseMsgBox({
    productView
    price
    currencyId = "EnlistedGold"
    purchase = @() rentSquad(armyId, squadId, rentTime, price)
    alwaysShowCancel = true
    srcComponent = "rent_squad"
    purchaseText = loc("btn/rentFor", {
      timeText = secondsToHoursLoc(rentTime)
    })
    title = loc("rentSquadHeader")
    description = loc("rentSquadInfo")
  })
  close()
}

let function mkButtonsBlock(viewOptions, rentOptions) {
  let {
    shopItem, productView, armyId, squadId, offer, isBuyDisabled = false
  } = viewOptions

  let squadRented = curUnlockedSquads.value
    .findvalue(@(s) s.squadId == squadId && (s?.expireTime ?? 0) > 0 )
  let isRented = squadRented != null
  let timerObj = isRented ? mkCountdownTimer({
    timestamp = squadRented.expireTime
    prefixLocId = loc("rented")
    expiredLocId = loc("rentExpired")
    color = activeTxtColor
    prefixColor = activeTxtColor
  }) : null

  let offerInfo = offer == null ? null
    : mkHeaderFlag({
        flow = FLOW_VERTICAL
        padding = [smallPadding, smallOffset, bigPadding, bigPadding]
        children = [
          txt({ text = loc("specialOfferShort") }.__update(defTxtStyle))
          mkCountdownTimer({ timestamp = offer.endTime })
        ]
      }, primeFlagStyle.__merge({
        offset = 0
        flagColor = discountBgColor
      }))

  let summary = mkPrice({
    shopItem,
    bgParams = { hplace = offer == null ? ALIGN_CENTER : ALIGN_RIGHT }
  })

  let purchaseInfo = isBuyDisabled ? null
    : {
        size = [flex(), SIZE_TO_CONTENT]
        valign = ALIGN_CENTER
        children = [ offerInfo, summary ]
      }


  let purchaseBtn = isBuyDisabled ? null
    : Purchase(loc("squads/purchase"),
        @() purchaseSquadCb(shopItem, productView),
        {
          size = btnSizeBig
          margin = 0
          hotkeys = [[ "^J:Y", { description = { skip = true }} ]]
        }
      )

  let rentBtn = isBuyDisabled || rentOptions.len() == 0 ? null
    : PrimaryFlat(isRented ? loc("squads/extend") : loc("squads/rent"),
        @() rentSquadCb(productView, rentOptions, armyId, squadId),
        {
          size = btnSizeBig
          margin = 0
          hotkeys = [[ "^J:Y", { description = { skip = true }} ]]
        }
      )
  return @() {
    watch = [isTestDriveProfileInProgress, canRentSquad]
    gap = bigPadding
    flow = FLOW_VERTICAL
    halign = ALIGN_CENTER
    children = [
      purchaseInfo
      timerObj
      purchaseBtn
      canRentSquad.value ? rentBtn : null
      isTestDriveProfileInProgress.value ? spinner
        : Bordered(loc("testDrive/squad"),
            @() startSquadTestDrive(armyId, squadId, shopItem?.guid ?? ""),
            {
              size = btnSizeBig
              margin = 0
              hotkeys = [[ "^J:X", { description = { skip = true }} ]]
            })
      mkPromoBackBtn(close)
    ]
  }
}

let wpSize = hdpxi(100)
let plusObj = faComp("plus", {
  padding = bigPadding
  fontSize = hdpx(36)
  color = activeTxtColor
})

let function mkAdditionalObject(viewOptions) {
  let { shopItem } = viewOptions
  let { wallposters = [] } = shopItem
  if (wallposters.len() == 0)
    return null

  return function() {
    let res = {
      watch = wallpostersCfg
    }

    let wpCfg = wallpostersCfg.value
    let wpChildren = wallposters.map(function(wp) {
      let wallposter = wpCfg.findvalue(@(cfg) cfg.armyId == wp.armyId && cfg.id == wp.id)
      return wallposter == null ? null : mkWallposterImg(wallposter.img, true, true, wpSize)
    }).filter(@(wp) wp != null)

    if (wpChildren.len() == 0)
      return res

    return res.__update({
      flow = FLOW_VERTICAL
      gap = smallPadding
      halign = ALIGN_RIGHT
      children = [
        txt({ text = loc("youWillAlsoGet") }.__update(defTxtStyle))
        {
          flow = FLOW_HORIZONTAL
          gap = smallOffset
          valign = ALIGN_CENTER
          children = [plusObj].extend(wpChildren)
        }
      ]
    })
  }
}

let function buySquadWnd() {
  let res = { watch = [viewData, rentSquadsConfig] }
  let viewOptions = viewData.value
  if (viewOptions == null)
    return res

  let { armyId, squadCfg, campaignGroup = CAMPAIGN_NONE } = viewOptions
  let rentOptions = rentSquadsConfig.value?[armyId][squadCfg.id] ?? []
  return res.__update({
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
          primeDescBlock(squadCfg, mkAdditionalObject(viewOptions)),
          mkButtonsBlock(viewOptions, rentOptions))
        mkPromoSquadIcon(squadCfg?.icon, false)
        topRightBlock
      ]
    )
  })
}

viewData.subscribe(@(val) val
  ? addScene(buySquadWnd)
  : removeScene(buySquadWnd))

if (viewData.value != null)
  addScene(buySquadWnd)

return open