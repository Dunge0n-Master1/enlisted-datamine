from "%enlSqGlob/ui_library.nut" import *

let exclamation = require("%enlist/components/exclamation.nut")
let { doesLocTextExist } = require("dagor.localize")
let { sub_txt, body_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let { borderColor } = require("profilePkg.nut")
let {
  bigPadding, smallPadding, rowBg, disabledTxtColor, smallOffset, defTxtColor
} = require("%enlSqGlob/ui/viewConst.nut")
let { smallUnseenNoBlink } = require("%ui/components/unseenComps.nut")
let { staticSeasonBPIcon } = require("%enlist/battlepass/battlePassPkg.nut")


let wpSize = hdpxi(190)
let wpHeaderWidth = hdpxi(150)
let iconSize = hdpx(60)

let mkText = @(text, style) {
  rendObj = ROBJ_TEXT
  color = defTxtColor
  text
}.__update(style)

let mkTextArea = @(text, style) {
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  size = [flex(), SIZE_TO_CONTENT]
  color = defTxtColor
  text
}.__update(style)

let mkTitleColumn = @(text) {
  size = [wpHeaderWidth, SIZE_TO_CONTENT]
  halign = ALIGN_RIGHT
  children = mkText(text, { color = disabledTxtColor }.__update(sub_txt))
}

let mkWpRow = @(locId, rowTitleText, txtStyle, isEmptyHidden = false)
  doesLocTextExist(locId) || !isEmptyHidden
    ? {
        size = [flex(), SIZE_TO_CONTENT]
        flow = FLOW_HORIZONTAL
        gap = bigPadding
        valign = ALIGN_BOTTOM
        children = [
          mkTitleColumn(rowTitleText)
          mkTextArea(loc(locId), txtStyle)
        ]
      }
    : null

let function mkWpBottomRow(wallposter) {
  let { armyId, campaignTitle, bpSeason = null, icon = null } = wallposter
  return {
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_HORIZONTAL
    gap = bigPadding
    children = [
      {
        size = [wpHeaderWidth, SIZE_TO_CONTENT]
        halign = ALIGN_RIGHT
        children = icon != null
          ? {
              rendObj = ROBJ_IMAGE
              size = [iconSize, iconSize]
              image = Picture($"{icon}:{iconSize.tointeger()}:{iconSize.tointeger()}:K?Ac")
            }
          : (bpSeason ?? 0) == 0 ? null : staticSeasonBPIcon(bpSeason, iconSize)
      }
      {
        size = [flex(), SIZE_TO_CONTENT]
        flow = FLOW_VERTICAL
        valign = ALIGN_BOTTOM
        children = [
          {
            rendObj = ROBJ_SOLID
            size = [pw(50), hdpx(1)]
            color = borderColor(0)
          }
          mkText(loc(armyId), { color = disabledTxtColor }.__update(body_txt))
          mkText(loc(campaignTitle), { color = disabledTxtColor }.__update(sub_txt))
        ]
      }
    ]
  }
}

let mkWallposterImg = @(img, hasReceived, isHovered, wpImgSize) {
  rendObj = ROBJ_IMAGE
  size = [wpImgSize, wpImgSize]
  picSaturate = hasReceived ? 1.2
    : isHovered ? 0.5
    : 0.1
  opacity = hasReceived || isHovered ? 1 : 0.7
  image = Picture(img)
}

let function mkWallposter(wallposter, sf = 0, isUnseen = false) {
  let { hasReceived, isHidden, img, nameLocId, descLocId, hintLocId } = wallposter
  let isHovered = sf & S_HOVER
  return {
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_HORIZONTAL
    gap = smallPadding
    valign = ALIGN_CENTER
    vplace = ALIGN_CENTER
    children = [
      mkWallposterImg(img, hasReceived, isHovered, wpSize)
      {
        rendObj = ROBJ_SOLID
        size = flex()
        padding = bigPadding
        color = rowBg(sf, 0)
        children = [
          {
            size = [flex(), SIZE_TO_CONTENT]
            flow = FLOW_VERTICAL
            gap = bigPadding
            children = [
              mkWpRow(nameLocId, loc("wp/name"), body_txt)
              { size = [flex(), smallOffset] }
              mkWpRow(descLocId, loc("wp/desc"), sub_txt, true)
              mkWpRow(hintLocId, loc("wp/toToGet"), sub_txt, true)
              mkWpBottomRow(wallposter)
            ]
          }
          isHidden ? exclamation().__update({ hplace = ALIGN_RIGHT }) : null
          isUnseen ? smallUnseenNoBlink : null
        ]
      }
    ]
  }
}

let function makeBigWpImage(wallposter, onClick) {
  let { img, nameLocId } = wallposter
  return {
    size = flex()
    flow = FLOW_VERTICAL
    gap = bigPadding
    padding = smallPadding
    halign = ALIGN_CENTER
    behavior = Behaviors.Button
    onClick
    children = [
      mkTextArea(loc(nameLocId), {
        size = [pw(80), SIZE_TO_CONTENT]
        halign = ALIGN_CENTER
      }.__update(body_txt))
      {
        rendObj = ROBJ_IMAGE
        size = flex()
        image = Picture(img)
        keepAspect = KEEP_ASPECT_FIT
      }
    ]
  }
}

return {
  mkWallposter
  mkWallposterImg
  makeBigWpImage
}
