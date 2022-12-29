from "%enlSqGlob/ui_library.nut" import *

let { sub_txt, body_txt} = require("%enlSqGlob/ui/fonts_style.nut")
let {
  eventCampaigns, hasChoosedCampaign, isCurCampaignAvailable, isEventModesOpened
} = require("eventModesState.nut")
let {
  defTxtColor, blurBgFillColor, smallPadding, titleTxtColor, blurBgColor, maxContentWidth,
  defBgColor, shadowStyle, commonBtnHeight
} = require("%enlSqGlob/ui/viewConst.nut")
let { localGap } = require("%enlist/gameModes/eventModeStyle.nut")
let { gameProfile } = require("%enlist/soldiers/model/config/gameProfile.nut")
let { curCampaign, setCurCampaign } = require("%enlist/meta/curCampaign.nut")
let { safeAreaBorders, safeAreaSize } = require("%enlist/options/safeAreaState.nut")
let { addModalWindow, removeModalWindow } = require("%ui/components/modalWindows.nut")
let math = require("%sqstd/math.nut")
let closeBtnBase = require("%ui/components/closeBtn.nut")


const TOTAL_ROWS = 2
const WND_UID = "CHOOSE_CAMPAIGN_WND"

let isOpened = mkWatched(persist, "isOpened", false)
let close = @() isOpened(false)

let campaignsCount = Computed(@() eventCampaigns.value.len())
let campaignsFreeHeight = sh(75)
let gapCards = hdpx(25)
let IMAGE_RATIO = 16.0 / 9.0
let nameBlockHeight = hdpx(50)
let hoverColor = Color(240, 200, 100, 190)
let selAnimOffset = hdpx(9)
let paddingTitle = hdpx(12)
let paddingInternal = hdpx(6)

let campPerRow = Computed(@()
  max(1, math.ceil(campaignsCount.value.tofloat() / TOTAL_ROWS).tointeger()))

let imgSize = Computed(function() {
  let height = min(
    (min(safeAreaSize.value[1], campaignsFreeHeight) - (TOTAL_ROWS - 1) * gapCards) / TOTAL_ROWS,
    ((safeAreaSize.value[0] - (campPerRow.value - 1) * gapCards) / campPerRow.value) / IMAGE_RATIO
  ).tointeger()
  let width = (height * IMAGE_RATIO).tointeger()
  return [width, height]
})

let closeBtn = closeBtnBase({ onClick = close }).__update({ pos = [0, fsh(4)] })
let selAnimDelay = 0.9
let selAnimDuration = 0.8

let mkSelectedFrame = @(size) {
  size
  vplace = ALIGN_CENTER
  hplace = ALIGN_CENTER
  opacity = 0
  rendObj = ROBJ_FRAME
  borderWidth = hdpx(4)
  transform = {}
  animations = [
    { prop = AnimProp.opacity, from = 0, to = 0.5, easing = CosineFull,
      delay = selAnimDelay, duration = selAnimDuration, play = true, loop = true }
    { prop = AnimProp.scale, from = [1, 1], to = size.map(@(v) (v + selAnimOffset).tofloat() / v), easing = OutCubic,
      delay = selAnimDelay, duration = selAnimDuration, play = true, loop = true }
  ]
}

let mkText = @(text, color = titleTxtColor, style = body_txt) {
  rendObj = ROBJ_TEXT
  text
  color
}.__update(style, shadowStyle)

let mkCampaignImg = @(campaign, sf) {
  size = flex()
  clipChildren = true
  children = {
    size = flex()
    rendObj = ROBJ_IMAGE
    keepAspect = KEEP_ASPECT_FILL
    transform = { scale = sf & S_HOVER ? [1.05, 1.05] : [1, 1] }
    transitions = [ { prop = AnimProp.scale, duration = 0.4, easing = OutQuintic } ]
    hplace = ALIGN_CENTER
    vplace = ALIGN_CENTER
    image = Picture($"ui/gameImage/{campaign}.jpg")
  }
}

let mkCampaignName = @(name) {
  rendObj = ROBJ_SOLID
  size = [flex(), nameBlockHeight]
  padding = paddingTitle
  vplace = ALIGN_BOTTOM
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  color = defBgColor
  children = mkText(name)
}


let campaignBtn = @(campaign) watchElemState(function(sf) {
  let isSelected = curCampaign.value == campaign
  let campaignName = loc(gameProfile.value?.campaigns[campaign].title ?? campaign)
  let size = imgSize.value
  return {
    watch = [imgSize, curCampaign, gameProfile]
    rendObj = ROBJ_BOX
    size
    padding = paddingInternal
    fillColor = Color(50,50,50)
    borderColor = sf & S_HOVER ? hoverColor : Color(80,80,80,80)
    borderWidth = (sf & S_HOVER) != 0 || isSelected ? hdpx(2) : 0
    behavior = Behaviors.Button
    function onClick() {
      setCurCampaign(campaign)
      close()
    }
    sound = {
      hover = "ui/enlist/button_highlight"
      click = "ui/enlist/button_click"
    }
    children = [
      mkCampaignImg(campaign, sf)
      mkCampaignName(campaignName)
      isSelected ? mkSelectedFrame(size) : null
    ]
  }
})

let mkRows = @(all, perRow) array(min(all.len(), TOTAL_ROWS))
  .map(function(_, rowIdx) {
    let inRowList = all.slice(rowIdx * perRow, min((rowIdx + 1) * perRow, all.len()))
    return {
      flow = FLOW_HORIZONTAL
      gap = gapCards
      children = inRowList.map(campaignBtn)
    }
  })

let header = {
  halign = ALIGN_CENTER
  hplace = ALIGN_CENTER
  flow = FLOW_VERTICAL
  children = {
    rendObj = ROBJ_TEXT
    color = defTxtColor
    text = loc("campaign/selectNew")
  }.__update(body_txt)
}

let campaignSelect = @() {
  watch = [eventCampaigns, campPerRow]
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  flow = FLOW_VERTICAL
  halign = ALIGN_CENTER
  gap = gapCards
  children = [header].extend(mkRows(eventCampaigns.value, campPerRow.value))

  transform = {}
  animations = [
    { prop = AnimProp.opacity, from = 0, to = 1, duration = 0.5, play = true, easing = OutCubic }
    { prop = AnimProp.translate, from =[hdpx(150), 0], play = true, to = [0, 0], duration = 0.2, easing = OutQuad }
  ]
}

let lobbyCampaignChooseWnd = @() {
  watch = safeAreaBorders
  size = [sw(100), sh(100)]
  halign = ALIGN_CENTER
  padding = safeAreaBorders.value
  rendObj = ROBJ_WORLD_BLUR_PANEL
  color = blurBgColor
  fillColor = blurBgFillColor

  children = {
    size = flex()
    maxWidth = maxContentWidth
    children = [
      closeBtn
      campaignSelect
    ]
  }
}

let open = @() addModalWindow({
  key = WND_UID
  rendObj = ROBJ_SOLID
  color = blurBgFillColor
  valign = ALIGN_CENTER
  children = lobbyCampaignChooseWnd
  onClick = close
})

let BLINK_SEC = 0.7
let function mkBlinkAnim(trigger) {
  let res = []
  for (local i = 0; i < 3; i++)
    res.append({ prop = AnimProp.opacity, from = 1, to = 0.3, delay = i * BLINK_SEC,
    duration = BLINK_SEC, easing = CosineFull, trigger
  })
  return res
}

let lobbyCampaignBlock = watchElemState(@(sf){
  rendObj = ROBJ_SOLID
  watch = [campaignsCount, hasChoosedCampaign]
  margin = [0,0,hdpx(150),0]
  size = [flex(), commonBtnHeight + localGap]
  flow = FLOW_VERTICAL
  behavior = Behaviors.Button
  gap = smallPadding
  color = ((sf & S_HOVER) != 0 && campaignsCount.value > 1) || !hasChoosedCampaign.value
    ? Color(35, 35, 35, 25)
    : blurBgFillColor
  valign = ALIGN_CENTER
  onClick = @() hasChoosedCampaign.value ? null : isOpened(true)
  padding = [0, localGap]
  children = [
    campaignsCount.value < 2 || hasChoosedCampaign.value ? null : mkText(loc("army/selectNew"), defTxtColor, sub_txt)
      @(){
        watch = [curCampaign, gameProfile]
        size = [flex(), SIZE_TO_CONTENT]
        flow = FLOW_HORIZONTAL
        valign = ALIGN_CENTER
        children = {
          rendObj = ROBJ_TEXT
          size = [flex(), SIZE_TO_CONTENT]
          text = loc(gameProfile.value?.campaigns[curCampaign.value]?.title ?? curCampaign.value)
          animations = mkBlinkAnim("campaign_blink")
        }.__update(body_txt)
      }
  ]
})

let function closeCb() {
  removeModalWindow(WND_UID)
}

if (isOpened.value)
  open()
isOpened.subscribe(@(v) v ? open() : closeCb())


let function checkWndRequired(_) {
  if (!isCurCampaignAvailable.value && eventCampaigns.value.len() > 1 && isEventModesOpened.value)
    isOpened(true)
}

foreach(v in [isCurCampaignAvailable, eventCampaigns, isEventModesOpened])
  v.subscribe(checkWndRequired)


return lobbyCampaignBlock
