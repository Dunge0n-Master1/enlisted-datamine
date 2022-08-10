from "%enlSqGlob/ui_library.nut" import *

let { utf8ToUpper } = require("%sqstd/string.nut")
let { makeVertScroll } = require("%ui/components/scrollbar.nut")
let textInput = require("%ui/components/textInput.nut")
let {addModalWindow, removeModalWindow} = require("%ui/components/modalWindows.nut")
let wndWidth = sw(80)

const WND_UID = "fontsDebugWnd"
let isOpened = mkWatched(persist, "isOpened", false)
let textInputWatch = mkWatched(persist, "textInputWatch", "")
let isUpperCaseModeOne = mkWatched(persist, "isUpperCaseModeOne", false)
let textBlockWidth = hdpx(400)

let textValue = Computed(@() "Font example 123:\n{0}".subst(isUpperCaseModeOne.value
  ? utf8ToUpper(textInputWatch.value)
  : textInputWatch.value) )

let inputBlock = textInput.NoFrame(textInputWatch, {
  placeholder = "Введи текст..."
  onChange = @(_) textInputWatch(textInputWatch.value)
  onEscape = @() textInputWatch("")
})

let btnUpperCase = @() {
  watch = isUpperCaseModeOne
  rendObj = ROBJ_BOX
  borderWidth = hdpx(1)
  halign = ALIGN_CENTER
  size = [hdpx(180), SIZE_TO_CONTENT]
  behavior = Behaviors.Button
  flow = FLOW_HORIZONTAL
  onClick = @() isUpperCaseModeOne(!isUpperCaseModeOne.value)
  children = {
    rendObj = ROBJ_TEXT
    text = isUpperCaseModeOne.value ? "Uppercase Mode: ON" : "Uppercase Mode: OFF"
  }
}

let topBlock = {
  size = [hdpx(900), SIZE_TO_CONTENT]
  vplace = ALIGN_TOP
  hplace = ALIGN_CENTER
  valign = ALIGN_CENTER
  gap = hdpx(20)
  flow = FLOW_HORIZONTAL
  children = [
    btnUpperCase
    inputBlock
  ]
}

let textResultBlock = @(fontStyle) @(){
  rendObj = ROBJ_BOX
  borderWidth = hdpx(1)
  fillColor = Color(15,15,15)
  borderColor = Color(50,50,50)
  padding = hdpx(5)
  gap = hdpx(5)
  size = [textBlockWidth, SIZE_TO_CONTENT]
  flow = FLOW_VERTICAL
  children = [
    {
      rendObj = ROBJ_TEXT
      text = $"{fontStyle[0]} {typeof fontStyle[1] != "table" ? fontStyle[1] : ""}"
    }
     @(){
      watch = textValue
      rendObj = ROBJ_TEXTAREA
      size = [textBlockWidth, SIZE_TO_CONTENT]
      behavior = Behaviors.TextArea
      text = textValue.value
    }.__update(typeof fontStyle[1] == "table" ? fontStyle[1] : {})
  ]
}

let wrapParams = {
  width = wndWidth
  hGap = hdpx(50)
  vGap = hdpx(50)
  halign = ALIGN_CENTER
}

let textsBlocks = @(fontStyles){
  size = [flex(), SIZE_TO_CONTENT]
  halign = ALIGN_CENTER
  flow = FLOW_HORIZONTAL
  gap = hdpx(20)
  children = wrap(fontStyles.map(@(style)
    textResultBlock(style)
    ), wrapParams)
}

let function contentBlock(fonts) {
  let fontStylesTable = fonts.topairs().sort(@(a,b)  (a[1]?.fontSize ?? 0) <=> (b[1]?.fontSize ?? -1))
  return {
    size = [wndWidth, flex()]
    flow = FLOW_VERTICAL
    padding = hdpx(20)
    gap = hdpx(50)
    halign = ALIGN_CENTER
    children = [
      topBlock
      makeVertScroll(textsBlocks(fontStylesTable))
    ]
  }
}

let open = @(fonts) addModalWindow({
  key = WND_UID
  rendObj = ROBJ_SOLID
  size = flex()
  color = 0xFF000000
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  children = contentBlock(fonts)
  onClick = @() isOpened(false)
})

let function initFontsDebugWnd(fonts){
  if (isOpened.value)
    open(fonts)

  isOpened.subscribe(@(v) v ? open(fonts) : removeModalWindow(WND_UID))
}

console_register_command(@() isOpened(!isOpened.value), "debug.fontsDebugWnd")

return initFontsDebugWnd