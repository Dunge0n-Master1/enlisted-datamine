from "%enlSqGlob/ui_library.nut" import *

let { h0_txt, h1_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let {
  bigPadding, titleTxtColor, defTxtColor, activeTxtColor, smallPadding, maxContentWidth,
  blurBgFillColor, isWide
} = require("%enlSqGlob/ui/viewConst.nut")
let { localGap } = require("eventModeStyle.nut")
let { mkArmyIcon } = require("%enlist/soldiers/components/armyPackage.nut")
let { mkHeaderFlag, casualFlagStyle } = require("%enlSqGlob/ui/mkHeaderFlag.nut")
let bottomBar = require("%enlist/mainMenu/bottomRightButtons.nut")

let wndHeaderHeight = hdpx(150)
let armyIconHeight = hdpx(36)

let function txtColor (sf){
  return sf & S_ACTIVE ? activeTxtColor
    : sf & S_HOVER ? titleTxtColor
    : defTxtColor
}

let windowTitle = @(title){
  vplace = ALIGN_CENTER
  children = mkHeaderFlag(
    {
      padding = [localGap, bigPadding * 3]
      rendObj = ROBJ_TEXT
      text = title
    }.__update(isWide ? h0_txt : h1_txt),
    {
      offset = hdpx(15)
    }.__update(casualFlagStyle)
  )
}

let headerImg = @(image) {
    size = [flex(), wndHeaderHeight]
    rendObj = ROBJ_IMAGE
    image = Picture(image)
    fallbackImage = Picture("ui/tunisia_city_inv_02.avif")
    keepAspect = KEEP_ASPECT_FILL
  }

let mkWindowHeader = @(title, image, addChild = null){
  size = [flex(), SIZE_TO_CONTENT]
  children = [
    headerImg(image)
    windowTitle(title)
    addChild
  ]
}

let function sequentialArmySelect(armies, armyId, deltaIdx, onArmySelect) {
  let currentArmieIdx = armies.findindex(@(val) val == armyId)
  if (currentArmieIdx != null){
    let newIdx = currentArmieIdx + deltaIdx
    if (newIdx >= 0 && newIdx < armies.len())
      onArmySelect(armies[newIdx])
  }
}

let function armyButton(armyId, onArmySelect, isSelected) {
  let stateFlag = Watched(0)
  return @(){
    rendObj = ROBJ_BOX
    watch = stateFlag
    size = SIZE_TO_CONTENT
    behavior = Behaviors.Button
    onElemState = @(sf) stateFlag(sf)
    borderWidth = (isSelected || (stateFlag.value & S_HOVER)) ? [0, 0, hdpx(4), 0] : 0
    children = [
      {
        flow = FLOW_HORIZONTAL
        gap = bigPadding
        size = SIZE_TO_CONTENT
        vplace = ALIGN_BOTTOM
        children = [
          mkArmyIcon(armyId, armyIconHeight)
        ]
      }
    ]
  }.__update(isSelected ? {} : {
      behavior = Behaviors.Button
      onClick =  @() onArmySelect(armyId)
      sound = {
        hover = "ui/enlist/button_highlight"
        click = "ui/enlist/button_click"
      }
    }
  )
}

let selectArmyBlock = @(armiesList, curArmyId, onArmySelect) function(){
  let children = armiesList.map(@(armyId)
    armyButton(armyId, onArmySelect, armyId == curArmyId))
  return {
    size = SIZE_TO_CONTENT
    flow = FLOW_HORIZONTAL
    hplace = ALIGN_CENTER
    gap = smallPadding
    hotkeys = [
      ["^J:LT",
        { action = @() sequentialArmySelect(armiesList, curArmyId, -1, onArmySelect),
          description = loc("army/previous")
        }],
      ["^J:RT",
        { action = @() sequentialArmySelect(armiesList, curArmyId, 1, onArmySelect),
          description = loc("army/next")
        }]
    ]
    children = children.len() > 1 ? children : null
  }
}


let footer = {
  size = [flex(), SIZE_TO_CONTENT]
  maxWidth = maxContentWidth
  hplace = ALIGN_CENTER
  children = bottomBar
}

let mkPanel = @(ovr) {
  rendObj = ROBJ_WORLD_BLUR_PANEL
  fillColor = blurBgFillColor
  padding = localGap
}.__update(ovr)

return {
  mkWindowHeader
  txtColor
  wndHeaderHeight
  selectArmyBlock
  footer
  mkPanel
}