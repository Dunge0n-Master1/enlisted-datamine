from "%enlSqGlob/ui_library.nut" import *

let { aboveUiLayer } = require("%enlist/uiLayers.nut")
let { WindowTransparent } = require("%ui/style/colors.nut")
let cursors = require("%ui/style/cursors.nut")
let fa = require("%ui/components/fontawesome.map.nut")
let { fontawesome } = require("%enlSqGlob/ui/fonts_style.nut")

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

let mkPanel = function(posSizeWatch, isOpenWatch, content, params = {}) {
  let pos = posSizeWatch.value?.pos ?? [0, 0]
  let size = params?.size ?? defaultSize
  style.__update(params?.style ?? {})

  if (!isOpenWatch.value) {
    return { watch = isOpenWatch }
  }

  return panelBlock.__update({
    fillColor = style.panelBgColor
    watch = [posSizeWatch, isOpenWatch]
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
        panelHeader(@() isOpenWatch(false))
        content
      ]
    })
  })
}

let Panel = function() {
  local panel = null
  local panelPosition = [0, 0]
  let setPosition = @(pos) panelPosition = clone pos
  let posSizeWatch = Watched({
    size = defaultSize
    pos = [0, 0]
  })
  let isOpen = Watched(false)

  let open = function(content, params) {
    posSizeWatch({
      size = defaultSize
      pos = panelPosition
    })
    panel = @() mkPanel(posSizeWatch, isOpen, content, params)
    aboveUiLayer.add(panel, params?.key ?? PANEL_DEFAULT_KEY)
    isOpen(true)
  }

  return {
    open
    close = @() isOpen(false)
    setPosition
  }
}

return Panel
