from "%enlSqGlob/ui_library.nut" import *

let mkLevels = require("%enlSqGlob/ui/mkLevelsComp.nut")

let { fontXXSmall, fontSmall } = require("%enlSqGlob/ui/fontsStyle.nut")
let {
  smallPadding, midPadding, bigPadding, colPart, defTxtColor, briteAccentColor,
  commonBorderRadius, hoverSlotTxtColor
} = require("%enlSqGlob/ui/designConst.nut")
let {
  mkSlotBgOverride, mkSlotTextOverride
} = require("%enlSqGlob/ui/slotPkg.nut")


let slotIconColor = 0xFF45545C
let slotIconHoverColor = 0xFF6A7B84
let itemNameHeight = colPart(0.5)

let tinyTxtStyle = { color = hoverSlotTxtColor }.__update(fontXXSmall)
let defTxtStyle = { color = defTxtColor }.__update(fontSmall)

let activeSlotCountOverride = {
  rendObj = ROBJ_SOLID
  color = briteAccentColor
}


const REMOVE_ADDED = "remove_added_animation"

let mkAddedIndo = @(added) {
  size = [colPart(0.4), colPart(0.25)]
  pos = [0, -colPart(0.15)]
  hplace = ALIGN_CENTER
  halign = ALIGN_CENTER
  rendObj = ROBJ_BOX
  borderRadius = commonBorderRadius
  fillColor = briteAccentColor
  children = {
    rendObj = ROBJ_TEXT
    text = $"+{added}"
    transform = { pivot = [0.5, 0.5] }
    animations = [
      { prop = AnimProp.scale, from = [1,1], to = [1.2, 1.2], duration = 1, play = true,
        loop = true, easing = Blink }
    ]
  }.__update(tinyTxtStyle)
  transform = {}
  animations = [
    { prop = AnimProp.translate, from = [0,0], to = [0, colPart(0.15)], duration = 1.2,
      trigger = REMOVE_ADDED }
    { prop = AnimProp.opacity, from = 1, to = 0.1, duration = 1.2, trigger = REMOVE_ADDED }
  ]
}


let mkSlotCount = @(count, isActive) {
  size = [ph(100), flex()]
  halign = ALIGN_CENTER
  children = {
    margin = [0, bigPadding]
    vplace = ALIGN_CENTER
    rendObj = ROBJ_TEXT
    text = count
  }.__update(defTxtStyle, mkSlotTextOverride(isActive))
}.__update(isActive ? activeSlotCountOverride : mkSlotBgOverride())


let upgStarParams = {
  starGap = -colPart(0.1)
  starSize = colPart(0.22)
}


let mkUpgradeTab = @(upgData, idx, isSelected, added, onClick)
  watchElemState(function(sf) {
    let isActive = isSelected || (sf & S_HOVER)
    return {
      size = [SIZE_TO_CONTENT, flex()]
      behavior = Behaviors.Button
      stopHover = true
      onClick
      children = [
        {
          size = [SIZE_TO_CONTENT, flex()]
          flow = FLOW_HORIZONTAL
          gap = smallPadding
          padding = [0, midPadding]
          valign = ALIGN_CENTER
          children = [
            idx == 0
              ? mkLevels(isActive, 0, 0, 1, upgStarParams)
              : mkLevels(isActive, idx, 0, 0, upgStarParams)
            {
              text = upgData.count - added
            }.__update(defTxtStyle, mkSlotTextOverride(isActive))
          ]
        }.__update(mkSlotBgOverride(isActive))
        added == 0 ? null : mkAddedIndo(added)
      ]
    }
  })


let purchaseBtnSize = colPart(1.6)
let mkPurchaseBtn = @(onClick) watchElemState(@(sf) {
  size = [purchaseBtnSize, purchaseBtnSize]
  margin = [itemNameHeight, 0]
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  behavior = Behaviors.Button
  onClick
  rendObj = ROBJ_BOX
  borderRadius = commonBorderRadius
  borderWidth = hdpx(1)
  borderColor = sf & S_HOVER ? slotIconHoverColor : slotIconColor
  children = {
    rendObj = ROBJ_IMAGE
    size = [colPart(0.6), colPart(0.6)]
    image = Picture("!ui/squads/plus.svg:{0}:{0}:K".subst(colPart(0.6)))
  }
})


return {
  mkUpgradeTab
  mkSlotCount
  mkPurchaseBtn
  itemNameHeight
  REMOVE_ADDED
}
