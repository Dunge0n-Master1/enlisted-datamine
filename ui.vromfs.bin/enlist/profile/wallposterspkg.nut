from "%enlSqGlob/ui_library.nut" import *

let exclamation = require("%enlist/components/exclamation.nut")
let { doesLocTextExist } = require("dagor.localize")
let { sub_txt, body_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let { bgColor, txtColor, borderColor } = require("profilePkg.nut")
let {
  bigPadding, smallPadding, disabledTxtColor, smallOffset, defTxtColor
} = require("%enlSqGlob/ui/viewConst.nut")
let { smallUnseenNoBlink } = require("%ui/components/unseenComps.nut")
let { staticSeasonBPIcon } = require("%enlist/battlepass/battlePassPkg.nut")
let { darkTxtColor } = require("%enlSqGlob/ui/designConst.nut")


let wpSize = hdpxi(190)
let wpHeaderWidth = hdpxi(150)
let iconSize = hdpxi(60)

let weakTxtColor = @(sf) (sf & S_HOVER) ? darkTxtColor : disabledTxtColor

let mkText = @(text, style) {
  rendObj = ROBJ_TEXT
  color = defTxtColor
  text
}.__update(style)

let mkTextArea = @(text, style, sf=0) {
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  size = [flex(), SIZE_TO_CONTENT]
  color = txtColor(sf)
  text
}.__update(style)

let mkTitleColumn = @(text, sf) {
  size = [wpHeaderWidth, SIZE_TO_CONTENT]
  halign = ALIGN_RIGHT
  children = mkText(text, { color = weakTxtColor(sf) }.__update(sub_txt))
}

let mkWpRow = @(locId, rowTitleText, txtStyle, isEmptyHidden = false, sf = 0)
  doesLocTextExist(locId) || !isEmptyHidden
    ? {
        size = [flex(), SIZE_TO_CONTENT]
        flow = FLOW_HORIZONTAL
        gap = bigPadding
        valign = ALIGN_CENTER
        children = [
          mkTitleColumn(rowTitleText, sf)
          mkTextArea(loc(locId), txtStyle, sf)
        ]
      }
    : null

let function mkWpBottomRow(wallposter, sf) {
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
          mkText(loc(armyId), { color = weakTxtColor(sf) }.__update(body_txt))
          mkText(loc(campaignTitle), { color = weakTxtColor(sf) }.__update(sub_txt))
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
        color = bgColor(sf)
        children = [
          {
            size = [flex(), SIZE_TO_CONTENT]
            flow = FLOW_VERTICAL
            gap = bigPadding
            children = [
              mkWpRow(nameLocId, loc("wp/name"), body_txt, false, sf)
              { size = [flex(), smallOffset] }
              mkWpRow(descLocId, loc("wp/desc"), sub_txt, true, sf)
              mkWpRow(hintLocId, loc("wp/toToGet"), sub_txt, true, sf)
              mkWpBottomRow(wallposter, sf)
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
    padding = bigPadding
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
