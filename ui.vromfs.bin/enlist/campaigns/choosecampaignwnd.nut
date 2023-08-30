from "%enlSqGlob/ui_library.nut" import *

let { fontBody, fontSub} = require("%enlSqGlob/ui/fontsStyle.nut")
let math = require("%sqstd/math.nut")
let { titleTxtColor, panelBgColor, defItemBlur, defTxtColor, darkPanelBgColor, brightAccentColor,
  accentColor, darkTxtColor, selectedPanelBgColor } = require("%enlSqGlob/ui/designConst.nut")
let { blinkUnseen } = require("%ui/components/unseenComponents.nut")
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
let { nestWatched } = require("%dngscripts/globalState.nut")

let isOpened = nestWatched("isOpened", false)

const SHAKE_TEXT_ID = "SHAKE_TEXT_ID"
const TOTAL_ROWS = 2
let IMAGE_RATIO = 16.0 / 9.0
let paddingInternal = hdpx(6)
let paddingTitle = hdpx(12)
let gapCards = hdpx(25)
let selAnimOffset = hdpx(9)
let campaignsFreeHeight = sh(75)
let nameBlockHeight = hdpx(50)
let btnOffset = nameBlockHeight + hdpx(12)

let campPerRow = Computed(@()
  max(1, math.ceil(visibleCampaigns.value.len().tofloat() / TOTAL_ROWS).tointeger()))

let function calcSize(safeAreaArr, campsPerRowCount) {
  let height = min(
    (min(safeAreaArr[1], campaignsFreeHeight) - (TOTAL_ROWS - 1) * gapCards) / TOTAL_ROWS,
    ((safeAreaArr[0] - (campsPerRowCount - 1) * gapCards) / campsPerRowCount) / IMAGE_RATIO
  ).tointeger()
  let width = (height * IMAGE_RATIO).tointeger()
  return [width, height]
}

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
}.__update(fontBody)

let mkCampaignImg = @(campaign, isAvailable, sf) {
  size = flex()
  clipChildren = true
  children = {
    size = flex()
    rendObj = ROBJ_IMAGE
    keepAspect = KEEP_ASPECT_FILL
    hplace = ALIGN_CENTER
    vplace = ALIGN_CENTER
    image = Picture($"ui/gameImage/{campaign}.avif")
  }.__update(isAvailable
    ? {
        transform = { scale = sf & S_HOVER ? [1.05, 1.05] : [1, 1] }
        transitions = [ { prop = AnimProp.scale, duration = 0.4, easing = OutQuintic } ]
      }
    : { tint = Color(40, 40, 40, 120), picSaturate = 0.0 })
}

let mkCampaignName = @(name, sf, isSelected) {
  rendObj = ROBJ_SOLID
  size = [flex(), nameBlockHeight]
  padding = paddingTitle
  vplace = ALIGN_BOTTOM
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  color = sf & S_HOVER ? accentColor
    : isSelected ? selectedPanelBgColor
    : panelBgColor
  children = mkText(name, sf & S_HOVER ? darkTxtColor
    : isSelected ? accentColor
    : defTxtColor)
}

let mkNotAvailableText = @(text, triggerId) {
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  transform = {}
  animations = [{ trigger = triggerId, prop = AnimProp.translate,
    from = [-hdpx(20), 0], to = [0, 0], play = false, duration = 1, easing = OutElastic }]
  children = {
    rendObj = ROBJ_TEXT
    text
    color = defTxtColor
  }.__update(fontBody)
}

let function campaignBtn(campaign, cardSize) {
  let isSelected = Computed(@() selectedCampaign.value == campaign)
  let isAvailableWatched = Computed(@() unlockedCampaigns.value.contains(campaign))
  let isUnseen = Computed(@() campaign in unseenCampaigns.value)

  return watchElemState(function(sf) {
    let isAvailable = isAvailableWatched.value
    let lock = lockedCampaigns.value?[campaign]
    let campaignName = loc(gameProfile.value?.campaigns[campaign]?.title ?? campaign)
    return {
      watch = [unseenCampaigns, isSelected, isAvailableWatched, gameProfile, safeAreaSize,
        campPerRow, lockedCampaigns, isUnseen]
      rendObj = ROBJ_BOX
      size = cardSize
      padding = paddingInternal
      fillColor = panelBgColor
      borderColor = sf & S_HOVER ? brightAccentColor : panelBgColor
      borderWidth = (sf & S_HOVER) || isSelected.value ? hdpx(2) : 0
      behavior = Behaviors.Button

      onClick = @() isAvailable
        ? selectCampaign(campaign)
        : anim_start(SHAKE_TEXT_ID + campaign)
      onHover = hoverHoldAction("unseenCampaign", campaign, @(c) markSeenCampaign(c))

      children = [
        mkCampaignImg(campaign, isAvailable, sf)
        mkCampaignName(campaignName, sf, isSelected.value)
        isAvailable ? null
          : mkNotAvailableText(
              lock == null ? loc("campaign/notAvailable")
                : lock?.reqVersion != null ? loc("campaign/oldClientVersion")
                : loc("campaign/locked"),
              $"{SHAKE_TEXT_ID}{campaign}")
        mkUnlockBtn(lock, { margin = [0, 0, btnOffset, 0] })
        isSelected.value ? mkSelectedFrame(cardSize) : null
        isUnseen.value ? blinkUnseen: null
      ]

      sound = {
        hover = "ui/enlist/button_highlight"
        click = "ui/enlist/button_click"
      }
    }
    })
}

let mkRows = @(all, perRow, cardSize) array(min(all.len(), TOTAL_ROWS))
  .map(function(_, rowIdx) {
    let inRowList = all.slice(rowIdx * perRow, min((rowIdx + 1) * perRow, all.len()))
    return {
      flow = FLOW_HORIZONTAL
      gap = gapCards
      children = inRowList.map(@(v) campaignBtn(v, cardSize))
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
    }.__update(fontBody)
    {
      rendObj = ROBJ_TEXT
      color = defTxtColor
      text = "({0})".subst(loc("campaign/changeAvailable"))
    }.__update(fontSub)
  ]
}

let function campaignSelect() {
  let cardSize = calcSize(safeAreaSize.value, campPerRow.value)
  return {
    watch = [safeAreaSize, visibleCampaigns, campPerRow]
    hplace = ALIGN_CENTER
    vplace = ALIGN_CENTER
    flow = FLOW_VERTICAL
    halign = ALIGN_CENTER
    gap = gapCards
    children = [header].extend(mkRows(visibleCampaigns.value, campPerRow.value, cardSize))

    transform = {}
    animations = [
      { prop = AnimProp.opacity, from = 0, to = 1, duration = 0.5, play = true, easing = OutCubic }
      { prop = AnimProp.translate, from =[hdpx(150), 0], play = true, to = [0, 0], duration = 0.2, easing = OutQuad }
    ]
  }
}

campaignSelectWnd = @() {
  watch = [safeAreaBorders, selectedCampaign]
  size = [sw(100), sh(100)]
  padding = safeAreaBorders.value
  rendObj = ROBJ_WORLD_BLUR_PANEL
  color = defItemBlur
  fillColor = darkPanelBgColor

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