from "%enlSqGlob/ui_library.nut" import *

let { h1_txt, body_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let { sceneWithCameraAdd, sceneWithCameraRemove } = require("%enlist/sceneWithCamera.nut")
let canDisplayOffers = require("%enlist/canDisplayOffers.nut")
let colorize = require("%ui/components/colorize.nut")
let { secondsToHoursLoc } = require("%ui/helpers/time.nut")
let { makeVertScroll, thinStyle } = require("%ui/components/scrollbar.nut")
let { safeAreaBorders } = require("%enlist/options/safeAreaState.nut")
let closeBtnBase = require("%ui/components/closeBtn.nut")
let textButton = require("%ui/components/textButton.nut")
let JB = require("%ui/control/gui_buttons.nut")
let { strokeStyle, bigPadding, hoverBgColor, accentTitleTxtColor, titleTxtColor
} = require("%enlSqGlob/ui/viewConst.nut")
let { mkFormatText } = require("%enlist/components/formatText.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { hasSpecialEvent, hasEventData, isRequestInProgress, isDataReady, offersTitle, offersTags,
  isUnseen, markSeen, timeLeft, headingAndDescription
} = require("offersState.nut")
let { squadsPromotion } = require("%enlist/unlocks/eventsTaskState.nut")
let spinner = require("%ui/components/spinner.nut")
let { eventTasksUi } = require("%enlist/unlocks/tasksWidgetUi.nut")
let { mkHeaderFlag, casualFlagStyle }= require("%enlSqGlob/ui/mkHeaderFlag.nut")
let { lockedCampaigns } = require("%enlist/meta/campaigns.nut")
let mkUnlockBtn = require("%enlist/campaigns/mkUnlockButton.nut")
let mkSquadBuyPromo = require("mkSquadBuyPromo.nut")
let { curArmyShopItems } = require("%enlist/shop/armyShopState.nut")

let PROMO_WIDTH = fsh(45)
let PROMO_GAP = fsh(2)
let DESC_WIDTH = fsh(120) - PROMO_WIDTH
let DESC_PADDING = hdpx(20)

let header_txt = { font = Fonts.trebuchet, fontSize = fsh(2.78) }
let text_txt = { font = Fonts.trebuchet, fontSize = fsh(1.76) }

let formatText = mkFormatText({
  defTextColor = Color(200,200,200)
  h1FontStyle = header_txt
  h2FontStyle = header_txt
  h3FontStyle = header_txt
  textFontStyle = text_txt
  noteFontStyle = text_txt
  h1Color = titleTxtColor
  h2Color = titleTxtColor
  h3Color = titleTxtColor
  emphasisColor = titleTxtColor
  padding = fsh(1)
}, {
  image = @(obj, _, style) {
    size = [flex(), SIZE_TO_CONTENT]
    clipChildren = true
    children = [
      {
        rendObj = ROBJ_IMAGE
        size = [DESC_WIDTH - DESC_PADDING * 2, SIZE_TO_CONTENT]
        image = Picture(obj.v)
        keepAspect = true
      }.__update(obj)
      !obj?.caption ? null : {
        rendObj = ROBJ_TEXTAREA
        size = [flex(), SIZE_TO_CONTENT]
        behavior = Behaviors.TextArea
        padding = style.padding
        halign = ALIGN_CENTER
        vplace = ALIGN_BOTTOM
        margin = [fsh(1), fsh(3)]
        text = obj?.caption
      }.__update(text_txt, strokeStyle)
    ]
  }
})

let scrollHandler = ScrollHandler()

let isOpened = mkWatched(persist, "isOpened", false)

let closeBtnSmall = closeBtnBase({
  padding = fsh(1)
  vplace = ALIGN_TOP
  hplace = ALIGN_RIGHT
  onClick = @() isOpened(false)
}).__update({ margin = fsh(1) })

let closeBtn = textButton(loc("mainmenu/btnClose"), @() isOpened(false),
  { hotkeys = [[$"^{JB.B}"]] })

let headerTimeLeft = @() {
  watch = timeLeft
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  text = loc("offers/timeLeft", {
    time = colorize(accentTitleTxtColor, secondsToHoursLoc(timeLeft.value))
  })
  vplace = ALIGN_BOTTOM
  margin = bigPadding
  fontFx = FFT_BLUR
  fontFxColor = 0x7F000000
}.__update(body_txt)

let function offersWindowTitle() {
  let { heading = null } = headingAndDescription.value
  let headingBackImage = !heading?.v ? null : {
    size = flex()
    rendObj = ROBJ_IMAGE
    image = Picture(heading.v)
    keepAspect = KEEP_ASPECT_FILL
    clipChildren = true
  }
  return {
    watch = [offersTitle, headingAndDescription]
    size = [flex(), hdpx(160)]
    valign = ALIGN_CENTER
    children = [
      headingBackImage
      headerTimeLeft
      mkHeaderFlag({
        rendObj = ROBJ_TEXT
        text = utf8ToUpper(offersTitle.value)
        padding = [fsh(2), fsh(3)]
        color = titleTxtColor
      }.__update(h1_txt),
      casualFlagStyle)
    ]
  }
}

let descriptionLoading = freeze({
  size = flex()
  flow  = FLOW_VERTICAL
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  gap = bigPadding
  children = [
    {
      rendObj = ROBJ_TEXT
      text = loc("Loading")
    }.__update(h1_txt)
    spinner
  ]
})

let descriptionCommon = {
  size = flex()
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = {
    rendObj = ROBJ_TEXTAREA
    size = [fsh(60), SIZE_TO_CONTENT]
    behavior = Behaviors.TextArea
    text = loc("offers/commonDescription")
  }.__update(body_txt)
}

let function offersWindowDescription() {
  local { description = null } = headingAndDescription.value
  if (description)
    description = formatText(description)
  return {
    size = flex()
    watch = [isRequestInProgress, isDataReady, headingAndDescription]
    children = isRequestInProgress.value ? descriptionLoading
      : isDataReady.value ? makeVertScroll({
          size = [flex(), SIZE_TO_CONTENT]
          padding = DESC_PADDING
          children = description
        }, { scrollHandler, styling = thinStyle })
      : descriptionCommon
  }
}

let function offersButtons() {
  let children = []
  let { campaign_unlock_button = null } = offersTags.value
  if (campaign_unlock_button != null) {
    let lock = lockedCampaigns.value?[campaign_unlock_button]
    children.append(mkUnlockBtn(lock))
  }
  children.append(closeBtn)
  return {
    watch = offersTags
    flow = FLOW_HORIZONTAL
    halign = ALIGN_CENTER
    children
  }
}

let curArmyShopSquads = Computed(function() {
  let res = {}
  foreach (item in curArmyShopItems.value)
    foreach (squad in item?.squads ?? [])
      res[squad.id] <- true

  return res
})

let curArmyOfferSquads = Computed(function() {
  let squads = squadsPromotion.value
  if (squads.len() == 0)
    return null

  let availSquads = curArmyShopSquads.value
  let res = squads.filter(@(id) id in availSquads)
  return res.len() == 0 ? null : res
})

let function mkPromoSquads(offerSquads) {
  let children = []
  foreach (squadId in offerSquads)
    children.append(mkSquadBuyPromo(squadId, {
      size = [PROMO_WIDTH, SIZE_TO_CONTENT]
    }))

  return {
    flow = FLOW_VERTICAL
    gap = PROMO_GAP
    halign = ALIGN_CENTER
    children
  }
}

let offersBlock = {
  rendObj = ROBJ_SOLID
  size = [DESC_WIDTH, flex()]
  halign = ALIGN_CENTER
  flow = FLOW_VERTICAL
  color = 0xFF050A0F
  children = [
    offersWindowTitle
    offersWindowDescription
    offersButtons
  ]
}

let function promoBlock() {
  let offerSquads = curArmyOfferSquads.value
  let hasOfferSquads = offerSquads != null
  return {
    watch = curArmyOfferSquads
    size = [PROMO_WIDTH, flex()]
    flow = FLOW_VERTICAL
    gap = PROMO_GAP
    valign = ALIGN_CENTER
    children = [
      hasOfferSquads ? mkPromoSquads(offerSquads) : null
      makeVertScroll(eventTasksUi, { styling = thinStyle })
    ]
  }
}

let offersWindow = @() {
  size = flex()
  halign = ALIGN_CENTER
  watch = safeAreaBorders
  padding = safeAreaBorders.value
  children = [
    {
      rendObj = ROBJ_WORLD_BLUR
      size = [SIZE_TO_CONTENT, flex()]
      flow = FLOW_HORIZONTAL
      gap = fsh(1.5)
      color = hoverBgColor
      children = [
        offersBlock
        promoBlock
      ]
    }
    closeBtnSmall
  ]
}

let function open() {
  sceneWithCameraAdd(offersWindow, "researches")
}

console_register_command(@() isOpened(true), "ui.offersPromoWindow")

let function close() {
  markSeen()
  sceneWithCameraRemove(offersWindow)
}

if (isOpened.value)
  open()

isOpened.subscribe(@(v) v ? open() : close())

let needShowOfferWindow = Computed(@() canDisplayOffers.value
  && hasSpecialEvent.value
  && hasEventData.value
  && isUnseen.value)

let openOfferWindowDelayed = @()
  gui_scene.resetTimeout(0.3, function() {
    if (needShowOfferWindow.value)
      isOpened(true)
  })

needShowOfferWindow.subscribe(@(v) v ? openOfferWindowDelayed() : null)
openOfferWindowDelayed()

return @() isOpened(true)
