from "%enlSqGlob/ui_library.nut" import *

let { body_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let {
  shadowStyle, blurBgColor, blurBgFillColor, defBgColor, titleTxtColor
} = require("%enlSqGlob/ui/viewConst.nut")
let { safeAreaBorders, safeAreaSize } = require("%enlist/options/safeAreaState.nut")
let { sceneWithCameraAdd, sceneWithCameraRemove } = require("%enlist/sceneWithCamera.nut")
let { selectedCampaign, curCampaign } = require("%enlist/meta/curCampaign.nut")
let { curArmies, curArmiesList, selectArmy } = require("%enlist/soldiers/model/state.nut")
let armiesPresentation = require("%enlSqGlob/ui/armiesPresentation.nut")
let { mkArmyIcon } = require("%enlist/soldiers/components/armyPackage.nut")
let { widgetUserName } = require("%enlist/components/userName.nut")
let { visibleCampaigns } = require("%enlist/meta/campaigns.nut")

let IMAGE_RATIO = 16.0 / 9.0
let hoverColor = Color(240, 200, 100, 190)
let paddingInternal = hdpx(6)
let paddingTitle = hdpx(12)
let gapCards = hdpx(100)

let imgSize = Computed(function() {
  let width = (min(safeAreaSize.value[0], sw(90)) / 2 - gapCards).tointeger()
  let height = (width / IMAGE_RATIO).tointeger()
  return [width, height]
})

let isOpened = Computed(@()
  (selectedCampaign.value != null || (visibleCampaigns.value.len() ?? 0) == 1)
  && curArmies.value?[curCampaign.value] == null)

let getArmyImage = @(armyId) armiesPresentation?[armyId].promoImage ?? $"ui/soldiers/{armyId}.jpg"

let mkText = @(text, color = titleTxtColor) {
  rendObj = ROBJ_TEXT
  text
  color
}.__update(body_txt, shadowStyle)

let mkArmyImage = @(image, sf) {
  size = flex()
  clipChildren = true
  children = {
    size = flex()
    rendObj = ROBJ_IMAGE
    keepAspect = KEEP_ASPECT_FILL
    imageHalign = ALIGN_CENTER
    imageValign = ALIGN_TOP
    image = Picture(image)
    fallbackImage = Picture("ui/soldiers/army_default.jpg")
    transform = { scale = sf & S_HOVER ? [1.05, 1.05] : [1, 1] }
    transitions = [ { prop = AnimProp.scale, duration = 0.4, easing = OutQuintic } ]
  }
}

let mkArmyName = @(name) {
  rendObj = ROBJ_SOLID
  size = [flex(), SIZE_TO_CONTENT]
  padding = paddingTitle
  vplace = ALIGN_BOTTOM
  halign = ALIGN_CENTER
  color = defBgColor
  children = mkText(name)
}

let mkArmyButton = @(armyId) watchElemState(function(sf) {
  let size = imgSize.value
  return {
    watch = [imgSize]
    rendObj = ROBJ_BOX
    size
    padding = paddingInternal
    fillColor = Color(50,50,50)
    borderColor = sf & S_HOVER ? hoverColor : Color(80,80,80,80)
    borderWidth = (sf & S_HOVER) != 0 ? hdpx(2) : 0
    behavior = Behaviors.Button

    onClick = @() selectArmy(armyId)

    children = [
      mkArmyImage(getArmyImage(armyId), sf),
      mkArmyName(loc(armyId)),
      (mkArmyIcon(armyId) ?? {}).__merge({ margin = paddingTitle })
    ]
  }
})

let mkChooseArmyBlock = @() {
  size = flex()
  flow = FLOW_VERTICAL
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  gap = fsh(3)
  children = [
    mkText(loc("choose_army"))
    @() {
      watch = curArmiesList
      gap = gapCards
      flow = FLOW_HORIZONTAL
      children = curArmiesList.value.map(mkArmyButton)
    }
  ]
}

let chooseArmyScene = @() {
  watch = safeAreaBorders
  size = [sw(100), sh(100)]
  padding = safeAreaBorders.value
  rendObj = ROBJ_WORLD_BLUR_PANEL
  color = blurBgColor
  fillColor = blurBgFillColor
  children = [
    mkChooseArmyBlock
    widgetUserName
  ]
}

let function open() {
  sceneWithCameraAdd(chooseArmyScene, "armory")
}

if (isOpened.value == true)
  open()

isOpened.subscribe(function(v) {
  if (v == true)
    open()
  else
    sceneWithCameraRemove(chooseArmyScene)
})

return isOpened
