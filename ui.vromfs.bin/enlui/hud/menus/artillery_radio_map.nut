import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *
from "minimap" import MinimapState

let {Point2,Point3} = require("dagor.math")
let { sqrt } = require("%sqstd/math.nut")
let mmContext = require("%ui/hud/huds/minimap/minimap_ctx.nut")
let {mmChildrenCtors} = require("%ui/hud/minimap_ctors.nut")
let {removeInteractiveElement, addInteractiveElement, hudIsInteractive} = require("%ui/hud/state/interactive_state.nut")
let {closeMenu} = require("%ui/hud/ct_hud_menus.nut")
let mouseButtons = require("%enlSqGlob/mouse_buttons.nut")
let JB = require("%ui/control/gui_buttons.nut")
let {isGamepad} = require("%ui/control/active_controls.nut")
let {DEFAULT_TEXT_COLOR} = require("%ui/hud/style.nut")
let cursors = require("%ui/style/cursors.nut")
let {isAlive, isDowned} = require("%ui/hud/state/health_state.nut")
let {isRadioMode} = require("%ui/hud/state/enlisted_hero_state.nut")
let { sound_play } = require("sound")
let {get_controlled_hero} = require("%dngscripts/common_queries.nut")
let {safeAreaAmount} = require("%enlSqGlob/safeArea.nut")
let {hintTextFunc, mouseNavTips, mkTips, navGamepadHints} = require("mapComps.nut")
let {CmdHeroSpeech, RequestCloseArtilleryMap, EventArtilleryMapPosSelected, CmdOpenArtilleryMap, CmdCloseArtilleryMap} = require("dasevents")
let {aircraftRequestTargetBiases, mkAircraftRequestPreview} = require("aircraft_request_preview.ui.nut")
let {isArtRequest} = require("art_request_preview.nut")
let {EventMinimapZoomed} = require("bhvMinimap")
let {currentShellType, changeShellTips, currentShellTypeIndex} = require("artillery_radio_map_shell_type.nut")
let {isAircraftRequest, artRequestTips} = require("art_request_tips.nut")
let {aircraftRequestAvailableTimeLeft} = require("%ui/hud/state/artillery.nut")
let showArtilleryMap = mkWatched(persist, "showArtilleryMap", false)
let selectedStartWorldPos = Watched(null)
let currentMouseWorldPos = Watched(Point3())

let mapSize = Computed(@() [safeAreaAmount.value*fsh(76), safeAreaAmount.value*fsh(76)])
let title = "map/artillery"
let tipLmb = "map/artilleryStrike"


isAlive.subscribe(function(live) {
  if (!live)
    showArtilleryMap(false)
})
isDowned.subscribe(function(downed){
  if (downed)
    showArtilleryMap(false)
})

isRadioMode.subscribe(@(active) showArtilleryMap(active))

let currentMaxLineLength = Computed(@() currentShellType.value?.maxLength ?? 0.0)
let isAircraftRequestActive = Computed(@() aircraftRequestAvailableTimeLeft.value <= 0.)

currentShellTypeIndex.subscribe(@(...) selectedStartWorldPos(null))

let function getAllowedLineEndPos(worldPos1, worldPos2, maxLineLength) {
  local dir = Point2(worldPos2.x, worldPos2.z) - Point2(worldPos1.x, worldPos1.z)
  let lineLengthSq = dir.lengthSq()
  local res = worldPos2
  if (lineLengthSq > 0.0 && lineLengthSq > maxLineLength * maxLineLength) {
    dir *= (maxLineLength / sqrt(lineLengthSq))
    res = worldPos1 + Point3(dir.x, 0.0, dir.y)
  }
  return res
}

let function onSelect(selectedPos) {
  if (selectedStartWorldPos.value || !currentShellType.value?.isLine) {
    let pos = selectedStartWorldPos.value ?? selectedPos
    let posEnd = getAllowedLineEndPos(pos, selectedPos, currentMaxLineLength.value)
    ecs.g_entity_mgr.sendEvent(get_controlled_hero(),
      EventArtilleryMapPosSelected({pos, typeIndex = currentShellTypeIndex.value, posEnd}))
    selectedStartWorldPos(null)
  } else
    selectedStartWorldPos(selectedPos)
}
let closeRequest = @() ecs.g_entity_mgr.sendEvent(get_controlled_hero(), RequestCloseArtilleryMap())

showArtilleryMap.subscribe(function(val){
  if (val) {
    closeMenu("BigMap")
    closeMenu("Scores")
    addInteractiveElement("artilleryMap")
    selectedStartWorldPos(null)
  } else {
    removeInteractiveElement("artilleryMap")
    closeRequest()
  }
})

let minimapState = MinimapState({
  ctx = mmContext
  visibleRadius = 350
  shape = "square"
})

let mapTransform = { rotate = 90 }
let markersTransform = {rotate = -90}

let visCone = {
  size = flex()
  minimapState = minimapState
  rendObj = ROBJ_MINIMAP_VIS_CONE
  behavior = Behaviors.Minimap
}

let mapRootAnims = [
  { prop=AnimProp.opacity, from=0, to=1, duration=0.15, play=true, easing=OutCubic }
  { prop=AnimProp.opacity, from=1, to=0, duration=0.25, playFadeOut=true, easing=OutCubic }
]

let function mouseTips() {
  let children = [
    mkTips(["LMB"], tipLmb)
    mouseNavTips
  ]
  return {
    flow = FLOW_HORIZONTAL
    gap = hdpx(10)
    children = children
  }
}
let titleHint = {
  padding = fsh(0.5)
  children = hintTextFunc(loc(title), DEFAULT_TEXT_COLOR)
  rendObj = ROBJ_WORLD_BLUR
  halign = ALIGN_CENTER
}

let tipsBlock = @(){
  size = [flex(), SIZE_TO_CONTENT]
  watch = [isGamepad, isAircraftRequest, isAircraftRequestActive]
  rendObj = ROBJ_WORLD_BLUR
  flow = FLOW_VERTICAL
  halign = ALIGN_CENTER
  padding = fsh(1)
  children = [
    isAircraftRequest.value && !isAircraftRequestActive.value ? artRequestTips : null
    changeShellTips
    isGamepad.value ? navGamepadHints : mouseTips
  ]
}

let framedMapBg = {
  rendObj = ROBJ_WORLD_BLUR
  color = Color(140,140,140,255)
  padding = fsh(1)
  behavior = Behaviors.ActivateActionSet
  actionSet = "BigMap"
}

let interactiveFrame = @() {
  rendObj = ROBJ_FRAME
  size = flex()
  borderWidth = hdpx(2)
  color = Color(180,160,10,130)

  // use frame since parent already has another hook
  behavior = Behaviors.ActivateActionSet
  actionSet = "StopInput"
}

let closeMapDesc = {
  action = @() closeRequest(),
  description = loc("Close"),
  inputPassive = true
}

let mapCoord = @(x) (x * 50) + 50

let mkStartPoint = {
  size = flex()
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  color = Color(90,90,90,50)
  fillColor = Color(0,0,0,0)
  rendObj = ROBJ_VECTOR_CANVAS
  lineWidth = hdpx(20)
  behavior = Behaviors.RtPropUpdate
  update = function() {
    let pos = minimapState.worldToMap(selectedStartWorldPos.value)
    let pos2 = minimapState.worldToMap(
      getAllowedLineEndPos(selectedStartWorldPos.value, currentMouseWorldPos.value, currentMaxLineLength.value))
    return {
      commands = [[VECTOR_LINE, mapCoord(pos.x), mapCoord(-pos.y), mapCoord(pos2.x), mapCoord(-pos2.y)]]
    }
  }
}

let mkArtilleryStartPos = @() { watch = selectedStartWorldPos }
  .__merge(selectedStartWorldPos.value ? mkStartPoint : {})

let function mkMapLayer(ctorDesc, paramsWatch) {
  return @() {
    watch = [paramsWatch, ctorDesc.watch]
    size = flex()
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    clipChildren = true
    eventPassThrough = true
    minimapState = minimapState
    transform = mapTransform
    behavior = Behaviors.Minimap
    children = ctorDesc.ctor(paramsWatch.value)
  }
}

let markersParams = Computed(@() {
  state = minimapState
  size = mapSize.value
  isCompassMinimap = false
  transform = markersTransform
  isInteractive = true
  showHero = true
})

let function getWorldPos(event, state) {
  let rect = event.targetRect
  let elemW = rect.r - rect.l
  let elemH = rect.b - rect.t
  let relX = (event.screenX - rect.l - elemW*0.5) * 2 / elemW
  let relY = (event.screenY - rect.t - elemH*0.5) * 2 / elemH
  return state.mapToWorld(relY, relX)
}

let function command(event, state) {
  if (event.button == 1) {
    if (selectedStartWorldPos.value)
      selectedStartWorldPos(null)
    else
      closeRequest()
  } else if (event.button == 0 || isGamepad.value)
    onSelect(getWorldPos(event, state))
}

showArtilleryMap.subscribe(function(show) {
  if (show) {
    sound_play("ui/radio_artillery")
    ecs.g_entity_mgr.sendEvent(get_controlled_hero(), CmdHeroSpeech({phrase="artStrikeOrder"}))
  }
})

let currentMinimapVisibleRadius = Watched(minimapState.getVisibleRadius())

let artilleryInactiveColor = Color(10, 10, 10, 100)
let artilleryActiveColor   = Color(84, 24, 24, 5)

let baseMap = @() {
  size = flex()
  watch = [currentShellType,
           currentMouseWorldPos,
           currentMinimapVisibleRadius,
           aircraftRequestTargetBiases,
           isArtRequest,
           isAircraftRequestActive]

  minimapState = minimapState
  rendObj = ROBJ_MINIMAP
  transform = mapTransform
  panMouseButton = mouseButtons.MMB
  behavior = hudIsInteractive.value
    ? [Behaviors.Minimap, Behaviors.Button, Behaviors.TrackMouse, Behaviors.MinimapInput]
    : [Behaviors.Minimap]
  color = Color(255, 255, 255, 200)

  halign = ALIGN_CENTER
  valign = ALIGN_CENTER

  clipChildren = true
  eventPassThrough = true
  stickCursor = false
  children = [visCone]
    .append(mkArtilleryStartPos)
    .append(isArtRequest.value ?
      mkAircraftRequestPreview(
        currentMouseWorldPos.value,
        currentShellType.value.radius,
        currentMinimapVisibleRadius.value
      ) : null)
    .extend(aircraftRequestTargetBiases.value
      .map(@(targetBias)
        mkAircraftRequestPreview(
          currentMouseWorldPos.value + targetBias,
          currentShellType.value.radius,
          currentMinimapVisibleRadius.value,
          isAircraftRequestActive.value ? artilleryActiveColor : artilleryInactiveColor
        )))

  onClick = @(e) command(e, minimapState)
  onMouseMove = @(e) currentMouseWorldPos(getWorldPos(e, minimapState))
}

let framedMap = @() framedMapBg.__merge({
  watch = [mapSize]
  size = mapSize.value
  children = [
    baseMap
  ]
    .extend(mmChildrenCtors.map(@(c) mkMapLayer(c, markersParams)))
    .append(interactiveFrame)
})

let mapBlock = @(){
  size = SIZE_TO_CONTENT
  flow = FLOW_VERTICAL
  halign = ALIGN_CENTER
  children = [
    titleHint
    framedMap
    tipsBlock
  ]
}

let function artilleryMap() {
  return {
    hplace = ALIGN_CENTER
    vplace = ALIGN_CENTER
    size = SIZE_TO_CONTENT
    watch = mapSize
    cursor = cursors.target
    sound = {
      attach = "ui/map_on"
      detach = "ui/map_off"
    }

    children = mapBlock

    animations = mapRootAnims
    hotkeys = [
      [ "Esc", closeMapDesc],
      [ "^{0}".subst(JB.B), closeMapDesc],
      [ "@HUD.BigMap", closeMapDesc ],
    ]
  }
}

ecs.register_es("artilllery_map_ui_es",
  {
    [CmdOpenArtilleryMap] = @(...) showArtilleryMap(true),
    [CmdCloseArtilleryMap] = @(...) showArtilleryMap(false)
  },
  {
    comps_rq = [
      ["human_weap__radioMode", ecs.TYPE_BOOL],
      ["squad_member__squad", ecs.TYPE_EID],
    ]
  },
  {tags = "gameClient"}
)

ecs.register_es("minimap_zoomed_es",
  {
    [EventMinimapZoomed] = @(...) currentMinimapVisibleRadius(minimapState.getVisibleRadius())
  },
  {
  },
  {tags = "gameClient"}
)

return {
  artilleryMap
  showArtilleryMap
}
