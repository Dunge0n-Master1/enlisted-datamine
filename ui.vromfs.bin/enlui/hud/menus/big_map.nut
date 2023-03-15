from "%enlSqGlob/ui_library.nut" import *
from "minimap" import MinimapState

let { h1_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let { mmChildrenCtors } = require("%ui/hud/minimap_ctors.nut")
let { bigmapDefaultVisibleRadius } = require("bigmap_state.nut")
let mmContext = require("%ui/hud/huds/minimap/minimap_ctx.nut")
let mouseButtons = require("%enlSqGlob/mouse_buttons.nut")
let mkTask = require("%ui/hud/huds/overlays/mkTask.nut")
let { makeVertScroll } = require("%ui/components/scrollbar.nut")

let { removeInteractiveElement, hudIsInteractive, switchInteractiveElement
} = require("%ui/hud/state/interactive_state.nut")
let {isGamepad} = require("%ui/control/active_controls.nut")

let {tipCmp} = require("%ui/hud/huds/tips/tipComponent.nut")
let {DEFAULT_TEXT_COLOR} = require("%ui/hud/style.nut")
let JB = require("%ui/control/gui_buttons.nut")
let { command } = require("%ui/hud/send_minimap_mark.nut")
let {safeAreaAmount} = require("%enlSqGlob/safeArea.nut")
let {mouseNavTips, placePointsTipGamepad, navGamepadHints, placePointsTipMouse} = require("mapComps.nut")
let {isAlive} = require("%ui/hud/state/health_state.nut")
let cursors = require("%ui/style/cursors.nut")
let { battleUnlocks, statsInGame, getTasksWithProgress } = require("%ui/hud/state/tasksInBattle.nut")
let { unlockProgress } = require("%enlSqGlob/userstats/unlocksState.nut")
let { missionName, missionType } = require("%enlSqGlob/missionParams.nut")
let { isReplay } = require("%ui/hud/state/replay_state.nut")

let isMapAutonomousInReplay = Watched(true)
let isMapInteractive = Computed(@() hudIsInteractive.value
  && (!isReplay.value || !isMapAutonomousInReplay.value))

let screen_aspect_ratio = sw(100)/sh(100)
local mapSizeForTasks = [fsh(70), fsh(70)]
let leftPadding = Watched(mapSizeForTasks[1]/10)
let mapPadding = fsh(1)

if (screen_aspect_ratio <= 1280.0/1024) {
  mapSizeForTasks = [fsh(50), fsh(50)]
  leftPadding(0)
}
else if ( screen_aspect_ratio <= 4.0/3 ) {
  mapSizeForTasks = [fsh(55), fsh(55)]
  leftPadding(0)
}

let showBigMap = mkWatched(persist, "showBigMap", false)
let needShowTasks = Computed(@() battleUnlocks.value.len()>0)
let mapSize = Computed(@() needShowTasks.value
  ? mapSizeForTasks
  : [safeAreaAmount.value*fsh(70), safeAreaAmount.value*fsh(70)])

let tasksList = @() {
  watch = [mapSize, battleUnlocks, unlockProgress, statsInGame]
  size = [hdpx(450), SIZE_TO_CONTENT]
  key = "big_map_tasks"
  children = makeVertScroll({
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    children = getTasksWithProgress(battleUnlocks.value, unlockProgress.value, statsInGame.value)
      .map(@(u) mkTask(u))
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
    isGamepad.value ? navGamepadHints : mouseNavTips
    isGamepad.value ? placePointsTipGamepad : placePointsTipMouse
    addChild
  ]
}
let mkInteractiveTips = @(internactiveTips, notInteractiveTips) @() {
  watch = isMapInteractive
  size = [flex(), hdpx(100)]
  valign = ALIGN_CENTER
  flow = FLOW_VERTICAL
  gap = fsh(0.5)
  padding = [mapPadding, 0]
  halign = ALIGN_CENTER
  children = isMapInteractive.value ? internactiveTips : notInteractiveTips
}

let function interactiveFrame() {
  let res = { watch = isMapInteractive }
  if (!isMapInteractive.value)
    return res
  return res.__update({
    rendObj = ROBJ_FRAME
    size = flex()
    borderWidth = hdpx(2)
    color = Color(180,160,10,130)

    behavior = Behaviors.ActivateActionSet
    actionSet = "StopInput"
  })
}

let bigMapEventHandlers = {
  ["HUD.Interactive"] = function(_event) {
    if (isReplay.value)
      isMapAutonomousInReplay(!isMapAutonomousInReplay.value)
    switchInteractiveElement("bigMap")
  },
  ["HUD.Interactive:end"] = function (event) {
    if (showBigMap.value && ((event?.dur ?? 0) > 500 || event?.appActive == false)) {
      if (isReplay.value)
        isMapAutonomousInReplay(true)
      removeInteractiveElement("bigMap")
    }
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
    command(e, minimapState)
}
let function onDoubleClickMap(e) {
  command(e, minimapState)
}

let markersParams = Computed(@() {
  state = minimapState
  size = mapSize.value
  isCompassMinimap = false
  transform = markersTransform
  isInteractive = isMapInteractive.value
  showHero = true
})

let baseMap = @() {
  size = mapSize.value
  watch = [isMapInteractive, mapSize]
  minimapState = minimapState
  rendObj = ROBJ_MINIMAP
  transform = mapTransform
  panMouseButton = mouseButtons.MMB
  behavior = isMapInteractive.value
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
  behavior = Behaviors.ActivateActionSet
  actionSet = "BigMap"
  watch = [ mapSize]
  size = mapSize.value
  children = [
    baseMap
  ]
    .extend(mmChildrenCtors.map(@(c) mkMapLayer(c, markersParams, mapSize.value)))
    .append(interactiveFrame)
}


let mapBlock = {
  flow = FLOW_VERTICAL
  halign = ALIGN_CENTER
  padding = [0, mapPadding]
  children = [
    mapLayers
    interactiveTips
  ]
}

let missionTitle = @(){
  watch = [missionName, missionType]
  size = [flex(), SIZE_TO_CONTENT]
  padding = [mapPadding, mapPadding]
  children = missionName.value == null ? null : {
    rendObj = ROBJ_TEXT
    text = loc(missionName.value, { mission_type = loc($"missionType/{missionType.value}") })
    fontFxColor = DEFAULT_TEXT_COLOR
  }.__update(h1_txt)
}


let mapContent = @() {
  watch = needShowTasks
  flow = FLOW_HORIZONTAL
  children = [
    mapBlock
    needShowTasks.value
      ? @() {
          watch = [isReplay, isMapInteractive]
          size = [SIZE_TO_CONTENT, flex()]
          disableInput = !isMapInteractive.value
          children = isReplay.value ? null : tasksList
        }
      : null
  ]
}


let function bigMap() {
  let needCursor = isMapInteractive.value
  return {
    rendObj = ROBJ_SOLID
    color = Color(0,0,0,140)
    watch = isMapInteractive
    key = "big_map"
    hplace = ALIGN_CENTER
    vplace = ALIGN_CENTER
    pos = [0, hdpx(30)]
    padding = [mapPadding, 0]
    cursor = needCursor ? cursors.normal : null
    flow = FLOW_VERTICAL
    sound = {
      attach = "ui/map_on"
      detach = "ui/map_off"
    }
    children = [
      missionTitle
      mapContent
    ]


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
