from "%enlSqGlob/ui_library.nut" import *

let { h2_txt, body_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let { kindIcon } = require("%enlSqGlob/ui/soldiersUiComps.nut")
let sClassesCfg = require("%enlist/soldiers/model/config/sClassesConfig.nut")
let { titleTxtColor, activeTxtColor, bigPadding, defTxtColor, commonBtnHeight, accentTitleTxtColor,
  freemiumColor, freemiumDarkColor } = require("%enlSqGlob/ui/viewConst.nut")
let { itemTypeIcon } = require("itemTypesData.nut")

let btnSizeSmall = [hdpx(330), commonBtnHeight]
let btnSizeBig = [hdpx(400), commonBtnHeight]
let mainBgColor = Color(98, 98, 80)
let primeColor = Color(146, 10, 1)
let receivedColor = Color(98, 98, 80)
let unavailableColor = Color(96, 96, 96)
let progressBarWidth = hdpxi(787)

let rewardToScroll = Watched(null)

let mkText = @(txt, style = {}) {
  rendObj = ROBJ_TEXT
  color = defTxtColor
  text = txt
}.__update(body_txt, style)

let mkSquadName = @(nameLocId, titleLocId, sClass, itemType, itemSubType) {
  flow = FLOW_HORIZONTAL
  gap = bigPadding
  valign = ALIGN_CENTER
  children = [
    sClass == null
      ? itemTypeIcon(itemType, itemSubType, { size = [hdpx(55), hdpx(55)] })
      : kindIcon(sClassesCfg.value?[sClass].kind ?? sClass, hdpx(55), null, titleTxtColor)
    {
      flow = FLOW_HORIZONTAL
      children = {
      flow = FLOW_VERTICAL
      children = [
         mkText(loc(nameLocId ?? ""), { color = accentTitleTxtColor }).__update(body_txt)
         mkText(loc(titleLocId ?? ""), { color = titleTxtColor }).__update(h2_txt)
        ]
      }
    }
  ]
}

let function campaignName(params){
  let {nameLocId, titleLocId, hasReceived, isPrimeSquad = false, sClass = null,
    itemType = null, itemSubType = null, isFreemium = false} = params
  return{
    vplace = ALIGN_CENTER
    flow = FLOW_VERTICAL
    pos = [-hdpx(23), 0]
    size = [flex(), SIZE_TO_CONTENT]
    children = [
      {
        rendObj = ROBJ_IMAGE
        minWidth = hdpx(300)
        flow = FLOW_VERTICAL
        valign = ALIGN_CENTER
        padding = [bigPadding * 2, bigPadding * 4]
        color = isPrimeSquad ? primeColor
          : isFreemium ? freemiumColor
          : hasReceived ? receivedColor
          : unavailableColor
        image = Picture($"!ui/gameImage/base_header_bar.svg:{hdpxi(150)}:4:K?Ac")
        children = mkSquadName(nameLocId, titleLocId, sClass, itemType, itemSubType)
      }
      {
        rendObj = ROBJ_VECTOR_CANVAS
        size = [hdpx(15), hdpx(15)]
        lineWidth = 0
        color = 0
        fillColor = isPrimeSquad ? Color(69, 24, 24)
          : isFreemium ? freemiumDarkColor
          : Color(54, 54, 45)
        commands = [
          [VECTOR_POLY, 0,0, 100,0, 100,100]
        ]
      }
    ]}
}

let mkReceivedBanner = @(bgColor) {
  size = [hdpx(180), hdpx(180)]
  hplace = ALIGN_RIGHT
  clipChildren = true
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = {
    size = [hdpx(300), hdpx(50)]
    pos = [hdpx(20), -hdpx(20)]
    transform = {rotate = 45}
    rendObj = ROBJ_SOLID
    color = bgColor
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    children = {
      rendObj = ROBJ_TEXT
      text = loc("squads/received")
    }.__update(body_txt)
  }
}

let infoBtnSize = hdpxi(20)
let weapInfoBtn =  @(sf) {
  rendObj = ROBJ_IMAGE
  size = [infoBtnSize, infoBtnSize]
  hplace = ALIGN_RIGHT
  vplace = ALIGN_TOP
  margin = hdpx(15)
  image =  Picture("{0}:{1}:{1}:K".subst("ui/skin#info/info_icon.svg", infoBtnSize))
  color = sf & S_ACTIVE ? activeTxtColor
    : sf & S_HOVER ? titleTxtColor
    : activeTxtColor
}

return {
  campaignName
  btnSizeSmall
  btnSizeBig
  receivedCommon = mkReceivedBanner(mainBgColor)
  receivedFreemium = mkReceivedBanner(freemiumColor)
  weapInfoBtn
  progressBarWidth
  rewardToScroll
}