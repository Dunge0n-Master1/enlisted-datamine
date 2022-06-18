from "%enlSqGlob/ui_library.nut" import *

let { body_txt, sub_txt} = require("%enlSqGlob/ui/fonts_style.nut")
let math = require("%sqstd/math.nut")
let {
  shadowStyle, titleTxtColor, defBgColor, blurBgColor,
  blurBgFillColor, defTxtColor
} = require("%enlSqGlob/ui/viewConst.nut")
let { txt } = require("%enlSqGlob/ui/defcomps.nut")
let unseenSignal = require("%ui/components/unseenSignal.nut")()
let { safeAreaBorders, safeAreaSize } = require("%enlist/options/safeAreaState.nut")
let closeBtnBase = require("%ui/components/closeBtn.nut")
let { onlineSettingUpdated } = require("%enlist/options/onlineSettings.nut")
let { sceneWithCameraAdd, sceneWithCameraRemove } = require("%enlist/sceneWithCamera.nut")
let { selectedCampaign, setCurCampaign } = require("%enlist/meta/curCampaign.nut")
let { unseenCampaigns, markSeenCampaign } = require("unseenCampaigns.nut")
let hoverHoldAction = require("%darg/helpers/hoverHoldAction.nut")
let { gameProfile } = require("%enlist/soldiers/model/config/gameProfile.nut")
let { unlockedCampaigns, visibleCampaigns, lockedCampaigns } = require("%enlist/meta/campaigns.nut")
let { widgetUserName } = require("%enlist/components/userName.nut")
let mkUnlockBtn = require("%enlist/campaigns/mkUnlockButton.nut")

let isOpened = mkWatched(persist,"isOpened", false)

const SHAKE_TEXT_ID = "SHAKE_TEXT_ID"
const TOTAL_ROWS = 2
let IMAGE_RATIO = 16.0 / 9.0
let hoverColor = Color(240, 200, 100, 190)
let paddingInternal = hdpx(6)
let paddingTitle = hdpx(12)
let gapCards = hdpx(25)
let selAnimOffset = hdpx(9)
let campaignsFreeHeight = sh(75)
let nameBlockHeight = hdpx(50)
let btnOffset = nameBlockHeight + hdpx(12)

let campPerRow = Computed(@()
  max(1, math.ceil(visibleCampaigns.value.len().tofloat() / TOTAL_ROWS).tointeger()))

let imgSize = Computed(function() {
  let height = min(
    (min(safeAreaSize.value[1], campaignsFreeHeight) - (TOTAL_ROWS - 1) * gapCards) / TOTAL_ROWS,
    ((safeAreaSize.value[0] - (campPerRow.value - 1) * gapCards) / campPerRow.value) / IMAGE_RATIO
  ).tointeger()
  let width = (height * IMAGE_RATIO).tointeger()
  return [width, height]
})

local campaignSelectWnd = null

let function close() {
  sceneWithCameraRemove(campaignSelectWnd)
  isOpened(false)
}

let function open() {
  close()
  sceneWithCameraAdd(campaignSelectWnd, "armory")
  isOpened(true)
}

let function selectCampaign(campaign) {
  setCurCampaign(campaign)
  close()
}

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

let mkText = @(text, color = titleTxtColor) {
  rendObj = ROBJ_TEXT
  text
  color
}.__update(body_txt, shadowStyle)

let mkCampaignImg = @(campaign, isAvailable, sf) {
  size = flex()
  clipChildren = true
  children = {
    size = flex()
    rendObj = ROBJ_IMAGE
    keepAspect = KEEP_ASPECT_FILL
    hplace = ALIGN_CENTER
    vplace = ALIGN_CENTER
    image = Picture($"ui/gameImage/{campaign}.jpg")
  }.__update(isAvailable
    ? {
        transform = { scale = sf & S_HOVER ? [1.05, 1.05] : [1, 1] }
        transitions = [ { prop = AnimProp.scale, duration = 0.4, easing = OutQuintic } ]
      }
    : { tint = Color(40, 40, 40, 120), picSaturate = 0.0 })
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

let mkNotAvailableText = @(text, triggerId) {
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  transform = {}
  animations = [{ trigger = triggerId, prop = AnimProp.translate,
    from = [-hdpx(20), 0], to = [0, 0], play = false, duration = 1, easing = OutElastic }]
  children = txt({ text }.__update(body_txt))
}

let campaignBtn = @(campaign) watchElemState(function(sf) {
  let isSelected = selectedCampaign.value == campaign
  let isAvailable = unlockedCampaigns.value.contains(campaign)
  let lock = lockedCampaigns.value?[campaign]
  let campaignName = loc(gameProfile.value?.campaigns[campaign]?.title ?? campaign)
  let size = imgSize.value
  return {
    watch = [imgSize, unseenCampaigns, selectedCampaign, unlockedCampaigns, gameProfile]
    rendObj = ROBJ_BOX
    size
    padding = paddingInternal
    fillColor = Color(50,50,50)
    borderColor = sf & S_HOVER ? hoverColor : Color(80,80,80,80)
    borderWidth = (sf & S_HOVER) != 0 || isSelected ? hdpx(2) : 0
    behavior = Behaviors.Button

    onClick = @() isAvailable
      ? selectCampaign(campaign)
      : anim_start(SHAKE_TEXT_ID + campaign)
    onHover = hoverHoldAction("unseenCampaign", campaign, @(c) markSeenCampaign(c))

    children = [
      mkCampaignImg(campaign, isAvailable, sf)
      mkCampaignName(campaignName)
      isAvailable ? null
        : mkNotAvailableText(
            lock == null ? loc("campaign/notAvailable")
              : lock?.reqVersion != null ? loc("campaign/oldClientVersion")
              : loc("campaign/locked"),
            $"{SHAKE_TEXT_ID}{campaign}")
      mkUnlockBtn(lock, { margin = [0, 0, btnOffset, 0] })
      isSelected ? mkSelectedFrame(size) : null
      campaign in unseenCampaigns.value
        ? unseenSignal.__update({ hplace = ALIGN_RIGHT })
        : null
    ]

    sound = {
      hover = "ui/enlist/button_highlight"
      click = "ui/enlist/button_click"
    }
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
  children = [
    {
      rendObj = ROBJ_TEXT
      color = defTxtColor
      text = loc("campaign/selectNew")
    }.__update(body_txt)
    {
      rendObj = ROBJ_TEXT
      color = defTxtColor
      text = "({0})".subst(loc("campaign/changeAvailable"))
    }.__update(sub_txt)
  ]
}

let campaignSelect = @() {
  watch = [visibleCampaigns, campPerRow]
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  flow = FLOW_VERTICAL
  halign = ALIGN_CENTER
  gap = gapCards
  children = [header].extend(mkRows(visibleCampaigns.value, campPerRow.value))

  transform = {}
  animations = [
    { prop = AnimProp.opacity, from = 0, to = 1, duration = 0.5, play = true, easing = OutCubic }
    { prop = AnimProp.translate, from =[hdpx(150), 0], play = true, to = [0, 0], duration = 0.2, easing = OutQuad }
  ]
}

campaignSelectWnd = @() {
  watch = [safeAreaBorders, selectedCampaign]
  size = [sw(100), sh(100)]
  padding = safeAreaBorders.value
  rendObj = ROBJ_WORLD_BLUR_PANEL
  color = blurBgColor
  fillColor = blurBgFillColor

  children = [
    selectedCampaign.value != null ? closeBtn : null
    campaignSelect
    widgetUserName
  ]
}

if (isOpened.value)
  open()

let campaignsUpdated = keepref(Computed(@() onlineSettingUpdated.value
  && unlockedCampaigns.value.len() > 0
  && selectedCampaign.value == null))

let function selectCampaignOrOpen(val) {
  if (val)
    if (unlockedCampaigns.value.len() == 1)
      selectCampaign(unlockedCampaigns.value[0])
    else
      open()
}

campaignsUpdated.subscribe(selectCampaignOrOpen)

return {
  open
  close
}