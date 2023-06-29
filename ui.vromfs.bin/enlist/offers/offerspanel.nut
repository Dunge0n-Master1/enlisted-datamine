from "%enlSqGlob/ui_library.nut" import *

let { fontLarge, fontSmall } = require("%enlSqGlob/ui/fontsStyle.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { doesLocTextExist } = require("dagor.localize")
let { eventsData, eventsKeysSorted, allActiveOffers } = require("offersState.nut")
let { taskSlotPadding } = require("%enlSqGlob/ui/tasksPkg.nut")
let offersWindow = require("offersWindow.nut")
let mkCountdownTimer = require("%enlSqGlob/ui/mkCountdownTimer.nut")
let offersPromoWndOpen = require("offersPromoWindow.nut")
let { defTxtColor, colPart, startBtnWidth, accentColor, bigPadding, miniPadding, midPadding,
  mkTimerIcon, darkTxtColor, smallPadding, defItemBlur, transpPanelBgColor, transpBgColor,
  highlightLineTop, highlightLineHgt, hoverSlotBgColor, brightAccentColor
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
let { curCampaignLocId } = require("%enlist/meta/curCampaign.nut")


const MAX_WIDGETS = 4
const DUR = 0.15

let defSmallTxtStyle = { color = defTxtColor }.__update(fontSmall)
let smallDiscountTxtStyle = { color = darkTxtColor }.__update(fontSmall)
let headerTxtStyle = @(sf) { color = sf & S_HOVER ?  darkTxtColor : defTxtColor }
  .__update(fontLarge)
let smallWidgetHeight = colPart(1.29) + highlightLineHgt
let largeWidgetHeight = colPart(4.29)
let widgetHeightDif = largeWidgetHeight - smallWidgetHeight
let largeWidgetInfoHeight = colPart(1.35)
let largeWidgetImgheight = largeWidgetHeight - largeWidgetInfoHeight

let curLargeWidgetIdx = Watched(0)
local oldLargeWidgetIdx = 0
let timerSize = defSmallTxtStyle.fontSize


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
let goToNextOffer = function() {
  oldLargeWidgetIdx = curLargeWidgetIdx.value
  curLargeWidgetIdx((curLargeWidgetIdx.value + 1) % offers)
}


let function startSwitchTimer(_ = null) {
  anim_skip(curLargeWidgetIdx.value)
  gui_scene.clearTimer(goToNextOffer)
  if (offers > 1 && switchTime.value > 0) {
    anim_start(curLargeWidgetIdx.value)
    gui_scene.setTimeout(SWITCH_SEC, goToNextOffer)
  }
}


let anims = freeze([
  { prop = AnimProp.scale, from = [0.301, 1], to = [1, 1], duration = DUR, play = true }
])

let mkOfferImage = @(image) freeze({
  size = flex()
  key = image
  rendObj = ROBJ_IMAGE
  image = Picture(image)
  keepAspect = KEEP_ASPECT_FILL
  imageHalign = ALIGN_CENTER
  transform = { pivot = [0, 0] }
  animations = anims
})

let mkSmallImage = @(image) {
  size = [colPart(2.38), smallWidgetHeight-highlightLineHgt]
  rendObj = ROBJ_IMAGE
  image = Picture(image)
  keepAspect = KEEP_ASPECT_FILL
  imageHalign = ALIGN_CENTER
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
  rendObj = ROBJ_WORLD_BLUR_PANEL
  fillColor = transpBgColor
  color = defItemBlur
  hplace = ALIGN_RIGHT
  vplace = ALIGN_TOP
  valign = ALIGN_TOP
  padding = taskSlotPadding
}

let mkInfo = @(nameTxt, sf, override = {}) {
  size = [flex(), largeWidgetInfoHeight]
  vplace = ALIGN_BOTTOM
  valign = ALIGN_CENTER
  children = [
    highlightLineTop
    {
      size = [flex(), SIZE_TO_CONTENT]
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      margin = bigPadding
      text = nameTxt
    }.__update(headerTxtStyle(sf))
  ]
}.__update(override)


let timer = mkTimerIcon(timerSize, {
  color = brightAccentColor
  margin = [miniPadding, smallPadding]
  hplace = ALIGN_RIGHT
})


let smallTimer = @(timestamp) timestamp <= 0 ? null : timer

let mkSmallInfo = @(nameTxt, override = {}) {
  rendObj = ROBJ_WORLD_BLUR
  size = flex()
  fillColor = transpPanelBgColor
  color = defItemBlur
  children = {
    size = [flex(), SIZE_TO_CONTENT]
    rendObj = ROBJ_TEXTAREA
    behavior = Behaviors.TextArea
    vplace = ALIGN_CENTER
    margin = midPadding
    text = nameTxt
  }.__update(defSmallTxtStyle)
}.__update(override)


let function mkSmallOfferInfo(offer, anim) {
  let { endTime = 0, widgetTxt = "", discountInPercent = 0, shopItemGuid = "" } = offer
  if (shopItemGuid not in displayedOffers) {
    displayedOffers[shopItemGuid] <- true
    sendBigQueryUIEvent("display_offer", null, {
      shopItem = shopItemGuid
      discountInPercent
    })
  }

  return {
    rendObj = ROBJ_WORLD_BLUR
    color = defItemBlur
    fillColor = transpPanelBgColor
    size = flex()
    children = [
      mkSmallInfo(widgetTxt)
      mkDiscountWidget(discountInPercent, smallDiscountIconStyle)
      smallTimer(endTime)
    ]
  }.__update(anim)
}


let function mkOfferInfo(offer, sf, anim) {
  let { endTime = 0, widgetTxt = "", discountInPercent = 0, shopItemGuid = "" } = offer
  let timerObject = {
    pos = [0, smallPadding - widgetHeightDif]
    hplace = ALIGN_RIGHT
    children = mkCountdownTimer({
      timestamp = endTime
      override = timerStyle
      color = accentColor
    })
  }

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
      mkDiscountWidget(discountInPercent, { pos = [0, -colPart(1)] }.__update(discountIconStyle))
      timerObject
    ]
  }.__update(anim)
}

let timeBeforeEvent = @(timestamp) timestamp <= 0 ? null : mkCountdownTimer({
  timestamp = timestamp
  override = timerStyle
  prefixLocId = loc("events/comingIn")
  prefixColor = brightAccentColor
  expiredLocId = ""
})


let contentAnim = freeze({
  animations = [
    freeze({ prop = AnimProp.opacity, from = 0, to = 0, duration = DUR / 1.5, play = true })
    freeze({ prop = AnimProp.opacity, from = 0, to = 1, delay = DUR / 1.5, duration = DUR / 1.5, play = true })
  ]
})


let widgetData = freeze({
  [WidgetType.FREEMIUM] = {
    ctor = @(campaignId, isSmall = false, hasAnim = true) function(sf) {
      let anim = hasAnim ? contentAnim : {}
      let infoContent = (sf & S_HOVER) != 0 || !isSmall
        ? mkInfo(loc("freemium/title/full", { name = utf8ToUpper(loc(campaignId)) }), sf, anim)
        : mkSmallInfo(loc("freemium/title/full", { name = utf8ToUpper(loc(campaignId)) }), anim)
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
    ctor = @(specOffer, isSmall = false, hasAnim = true) function(sf) {
      let anim = hasAnim ? contentAnim : {}
      let infoContent = (sf & S_HOVER) != 0 || !isSmall
        ? mkOfferInfo(specOffer, sf, anim)
        : mkSmallOfferInfo(specOffer, anim)
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
    ctor = @(eventData, isSmall = false, hasAnim = true) function(sf) {
      let anim = hasAnim ? contentAnim : {}
      let isBig = (sf & S_HOVER) != 0 || !isSmall
      let infoContent = isBig
        ? mkInfo(eventData.text, sf, anim)
        : mkSmallInfo(eventData.text, anim)
      let timerCtor = (sf & S_HOVER) != 0 || !isSmall ? timeBeforeEvent : smallTimer
      return @() {
        size = flex()
        watch = eventStartTime
        halign = ALIGN_CENTER
        children = [
          infoContent
          {
            size = flex()
            pos = [0, isBig ? -widgetHeightDif : 0]
            children = timerCtor(eventStartTime.value?[eventData.queueId] ?? 0)
          }.__update(anim)
        ]
      }}
    onClick = @(_) openEventModes()
  },

  [WidgetType.EVENT_SPECIAL] = {
    ctor = @(v, isSmall = false, hasAnim = true) function(sf) {
      let anim = hasAnim ? contentAnim : {}
      let infoContent = (sf & S_HOVER) != 0 || !isSmall
        ? mkInfo(utf8ToUpper(v.titleshort), sf, anim)
        : mkSmallInfo(utf8ToUpper(v.titleshort), anim)
      return infoContent
    }
    onClick = @(v) offersPromoWndOpen(v.id)
  },

  [WidgetType.URL] = {
    ctor = @(v, isSmall = false, hasAnim = true) function(sf) {
      let anim = hasAnim ? contentAnim : {}
      let infoContent = isSmall
        ? mkSmallInfo(v.title, anim)
        : mkInfo(v.title, sf, anim)
      return infoContent
    }
    onClick = @(v) openUrl(v.url)
  }
})

let widgetList = Computed(function() {
  let list = []

  list.extend(allActiveOffers.value.map(@(specOffer, idx) {
    widgetType = WidgetType.OFFER
    data = specOffer
    id = idx
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

  list.extend(eventForcedUrl.value.map(@(v, idx) {
    widgetType = WidgetType.URL
    data = v
    id = idx
    backImage = v?.image ?? defExtUrlImg
  }))

  foreach (eventId in eventsKeysSorted.value) {
    if (list.len() >= MAX_WIDGETS)
      break
    let event = eventsData.value?[eventId]
    if (event != null) {
      let { id, imagepromo = defOfferImg } = event
      list.append({
        id
        widgetType = WidgetType.EVENT_SPECIAL
        data = event
        backImage = imagepromo
      })
    }
  }

  if (list.len() < MAX_WIDGETS && needFreemiumStatus.value)
    list.insert(0, {
      widgetType = WidgetType.FREEMIUM
      data = curCampaignLocId.value
      backImage = campPresentation.value?.widgetImage ?? defOfferImg
    })

  return list
})


let animTable = {
  shrinksBelowAnim = {
    transform = { pivot = [1, 0] }
    animations = [
      { prop = AnimProp.opacity, from = 1, to = 0.7, duration = DUR, play = true}
      { prop = AnimProp.scale, from = [1, 3.325], to = [1, 1], duration = DUR, play = true }
    ]
  }
  shrinksAboveAnim = {
    transform = { pivot = [1, 1] }
    animations = [
      { prop = AnimProp.opacity, from = 1, to = 0.7, duration = DUR, play = true}
      { prop = AnimProp.scale, from = [1, 3.325], to = [1, 1], duration = DUR, play = true }
    ]
  }
  moveUpAnim = {
    transform = { pivot = [0, 0] }
    animations = [
      { prop = AnimProp.translate, from = [0, widgetHeightDif], to = [0, 0], duration = DUR, play = true}
    ]
  }
  moveDownAnim = {
    transform = { pivot = [0, 0] }
    animations = [
      { prop = AnimProp.translate, from = [0, -widgetHeightDif], to = [0, 0], duration = DUR, play = true}
    ]
  }
}

let contentImgAnim = {
  transform = { pivot = [0, 0] }
  animations = [
    { prop = AnimProp.scale, from = [3.325, 1], to = [1, 1], duration = DUR, play = true }
  ]
}


let function mkSmallWidget(content, idx, oldIdx, curIdx) {
  if (content == null)
    return null

  let animKey = idx > oldIdx && idx < curIdx ? "moveUpAnim"
    : idx < oldIdx && idx > curIdx ? "moveDownAnim"
    : oldIdx == idx && curIdx > idx ? "shrinksBelowAnim"
    : oldIdx == idx && curIdx < idx ? "shrinksAboveAnim"
    : null

  let hasContAnim = animKey == "shrinksBelowAnim" || animKey == "shrinksAboveAnim"
  let contImgAnim = hasContAnim ? contentImgAnim : {}

  let { widgetType, id = "", data = null, backImage = null } = content
  let offerData = widgetData[widgetType]
  let { ctor = null, onClick = null } = offerData
  let smallImg = freeze({
    size = [colPart(2.38), flex()]
    clipChildren = true
    valign = ALIGN_BOTTOM
    children = mkSmallImage(backImage).__update(contImgAnim)
  })

  let wContent = ctor?(data, true, hasContAnim)
  return watchElemState(@(sf) {
    size = [startBtnWidth, smallWidgetHeight]
    key = id
    behavior = Behaviors.Button
    onClick = @() onClick?(data)
    onHover = function(_on) {
      oldLargeWidgetIdx = curLargeWidgetIdx.value
      curLargeWidgetIdx(idx)
    }
    flow = FLOW_VERTICAL
    clipChildren = true
    rendObj = ROBJ_WORLD_BLUR
    fillColor = transpPanelBgColor
    color = defItemBlur
    children = [
      highlightLineTop
      {
        flow = FLOW_HORIZONTAL
        size = flex()
        children = [
          smallImg
          wContent?(sf)
        ]
      }
    ]
  }.__update(animKey == null ? {} : animTable[animKey]))
}


let animations1 = freeze([{ prop = AnimProp.fillColor, from = transpPanelBgColor, to = hoverSlotBgColor,
        duration = DUR, play = true, trigger = "hovered+asasd"}])
let animations0 = freeze([
  { prop = AnimProp.color, from = transpPanelBgColor, to = hoverSlotBgColor, duration = 1, play = true,
    trigger = "hovered",}
  { prop = AnimProp.opacity, from = 0.7, to = 1, duration = DUR, play = true}
  { prop = AnimProp.scale, from = [1, 0.301], to = [1, 1], duration = DUR, play = true }
])

let function mkLargeWidget(content, idx, oldIdx) {
  if (content == null)
    return null

  let { widgetType, id = "", data = null, backImage = null } = content
  let offerData = widgetData[widgetType]
  let { ctor = null, onClick = null } = offerData
  let wContent = ctor?(data)
  let bgImage = freeze({
    rendObj = ROBJ_WORLD_BLUR
    size = [flex(), largeWidgetImgheight]
    color = defItemBlur
    fillColor = transpPanelBgColor
    clipChildren = true
    children = mkOfferImage(backImage)
  })

  return watchElemState(@(sf) {
    key = id
    size = [startBtnWidth, largeWidgetHeight]
    behavior = Behaviors.Button
    onClick = @() onClick?(data)
    onHover = function(on) {
      curLargeWidgetIdx(idx)
      if (on) {
        anim_skip(id)
        anim_start("hovered+asasd")
        gui_scene.clearTimer(goToNextOffer)
      }
      else
        startSwitchTimer()
    }
    clipChildren = true
    children = [
      bgImage
      {
        rendObj = ROBJ_WORLD_BLUR
        size = [flex(), largeWidgetInfoHeight]
        vplace = ALIGN_BOTTOM
        fillColor = sf & S_HOVER ? hoverSlotBgColor : transpPanelBgColor
        color = defItemBlur
        animations = animations1
        transform = {}
        children = wContent?(sf)
      }
    ]
    transform = { pivot = [1, idx < oldIdx ? 0 : 1] }
    animations = animations0
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
    halign = ALIGN_RIGHT
    children = widgets.map(@(w, idx) curLargeWidgetIdx.value == idx
      ? mkLargeWidget(w, idx, oldLargeWidgetIdx)
      : mkSmallWidget(w, idx, oldLargeWidgetIdx, curLargeWidgetIdx.value)
    )
  })
}

return offersPromoWidget
