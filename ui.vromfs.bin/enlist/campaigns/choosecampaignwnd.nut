from "%enlSqGlob/ui_library.nut" import *

let { fontXLarge, fontMedium } = require("%enlSqGlob/ui/fontsStyle.nut")
let { colPart, colFull, defTxtColor, titleTxtColor, midPadding, commonBorderRadius,
  selectedBgColor, navHeight, sidePadding
} = require("%enlSqGlob/ui/designConst.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { safeAreaBorders } = require("%enlist/options/safeAreaState.nut")
let { onlineSettingUpdated } = require("%enlist/options/onlineSettings.nut")
let { sceneWithCameraAdd, sceneWithCameraRemove } = require("%enlist/sceneWithCamera.nut")
let { selectedCampaign, setCurCampaign } = require("%enlist/meta/curCampaign.nut")
let { unseenCampaigns, markSeenCampaign } = require("unseenCampaigns.nut")
let hoverHoldAction = require("%darg/helpers/hoverHoldAction.nut")
let { gameProfile } = require("%enlist/soldiers/model/config/gameProfile.nut")
let { unlockedCampaigns, visibleCampaigns, lockedCampaigns } = require("%enlist/meta/campaigns.nut")
let { widgetUserName } = require("%enlist/components/userName.nut")
let { nestWatched } = require("%dngscripts/globalState.nut")
let { doubleSideHighlightLine, doubleSideBg } = require("%enlSqGlob/ui/defComponents.nut")
let { Bordered } = require("%ui/components/txtButton.nut")
let JB = require("%ui/control/gui_buttons.nut")
let { mkColoredGradientY } = require("%enlSqGlob/ui/gradients.nut")
let { unseenPanel } = require("%ui/components/unseenComponents.nut")
let { makeHorizScroll, styling } = require("%ui/components/scrollbar.nut")
let { isGamepad } = require("%ui/control/active_controls.nut")
let { shopItems } = require("%enlist/shop/shopItems.nut")
let buyShopItem = require("%enlist/shop/buyShopItem.nut")


let isOpened = nestWatched("isCampaignWndOpened", false)
const SHAKE_TEXT_ID = "SHAKE_TEXT_ID"
let cardSize = [colFull(4), colPart(7.516)]
let nameBlockSize = [colFull(4), colPart(1.322)]
let unseenPanelPos = [0, -colPart(0.709) - colPart(0.387)]

let nameBlockBgImg = mkColoredGradientY(0xFF444555, 0xFF181F34)
let activeNameBlockBgImg = mkColoredGradientY(0xFF5979B4, 0xFF2B2D44)
let scrollStyle = styling.__merge({ Bar = styling.Bar(false) })

let titleTxtStyle = { color = titleTxtColor }.__update(fontXLarge)
let defTxtStyle = { color = defTxtColor }.__update(fontMedium)

let tblScrollHandler = ScrollHandler()

let selectedLine = {
  size = [flex(), colPart(0.06)]
  rendObj = ROBJ_BOX
  borderWidth = 0
  borderRadius = commonBorderRadius
  fillColor = selectedBgColor
  vplace = ALIGN_BOTTOM
  pos = [0, midPadding]
}


let wndHeader = {
  minWidth = colFull(8)
  hplace = ALIGN_CENTER
  halign = ALIGN_CENTER
  flow = FLOW_VERTICAL
  gap = midPadding
  margin = [colPart(1.61), 0 ,0,0 ]
  children = [
    {
      size = [SIZE_TO_CONTENT, colPart(1.023)]
      children = [
        doubleSideBg({
          rendObj = ROBJ_TEXT
          text = utf8ToUpper(loc("campaign/selectNew"))
        }.__update(titleTxtStyle))
        doubleSideHighlightLine
        doubleSideHighlightLine({ vplace = ALIGN_BOTTOM })]
    }
    {
      rendObj = ROBJ_TEXT
      text = loc("campaign/changeAvailable")
    }.__update(defTxtStyle)
  ]
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


let backBtn = Bordered(loc("gamemenu/btnBack"), close, { hotkeys = [[$"^{JB.B} | Esc"]] })


let function mkAnimations(idx, len) {
  let delay = idx * min(0.15, 0.9 / len)
  return [
    { prop = AnimProp.opacity, from = 0, to = 0, duration = delay, play = true }
    { prop = AnimProp.opacity, from = 0, to = 1, duration = 0.3, delay,
      play = true, easing = InOutCubic }
    { prop = AnimProp.translate, from = [sw(20), -fsh(5)], to = [0,0], duration = 0.4, delay,
      play = true, easing = InOutCubic }
    { prop = AnimProp.scale, from = [1.3, 1.3], to = [1,1], duration = 0.3, delay,
      play = true, easing = InOutCubic }
  ]
}


let mkImage = @(image, isAvailable, sf) {
  size = flex()
  clipChildren = true
  children = {
    size = flex()
    rendObj = ROBJ_IMAGE
    keepAspect = KEEP_ASPECT_FILL
    imageHalign = ALIGN_CENTER
    imageValign = ALIGN_CENTER
    image = Picture(image)
  }.__update(isAvailable
    ? {
        transform = { scale = sf & S_HOVER ? [1.05, 1.05] : [1, 1] }
        transitions = [ { prop = AnimProp.scale, duration = 0.4, easing = OutQuintic } ]
      }
    : { picSaturate = 0.3, tint = Color(0, 0, 0, 128) })
}


let nameBlock = @(name, sf, isSelected = false) {
  rendObj = ROBJ_IMAGE
  size = [flex(), nameBlockSize[1]]
  image = isSelected || (sf & S_ACTIVE) || (sf & S_HOVER) ? activeNameBlockBgImg : nameBlockBgImg
  valign = ALIGN_CENTER
  vplace = ALIGN_BOTTOM
  gap = midPadding
  children = [
    {
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      size = [flex(), SIZE_TO_CONTENT]
      text = name
      halign = ALIGN_CENTER
    }.__update(defTxtStyle)
  ]
}


let function unlockCampaign(campaign) {
  let { reqPurchase = null } = campaign
  if (reqPurchase == null)
    return null
  let sItem = shopItems.value?[reqPurchase.findvalue(@(id) id in shopItems.value)]
  if (sItem == null)
    return null
  buyShopItem({ shopItem = sItem })
}


let mkCampaignCard = @(campaign, idx) watchElemState(function(sf) {
  let isAvailable = unlockedCampaigns.value.contains(campaign)
  let isUnseen = campaign in unseenCampaigns.value
  let title = loc(gameProfile.value?.campaigns[campaign]?.title ?? campaign)
  let campaignImg = $"ui/gameImage/{campaign}"
  let isSelected = selectedCampaign.value == campaign
  let animations = mkAnimations(idx, unlockedCampaigns.value.len())
  let lockedCampaign = lockedCampaigns.value?[campaign]
  let xmbNode = XmbNode()
  return {
    watch = [unlockedCampaigns, unseenCampaigns, gameProfile, lockedCampaigns,
      selectedCampaign, isGamepad]
    size = cardSize
    animations
    key = idx
    transform = {}
    behavior = Behaviors.Button
    onClick = @() isAvailable ? selectCampaign(campaign)
      : lockedCampaign != null ? unlockCampaign(lockedCampaign)
      : anim_start(SHAKE_TEXT_ID + campaign)
    function onAttach(){
      if (!isSelected)
        return
      if (isGamepad.value)
        move_mouse_cursor(idx, false)
      gui_scene.setXmbFocus(xmbNode)
    }
    onHover = hoverHoldAction("unseenCampaign", campaign, markSeenCampaign)
    children = [
      isUnseen ? unseenPanel(loc("unseen/campaign"), { pos = unseenPanelPos})
        : null
      mkImage(campaignImg, isAvailable, sf)
      nameBlock(utf8ToUpper(title), sf)
      isSelected ? selectedLine : null
    ]
  }
})


let campaignSelect = @() {
  watch = visibleCampaigns
  size = flex()
  xmbNode = XmbContainer({
    canFocus = @() false
    scrollSpeed = 10.0
    isViewport = true
  })
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = [
    makeHorizScroll({
      flow = FLOW_HORIZONTAL
      gap = colPart(0.51)
      vplace = ALIGN_CENTER
      children = visibleCampaigns.value.map(@(val, idx) mkCampaignCard(val, idx))
    }, {
      size = flex()
      scrollHandler = tblScrollHandler
      styling = scrollStyle
      rootBase = class {
        key = "campaignWindowScroll"
        behavior = Behaviors.Pannable
        wheelStep = 0.82
      }
    })
  ]
}


let topBlock = {
  size = [flex(), navHeight]
  valign = ALIGN_CENTER
  children = backBtn
}


campaignSelectWnd = @() {
  watch = safeAreaBorders
  size = flex()
  padding = [safeAreaBorders.value[0] , sidePadding + safeAreaBorders.value[1]]
  children = [
    wndHeader
    campaignSelect
    topBlock
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