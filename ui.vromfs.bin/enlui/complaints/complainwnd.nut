from "%enlSqGlob/ui_library.nut" import *

let JB = require("%ui/control/gui_buttons.nut")
let { h2_txt, body_txt, sub_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let colors = require("%ui/style/colors.nut")
let bigGap = hdpx(10)
let { clearBorderSymbols } = require("%sqstd/string.nut")
let { addModalWindow, removeModalWindow } = require("%ui/components/modalWindows.nut")
let msgbox = require("%ui/components/msgbox.nut")
let eventbus = require("eventbus")
let { INVALID_USER_ID } = require("matching.errors")

let closeBtn = require("%ui/components/closeBtn.nut")
let combobox = require("%ui/components/combobox.nut")
let textInput = require("%ui/components/textInput.nut")
let textButton = require("%ui/components/textButton.nut")

const WND_UID = "complain_window"
const MIN_COMPLAIN_SYMBOLS = 10
let headerHeight = hdpx(45)
let complainTypes = ["Cheating", "Exploiting"]
let defaultType = complainTypes[0]

let wndWidth = hdpx(500)
let lastOpenParams = persist("lastOpenParams", @() {})

let function close() {
  removeModalWindow(WND_UID)
  lastOpenParams.clear()
}

let header = @(name) {
  size = [flex(), headerHeight]
  rendObj = ROBJ_SOLID
  color = colors.WindowHeader
  valign = ALIGN_CENTER
  padding = bigGap
  children = [
    {
      rendObj = ROBJ_TEXT
      text = loc("complain/header", { name = name })
    }.__update(h2_txt)
    closeBtn({ onClick = close })
  ]
}

let visualDisabledBtnParams = {
  style = {
    BgNormal = colors.BtnBgDisabled
    BdNormal = colors.BtnBdDisabled
    TextNormal = colors.BtnTextVisualDisabled
  }
}

let mkSubmitButton = @(cantSubmitReason, trySubmit) @() {
  watch = cantSubmitReason
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_VERTICAL
  halign = ALIGN_CENTER
  xmbNode = XmbNode()
  children = [
    {
      size = [flex(), SIZE_TO_CONTENT]
      minHeight = hdpx(20)
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      halign = ALIGN_CENTER
      color = colors.TextInactive
      text = cantSubmitReason.value ?? " "
    }.__update(sub_txt)
    textButton(loc("btn/send"), trySubmit,
      cantSubmitReason.value == null ? {} : visualDisabledBtnParams)
  ]
}

let function complainWnd(sessionId, userId, name) {
  let curType = Watched(defaultType)
  let complainText = Watched("")
  let cantSubmitReason = Computed(@() clearBorderSymbols(complainText.value).len() < MIN_COMPLAIN_SYMBOLS
    ? loc("msg/complain/needDetailedComment")
    : null)

  let trySubmit = function() {
    if (cantSubmitReason.value != null) {
      msgbox.show({ text = cantSubmitReason.value })
      return
    }

    if (userId != INVALID_USER_ID)
      eventbus.send("penitentiary.complain", {
          userId = userId
          sessionId = sessionId
          complainType = curType.value
          message = clearBorderSymbols(complainText.value)
      })
    else {
      log($"[COMPLAIN] Attempt to complain on bot {name}, {sessionId}")
      log(clearBorderSymbols(complainText.value))
    }

    msgbox.show({ text = loc("msg/complain/complainSent") })
    close()
  }

  return {
    size = [wndWidth, SIZE_TO_CONTENT]
    vplace = ALIGN_CENTER
    hplace = ALIGN_CENTER
    rendObj = ROBJ_WORLD_BLUR_PANEL
    color = colors.WindowBlur
    padding = 2 * bigGap
    gap = bigGap

    flow = FLOW_VERTICAL
    halign = ALIGN_CENTER
    stopMouse = true
    xmbNode = XmbContainer()

    children = [
      header(name)
      {
        size = [flex(), hdpx(40)]
        children = combobox(curType, complainTypes.map(@(t) [t, loc($"complain/{t}")]))
      }
      textInput(complainText, {
        placeholder = loc("complain/inputTextPlaceholder")
        textmargin = hdpx(5)
        xmbNode = XmbNode()
        onChange = @(value) complainText(value)
        onReturn = trySubmit
        onEscape = close
      }.__update(body_txt))
      mkSubmitButton(cantSubmitReason, trySubmit)
    ]
  }
}

let function open(sessionId, userId, name) {
  lastOpenParams.sessionId <- sessionId
  lastOpenParams.userId <- userId
  lastOpenParams.name <- name
  addModalWindow({
    key = WND_UID
    size = [sw(100), sh(100)]
    rendObj = ROBJ_WORLD_BLUR_PANEL
    fillColor = colors.ModalBgTint
    onClick = close
    children = complainWnd(sessionId, userId, name)
    hotkeys = [[$"^{JB.B} | Esc", { action = close, description = loc("Cancel") }]]
  })
}

if (lastOpenParams.len() > 0)
  open(lastOpenParams.sessionId, lastOpenParams.userId, lastOpenParams.name)

return open