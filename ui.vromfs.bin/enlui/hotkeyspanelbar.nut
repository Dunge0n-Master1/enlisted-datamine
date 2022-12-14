from "%enlSqGlob/ui_library.nut" import *


let { fontLarge } = require("%enlSqGlob/ui/fontsStyle.nut")
let { defTxtColor, smallPadding, columnGap, sidePadding, footerContentHeight, colPart
} = require("%enlSqGlob/ui/designConst.nut")
let { startswith } = require("string")
let { isGamepad } = require("%ui/control/active_controls.nut")
let controllerType = require("%ui/control/controller_type.nut")
let controlsTypes = require("%ui/control/controls_types.nut")
let gamepadImgByKey = require("%ui/components/gamepadImgByKey.nut")
let JB = require("%ui/control/gui_buttons.nut")
let { getHotkeysComps } = require("hotkeysPanelStateComps.nut")
let {cursorPresent, cursorOverStickScroll, config, cursorOverClickable} = gui_scene


let navState = { value = [] }
let getNavState = @(...) navState.value
let navStateGen = Watched(0)
let defTxtStyle = { color = defTxtColor }.__update(fontLarge)
let panelHeight = colPart(0.54)
let combine_func = @(a, b) a.action == b.action
let isActivateKey = @(key) JB.A == key.btnName


let mktext = @(text){
  rendObj = ROBJ_TEXT
  text
}.__update(defTxtStyle)
let defaultJoyAHint = loc("ui/cursor.activate")


gui_scene.setHotkeysNavHandler(function(state) {
  navState.value = state
  navStateGen(navStateGen.value + 1)
})


let function mkNavBtn(params = { hotkey = null, gamepad = true }){
  let description = params?.hotkey.description
  let skip = description?.skip
  if (skip)
    return null
  let btnNames = params?.hotkey.btnName ?? []
  let children = params?.gamepad
    ? btnNames.map(@(btnName) gamepadImgByKey.mkImageCompByDargKey(btnName,
      { size = [SIZE_TO_CONTENT, defTxtStyle.fontSize] }))
    : btnNames.map(@(btnName) {rendObj = ROBJ_TEXT text = btnName }.__update(defTxtStyle))

  if (type(description)=="string")
    children.append(mktext(description))

  return {
    flow = FLOW_HORIZONTAL
    gap = smallPadding
    valign = ALIGN_CENTER
    vplace = ALIGN_CENTER
    children = children
  }
}


let function combineHotkeys(data, filter_func){
  let hotkeys = []
  local isActivateForced = false
  foreach (k in data) {
    if (isActivateKey(k)) {
      isActivateForced = true
      continue
    }
    if (!filter_func(k))
      continue
    let t = clone k
    local key_used = false
    foreach (r in hotkeys) {
      if (combine_func(r,t)) {
        r.btnName.append(t.btnName)
        key_used = true
        break
      }
    }
    if (!key_used) {
      t.btnName = [t.btnName]
      hotkeys.append(t)
    }
  }
  return {
    hotkeys
    needShowHotkeys = isActivateForced || hotkeys.len() > 0
  }
}


let function getJoyAHintText(data, filter_func) {
  local hotkeyAText = defaultJoyAHint
  foreach (k in data)
    if (filter_func(k) && isActivateKey(k)) {
      if (typeof k?.description == "string")
        hotkeyAText = k.description
      else if (k?.description?.skip)
        hotkeyAText = null
    }
  return hotkeyAText
}


let function filterHotkeys(hotkey, devid) {
  let descrExist = "description" in hotkey
  return devid.indexof(hotkey.devId) != null && (!descrExist || hotkey.description != null)
}


let makeFilterFunc = @(is_gamepad) is_gamepad
  ? @(hotkey) filterHotkeys(hotkey, [DEVID_JOYSTICK])
  : @(hotkey) filterHotkeys(hotkey, [DEVID_KEYBOARD, DEVID_MOUSE])


let show_tips = Computed(@() cursorPresent.value
  && isGamepad.value
  && combineHotkeys(getNavState(navStateGen.value), makeFilterFunc(isGamepad.value)).needShowHotkeys)
let joyAHint = Computed(@() getJoyAHintText(navState.value, makeFilterFunc(isGamepad.value)))

let svgImg = memoize(function(image){
  let h = gamepadImgByKey.getBtnImageHeight(image, defTxtStyle.fontSize)
  return freeze({
    size = [h, h]
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    rendObj = ROBJ_IMAGE
    image = Picture("!ui/skin#{0}.svg:{1}:{1}:K".subst(image, h.tointeger()))
    keepAspect = true
  })
})


let manualHint = @(images, text=""){
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  gap = smallPadding
  children = images.map(@(image) svgImg(image)).append(mktext(text))
}


let function gamepadCursorNavImages(cType){
  switch (cType) {
    case controlsTypes.ds4gamepad: return ["ds4/lstick_4" "ds4/dpad"]
    case controlsTypes.nxJoycon: return ["nswitch/lstick_4" "nswitch/dpad"]
  }
  return ["x1/lstick_4" "x1/dpad"]
}


let function gamepadcursorclick_image(imagesMap) {
  let clickButtons = config.getClickButtons()
  return clickButtons
    .filter(@(btn) startswith(btn, "J:"))
    .map(@(btn) imagesMap?[btn])
}


let function gamepadCursor() {
  let keyImages = gamepadImgByKey.keysImagesMap
  let clickHint = manualHint(gamepadcursorclick_image(keyImages.value), joyAHint.value)
  let clickHintStub = {size = [calc_comp_size(clickHint)[0], 0], key = {}}
  let scrollHint = manualHint([keyImages.value?["J:R.Thumb.hv"]],
    loc("ui/cursor.scroll"))
  return {
    watch = [joyAHint, cursorOverStickScroll, cursorOverClickable, keyImages]
    flow = FLOW_HORIZONTAL
    gap = columnGap
    hplace = ALIGN_LEFT
    size = [SIZE_TO_CONTENT, panelHeight]
    valign = ALIGN_CENTER
    zOrder = Layers.MsgBox
    children = [
      manualHint(gamepadCursorNavImages(controllerType.value),loc("ui/cursor.navigation"))
      cursorOverClickable.value && joyAHint.value ? clickHint : clickHintStub
      cursorOverStickScroll.value ? scrollHint : null
    ]
  }
}


let function tipsC() {
  let filteredHotkeys = combineHotkeys(getNavState(), makeFilterFunc(isGamepad.value)).hotkeys
  let tips = (cursorPresent.value && isGamepad.value) ? [gamepadCursor] : []
  tips.extend(filteredHotkeys.map(@(hotkey) mkNavBtn(
    { hotkey = hotkey, gamepad = isGamepad.value })))
  tips.extend(getHotkeysComps().values())
  return {
    watch = [isGamepad, cursorPresent]
    gap = smallPadding
    flow = FLOW_HORIZONTAL
    zOrder = Layers.MsgBox
    children = tips
  }
}


let hotkeysButtonsBar = @() {
  watch = show_tips
  size = [flex(), footerContentHeight]
  padding = [0, sidePadding]
  vplace = ALIGN_BOTTOM
  valign = ALIGN_CENTER
  children = show_tips.value ? tipsC : null
}



return { hotkeysButtonsBar }