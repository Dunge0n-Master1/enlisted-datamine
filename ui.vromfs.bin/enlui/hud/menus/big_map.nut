from "%enlSqGlob/ui_library.nut" import *
from "minimap" import MinimapState


let { mmChildrenCtorsGeneration, getMmChildrenCtors } = require("%ui/hud/huds/minimap/minimap_state.nut")
let { bigmapDefaultVisibleRadius } = require("bigmap_state.nut")
let mmContext = require("%ui/hud/huds/minimap/minimap_ctx.nut")
let mouseButtons = require("%enlSqGlob/mouse_buttons.nut")
let mkTask = require("%ui/hud/huds/overlays/mkTask.nut")
let { makeVertScroll } = require("%darg/components/scrollbar.nut")

let { removeInteractiveElement, hudIsInteractive, switchInteractiveElement
} = require("%ui/hud/state/interactive_state.nut")
let {isGamepad} = require("%ui/control/active_controls.nut")

let {tipCmp} = require("%ui/hud/huds/tips/tipComponent.nut")
let {DEFAULT_TEXT_COLOR} = require("%ui/hud/style.nut")
let JB = require("%ui/control/gui_buttons.nut")
let sendMark = require("%ui/hud/send_minimap_mark.nut")
let {safeAreaAmount} = require("%enlSqGlob/safeArea.nut")
let {mouseNavTips, placePointsTipGamepad, navGamepadHints, placePointsTipMouse} = require("mapComps.nut")
let {isAlive} = require("%ui/hud/state/health_state.nut")
let cursors = require("%ui/style/cursors.nut")
let tasksInBattle = require("%ui/hud/state/tasksInBattle.nut")

let screen_aspect_ratio = sw(100)/sh(100)
local mapSizeForTasks = [fsh(70), fsh(70)]
let leftPadding = Watched(mapSizeForTasks[1]/10)

if (screen_aspect_ratio <= 1280.0/1024) {
  mapSizeForTasks = [fsh(50), fsh(50)]
  leftPadding(0)
}
else if ( screen_aspect_ratio <= 4.0/3 ) {
  mapSizeForTasks = [fsh(55), fsh(55)]
  leftPadding(0)
}

let showBigMap = mkWatched(persist, "showBigMap", false)
let needShowTasks = Computed(@() tasksInBattle.value.len()>0)
let mapSize = Computed(@() needShowTasks.value
  ? mapSizeForTasks
  : [safeAreaAmount.value*fsh(70), safeAreaAmount.value*fsh(70)])

let tasksList = @() {
  watch = tasksInBattle
  size = [hdpx(450), SIZE_TO_CONTENT]
  children = makeVertScroll({
      size = [flex(), SIZE_TO_CONTENT]
      flow = FLOW_VERTICAL
      children = tasksInBattle.value.map(@(u) mkTask(u))
    },
    {
      size = [flex(), SIZE_TO_CONTENT]
      maxHeight = mapSize.value[0]
    })
}


isAlive.subscribe(function(live) {
  if (!live)
    showBigMap(false)
})

showBigMap.subscribe(@(_) removeInteractiveElement("bigMap"))

let mapRootAnims = [
  { prop=AnimProp.opacity, from=0, to=1, duration=0.15, play=true, easing=OutCubic }
  { prop=AnimProp.opacity, from=1, to=0, duration=0.25, playFadeOut=true, easing=OutCubic }
]


let minimapState = MinimapState({
  ctx = mmContext
  visibleRadius = bigmapDefaultVisibleRadius.value
  shape = "square"
})
let mapTransform = { rotate = 90 }
let markersTransform = {rotate = -90}

bigmapDefaultVisibleRadius.subscribe(@(r) minimapState.setVisibleRadius(r))

let visCone = {
  size = flex()
  minimapState = minimapState
  rendObj = ROBJ_MINIMAP_VIS_CONE
  behavior = Behaviors.Minimap
}

let modeHotkeyTip = tipCmp({
  text = loc("controls/HUD.Interactive")
  inputId = "HUD.Interactive"
  textColor = DEFAULT_TEXT_COLOR
  main_params= {
    size = [SIZE_TO_CONTENT, ph(100)]
  }
  animations = []
  style = {rendObj=null}
})

let mkPlacePointsTip = @(mapSize, addChild) @() {
  watch = [mapSize, isGamepad]
  size = [mapSize.value[0], SIZE_TO_CONTENT]
  flow = FLOW_VERTICAL
  halign = ALIGN_CENTER
  gap = fsh(0.5)
  children = [
    //modeHotkeyTip
    isGamepad.value ? navGamepadHints : mouseNavTips
    isGamepad.value ? placePointsTipGamepad : placePointsTipMouse
    addChild
  ]
}
let mkInteractiveTips = @(internactiveTips, notInteractiveTips) @() {
  watch = hudIsInteractive
  size = [flex(), fontH(430)]
  flow = FLOW_VERTICAL
  gap = fsh(0.5)
  padding = [fsh(1), 0]
  halign = ALIGN_CENTER
  children = hudIsInteractive.value ? internactiveTips : notInteractiveTips
}

let function interactiveFrame() {
  let res = { watch = hudIsInteractive }
  if (!hudIsInteractive.value)
    return res
  return res.__update({
    rendObj = ROBJ_FRAME
    size = flex()
    borderWidth = hdpx(2)
    color = Color(180,160,10,130)

    // use frame since parent already has another hook
    hooks = HOOK_ATTACH
    actionSet = "StopInput"
  })
}

let bigMapEventHandlers = {
  ["HUD.Interactive"] = @(_event) switchInteractiveElement("bigMap"),
  ["HUD.Interactive:end"] = function onHudInteractiveEnd(event) {
    if (showBigMap.value && ((event?.dur ?? 0) > 500 || event?.appActive == false))
      removeInteractiveElement("bigMap")
  }
}

let closeMapDesc = {
  action = @() showBigMap(false),
  description = loc("Close"),
  inputPassive = true
}

let function mkMapLayer(ctorWatch, paramsWatch, map_size) {
  return @() {
    watch = [paramsWatch, ctorWatch?.watch]
    size = map_size
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    clipChildren = true
    eventPassThrough = true
    minimapState = minimapState
    transform = mapTransform
    behavior = Behaviors.Minimap
    children = ctorWatch?.ctor(paramsWatch.value)
  }
}

let interactiveTips = mkInteractiveTips(
  mkPlacePointsTip(mapSize, null),
  modeHotkeyTip)

let function onClickMap(e){
  if (e.button==1 || (isGamepad.value && e.button==0))
    sendMark(e, minimapState)
}
let function onDoubleClickMap(e) {
  sendMark(e, minimapState)
}

let markersParams = Computed(@() {
  state = minimapState
  size = mapSize.value
  isCompassMinimap = false
  transform = markersTransform
  isInteractive = hudIsInteractive.value
  showHero = true
})

let baseMap = @() {
  size = mapSize.value
  watch = mapSize
  minimapState = minimapState
  rendObj = ROBJ_MINIMAP
  transform = mapTransform
  panMouseButton = mouseButtons.MMB
  behavior = hudIsInteractive.value
    ? [Behaviors.Minimap, Behaviors.Button, Behaviors.MinimapInput]
    : [Behaviors.Minimap]
  color = Color(255, 255, 255, 200)

  halign = ALIGN_CENTER
  valign = ALIGN_CENTER

  clipChildren = true
  eventPassThrough = true
  stickCursor = false
  children = [visCone]

  onClick = onClickMap
  onDoubleClick = onDoubleClickMap
}

let mapLayers = @() {
  hooks = HOOK_ATTACH
  actionSet = "BigMap"
  watch = [mmChildrenCtorsGeneration, mapSize]
  size = mapSize.value
  children = [
    baseMap
  ]
    .extend(getMmChildrenCtors().map(@(c) mkMapLayer(c, markersParams, mapSize.value)))
    .append(interactiveFrame)
}

let framedMap = @() {
  color = Color(0,0,0,140)
  rendObj = ROBJ_SOLID
  padding = fsh(1)
  watch = mapSize
  children = mapLayers
}

let mapBlock = @(){
  watch = hudIsInteractive
  size = SIZE_TO_CONTENT
  flow = FLOW_VERTICAL
  halign = ALIGN_CENTER
  children = [
    framedMap
    interactiveTips
  ]
}

let function bigMap() {
  let needCursor = hudIsInteractive.value
  return {
    watch = hudIsInteractive
    key = "big_map"
    hplace = ALIGN_CENTER
    vplace = ALIGN_CENTER
    pos = [0, hdpx(30)]
    size = SIZE_TO_CONTENT
    cursor = needCursor ? cursors.normal : null
    sound = {
      attach = "ui/map_on"
      detach = "ui/map_off"
    }

    children = @() {
      watch = [needShowTasks, hudIsInteractive]
      size = SIZE_TO_CONTENT
      flow = FLOW_HORIZONTAL
      gap = fsh(1)
      children = [
        needShowTasks.value ? @(){size = [leftPadding.value, 0] watched= leftPadding} : null
        mapBlock
        needShowTasks.value
          ? @() {
              size = [SIZE_TO_CONTENT, mapSize.value[1] + fsh(11)]
              disableInput = !hudIsInteractive.value
              children = tasksList
            }
          : null
      ]
    }


    animations = mapRootAnims
    hotkeys = [
      [ "Esc", closeMapDesc],
      [ $"^{JB.B}", closeMapDesc],
      [ "@HUD.BigMap", closeMapDesc ],
      [$"J:RB | J:LB"] //just mask them out
    ]
    eventHandlers = bigMapEventHandlers
  }
}

return {
  bigMap
  showBigMap
}
