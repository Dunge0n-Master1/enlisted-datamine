from "%enlSqGlob/ui_library.nut" import *

let mkPieMenuDarg = require("%ui/components/mkPieMenuBase.nut")
let cursors = require("%ui/style/cursors.nut")
let {isGamepad} = require("%ui/control/active_controls.nut")
let dainput = require("dainput2")
let JB = require("%ui/control/gui_buttons.nut")
let {mkHintRow, mkHotkey} = require("%ui/components/uiHotkeysHint.nut")
let {HUD_TIPS_HOTKEY_FG} = require("%ui/hud/style.nut")

let cfgMax = {
  itemsOffset = 1
  gamepadHotkeys = ["J:LB", "J:D.Up", "J:RB", "J:D.Right", "J:Y", "J:D.Down", "J:X", "J:L.Thumb", "J:D.Left"]
}
let cfgByAmount = {
  [1] = ["J:D.Up"],
  [2] = ["J:D.Up", "J:D.Down"],
  [3] = ["J:D.Up", "J:D.Right", "J:D.Left"],
  [4] = ["J:D.Up", "J:D.Right", "J:D.Down", "J:D.Left"],
  [5] = ["J:D.Up", "J:D.Right", "J:D.Down", "J:X", "J:D.Left"],
  [6] = {
    itemsOffset = 1
    gamepadHotkeys = ["J:D.Left", "J:D.Up", "J:D.Right", "J:Y", "J:D.Down", "J:X"]
  },
  [7] = {
    itemsOffset = 1
    gamepadHotkeys = ["J:LB", "J:D.Up", "J:RB", "J:D.Right", "J:D.Down", "J:X", "J:D.Left"]
  },
  [8] = {
    itemsOffset = 1
    gamepadHotkeys = ["J:LB", "J:D.Up", "J:RB", "J:D.Right", "J:Y", "J:D.Down", "J:X", "J:D.Left"]
  },
}.map(@(v) type(v) != "array" ? v : { gamepadHotkeys = v })

let function locAction(action){
  return loc($"controls/{action}", action)
}
let activateHotkey = "^{0}".subst(JB.A)
let closeHotkey = "^Esc | {0}".subst(JB.B)

let isCurrent = @(sf, curIdx, idx) (sf & S_HOVER) || curIdx == idx

let white = Color(255,255,255)
let dark = Color(200,200,200)
let disabledColor = Color(60,60,60)
let curTextColor = Color(250,250,200,200)
let defTextColor = Color(150,150,150,50)
let disabledTextColor = Color(50, 50, 50, 50)

local function mkDefTxtCtor(text, available) {
  if (!(text instanceof Watched))
    text = Watched(text)
  return @(curIdx, idx)
    watchElemState(@(sf) {
      watch = [available, text]
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      text = text.value
      color = !available.value ? disabledTextColor
        : isCurrent(sf, curIdx.value, idx) ? curTextColor
        : defTextColor
      hplace = ALIGN_CENTER
      vplace = ALIGN_CENTER
      maxWidth = hdpx(140)
      valign = ALIGN_CENTER
    })
}

let function mkmkDefCtor(elemSize) {
  return function (curImage, fallbackImage=null, available = Watched(true)){
    if (curImage==null)
      return null
    let fallbackPicture = fallbackImage!=null ? Picture(fallbackImage) : null
    let function ctor(curIdx, idx){
      return watchElemState(function(sf) {
        let isWatched = curImage instanceof Watched
        let curVal = isWatched ? (curImage.value ?? "") : curImage
        return {
          image = ( curVal == "" ) ? fallbackPicture : Picture(curVal)
          fallbackImage = fallbackPicture
          watch = [available, isWatched ? curImage : null]
          rendObj = ROBJ_IMAGE
          color = !available.value ? disabledColor
            : (curIdx.value==idx || (sf & S_HOVER)) ? white : dark

          size = elemSize
          hplace = ALIGN_CENTER
          vplace = ALIGN_CENTER
        }
      })
    }
    return ctor
  }
}

let pic = memoize(@(sz) Picture("ui/uiskin/white_circle.svg:{0}:{0}:K".subst(sz.tointeger())))

let function mkBlurBack(radius) {
  let size = array(2, 2 * radius * 1.02)
  return {
    size
    rendObj = ROBJ_MASK
    image = pic(size[0])
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
    size = SIZE_TO_CONTENT
    valign = ALIGN_CENTER
    hplace = ALIGN_CENTER
    flow = FLOW_HORIZONTAL
    gap = hdpx(10)
    children = [
      available && (curIdx.value !=null) ? mkHintRow(activateHotkey) : null
      @() {
        watch = text
        size = SIZE_TO_CONTENT
        halign = ALIGN_CENTER
        maxWidth = 0.7 * radius
        rendObj = ROBJ_TEXTAREA
        behavior = Behaviors.TextArea
        color = available ? curTextColor : disabledTextColor
        text = text.value
      }
    ]
  })
}
let closeHint = {
  flow = FLOW_HORIZONTAL
  gap = hdpx(10)
  valign = ALIGN_CENTER
  hplace = ALIGN_CENTER
  children = [
    mkHintRow(closeHotkey)
    {
      rendObj = ROBJ_TEXT
      opacity = 0.5
      text = loc("pieMenu/close")
    }
  ]
}

local function mkPieMenuRoot(actions, curIdx, radius, showPieMenu, close = null) {
  close = close ?? @() showPieMenu(false)

  let descr = function(){
    let available = actions?[curIdx.value]?.available

    return {
      watch = available
      hplace = ALIGN_CENTER
      vplace = ALIGN_CENTER
      size = SIZE_TO_CONTENT
      gap = hdpx(40)
      flow = FLOW_VERTICAL
      children = [
        mkSelectedActionHint(curIdx, available?.value ?? true, actions, radius)
        closeHint
      ]
    }
  }
  let desc = {
    key = {}
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
      [activateHotkey, {description = { skip = true }, action = @() actions?[curIdx.value]?.onClick?()}],
      [closeHotkey, {description = {skip = true}, action = close}],
    ]

    children = [
      mkBlurBack(radius)
      mkPieMenuDarg({
        stickNo = 0
        devId = isGamepad.value ? DEVID_JOYSTICK : DEVID_MOUSE
        onClick = @(idx) actions?[idx]?.onClick?()
        radius = radius
        curIdx = curIdx
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
  @() available?.value ?? true ? action() : disabledAction?()

let mkOnClick = @(a, onSelect, showPieMenu) function() {
  onSelect()
  if (a?.closeOnClick ?? false)
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
//    color = Color(180,180,180,200)
    children = [
      {rendObj = ROBJ_TEXT text = text color=Color(0,0,0)}
    ]
  }
}

local function mkCtor(ctor, mkDefCtor, image, fallbackImage, available, text, hotkey, action) {
  available = available ?? Watched(true)
  let main = ctor
    ?? mkDefCtor(image, fallbackImage, available)
    ?? mkDefTxtCtor(text ?? "", available)
  return @(curIdx, idx) function() {
    let children = [main(curIdx, idx)]
    if (hotkey != null && available.value)
      children.insert(0, mkHotkey(hotkey, action, { textFunc }))
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

let idxToKbHotkey = @(idx) ((idx + 1) % 10).tostring()
let function combineHotkeys(list) {
  let all = list.filter(@(h) h != null)
  if (all.len() == 0)
    return null
  return "^{0}".subst(" | ".join(all))
}

let function shiftArray(arr, offset) {
  let total = arr.len()
  if (total < 2 || offset == 0)
    return arr
  let idx = (clamp(offset, 1 - total, total - 1) + total) % total
  return arr.slice(idx, total).extend(arr.slice(0, idx))
}

local function filterAndUpdateActions(actions, showPieMenu, mkDefCtor){
  let { itemsOffset = 0, gamepadHotkeys } = cfgByAmount?[actions.len()] ?? cfgMax
  actions = actions.map(function(a, idx) {
    let available = (a?.available != null && !(a?.available instanceof Watched))
      ? Watched(a.available)
      : a?.available
    if (a == null || (type(a?.action)=="string" && dainput.get_action_handle(a?.action, 0xFFFF) == dainput.BAD_ACTION_HANDLE)) //action invaild if there is no such action in actions config)
      return null
    let text = a?.text ?? ((type(a.action)=="string") ? locAction(a.action) : null)
    let action = type(a.action) == "function" ? a.action : @() dainput.send_action_event(dainput.get_action_handle(a.action, 0xFFFF))
    let onSelect = mkOnSelect(action, a?.disabledAction, available)
    let onClick = mkOnClick(a, onSelect, showPieMenu)
    let gpHotkey = gamepadHotkeys?[idx]
    let hotkeys = combineHotkeys([idxToKbHotkey(idx), gpHotkey])
    let ctor = mkCtor(a?.ctor, mkDefCtor, a?.image, a?.fallbackImage, available, text, hotkeys, onClick)
    return a.__merge({
      text
      action
      ctor
      disabledtext = a?.disabledtext ?? loc("pieMenu/actionUnavailable", "{action} ({unavailable})", {action=text unavailable=loc("unavailable")})
      onSelect
      onClick
      available

      //need to filter used shortcuts
      idx
      gpHotkey
    })
  })
  if (actions.len() == 1) //fill only half of pie menu when single action
    actions.append(null)
  actions = shiftArray(actions, itemsOffset)
  return actions
}

let function removeValue(list, value) {
  let idx = list.indexof(value)
  if (idx != null)
    list.remove(idx)
}

let function collectUnusedHotkeys(actions) {
  let gpUnused = clone cfgMax.gamepadHotkeys
  let idxUnused = cfgMax.gamepadHotkeys.map(@(_, idx) idx)
  foreach (action in actions) {
    removeValue(gpUnused, action?.gpHotkey)
    removeValue(idxUnused, action?.idx)
  }
  let allUnused = idxUnused.map(idxToKbHotkey)
    .extend(gpUnused)
  return combineHotkeys(allUnused)
}

let function mkPieMenu(actions, curIdx = Watched(null), showPieMenu = Watched(false),
  radius = Watched(hdpx(350)), elemSize = null, close = null
){
  elemSize = elemSize ?? Computed(@() array(2, (0.4 * radius.value).tointeger()))

  return function(){
    let mkDefCtor = mkmkDefCtor(elemSize.value)
    let actionsV = filterAndUpdateActions(actions.value, showPieMenu, mkDefCtor)
    let hotkeysStubs = collectUnusedHotkeys(actionsV)
    let res = { watch = [showPieMenu, isGamepad, actions, elemSize, radius] }
    if (!showPieMenu.value)
      return res

    return res.__update({
      size = flex()
      children = [
        mkPieMenuRoot(actionsV, curIdx, radius.value, showPieMenu, close)
        hotkeysStubs == null ? null
          : { key = hotkeysStubs, hotkeys = [[hotkeysStubs, @() null]] }
      ]
      function onAttach(elem) {
        move_mouse_cursor(elem)
      }
    })
  }
}

return kwarg(mkPieMenu)
