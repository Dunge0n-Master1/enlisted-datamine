from "%enlSqGlob/ui_library.nut" import *

let { sub_txt, h2_bold_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { startBtnWidth } = require("%enlist/startBtn.nut")
let { doesLocTextExist } = require("dagor.localize")
let { hasSpecialEvent, hasEventData, allActiveOffers, headingAndDescription, offersShortTitle
} = require("offersState.nut")
let offersWindow = require("offersWindow.nut")
let mkDotPaginator = require("%enlist/components/mkDotPaginator.nut")
let mkCountdownTimer = require("%enlSqGlob/ui/mkCountdownTimer.nut")
let offersPromoWndOpen = require("offersPromoWindow.nut")
let { accentTitleTxtColor, activeTxtColor, defBgColor, smallPadding, bigPadding, translucentBgColor
} = require("%enlSqGlob/ui/viewConst.nut")
let { hasBaseEvent, openEventModes, promotedEvent, eventStartTime, timeUntilStart
} = require("%enlist/gameModes/eventModesState.nut")
let {
  needFreemiumStatus, campPresentation
} = require("%enlist/campaigns/campaignConfig.nut")
let freemiumWnd = require("%enlist/currency/freemiumWnd.nut")
let { gameProfile } = require("%enlist/soldiers/model/config/gameProfile.nut")
let { curCampaign  } = require("%enlist/meta/curCampaign.nut")
let { sendBigQueryUIEvent } = require("%enlist/bigQueryEvents.nut")
let { mkDiscountWidget } = require("%enlist/shop/currencyComp.nut")
let { eventForcedUrl, squadsPromotion } = require("%enlist/unlocks/eventsTaskState.nut")
let openUrl = require("%ui/components/openUrl.nut")
let premiumWnd = require("%enlist/currency/premiumWnd.nut")


enum WidgetType {
  FREEMIUM
  OFFER
  EVENT_BASE
  EVENT_SPECIAL
  URL
}

let customOfferActions = {
  ["PREMIUM"] = @(_specOffer) premiumWnd()
}

const SWITCH_SEC = 8.0
const defOfferImg = "ui/stalingrad_tractor_plant_offer.jpg"
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
  imageValign = ALIGN_TOP
  animations = [
    { prop = AnimProp.opacity, from = 0, to = 1, duration = 0.6, play = true }
    { prop = AnimProp.opacity, from = 1, to = 0, duration = 0.6, playFadeOut = true }
  ]
}

let discountIconStyle = {
  size = [hdpx(76), hdpx(38)]
  textStyle = h2_bold_txt
  hplace = ALIGN_LEFT
  vplace = ALIGN_CENTER
  pos = [-hdpx(8), 0]
}

let timerStyle = {
  rendObj = ROBJ_BOX
  hplace = ALIGN_RIGHT
  padding = bigPadding
  fillColor = translucentBgColor
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
    color = sf & S_HOVER ? activeTxtColor : accentTitleTxtColor
  }.__update(sub_txt)
}.__update(override)

let function mkOfferInfo(sf, offer) {
  let { endTime = 0, widgetTxt = "", discountInPercent = 0, shopItem = null } = offer
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
      mkDiscountWidget(discountInPercent, discountIconStyle)
      timerObject
    ]
  }
}

let timeBeforeEvent = @(timestamp) timestamp <= 0 ? null : mkCountdownTimer({
  timestamp = timestamp
  override = timerStyle
  prefixLocId = loc("events/comingIn")
  prefixColor = accentTitleTxtColor
  expiredLocId = ""
})

let widgetData = {
  [WidgetType.FREEMIUM] = {
    ctor = @(campaignId) @(sf) {
      size = flex()
      flow = FLOW_VERTICAL
      halign = ALIGN_CENTER
      valign = ALIGN_BOTTOM
      children = mkInfo(sf, loc("freemium/title/full",
        { name = utf8ToUpper(loc(campaignId)) }))
    }
    onClick = @(_) freemiumWnd()
  },

  [WidgetType.OFFER] = {
    ctor = @(specOffer) @(sf) mkOfferInfo(sf, specOffer)
    onClick = function(specOffer) {
      let action = customOfferActions?[specOffer.offerType] ?? offersWindow
      action(specOffer)
      let { discountInPercent = 0, shopItem = null } = specOffer
      let { guid = "" } = shopItem
      sendBigQueryUIEvent("open_offer", null, {
        shopItem = guid
        discountInPercent
      })
    }
  },

  [WidgetType.EVENT_BASE] = {
    ctor = @(eventData) @(sf) @() {
      size = flex()
      watch = eventStartTime
      halign = ALIGN_CENTER
      children = [
        mkInfo(sf, eventData.text)
        timeBeforeEvent(eventStartTime.value?[eventData.queueId] ?? 0)
      ]
    }
    onClick = @(_) openEventModes()
  },

  [WidgetType.EVENT_SPECIAL] = {
    ctor = @(title) @(sf) mkInfo(sf, utf8ToUpper(title))
    onClick = @(_) offersPromoWndOpen()
  },

  [WidgetType.URL] = {
    ctor = @(v) @(sf) mkInfo(sf, v.title)
    onClick = @(v) openUrl(v.url)
  }
}

let widgetList = Computed(function() {
  let list = []

  if (needFreemiumStatus.value)
    list.append({
      id = WidgetType.FREEMIUM
      data = gameProfile.value?.campaigns[curCampaign.value].title ?? curCampaign.value
      backImage = campPresentation.value?.widgetImage ?? defOfferImg
    })

  list.extend(allActiveOffers.value.map(@(specOffer) {
    id = WidgetType.OFFER
    data = specOffer
    backImage = specOffer?.widgetImg ?? defOfferImg
  }))

  if (hasBaseEvent.value) {
    let title = loc(doesLocTextExist(promotedEvent.value?.locId ?? "")
      ? promotedEvent.value.locId
      : "events_and_custom_matches")

    timeUntilStart()

    list.append({
      id = WidgetType.EVENT_BASE
      data = { text = utf8ToUpper(title), queueId = promotedEvent.value?.queueId ?? "" }
      backImage = promotedEvent.value?.extraParams.image ?? defOfferImg
    })
  }

  list.extend(eventForcedUrl.value.map(@(v) {
    id = WidgetType.URL
    data = v
    backImage = v?.image ?? defExtUrlImg
  }))

  if ((hasSpecialEvent.value || squadsPromotion.value.len() > 0) && hasEventData.value)
    list.append({
      id = WidgetType.EVENT_SPECIAL
      data = offersShortTitle.value
      backImage = headingAndDescription.value?.heading.v ?? defOfferImg
    })

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
  let res = { watch = [widgetList, curWidgetIdx] }
  let widgets = widgetList.value
  if (widgets.len() == 0)
    return res

  let { id = null, data = null, backImage = null, } = widgets?[curWidgetIdx.value]
  let { ctor = null, onClick = null } = widgetData?[id]
  let content = ctor?(data)
  return res.__update({
    size = [startBtnWidth, SIZE_TO_CONTENT]
    children = [
      mkOfferImage(backImage)
      {
        size = [flex(), SIZE_TO_CONTENT]
        flow = FLOW_VERTICAL
        children = [
          watchElemState(@(sf) {
            size = [flex(), hdpx(125)]
            behavior = Behaviors.Button
            onClick = @() onClick?(data)
            onHover = @(on) paginatorTimer(on ? 0 : SWITCH_SEC)
            children = content?(sf)
          })
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
