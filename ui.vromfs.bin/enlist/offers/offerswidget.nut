from "%enlSqGlob/ui_library.nut" import *

let { sub_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { startBtnWidth } = require("%enlist/startBtn.nut")
let { hasSpecialEvent, hasEventData, allActiveOffers, headingAndDescription, offersShortTitle
} = require("offersState.nut")
let { taskSlotPadding } = require("%enlSqGlob/ui/taskPkg.nut")
let offersWindow = require("offersWindow.nut")
let mkDotPaginator = require("%enlist/components/mkDotPaginator.nut")
let mkCountdownTimer = require("%enlist/components/mkCountdownTimer.nut")
let offersPromoWndOpen = require("offersPromoWindow.nut")
let { accentTitleTxtColor, activeTxtColor, defBgColor, smallPadding
} = require("%enlSqGlob/ui/viewConst.nut")
let { mkDiscountIcon } = require("%enlist/shop/shopPkg.nut")
let { hasBaseEvent, openEventModes, promotedEvent
} = require("%enlist/gameModes/eventModesState.nut")
let { needFreemiumStatus } = require("%enlist/campaigns/freemiumState.nut")
let freemiumWnd = require("%enlist/currency/freemiumWnd.nut")
let { gameProfile } = require("%enlist/soldiers/model/config/gameProfile.nut")
let { curCampaign  } = require("%enlist/meta/curCampaign.nut")
let { sendBigQueryUIEvent } = require("%enlist/bigQueryEvents.nut")
let { eventForcedUrl, isPromoteCampaign } = require("%enlist/unlocks/eventsTaskState.nut")
let openUrl = require("%ui/components/openUrl.nut")

const SWITCH_SEC = 8.0
const defOfferImg = "ui/tunisia_city_inv_01.jpg"
const defExtUrlImg = "ui/normandy_village_04.jpg"

let curWidgetIdx = Watched(0)
let displayedOffers = {}

let mkOfferImage = @(img) {
  key = $"offer_{img}"
  rendObj = ROBJ_IMAGE
  size = flex()
  image = Picture(img)
  keepAspect = KEEP_ASPECT_FILL
  imageHalign = ALIGN_RIGHT
  animations = [
    { prop = AnimProp.opacity, from = 0, to = 1, duration = 0.6, play = true }
    { prop = AnimProp.opacity, from = 1, to = 0, duration = 0.6, playFadeOut = true }
  ]
}

let discountIconStyle = {
  hplace = ALIGN_RIGHT
  pos = [hdpx(11), hdpx(18)]
}

let timerStyle = {
  hplace = ALIGN_LEFT
  padding = taskSlotPadding
}

let mkInfo = @(sf, nameTxt, override = {}) {
  rendObj = ROBJ_SOLID
  size = [flex(), SIZE_TO_CONTENT]
  padding = smallPadding
  vplace = ALIGN_BOTTOM
  color = defBgColor
  children = {
    size = [flex(), SIZE_TO_CONTENT]
    rendObj = ROBJ_TEXTAREA
    behavior = Behaviors.TextArea
    text = nameTxt
    halign = ALIGN_CENTER
    color = sf & S_HOVER ? accentTitleTxtColor : activeTxtColor
  }.__update(sub_txt)
}.__update(override)

let function mkOfferInfo(sf, offer) {
  let { endTime = 0, widgetTxt = "", discountInPercent = 0, shopItem = null } = offer
  let discountObject = discountInPercent <= 0 ? null
    : mkDiscountIcon(discountInPercent, discountIconStyle)
  let timerObject = mkCountdownTimer({
    timestamp = endTime
    override = timerStyle
  })

  let { guid = null } = shopItem
  if (guid not in displayedOffers) {
    displayedOffers[guid] <- true
    sendBigQueryUIEvent("display_offer", null, {
      shopItem = guid
      discountInPercent
    })
  }

  return {
    size = flex()
    children = [
      mkInfo(sf, widgetTxt)
      discountObject
      timerObject
    ]
  }
}


let widgetList = Computed(function() {
  let list = []

  if (needFreemiumStatus.value) {
    let campaignName = loc(gameProfile.value?.campaigns[curCampaign.value].title
      ?? curCampaign.value)
    list.append({
      backImage = "ui/uiskin/offers/freemium_widget.jpg"
      mkContent = @(sf) {
        size = flex()
        flow = FLOW_VERTICAL
        halign = ALIGN_CENTER
        valign = ALIGN_BOTTOM
        children = mkInfo(sf, loc("freemium/title/full",
          { name = utf8ToUpper(campaignName) }))
      }
      onClick = freemiumWnd
    })
  }

  list.extend(allActiveOffers.value.map(@(specOffer, idx) {
    backImage = specOffer?.widgetImg ?? defOfferImg
    mkContent = @(sf) mkOfferInfo(sf, specOffer)
    onClick = function() {
      offersWindow(idx)
      let { discountInPercent = 0, shopItem = null } = specOffer
      let { guid = "" } = shopItem
      sendBigQueryUIEvent("open_offer", null, {
        shopItem = guid
        discountInPercent
      })
    }
  }))

  if (hasBaseEvent.value) {
    let { image = null } = promotedEvent.value
    list.append({
      backImage = image ?? defOfferImg
      mkContent = @(sf) mkInfo(sf,
        utf8ToUpper($"{loc("events")} / {loc("custom_matches")}"))
      onClick = openEventModes
    })
  }

  list.extend(eventForcedUrl.value.map(@(v) {
    backImage = v?.image ?? defExtUrlImg
    mkContent = @(sf) mkInfo(sf, v.title)
    onClick = @() openUrl(v.url)
  }))

  if (hasSpecialEvent.value && hasEventData.value && isPromoteCampaign.value) {
    let { heading = null } = headingAndDescription.value
    list.append({
      backImage = heading?.v ?? defOfferImg
      mkContent = @(sf) mkInfo(sf, utf8ToUpper(offersShortTitle.value))
      onClick = offersPromoWndOpen
    })
  }

  return list
})

widgetList.subscribe(function(wList) {
  let wCount = wList.len()
  if (wCount == 0)
    return curWidgetIdx(-1)

  curWidgetIdx(clamp(curWidgetIdx.value, 0, wCount - 1))
})

let paginatorTimer = Watched(SWITCH_SEC)

let offersPaginator = mkDotPaginator({
  id = "offers"
  pageWatch = curWidgetIdx
  dotSize = hdpx(9)
  switchTime = paginatorTimer
})

let function offersPromoWidget() {
  let res = { watch = widgetList }
  let widgets = widgetList.value
  if (widgets.len() == 0)
    return res

  return res.__update({
    size = [startBtnWidth, SIZE_TO_CONTENT]
    children = widgets.len() == 0 ? null
      : [
          @() {
            watch = curWidgetIdx
            size = flex()
            children = mkOfferImage(widgets?[curWidgetIdx.value].backImage)
          }
          {
            size = [flex(), SIZE_TO_CONTENT]
            flow = FLOW_VERTICAL
            children = [
              @() {
                watch = curWidgetIdx
                size = [flex(), hdpx(125)]
                children = watchElemState(@(sf) {
                  size = flex()
                  behavior = Behaviors.Button
                  onClick = widgets?[curWidgetIdx.value].onClick
                  onHover = @(on) paginatorTimer(on ? 0 : SWITCH_SEC)
                  children = widgets?[curWidgetIdx.value].mkContent(sf)
                })
              }
              {
                rendObj = ROBJ_SOLID
                size = [flex(), SIZE_TO_CONTENT]
                padding = smallPadding
                halign = ALIGN_CENTER
                color = defBgColor
                children = offersPaginator(widgets.len())
              }
            ]
          }
        ]
  })
}

return offersPromoWidget
