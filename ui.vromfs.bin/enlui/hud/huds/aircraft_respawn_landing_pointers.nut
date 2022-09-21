from "%enlSqGlob/ui_library.nut" import *

let { sub_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let { landing_zones_GetWatched, landing_zones_Set } = require("%ui/hud/state/aircraft_respawn_landing_zones_state.nut")
let { DEFAULT_TEXT_COLOR } = require("%ui/hud/style.nut")
let { safeAreaVerPadding, safeAreaHorPadding } = require("%enlSqGlob/safeArea.nut")
let { logerr } = require("dagor.debug")

let ZONE_ICON_COLOR = Color(0,0,0,255)

let baseZoneAppearAnims = [
  { prop=AnimProp.scale, from=[2.5,2.5], to=[1,1], duration=0.4, play=true }
  { prop=AnimProp.opacity, from=0.0, to=1.0, duration=0.2, play=true }
]

let transformCenterPivot = {pivot = [0.5, 0.5]}

let animActive = [
  { prop=AnimProp.scale, from=[7.5,7.5], to=[1,1], duration=0.3, play=true }
  { prop=AnimProp.translate, from=[0,sh(20)], to=[0,0], duration=0.4, play=true, easing=OutQuart }
  { prop=AnimProp.opacity, from=0.0, to=1.0, duration=0.25, play=true }
]

let getPicture = memoize(function getPicture(name, iconSz) {
  if ((name ?? "") == "")
    return null

  local imagename = null
  if (name.indexof("/") != null) {
    imagename = name.endswith(".svg") ? "{0}:{1}:{1}:K".subst(name, iconSz.tointeger()) : name
  }

  if (!imagename) {
    logerr($"Can't find image with name {name}")
    return null
  }

  return Picture(imagename)
})

let zSize = [fsh(3), fsh(3)]
let zIconSz = [zSize[0] / 1.5, zSize[1] / 1.5]
let zMargin = (zSize[0] / 1.5).tointeger()

let blur_back = {
  size = zSize
  rendObj = ROBJ_MASK
  image = Picture("ui/skin#white_circle.svg:{0}:{0}:K".subst(zSize[1].tointeger()))
  children = [{ size = flex() rendObj = ROBJ_WORLD_BLUR color = Color(220, 220, 220, 255) }]
}

let mkZoneIcon = memoize(function(icon) {
  let zoneIconPic = getPicture(icon, zIconSz[0])
  if (zoneIconPic == null)
    return null

  return {
    rendObj = ROBJ_IMAGE
    size = zIconSz
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    color = ZONE_ICON_COLOR
    transform = transformCenterPivot
    image = zoneIconPic
    animations = baseZoneAppearAnims
  }
})
let zTransitions = [{ prop=AnimProp.translate, duration=0.2 }]

let zoneCtor = @(eid, icon) {
  size = zSize
  margin = [0, zMargin]
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  key = eid
  zoneData = { zoneEid = eid }
  children = {
    flow = FLOW_VERTICAL
    halign = ALIGN_CENTER
    children = {
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      size = zSize
      children = [
        blur_back
        mkZoneIcon(icon)
      ]
    }
    transitions = zTransitions
    animations = animActive
  }
}

let function distanceText(eid, radius) {
  return {
    rendObj = ROBJ_TEXT
    color = DEFAULT_TEXT_COLOR
    hplace = ALIGN_CENTER
    halign = ALIGN_CENTER
    pos = [0, fsh(3.5)]
    size = [fsh(5), fontH(100)]

    behavior = Behaviors.DistToSphere
    targetEid = eid
    radius
    minDistance = 0
  }.__update(sub_txt)
}

let pointerColor = Color(200,200,200)
let animations = [
  { prop=AnimProp.opacity, from=0, to=1, duration=0.5, play=true, easing=InOutCubic }
  { prop=AnimProp.opacity, from=1, to=0, duration=0.3, playFadeOut=true, easing=InOutCubic }
]
let pic = Picture("!ui/skin#target_pointer.png")

let mkZonePointer = memoize(function(eid) {
  let state = landing_zones_GetWatched(eid)

  return function(){
    let {radius, icon} = state.value
    return {
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      size = [0,0]

      key = eid
      data = {
        zoneEid = eid
      }
      transform = {}
      children = {
        halign = ALIGN_CENTER
        valign = ALIGN_CENTER
        data = {
          eid = eid
          priorityOffset = 10000
        }
        size = flex()
        pos = [0, -fsh(1)]
        behavior = [Behaviors.DistToPriority, Behaviors.OverlayTransparency]
        children = [
          {
            size = [fsh(4.8), fsh(4.8)]
            halign = ALIGN_CENTER
            transform = {}

            children = {
              rendObj = ROBJ_IMAGE
              image = pic
              size = [fsh(4), fsh(4.8)]
              pos = [fsh(0.0), -fsh(0.35)]
              color = pointerColor
            }
          }
          zoneCtor(eid, icon)
          distanceText(eid, radius)
        ]
      }

      animations
    }
  }
})

let memoizedMap = mkMemoizedMapSet(mkZonePointer)

let function pointers() {
  return {
    watch = [landing_zones_Set, safeAreaHorPadding, safeAreaVerPadding]
    size = [sw(100)-safeAreaHorPadding.value*2 - fsh(6), sh(100) - safeAreaVerPadding.value*2-fsh(8)]
    behavior = Behaviors.ZonePointers
    halign = ALIGN_CENTER
    hplace = ALIGN_CENTER
    vplace = ALIGN_CENTER
    valign = ALIGN_CENTER
    children = memoizedMap(landing_zones_Set.value).values()
  }
}

return pointers
