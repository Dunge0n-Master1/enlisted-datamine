import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *
from "minimap" import MinimapState

let { mmChildrenCtorsGeneration, getMmChildrenCtors } = require("%ui/hud/huds/minimap/minimap_state.nut")
let mmContext = require("%ui/hud/huds/minimap/minimap_ctx.nut")
let {EventMortarCanceled} = require("dasevents")
let {get_controlled_hero} = require("%dngscripts/common_queries.nut")

let mortarMarkers = Watched({})
let mortarTarget = Watched(null)
ecs.register_es("mortar_target_ui_es",
  {
    function onInit(eid, _comp){
      mortarTarget(eid)
    },
    function onDestroy(){
      mortarTarget(null)
    }
  },
  {comps_rq = ["mortar_target", "transform"]}
)

ecs.register_es("mortar_markers_ui_es",
  {
    function onInit(eid, comp){
      mortarMarkers.mutate(@(v) v[eid] <- comp["type"])
    },
    function onDestroy(eid, _comp){
      if (eid in mortarMarkers.value) {
        mortarMarkers.mutate(@(v) delete v[eid])
      }
    }
  },
  {
    comps_ro = [["type", ecs.TYPE_STRING]],
    comps_rq = ["mortar_marker", "transform"]
  }
)

let mortarTargetMapIconSize = [sh(3.0), sh(3.0)]
let mortarMarkerMapIconSize = [sh(1.5), sh(1.5)]

let mortarImages = {
  mortarTarget = Picture("!ui/skin#sniper_rifle.svg:{0}:{1}:K".subst(mortarTargetMapIconSize[0], mortarTargetMapIconSize[1]))
  mortarKill = Picture("!ui/skin#skull.svg:{0}:{1}:K".subst(mortarTargetMapIconSize[0], mortarTargetMapIconSize[1]))
  mortarShellExplode = Picture("!ui/skin#launcher.svg:{0}:{1}:K".subst(mortarTargetMapIconSize[0], mortarTargetMapIconSize[1]))
}
let function mkMortarMarker(eid, image=null, _size = mortarTargetMapIconSize){
  return {
    image = image ?? mortarImages.mortarTarget
    size = mortarTargetMapIconSize
    valign = ALIGN_CENTER
    transform = {}
    rendObj = ROBJ_IMAGE
    data = {
      eid = eid
      clampToBorder = true
    }
  }
}

let function mkMortarMarkers(targets){
  let children = []
  foreach (eid, typ in targets){
    let image = mortarImages?[typ]
    children.append(mkMortarMarker(eid, image, mortarMarkerMapIconSize))
  }
  return children
}

let size  = [sh(30), sh(30)]
let transform = {rotate = 0}

let function closeMortarMap(){
  ecs.g_entity_mgr.sendEvent(get_controlled_hero(), EventMortarCanceled())
}

let minimapState = MinimapState({
  ctx = mmContext
  visibleRadius = 200
  shape = "circle"
  isViewUp = true
})

let visCone = {
  size = flex()
  minimapState = minimapState
  rendObj = ROBJ_MINIMAP_VIS_CONE
  behavior = Behaviors.Minimap
  transform = transform
}

let blurBack = {
  rendObj  = ROBJ_MASK
  image = Picture("ui/uiskin/white_circle.svg:{0}:{0}:K".subst(size[0].tointeger()))
  children = {rendObj = ROBJ_WORLD_BLUR, size = size}
}

let commonLayerParams = {
  state = minimapState
  size = size
  transform = transform
  showHero = false
  isInteractive=false
}

let mkLayer = @(ctorWatch, params) @(){
  watch = ctorWatch.watch
  size = flex()
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  clipChildren = false
  minimapState = minimapState
  transform = transform
  behavior = Behaviors.Minimap
  children = ctorWatch.ctor(params)
}

let function mortarMap() {
  let function map() {
    let children = [
      visCone
    ]
    children.extend(getMmChildrenCtors().map(@(c) mkLayer(c, commonLayerParams)))
    children.extend(mkMortarMarkers(mortarMarkers.value))
    children.append(mkMortarMarker(mortarTarget.value))
    return {
      size = size
      minimapState = minimapState
      rendObj = ROBJ_MINIMAP
      dirRotate = true
      transform = {}
      behavior = [Behaviors.Minimap]
      color = Color(255, 255, 255, 200)
      children = children
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
    }
  }
  return {
    size = size
    children = [
      blurBack,
      map,
      {
        color = Color(120,80,80,130)
        fillColor = Color(0,0,0,0)
        rendObj=ROBJ_VECTOR_CANVAS
        size=size
        commands = [[VECTOR_WIDTH, hdpx(4)], [VECTOR_ELLIPSE, 50, 50, 49.5, 49.5]]
      }
    ]
    watch = [mmChildrenCtorsGeneration, mortarTarget, mortarMarkers]
  }
}

return {
  mortarMap = mortarMap
  closeMortarMap = closeMortarMap
  mortarTarget = mortarTarget
  mortarMarkers = mortarMarkers
}
