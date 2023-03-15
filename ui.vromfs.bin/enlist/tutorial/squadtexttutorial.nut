from "%enlSqGlob/ui_library.nut" import *
let { body_txt, h2_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let { controlHudHint, mkHasBinding } = require("%ui/components/controlHudHint.nut")
let { addModalWindow, removeModalWindow } = require("%ui/components/modalWindows.nut")
let { Flat } = require("%ui/components/textButton.nut")
let closeBtnBase = require("%ui/components/closeBtn.nut")
let {
  defTxtColor, maxContentWidth, bigPadding, defInsideBgColor, titleTxtColor, disabledTxtColor,
  isWide
} = require("%enlSqGlob/ui/viewConst.nut")
let { getTutorial } = require("squadTextTutorialPresentation.nut")
let faComp = require("%ui/components/faComp.nut")
let mkDotPaginator = require("%enlist/components/mkDotPaginator.nut")

const WND_UID = "SQUAD_TEXT_TUTORIAL"

let curPage = Watched(0)
let internalContentWidth = hdpx(1200)

let smallPadding = hdpx(30)
let largePadding = hdpx(60)
let imageSize = isWide ? [hdpx(1200), hdpx(505)] : [hdpx(1000), hdpx(421)]


let tutorialImage = @(image) image == null ? null :{
  rendObj = ROBJ_IMAGE
  size = imageSize
  hplace = ALIGN_CENTER
  image = Picture(image)
  keepAspect = KEEP_ASPECT_FIT
}

let function close(){
  removeModalWindow(WND_UID)
  curPage(0)
}

let closeButton = closeBtnBase({
  onClick = close
  hplace = ALIGN_RIGHT
})

let topBlock = @(squadType){
  rendObj = ROBJ_SOLID
  color = defInsideBgColor
  size = [internalContentWidth, SIZE_TO_CONTENT]
  valign = ALIGN_CENTER
  padding = bigPadding * 2
  children = {
    rendObj = ROBJ_TEXT
    text = loc($"{squadType}_available_header")
  }.__update(h2_txt)
}

let tutorialPaginator = mkDotPaginator({
  id = "squad_tutorial"
  pageWatch = curPage
})

let centralBlock = @(neededTutorial, totalPagesCount) function() {
  let value = neededTutorial[curPage.value]
  let watches = [curPage]
  let hotkeysArr = value?.hotkey ?? []
  foreach (key in hotkeysArr)
    watches.append(mkHasBinding(key))

  return {
    size = [internalContentWidth, flex()]
    watch = watches
    children = {
      size = flex()
      flow = FLOW_VERTICAL
      gap = smallPadding
      halign = ALIGN_CENTER
      children = [
        tutorialImage(value?.image)
        tutorialPaginator(totalPagesCount)
        {
          flow = FLOW_HORIZONTAL
          valign = ALIGN_TOP
          gap = hdpx(10)
          size = [pw(75), SIZE_TO_CONTENT]
          children = [
            hotkeysArr.len() <= 0 ? null : {
              flow = FLOW_HORIZONTAL
              children = hotkeysArr.filter(@(_, idx) watches[idx].value).map(@(v)
                controlHudHint({
                  id = v ?? ""
                  text_params = {
                    fontSize = body_txt.fontSize
                  }
                })
              )
            }
            {
              rendObj = ROBJ_TEXTAREA
              behavior = Behaviors.TextArea
              size = [flex(), SIZE_TO_CONTENT]
              text = loc(value?.text ?? "")
              color = defTxtColor
            }.__update(body_txt)
          ]
        }
      ]
    }
  }
}

let okBtn = Flat(loc("Ok"), close, {
    hplace = ALIGN_RIGHT
    vplace = ALIGN_BOTTOM
    margin = 0
})

let function prevPageArrow() {
  let onClick = @() curPage.value > 0
    ? curPage(curPage.value - 1)
    : null
  return watchElemState(@(sf){
    behavior = Behaviors.Button
    watch = curPage
    hplace = ALIGN_LEFT
    vplace = ALIGN_CENTER
    onClick
    hotkeys = [["^J:LB", {description = loc("tutorial/previousPage"), action = onClick} ]]
    children = faComp("chevron-left", {
      fontSize = hdpx(50)
      color = curPage.value <= 0 ? disabledTxtColor
        : sf & S_ACTIVE ? defTxtColor
        : sf & S_HOVER ? titleTxtColor
        : defTxtColor
    })
  })
}

let function nextPageArrow(totalPagesCount) {
  let onClick = @() curPage.value < totalPagesCount - 1
    ? curPage(curPage.value + 1)
    : null
  return watchElemState(@(sf){
    behavior = Behaviors.Button
    watch = curPage
    hplace = ALIGN_RIGHT
    vplace = ALIGN_CENTER
    onClick
    hotkeys = [["^J:RB", {description = loc("tutorial/nextPage"), action = onClick}]]
    children = faComp("chevron-right", {
      fontSize = hdpx(50)
      color = curPage.value >= totalPagesCount - 1 ? disabledTxtColor
        : sf & S_ACTIVE ? defTxtColor
        : sf & S_HOVER ? titleTxtColor
        : defTxtColor
    })
  })
}

let function squadTextTutorial(squadType){
  let neededTutorial = getTutorial(squadType)
  let totalPagesCount = neededTutorial.len()
  return {
    size = [sw(95), hdpx(900)]
    maxWidth = maxContentWidth
    rendObj = ROBJ_IMAGE
    halign = ALIGN_CENTER
    image = Picture("ui/squads_tutorial_background.avif")
    keepAspect = KEEP_ASPECT_FILL
    padding = [smallPadding, largePadding]
    clipChildren = true
    children = [
      closeButton
      {
        size = flex()
        flow = FLOW_VERTICAL
        gap = smallPadding
        halign = ALIGN_CENTER
        children = [
          topBlock(squadType)
          centralBlock(neededTutorial, totalPagesCount)
        ]
      }
      okBtn
      prevPageArrow()
      nextPageArrow(totalPagesCount)
    ]
  }
}

let openSquadTextTutorial = @(squadType) addModalWindow({
  key = WND_UID
  rendObj = ROBJ_WORLD_BLUR_PANEL
  fillColor = defInsideBgColor
  size = flex()
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  vplace = ALIGN_CENTER
  hplace = ALIGN_CENTER
  children = squadTextTutorial(squadType)
  onClick = @() null
})

return openSquadTextTutorial