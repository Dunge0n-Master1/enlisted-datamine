from "%enlSqGlob/ui_library.nut" import *

let JB = require("%ui/control/gui_buttons.nut")
let mkPieMenuDarg = require("%ui/components/mkPieMenuBase.nut")
let cursors = require("%ui/style/cursors.nut")
let { isGamepad } = require("%ui/control/active_controls.nut")
let dainput = require("dainput2")
let { mkHotkey } = require("%ui/components/uiHotkeysHint.nut")
let { HUD_TIPS_HOTKEY_FG } = require("%ui/hud/style.nut")

let function locAction(action) {
  return loc($"controls/{action}", action)
}
let closeHotkey = $"^{JB.B} | Esc"

let white = Color(255,255,255)
let dark = Color(200,200,200)
let disabledColor = Color(60,60,60)
let curTextColor = Color(250,250,200,200)
let defTextColor = Color(150,150,150,50)
let disabledTextColor = Color(50, 50, 50, 50)

let mkDefTxtCtor = @(text, available) function(curIdx, idx) {
  if (!(text instanceof Watched))
    text = Watched(text)
  let isActive = Computed(@() curIdx.value == idx)
  return watchElemState(@(sf) {
    watch = [available, text, isActive]
    rendObj = ROBJ_TEXTAREA
    behavior = Behaviors.TextArea
    text = text.value
    color = !available.value ? disabledTextColor
      : (sf & S_HOVER) || isActive.value ? curTextColor
      : defTextColor
    hplace = ALIGN_CENTER
    vplace = ALIGN_CENTER
    maxWidth = hdpx(140)
    valign = ALIGN_CENTER
  })
}

let mkDefImageCtor = @(elemSize) function (curImage, fallbackImage=null, available = Watched(true)) {
  if (curImage == null)
    return null
  let fallbackPicture = fallbackImage != null ? Picture(fallbackImage) : null
  return function(curIdx, idx) {
    if (!(curImage instanceof Watched))
      curImage = Watched(curImage)
    let isActive = Computed(@() curIdx.value == idx)
    return watchElemState(@(sf) {
      rendObj = ROBJ_IMAGE
      watch = [available, curImage, isActive]
      image = curImage.value == "" ? fallbackPicture : Picture(curImage.value)
      fallbackImage = fallbackPicture
      color = !available.value ? disabledColor
        : (sf & S_HOVER) || isActive.value ? white
        : dark
      size = elemSize
      hplace = ALIGN_CENTER
      vplace = ALIGN_CENTER
    })
  }
}


let function mkBlurBack(radius) {
  let size = array(2, 2 * radius * 1.02)
  return {
    size
    rendObj = ROBJ_MASK
    image = Picture("ui/uiskin/white_circle.svg:{0}:{0}:K".subst(size[0].tointeger()))
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    children = {
      rendObj = ROBJ_WORLD_BLUR
      size
      color = Color(190,190,190,190)
    }
  }
}

let mkSelectedActionHint = @(curIdx, available, actions, radius) function() {
  let res = { watch = curIdx }
  let action = actions?[curIdx.value]
  if (action == null)
    return res
  local text = available ? action?.text : action?.disabledtext
  if (!(text instanceof Watched))
    text = Watched(text)
  return res.__update({
    rendObj = ROBJ_TEXTAREA
    watch = [curIdx, text]
    size = SIZE_TO_CONTENT
    valign = ALIGN_CENTER
    hplace = ALIGN_CENTER
    halign = ALIGN_CENTER
    maxWidth = 0.7 * radius
    behavior = Behaviors.TextArea
    color = available ? curTextColor : disabledTextColor
    text = text.value
  })
}

local function mkPieMenuRoot(actions, curIdx, radius, showPieMenu, key = null, stickNo = 1) {
  let closeWithoutClick = function() {
    curIdx(null)
    showPieMenu(false)
  }

  let curHoveredIdx = Watched(null)
  curHoveredIdx.subscribe(function(v) { if (v != null || !isGamepad.value) curIdx(v) })

  let descr = function(){
    let available = actions?[curIdx.value].available

    return {
      watch = available
      hplace = ALIGN_CENTER
      vplace = ALIGN_CENTER
      children = mkSelectedActionHint(curIdx, available?.value ?? true, actions, radius)
    }
  }
  let desc = {
    key
    size = flex()
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    sound = {
      attach = "ui/map_on"
      detach = "ui/map_off"
    }
    behavior = Behaviors.ActivateActionSet
    actionSet = "PieMenu"
    hotkeys = [
      [closeHotkey, {description = {skip = true}, action = closeWithoutClick}],
    ]

    children = [
      mkBlurBack(radius)
      mkPieMenuDarg({
        stickNo
        devId = isGamepad.value ? DEVID_JOYSTICK : DEVID_MOUSE
        onClick = @(_) showPieMenu(false) // if we close and an item is selected, onDetach will handle the click. Otherwise, pie menu will just close
        radius = radius
        onDetach = @() actions?[curIdx.value].onClick()
        onAttach = @() curIdx(null)
        curIdx
        curHoveredIdx
        children = [descr]
        objs = actions
      })
    ]
  }

  if (!isGamepad.value)
    desc.cursor <- cursors.normal

  return desc
}

let mkOnSelect = @(action, disabledAction, available)
  @() available.value ? action() : disabledAction?()

let mkOnClick = @(onSelect, showPieMenu) function() {
  onSelect()
  showPieMenu(false)
}

let mkOnHotkey = @(curIdx, idx, showPieMenu) function() {
  curIdx(idx)
  showPieMenu(false)
}

let function textFunc(text) {
  return {
    fillColor = HUD_TIPS_HOTKEY_FG
    borderWidth = 0
    borderRadius = hdpx(2)
    size = SIZE_TO_CONTENT
    padding = [0, hdpx(3)]
    rendObj = ROBJ_BOX
    children = [
      {rendObj = ROBJ_TEXT text = text color=Color(0,0,0)}
    ]
  }
}

local function mkCtor(ctor, mkDefCtor, image, fallbackImage, available, text, hotkey, hotkeyAction) {
  available = available ?? Watched(true)
  let main = ctor
    ?? mkDefCtor(image, fallbackImage, available)
    ?? mkDefTxtCtor(text ?? "", available)
  return @(curIdx, idx) function() {
    let children = [main(curIdx, idx)]
    if (hotkey != null)
      if (available.value)
        children.insert(0, mkHotkey(hotkey, hotkeyAction, { textFunc }))
      else
        children.insert(0, { hotkeys = [[hotkey, @() null]] })
    return {
      watch = [isGamepad, available]
      halign = ALIGN_CENTER
      gap = isGamepad.value ? hdpx(1) : hdpx(5)
      valign = ALIGN_CENTER
      flow = isGamepad.value ? FLOW_VERTICAL : FLOW_HORIZONTAL
      children
    }
  }
}

let KEYBOARD_HOTKEY_MAX_NUM = 9

let idxToKbHotkey = @(idx) ((idx + 1) % (KEYBOARD_HOTKEY_MAX_NUM + 1)).tostring()
let mkKbdHotkeyStub = @(actionsCount) "{0}".subst(" | ".join(
  [].resize(KEYBOARD_HOTKEY_MAX_NUM - min(actionsCount, KEYBOARD_HOTKEY_MAX_NUM))
    .map(@(_, idx) idx + actionsCount + 1)))

local function filterAndUpdateActions(actions, showPieMenu, mkDefCtor, curIdx){
  actions = actions.map(function(a, idx) {
    let available = a?.available instanceof Watched
      ? a.available
      : Watched(a?.available ?? true)
    if (a == null
       || (type(a?.action)=="string"
           //action invaild if there is no such action in actions config)
           && dainput.get_action_handle(a?.action, 0xFFFF) == dainput.BAD_ACTION_HANDLE))
      return null
    let text = a?.text ?? ((type(a.action)=="string") ? locAction(a.action) : null)
    let action = type(a.action) == "function"
      ? a.action
      : @() dainput.send_action_event(dainput.get_action_handle(a.action, 0xFFFF))
    let onSelect = mkOnSelect(action, a?.disabledAction, available)
    let onClick = mkOnClick(onSelect, showPieMenu)
    let onHotkey = mkOnHotkey(curIdx, idx, showPieMenu)
    let kbdHotkey = "{0}".subst(idxToKbHotkey(idx))
    let ctor = mkCtor(a?.ctor, mkDefCtor, a?.image, a?.fallbackImage, available, text, kbdHotkey, onHotkey)
    return a.__merge({
      text
      action
      ctor
      disabledtext = a?.disabledtext ?? loc("pieMenu/actionUnavailable")
      onSelect
      onClick
      available
      idx
    })
  })
  return actions
}

let function mkPieMenu(actions, curIdx = Watched(null), showPieMenu = Watched(false),
  radius = Watched(hdpx(350)), elemSize = null, key = null, stickNo = 1
){
  elemSize = elemSize ?? Computed(@() array(2, (0.4 * radius.value).tointeger()))

  return function(){
    let mkDefCtor = mkDefImageCtor(elemSize.value)
    let actionsV = filterAndUpdateActions(actions.value, showPieMenu, mkDefCtor, curIdx)
    let kbdHotkeyStub = mkKbdHotkeyStub(actionsV.len())
    let res = { watch = [showPieMenu, isGamepad, actions, elemSize, radius] }
    if (!showPieMenu.value)
      return res

    return res.__update({
      size = flex()
      children = [
        mkPieMenuRoot(actionsV, curIdx, radius.value, showPieMenu, key, stickNo)
        { key = kbdHotkeyStub, hotkeys = [[kbdHotkeyStub, @() null]] }
      ]
      function onAttach(elem) {
        move_mouse_cursor(elem)
      }
    })
  }
}

return kwarg(mkPieMenu)
