from "%enlSqGlob/ui_library.nut" import *

let JB = require("%ui/control/gui_buttons.nut")
let { body_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let spinner = require("%ui/components/spinner.nut")({ height = hdpx(80) })
let { WindowTransparent } = require("%ui/style/colors.nut")
let { titleTxtColor, commonBtnHeight } = require("%enlSqGlob/ui/viewConst.nut")
let { noteTextArea, txt } = require("%enlSqGlob/ui/defcomps.nut")
let { modDownloadShowProgress, modDownloadMessage } = require("customMissionState.nut")
let { Bordered } = require("%ui/components/textButton.nut")

let btnStyle = {
  margin = 0,
  size = [SIZE_TO_CONTENT, commonBtnHeight]
}

let defaultSize = [hdpx(432), hdpx(324)]

let queueTitle = noteTextArea({
  size = [flex(), SIZE_TO_CONTENT]
  text = loc("mods/Downloading")
  halign = ALIGN_CENTER
  color = titleTxtColor
}).__update(body_txt)

let queueContent = @(message) {
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  fillColor = Color(10,10,10,10)
  size = flex()
  flow = FLOW_HORIZONTAL
  gap = hdpx(20)
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  children = txt({
      text = loc(message)
      color = titleTxtColor
    }).__update(body_txt)
}

let closeButton = Bordered(loc("Ok"),
  function(){
    modDownloadShowProgress(false)
    modDownloadMessage("")
  },
  btnStyle.__merge({
    hplace = ALIGN_CENTER
    vplace = ALIGN_BOTTOM
    hotkeys = [[$"^{JB.B} | Enter | Space | Esc", { skip = true }]]
  })
)


let infoContainer = @(text) {
  size = defaultSize
  gap = hdpx(20)
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  flow = FLOW_VERTICAL
  padding = hdpx(20)
  fillColor = WindowTransparent
  borderRadius = hdpx(2)
  rendObj = ROBJ_WORLD_BLUR_PANEL
  transform = {}
  animations = [
    { prop=AnimProp.translate,  from=[0, sh(5)], to=[0,0], duration=0.5, play=true, easing=OutBack }
    { prop=AnimProp.opacity, from=0.0, to=1.0, duration=0.25, play=true, easing=OutCubic }
    { prop=AnimProp.translate, from=[0,0], to=[0, sh(30)], duration=0.7, playFadeOut=true, easing=OutCubic }
    { prop=AnimProp.opacity, from=1.0, to=0.0, duration=0.6, playFadeOut=true, easing=OutCubic }
  ]
  children = text == ""
    ? [
        queueTitle
        {
          size = flex()
          halign = ALIGN_CENTER
          valign = ALIGN_CENTER
          children = spinner
        }
      ]
    : [
        queueTitle
        queueContent(text)
        closeButton
      ]
}

return function queueWaitingInfo() {
  if (!modDownloadShowProgress.value && modDownloadMessage.value == "")
    return {
      watch = [modDownloadShowProgress, modDownloadMessage]
    }

  return {
    watch = [modDownloadShowProgress, modDownloadMessage]
    rendObj = ROBJ_WORLD_BLUR_PANEL
    stopMouse = true
    fillColor = Color(10,10,10,10)
    size = [sw(100), sh(100)]
    children = infoContainer(modDownloadMessage.value)
  }
}