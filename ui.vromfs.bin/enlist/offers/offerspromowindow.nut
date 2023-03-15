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
let { hasSpecialEvent, isRequestInProgress, eventsAvailable, isUnseen, markSeen
} = require("offersState.nut")
let spinner = require("%ui/components/spinner.nut")
let { eventTasksUi } = require("%enlist/unlocks/tasksWidgetUi.nut")
let { mkHeaderFlag, casualFlagStyle }= require("%enlSqGlob/ui/mkHeaderFlag.nut")
let { lockedCampaigns } = require("%enlist/meta/campaigns.nut")
let mkUnlockBtn = require("%enlist/campaigns/mkUnlockButton.nut")
let mkSquadBuyPromo = require("mkSquadBuyPromo.nut")
let { curArmyShopItems } = require("%enlist/shop/armyShopState.nut")
let serverTime = require("%enlSqGlob/userstats/serverTime.nut")


let PROMO_WIDTH = fsh(45)
let PROMO_GAP = fsh(2)
let DESC_WIDTH = fsh(120) - PROMO_WIDTH
let DESC_PADDING = hdpx(20)
let IMAGE_WIDTH = DESC_WIDTH - DESC_PADDING * 2

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
  image = function(obj, _, style) {
    local { width = IMAGE_WIDTH, height = null } = obj
    if (width > IMAGE_WIDTH) {
      height = height != null ? IMAGE_WIDTH * height / width : SIZE_TO_CONTENT
      width = IMAGE_WIDTH
    } else
      height = height ?? SIZE_TO_CONTENT
    return {
      size = [flex(), SIZE_TO_CONTENT]
      halign = ALIGN_CENTER
      clipChildren = true
      children = [
        obj.__merge({
          rendObj = ROBJ_IMAGE
          size = [width, height]
          image = Picture(obj.v)
          keepAspect = KEEP_ASPECT_FIT
          imageAffectsLayout = true
        })
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
  }
})

let scrollHandler = ScrollHandler()

let curEventId = mkWatched(persist, "curEventId", null)
let curEventData = Computed(@() eventsAvailable.value.findvalue(@(e) e.id == curEventId.value))


let closeBtnSmall = closeBtnBase({
  padding = fsh(1)
  vplace = ALIGN_TOP
  hplace = ALIGN_RIGHT
  onClick = @() curEventId(null)
}).__update({ margin = fsh(1) })

let closeBtn = textButton(loc("mainmenu/btnClose"), @() curEventId(null),
  { hotkeys = [[$"^{JB.B}"]] })

let function mkHeaderTimeLeft(time) {
  let timeLeft = Computed(@() max(0, time - serverTime.value))
  return @() {
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
}

let function offersWindowTitle() {
  let { title = "", heading = null, end = 0 } = curEventData.value
  let headingBackImage = !heading ? null : {
    size = flex()
    rendObj = ROBJ_IMAGE
    image = Picture(heading)
    keepAspect = KEEP_ASPECT_FILL
    imageHalign = ALIGN_CENTER
    imageValign = ALIGN_BOTTOM
  }
  return {
    watch = curEventData
    size = [flex(), hdpx(160)]
    valign = ALIGN_CENTER
    children = [
      headingBackImage
      mkHeaderTimeLeft(end)
      mkHeaderFlag({
        rendObj = ROBJ_TEXT
        text = utf8ToUpper(title)
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
  local { description = null } = curEventData.value
  if (description)
    description = formatText(description)
  return {
    size = flex()
    watch = [isRequestInProgress, curEventData]
    children = isRequestInProgress.value ? descriptionLoading
      : description ? makeVertScroll({
          size = [flex(), SIZE_TO_CONTENT]
          padding = DESC_PADDING
          children = description
        }, { scrollHandler, styling = thinStyle })
      : descriptionCommon
  }
}

let function offersButtons() {
  let children = []
  let { campaign_unlock_button = null } = curEventData.value?.tags
  if (campaign_unlock_button != null) {
    let lock = lockedCampaigns.value?[campaign_unlock_button]
    children.append(mkUnlockBtn(lock))
  }
  children.append(closeBtn)
  return {
    watch = curEventData
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
  let { squads = [] } = curEventData.value
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
    watch = [curArmyOfferSquads, curEventId]
    size = [PROMO_WIDTH, flex()]
    flow = FLOW_VERTICAL
    gap = PROMO_GAP
    valign = ALIGN_CENTER
    children = [
      hasOfferSquads ? mkPromoSquads(offerSquads) : null
      makeVertScroll(eventTasksUi(curEventId.value), { styling = thinStyle })
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

console_register_command(@(id) curEventId(id), "ui.offersPromoWindow")

let function close() {
  markSeen()
  sceneWithCameraRemove(offersWindow)
}

if (curEventId.value != null)
  open()

curEventId.subscribe(@(v) v != null ? open() : close())

let needShowOfferWindow = Computed(@() canDisplayOffers.value
  && hasSpecialEvent.value
  && isUnseen.value)

let openOfferWindowDelayed = @()
  gui_scene.resetTimeout(0.3, function() {
    if (needShowOfferWindow.value)
      curEventId(eventsAvailable.value[0].id)
  })

needShowOfferWindow.subscribe(@(v) v ? openOfferWindowDelayed() : null)
openOfferWindowDelayed()

return @(id) curEventId(id)
