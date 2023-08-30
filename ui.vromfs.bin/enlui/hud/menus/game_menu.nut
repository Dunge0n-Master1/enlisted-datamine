from "%enlSqGlob/ui_library.nut" import *

let { fontHeading1, fontBody } = require("%enlSqGlob/ui/fontsStyle.nut")
let { TextDefault, TextHighlight, TextHover } = require("%ui/style/colors.nut")
let cursors = require("%ui/style/cursors.nut")
let gamepadImgByKey = require("%ui/components/gamepadImgByKey.nut")
let { isGamepad } = require("%ui/control/active_controls.nut")
let JB = require("%ui/control/gui_buttons.nut")
let { btnExitGame, btnResume, btnBindKeys, btnOptions } = require("game_menu_items.nut")
let menuCurrentIndex = Watched(-1)
let menuItems = {value = [btnResume, btnOptions, btnBindKeys, btnExitGame]}
let menuItemsGen = Watched(0)

let function setMenuItems(items) {
  menuItems.value = items
  menuItemsGen(menuItemsGen.value+1)
}
let getMenuItems = @() menuItems.value
  .filter(@(item) item != null && (item?.isAvailable() ?? true))

let showGameMenu = mkWatched(persist, "showGameMenu", false)

let function closeMenu() {
  menuCurrentIndex(-1)
  showGameMenu(false)
}

let function callHandler(item) {
  closeMenu()
  item?.action()
}

let height = calc_str_box("A", fontBody)[1]

let function makeMenuItem(data, idx) {
  let stateFlags = Watched(0)
  let isCur = (idx==menuCurrentIndex.value)
  let imgA = gamepadImgByKey.mkImageCompByDargKey(JB.A, {
    height = height
    vplace = ALIGN_CENTER
    pos = [-fsh(3.5), 0]
    transform = {
      scale = isCur ? [1,1] : [0,1]
      pivot = [0.7,0.5]
    }
    opacity = isCur ? 1: 0
    transitions = [
      { prop=AnimProp.translate, duration = 0.3, easing = InOutCubic }
      { prop=AnimProp.opacity, duration = 0.3, easing = InOutCubic }
      { prop=AnimProp.scale, duration = 0.4, easing = InOutCubic }
    ]
    animations = [
      { prop=AnimProp.scale, from=[0,1], to=[1,1], duration=0.25, play=true, easing=InOutCubic}
    ]
  })

  return @() {
    key = data
    rendObj = ROBJ_TEXT
    text = data.text
    behavior = Behaviors.Button
    sound = {
      click  = "ui/button_click"
      hover  = "ui/menu_highlight"
      active = "ui/button_action"
    }

    skipDirPadNav = true
    watch = [stateFlags, isGamepad]
    color = isCur ? TextHighlight
      : stateFlags.value & S_HOVER ? TextHover
      : TextDefault
    transitions = [
      { prop=AnimProp.translate, duration = 0.3, easing = InOutCubic }
    ]
    transform = {
      translate = [isCur ? -fsh(0.5) : -0, 0]
    }

    fontFx = isCur ? FFT_GLOW : FFT_NONE
    fontFxColor = TextDefault
    fontFxFactor = min(48, hdpx(48))
    children = isGamepad.value ? imgA : null
    margin = [fsh(2), fsh(8)]
    onClick = @() callHandler(data)
    onElemState = @(sf) stateFlags(sf)
    onHover = @(on) on ? menuCurrentIndex(idx) : null

    cursorNavAnchor = [elemh(80), elemh(90)]
  }.__update(fontHeading1)
}

let function goToNext(d) {
  let menuItemsVal = getMenuItems()
  let nextIdx = ((menuCurrentIndex.value ?? 0) + d + menuItemsVal.len()) % menuItemsVal.len()
  menuCurrentIndex(nextIdx)
  let target = menuItemsVal?[nextIdx]
  if (target != null)
    move_mouse_cursor(target, false)
}

let skip ={skip=true}
let function gameMenu() {
  let menuItemsVal = getMenuItems()
  let activateCurrent = @() callHandler(menuItemsVal?[menuCurrentIndex.value])

  let menu = {
    size = SIZE_TO_CONTENT
    flow = FLOW_VERTICAL
    pos = [sh(14), sh(30)]

    hotkeys = [
      ["@HUD.GameMenu", {action=closeMenu description=skip}],
      [$"^{JB.B} | J:Start", {action=closeMenu description=loc("BackBtn")}],
      [$"^{JB.A} | Enter | Space", {action=activateCurrent description=skip}],
      ["^Up | J:D.Up", {action =@() goToNext(-1) description = skip}],
      ["^Down | J:D.Down", {action =@() goToNext(1) description= skip}],
    ]

    children = menuItemsVal.map(makeMenuItem)

    transform = {}
    animations = [
      { prop=AnimProp.translate, from=[-sh(10),0], to=[0, 0], duration=0.2, play=true, easing=OutCubic}
    ]

    onAttach = @() defer(@() menuCurrentIndex(0))
  }

  return {
    watch = [menuCurrentIndex, menuItemsGen]
    key = "gameMenu"
    size = [sw(100), sh(100)]
    cursor = cursors.normal

    children = [
      {
        size = [sw(120), sh(100)]
        stopHotkeys = true
        stopMouse = true
        rendObj = ROBJ_WORLD_BLUR_PANEL
        color = Color(130,130,130)
      }
      menu
    ]

    transform = {
      pivot = [0.5, 0.25]
    }
    animations = [
      { prop=AnimProp.opacity, from=0, to=1, duration=0.2, play=true, easing=InOutCubic}
      { prop=AnimProp.opacity, from=1, to=0, duration=0.2, playFadeOut=true, easing=InOutCubic}
      //{ prop=AnimProp.scale, from=[1,1], to=[3, 1.5], duration=0.2, playFadeOut=true, easing=InOutCubic}
      { prop=AnimProp.translate, from=[0,0], to=[-sh(10),0], duration=0.2, playFadeOut=true, easing=InOutCubic}
    ]
    sound = {
      attach="ui/menu_enter"
      detach="ui/menu_exit"
    }

    behavior = Behaviors.ActivateActionSet
    actionSet = "StopInput"
  }
}


return {
  gameMenu
  setMenuItems
  showGameMenu
}
