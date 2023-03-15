from "%enlSqGlob/ui_library.nut" import *

let { fontLarge, fontSmall } = require("%enlSqGlob/ui/fontsStyle.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { doesLocTextExist } = require("dagor.localize")
let { hasSpecialEvent, eventsAvailable, allActiveOffers } = require("offersState.nut")
let { taskSlotPadding } = require("%enlSqGlob/ui/taskPkg.nut")
let offersWindow = require("offersWindow.nut")
let mkCountdownTimer = require("%enlSqGlob/ui/mkCountdownTimer.nut")
let offersPromoWndOpen = require("offersPromoWindow.nut")
let { titleTxtColor, defTxtColor, colPart, startBtnWidth, defVertGradientImg, hoverVertGradientImg,
  accentColor, bigPadding, transpPanelBgColor, miniPadding, midPadding, darkTxtColor
} = require("%enlSqGlob/ui/designConst.nut")
let { hasBaseEvent, openEventModes, promotedEvent, eventStartTime, timeUntilStart
} = require("%enlist/gameModes/eventModesState.nut")
let { needFreemiumStatus, campPresentation
} = require("%enlist/campaigns/campaignConfig.nut")
let freemiumWnd = require("%enlist/currency/freemiumWnd.nut")
let { sendBigQueryUIEvent } = require("%enlist/bigQueryEvents.nut")
let { mkDiscountWidget } = require("%enlist/shop/currencyComp.nut")
let { eventForcedUrl } = require("%enlist/unlocks/eventsTaskState.nut")
let openUrl = require("%ui/components/openUrl.nut")
let premiumWnd = require("%enlist/currency/premiumWnd.nut")
let faComp = require("%ui/components/faComp.nut")
let { curCampaignLocId } = require("%enlist/meta/curCampaign.nut")


let defSmallTxtStyle = { color = defTxtColor }.__update(fontSmall)
let smallDiscountTxtStyle = { color = darkTxtColor }.__update(fontSmall)
let headerTxtStyle = @(sf) { color = sf & S_HOVER ?  titleTxtColor : defTxtColor }
  .__update(fontLarge)
let smallWidgetHeight = colPart(1.29)
let largeWidgetHeight = colPart(4.29)
let largeWidgetInfoHeight = colPart(1.35)
let largeWidgetImgheight = largeWidgetHeight - largeWidgetInfoHeight
let curLargeWidgetIdx = Watched(0)


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
const defOfferImg = "ui/stalingrad_tractor_plant_offer.avif"
const defExtUrlImg = "ui/normandy_village_04.avif"

local offers = 1
let switchTime = Watched(SWITCH_SEC)
let displayedOffers = {}
let goToNextOffer = @() curLargeWidgetIdx((curLargeWidgetIdx.value + 1) % offers)


let function startSwitchTimer(_ = null) {
  anim_skip(curLargeWidgetIdx.value)
  gui_scene.clearTimer(goToNextOffer)
  if (offers > 1 && switchTime.value > 0) {
    anim_start(curLargeWidgetIdx.value)
    gui_scene.setTimeout(SWITCH_SEC, goToNextOffer)
  }
}


let mkOfferImage = @(img) {
  size = [flex(), largeWidgetImgheight]
  key = $"offer_{img}"
  rendObj = ROBJ_IMAGE
  image = Picture(img)
  keepAspect = KEEP_ASPECT_FILL
  imageHalign = ALIGN_RIGHT
}

let discountIconStyle = {
  size = [colPart(1.23), colPart(0.62)]
  hplace = ALIGN_LEFT
  vplace = ALIGN_CENTER
}


let smallDiscountIconStyle = {
  size = [colPart(0.8), colPart(0.4)]
  vplace = ALIGN_BOTTOM
  hplace = ALIGN_LEFT
  pos = [-colPart(2.4), 0]
  textStyle = smallDiscountTxtStyle
}


let timerStyle = {
  rendObj = ROBJ_BOX
  hplace = ALIGN_RIGHT
  vplace = ALIGN_TOP
  valign = ALIGN_TOP
  padding = taskSlotPadding
  fillColor = transpPanelBgColor
}

let mkInfo = @(nameTxt, sf, override = {}) {
  rendObj = ROBJ_IMAGE
  image = sf & S_HOVER ? hoverVertGradientImg : defVertGradientImg
  size = [flex(), largeWidgetInfoHeight]
  padding = bigPadding
  vplace = ALIGN_BOTTOM
  valign = ALIGN_CENTER
  children = {
    size = [flex(), SIZE_TO_CONTENT]
    rendObj = ROBJ_TEXTAREA
    behavior = Behaviors.TextArea
    text = nameTxt
  }.__update(headerTxtStyle(sf))
}.__update(override)


let smallTimer = @(timestamp) timestamp <= 0 ? null : faComp("clock-o", {
  fontSize = defSmallTxtStyle.fontSize
  color = accentColor
  padding = miniPadding
  hplace = ALIGN_RIGHT
})


let mkSmallInfo = @(nameTxt) {
  rendObj = ROBJ_IMAGE
  image = defVertGradientImg
  size = flex()
  padding = midPadding
  children = {
    size = [flex(), SIZE_TO_CONTENT]
    rendObj = ROBJ_TEXTAREA
    behavior = Behaviors.TextArea
    vplace = ALIGN_CENTER
    text = nameTxt
  }.__update(defSmallTxtStyle)
}


let function mkSmallOfferInfo(offer) {
  let { endTime = 0, widgetTxt = "", discountInPercent = 0, shopItemGuid = "" } = offer
  if (shopItemGuid not in displayedOffers) {
    displayedOffers[shopItemGuid] <- true
    sendBigQueryUIEvent("display_offer", null, {
      shopItem = shopItemGuid
      discountInPercent
    })
  }

  return {
    rendObj = ROBJ_SOLID
    color = 0xAAAA0000
    size = flex()
    children = [
      mkSmallInfo(widgetTxt)
      mkDiscountWidget(discountInPercent, smallDiscountIconStyle)
      smallTimer(endTime)
    ]
  }
}


let function mkOfferInfo(offer, sf) {
  let { endTime = 0, widgetTxt = "", discountInPercent = 0, shopItemGuid = "" } = offer
  let timerObject = mkCountdownTimer({
    timestamp = endTime
    override = timerStyle
  })

  if (shopItemGuid not in displayedOffers) {
    displayedOffers[shopItemGuid] <- true
    sendBigQueryUIEvent("display_offer", null, {
      shopItem = shopItemGuid
      discountInPercent
    })
  }

  return {
    size = flex()
    children = [
      mkInfo(widgetTxt, sf)
      mkDiscountWidget(discountInPercent, discountIconStyle)
      timerObject
    ]
  }
}

let timeBeforeEvent = @(timestamp) timestamp <= 0 ? null : mkCountdownTimer({
  timestamp = timestamp
  override = timerStyle
  prefixLocId = loc("events/comingIn")
  prefixColor = accentColor
  expiredLocId = ""
})


let widgetData = freeze({
  [WidgetType.FREEMIUM] = {
    ctor = @(campaignId, isSmall = false) function(sf) {
      let infoContent = (sf & S_HOVER) != 0 || !isSmall
        ? mkInfo(loc("freemium/title/full", { name = utf8ToUpper(loc(campaignId)) }), sf)
        : mkSmallInfo(loc("freemium/title/full", { name = utf8ToUpper(loc(campaignId)) }))
      return {
        size = flex()
        flow = FLOW_VERTICAL
        halign = ALIGN_CENTER
        valign = ALIGN_BOTTOM
        children = infoContent
      }}
    onClick = @(_) freemiumWnd()
  },

  [WidgetType.OFFER] = {
    ctor = @(specOffer, isSmall = false) function(sf) {
      let infoContent = (sf & S_HOVER) != 0 || !isSmall
        ? mkOfferInfo(specOffer, sf)
        : mkSmallOfferInfo(specOffer)
      return infoContent
    }
    onClick = function(specOffer) {
      let action = customOfferActions?[specOffer.offerType] ?? offersWindow
      action(specOffer)
      let { discountInPercent = 0, shopItemGuid = "" } = specOffer
      sendBigQueryUIEvent("open_offer", null, {
        shopItem = shopItemGuid
        discountInPercent
      })
    }
  },

  [WidgetType.EVENT_BASE] = {
    ctor = @(eventData, isSmall = false) function(sf) {
      let infoContent = (sf & S_HOVER) != 0 || !isSmall
        ? mkInfo(eventData.text, sf)
        : mkSmallInfo(eventData.text)
      let timerCtor = (sf & S_HOVER) != 0 || !isSmall ? timeBeforeEvent : smallTimer
      return @() {
        size = flex()
        watch = eventStartTime
        halign = ALIGN_CENTER
        children = [
          infoContent
          timerCtor(eventStartTime.value?[eventData.queueId] ?? 0)
        ]
      }}
    onClick = @(_) openEventModes()
  },

  [WidgetType.EVENT_SPECIAL] = {
    ctor = @(v, isSmall = false) function(sf) {
      let infoContent = (sf & S_HOVER) != 0 || !isSmall
        ? mkInfo(utf8ToUpper(v.titleshort), sf)
        : mkSmallInfo(utf8ToUpper(v.titleshort))
      return infoContent
    }
    onClick = @(v) offersPromoWndOpen(v.id)
  },

  [WidgetType.URL] = {
    ctor = @(v, isSmall = false) function(sf) {
      let infoContent = isSmall
        ? mkSmallInfo(v.title)
        : mkInfo(v.title, sf)
      return infoContent
    }
    onClick = @(v) openUrl(v.url)
  }
})

let widgetList = Computed(function() {
  let list = []

  if (needFreemiumStatus.value)
    list.append({
      widgetType = WidgetType.FREEMIUM
      data = curCampaignLocId.value
      backImage = campPresentation.value?.widgetImage ?? defOfferImg
    })

  list.extend(allActiveOffers.value.map(@(specOffer) {
    widgetType = WidgetType.OFFER
    data = specOffer
    backImage = specOffer?.widgetImg ?? defOfferImg
  }))

  if (hasBaseEvent.value) {
    let title = loc(doesLocTextExist(promotedEvent.value?.locId ?? "")
      ? promotedEvent.value.locId
      : "events_and_custom_matches")

    timeUntilStart()

    list.append({
      widgetType = WidgetType.EVENT_BASE
      data = { text = utf8ToUpper(title), queueId = promotedEvent.value?.queueId ?? "" }
      backImage = promotedEvent.value?.extraParams.image ?? defOfferImg
    })
  }

  list.extend(eventForcedUrl.value.map(@(v) {
    widgetType = WidgetType.URL
    data = v
    backImage = v?.image ?? defExtUrlImg
  }))

  if (hasSpecialEvent.value)
    eventsAvailable.value.each(function(event) {
      let { id, imagepromo = defOfferImg } = event
      list.append({
        id
        widgetType = WidgetType.EVENT_SPECIAL
        data = event
        backImage = imagepromo
      })
    })

  return list
})


let mkSmallImage = @(image) {
  size = [colPart(2.38), smallWidgetHeight]
  key = $"offer_{image}"
  rendObj = ROBJ_IMAGE
  image = Picture(image)
  keepAspect = KEEP_ASPECT_FILL
}


let function mkSmallWidget(content, offerData, idx) {
  if (content == null)
    return null
  let { data = null, backImage = null } = content
  let { ctor = null, onClick = null } = offerData
  let wContent = ctor?(data, true)
  return watchElemState(@(sf) {
    size = [startBtnWidth, smallWidgetHeight]
    behavior = Behaviors.Button
    onClick = @() onClick?(data)
    onHover = @(_on) curLargeWidgetIdx(idx)
    flow = FLOW_HORIZONTAL
    clipChildren = true
    children = [
      mkSmallImage(backImage)
      wContent?(sf)
    ]
  })
}


let function mkLargeWidget(content, offerData, idx) {
  if (content == null)
    return null
  let { id = null, data = null, backImage = null } = content
  let { ctor = null, onClick = null } = offerData
  let wContent = ctor?(data)
  return watchElemState(@(sf) {
    key = id
    size = [startBtnWidth, largeWidgetHeight]
    behavior = Behaviors.Button
    onClick = @() onClick?(data)
    onHover = function(on) {
      curLargeWidgetIdx(idx)
      if (on) {
        anim_skip(id)
        gui_scene.clearTimer(goToNextOffer)
      }
      else
        startSwitchTimer()
    }
    clipChildren = true
    transform = {}
    animations = [
      { prop = AnimProp.opacity, from = 0.7, to = 1.0, duration = 0.2, play = true}
      { prop = AnimProp.scale, from = [1.0, 0.9], to = [1.0, 1.0], duration = 0.2, play = true }
    ]
    children = [
      mkOfferImage(backImage)
      wContent?(sf)
    ]
  })
}


let function offersPromoWidget() {
  let res = { watch = [widgetList, curLargeWidgetIdx] }
  let widgets = widgetList.value
  if (widgets.len() == 0)
    return res
  offers = widgets.len()
  if (offers <= 1) {
    gui_scene.clearTimer(goToNextOffer)
    foreach (v in [curLargeWidgetIdx, switchTime])
      v.unsubscribe(startSwitchTimer)
  }
  else {
    foreach (v in [curLargeWidgetIdx, switchTime])
      v.subscribe(startSwitchTimer)
    startSwitchTimer()
  }
  return res.__update({
    size = [startBtnWidth, SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    gap = bigPadding
    children = widgets.map(function(w, idx) {
      let { widgetType = null } = w
      return curLargeWidgetIdx.value == idx
        ? mkLargeWidget(w, widgetData?[widgetType], idx)
        : mkSmallWidget(w, widgetData?[widgetType], idx)
    })
  })
}

return offersPromoWidget
