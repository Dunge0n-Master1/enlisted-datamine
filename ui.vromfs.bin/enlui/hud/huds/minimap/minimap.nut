from "%enlSqGlob/ui_library.nut" import *
from "minimap" import MinimapState

let {hudIsInteractive} = require("%ui/hud/state/interactive_state.nut")
let mmContext = require("minimap_ctx.nut")
let {isGamepad, isTouch} = require("%ui/control/active_controls.nut")
let command = require("%ui/hud/send_minimap_mark.nut")
let {controlHudHint} = require("%ui/components/controlHudHint.nut")
let { getMmChildrenCtors, mmChildrenCtorsGeneration, minimapDefaultVisibleRadius, regionsColorsUpdate } = require("%ui/hud/huds/minimap/minimap_state.nut")
let mouseButtons = require("%enlSqGlob/mouse_buttons.nut")

let mapSize = [fsh(17), fsh(17)]
let mapContentMargin = fsh(0.5)//needed because of compass arrows that are out of size

let MMSHAPES = {
  SQUARE = {
    rendType = "square"
    rotate = 90
    minimapObjsTransform = {rotate=-90}
    blurBackMask = null
    clipChildren = true
    viewDependentRotation = false
    canvasInteractive = [
      [VECTOR_WIDTH, hdpx(4)],
      [VECTOR_RECTANGLE, 0.5, 0.5, 99.5, 99.5],
    ]
  },
  CIRCLE = {
    blurBackMask = Picture("ui/uiskin/white_circle.svg:{0}:{0}:K".subst(mapSize[0].tointeger()))
    rendType = "circle"
    rotate = 0
    minimapObjsTransform = {rotate=0}
    viewDependentRotation=true
    clipChildren = false
    canvasInteractive = [
      [VECTOR_WIDTH, hdpx(4)],
      [VECTOR_ELLIPSE, 50, 50, 49.5, 49.5]
    ]
  }
}

let curMinimapShape = MMSHAPES.SQUARE
let minimapState = MinimapState({
  ctx = mmContext
  visibleRadius = minimapDefaultVisibleRadius.value
  shape = curMinimapShape.rendType
})
minimapDefaultVisibleRadius.subscribe(@(r) minimapState.setVisibleRadius(r))
let mapTransform = { rotate = curMinimapShape.rotate }


let blurredWorld = {
  rendObj = ROBJ_MASK
  image = curMinimapShape.blurBackMask
  size = mapSize
  children = {
    rendObj = ROBJ_WORLD_BLUR
    size = flex()
  }
}


let regionsGeometry = @() {
  watch = regionsColorsUpdate
  size = flex()
  minimapState = minimapState
  rendObj = ROBJ_MINIMAP_REGIONS_GEOMETRY
  behavior = Behaviors.Minimap
}.__update(regionsColorsUpdate.value)

let visCone = {
  size = flex()
  minimapState = minimapState
  rendObj = ROBJ_MINIMAP_VIS_CONE
  behavior = Behaviors.Minimap
}

let function onClick(e){
  if (e.button == 1 || isGamepad.value)
    command(e, minimapState)
}
let function onDoubleClick(e) {
  command(e, minimapState)
}


let mapHotKey = {
  children = controlHudHint("HUD.BigMap")
  hplace = ALIGN_LEFT
  vplace = ALIGN_BOTTOM
  margin = [hdpx(3),hdpx(3)]
  opacity = 0.7
}

let baseMap = {
  size = mapSize
  transform = mapTransform
  minimapState = minimapState
  rendObj = ROBJ_MINIMAP
  behavior = Behaviors.Minimap
  margin = mapContentMargin

  children = [regionsGeometry, visCone]
}

let commonLayerParams = {
  state = minimapState
  size = mapSize
  isCompassMinimap = curMinimapShape.viewDependentRotation
  transform = curMinimapShape.minimapObjsTransform
  showHero = false
}

let function mkMinimapLayer(ctorWatch, params) {
  return @() {
    watch = ctorWatch.watch
    size = flex()
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    clipChildren = params?.clipChildren ?? curMinimapShape.clipChildren
    minimapState = minimapState
    transform = mapTransform
    behavior = Behaviors.Minimap
    children = ctorWatch.ctor(params)
  }
}

let noClipMap = @(panButton, clickOverride = null) @() {
  watch = hudIsInteractive
  size = mapSize
  transform = mapTransform
  minimapState = minimapState
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  margin = mapContentMargin
  stickCursor = false
  eventPassThrough = true
  panMouseButton = panButton
  behavior = isTouch.value ? [Behaviors.Button]
    : (hudIsInteractive.value
    ? [Behaviors.Button, Behaviors.MinimapInput]
    : null)

  onClick = clickOverride ?? onClick
  skipDirPadNav = true
  onDoubleClick = onDoubleClick
}

let interactiveCanvas = @() {
  watch = hudIsInteractive
  size = flex()
  children = hudIsInteractive.value
    ? {
        rendObj = ROBJ_VECTOR_CANVAS
        color = Color(180,160,10,130)
        fillColor = Color(0,0,0,0)
        size = flex()
        commands = curMinimapShape.canvasInteractive
      }
    : null
}

let function makeMinimap(panButton = mouseButtons.LMB, clickOverride = null) {
  return @() {
    watch = mmChildrenCtorsGeneration
    size = mapSize
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    clipChildren = curMinimapShape.clipChildren

    children = [
      blurredWorld,
      baseMap,
    ]
      .extend(getMmChildrenCtors().map(@(c) mkMinimapLayer(c, commonLayerParams)))
      .append(
        interactiveCanvas,
        noClipMap(panButton, clickOverride),
        mapHotKey
      )
  }
}

return kwarg(makeMinimap)
