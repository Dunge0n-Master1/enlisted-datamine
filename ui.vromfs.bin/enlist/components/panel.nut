from "%enlSqGlob/ui_library.nut" import *

let { aboveUiLayer } = require("%enlist/uiLayers.nut")
let { isLoggedIn } = require("%enlSqGlob/login_state.nut")
let { WindowTransparent } = require("%ui/style/colors.nut")
let cursors = require("%ui/style/cursors.nut")
let fa = require("%ui/components/fontawesome.map.nut")
let { fontawesome } = require("%enlSqGlob/ui/fonts_style.nut")
let JB = require("%ui/control/gui_buttons.nut")

const PANEL_DEFAULT_KEY = "panel"
let defaultSize = [hdpx(480), hdpx(360)]

let insideBlock = {
  valign = ALIGN_TOP
  halign = ALIGN_CENTER
  flow = FLOW_VERTICAL
  size = SIZE_TO_CONTENT
  transform = {}
  animations = [
    { prop=AnimProp.translate,  from=[0, sh(5)], to=[0,0], duration=0.5, play=true, easing=OutBack }
    { prop=AnimProp.opacity, from=0.0, to=1.0, duration=0.25, play=true, easing=OutCubic }
    { prop=AnimProp.translate, from=[0,0], to=[0, sh(30)], duration=0.7, playFadeOut=true, easing=OutCubic }
    { prop=AnimProp.opacity, from=1.0, to=0.0, duration=0.6, playFadeOut=true, easing=OutCubic }
  ]
}

let style = {
  panelBgColor      = WindowTransparent
  headerFillColor   = Color(20, 20, 20, 20)
  headerBorderColor = null
  headerBorderWidth = null
  headerTxtColor    = Color(140, 140, 140)
  headerFontSize    = hdpx(18)
  headerPadding     = hdpx(5)
  headerCloseBtnSize = [hdpx(32), hdpx(32)]
}

let panelHeader = @(onClick) {
  rendObj = ROBJ_BOX
  fillColor = style.headerFillColor
  borderWidth = style.headerBorderWidth
  borderColor = style.headerBorderColor
  halign = ALIGN_RIGHT
  size = [flex(), SIZE_TO_CONTENT]
  children = {
    rendObj = ROBJ_TEXT
    text = fa["close"]
    font = fontawesome.font
    behavior = Behaviors.Button
    onClick
    fontSize = style.headerFontSize
    padding = style.headerPadding
    size = style.headerCloseBtnSize
    color = style.headerTxtColor
    hotkeys = [[ $"^{JB.B} | Esc" ]]
  }
}

let panelBlock = {
  borderRadius = hdpx(2)
  rendObj = ROBJ_WORLD_BLUR_PANEL
  size = SIZE_TO_CONTENT
  behavior = Behaviors.MoveResize
  moveResizeCursors = null
  stopHover = true
}

let mkPanel = function(posSizeWatch, content, closeCb, params = {}) {
  let pos = posSizeWatch.value?.pos ?? [0, 0]
  let size = params?.size ?? defaultSize
  style.__update(params?.style ?? {})

  return panelBlock.__update({
    fillColor = style.panelBgColor
    watch = posSizeWatch
    cursor = cursors.normal
    pos
    onMoveResize = function(dx, dy, _dw, _dh) {
      let newPosSize = {size, pos = [
          clamp(pos[0] + dx, 0, sw(100) - size[0]),
          clamp(pos[1] + dy, 0, sh(100) - size[1])
        ]}
        posSizeWatch(newPosSize)
        return newPosSize
    }
    children = insideBlock.__update({
      children = [
        panelHeader(closeCb)
        content
      ]
    })
  })
}

isLoggedIn.subscribe(function(val) {
  if (!val)
    aboveUiLayer.clear()
})

let Panel = function() {
  local panel = null
  local panelPosition = [0, 0]
  let setPosition = @(pos) panelPosition = clone pos
  let posSizeWatch = Watched({
    size = defaultSize
    pos = [0, 0]
  })
  local key = null

  let close = function() {
    aboveUiLayer.remove(key)
  }

  let open = function(content, params) {
    posSizeWatch({
      size = defaultSize
      pos = panelPosition
    })
    key = params?.key ?? PANEL_DEFAULT_KEY
    panel = @() mkPanel(posSizeWatch, content, close, params)
    aboveUiLayer.add(panel, key)
  }

  return {
    open
    close
    isOpen = @() aboveUiLayer.isUidInList(key)
    setPosition
  }
}

return Panel
