from "%enlSqGlob/ui_library.nut" import *

let {
  TextDefault, BtnBdDisabled, ModalBgTint
} = require("%ui/style/colors.nut")
let { show } = require("%ui/components/msgbox.nut")
let {addModalWindow, removeModalWindow} = require("%ui/components/modalWindows.nut")
let fontIconButton = require("%ui/components/fontIconButton.nut")
let eventbus = require("eventbus")
let { browser_go_back = @() null,
        browser_reload_page = @() null,
        can_use_embeded_browser = @() false } = require_optional("browser")

let windowTitle = Watched(null)
let canGoBack = Watched(false)
let isBrowserClosed = Watched(true)

const WND_UID = "webbrowser_window"


let function handleBrowserEvent(val) {
  if ("canGoBack" in val)
    canGoBack(!!val.canGoBack)
  if ("title" in val)
    windowTitle(val.title ?? "")
}

eventbus.subscribe("browser_event", handleBrowserEvent)

let windowTitleHeader = @() {
  rendObj = ROBJ_TEXT
  vplace = ALIGN_CENTER
  watch = windowTitle
  text = windowTitle.value
  color = TextDefault
  size = [flex(), SIZE_TO_CONTENT]
  padding = [hdpx(5), hdpx(20)]
}

let controlPanel = {
  size = [flex(), hdpx(35)]
  flow = FLOW_HORIZONTAL
  gap = hdpx(5)
  children = [
    fontIconButton("arrow-left", {
      padding = hdpx(5)
      onClick = browser_go_back
      watch = canGoBack
      isEnabled = @() canGoBack.value
      iconColor = @(_) canGoBack.value ? null : BtnBdDisabled
    })
    fontIconButton("refresh", {
      padding = hdpx(5)
      onClick = browser_reload_page
    })
    windowTitleHeader
    fontIconButton("close", {
      padding = hdpx(5)
      onClick = function(){
        removeModalWindow(WND_UID)
        isBrowserClosed(true)
      }
    })
  ]
}

let function showBrowser(url = "") {
  if (can_use_embeded_browser()) {
    isBrowserClosed(false)
    addModalWindow({
      key = WND_UID
      rendObj = ROBJ_WORLD_BLUR_PANEL
      fillColor = ModalBgTint
      onClick = @() null
      children = {
        clipChildren = true
        flow = FLOW_VERTICAL
        // Currently in-game browser will only be used for Chinese version of the game.
        // It was requested that the browser window would be 1200x768.
        size = [hdpx(1200), hdpx(768)]
        rendObj = ROBJ_SOLID
        color = Color(20,20,20,255)
        hplace = ALIGN_CENTER
        vplace = ALIGN_CENTER
        children = [
          controlPanel
          {
            size = flex()
            rendObj = ROBJ_BROWSER
            behavior = Behaviors.Browser
            defaultUrl = url != "" ? url : null
          }
        ]
      }
    })
  } else {
    show({text = loc("error/CANNOT_DISPLAY_WEBBROWSER")})
  }
}

return {
  showBrowser
  isBrowserClosed
}