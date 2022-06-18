from "%enlSqGlob/ui_library.nut" import *

let { logerr } = require("dagor.debug")
let { endswith } = require("string")

let ZONE_ICON_COLOR = Color(200,200,200,200)

let baseZoneAppearAnims = [
  { prop=AnimProp.scale, from=[2.5,2.5], to=[1,1], duration=0.4, play=true}
  { prop=AnimProp.opacity, from=0.0, to=1.0, duration=0.2, play=true}
]

let transformCenterPivot = {pivot = [0.5, 0.5]}

let animActive = [
  { prop=AnimProp.scale, from=[7.5,7.5], to=[1,1], duration=0.3, play=true}
  { prop=AnimProp.translate, from=[0,sh(20)], to=[0,0], duration=0.4, play=true, easing=OutQuart}
  { prop=AnimProp.opacity, from=0.0, to=1.0, duration=0.25, play=true}
]

let getPicture = memoize(function getPicture(name, iconSz) {
  if ((name ?? "") == "")
    return null

  local imagename = null
  if (name.indexof("/") != null) {
    imagename = endswith(name,".svg") ? "{0}:{1}:{1}:K".subst(name, iconSz.tointeger()) : name
  }

  if (!imagename) {
    logerr("no image found")
    return null
  }

  return Picture(imagename)
}, @(name, iconSz) $"{name}{iconSz}")

let capzonBlurback = memoize(@(height) {
    size = [height, height]
    rendObj = ROBJ_MASK
    image = Picture("ui/skin#white_circle.svg:{0}:{0}:K".subst(height.tointeger()))
    children = [{size = flex() rendObj = ROBJ_WORLD_BLUR color = Color(220, 220, 220, 255)}]
  })

let capzonDarkback = memoize(@(height) {
    size = [height, height]
    rendObj = ROBJ_IMAGE
    image = Picture("ui/skin#white_circle.svg:{0}:{0}:K".subst(height.tointeger()))
    color = Color(0, 0, 0, 120)
  })

let function resupplyZoneCtor(zoneData, params={}) {
  if (zoneData == null)
    return { ui_order = zoneData?.ui_order ?? 0 }

  let size = params?.size ?? [fsh(3), fsh(3)]
  let animAppear = params?.animAppear

  let iconSz = [size[0] / 1.5, size[1] / 1.5]
  let blur_back = ("customBack" in params) ? params.customBack(size[1])
    : (params?.useBlurBack ?? true) ? capzonBlurback(size[1])
    : capzonDarkback(size[1])

  local zoneIcon = null

  let zoneIconPic = getPicture(zoneData?.icon, iconSz[0])
  if (zoneIconPic) {
    zoneIcon = {
      rendObj = ROBJ_IMAGE
      size = iconSz
      halign  = ALIGN_CENTER
      valign = ALIGN_CENTER
      color = ZONE_ICON_COLOR
      transform = transformCenterPivot
      image = zoneIconPic
      animations = animAppear ?? baseZoneAppearAnims
    }
  }

  let margin = params?.margin ?? (size[0] / 1.5).tointeger()
  let innerZone = {
    flow = FLOW_VERTICAL
    halign = ALIGN_CENTER
    children = [
      {
        halign  = ALIGN_CENTER
        valign = ALIGN_CENTER
        size = size
        children = [
          blur_back
          zoneData?.active ? zoneIcon : null
        ]
      }
    ]
    transitions = [{ prop=AnimProp.translate, duration=0.2 }]
  }

  let zone = {
    size = size
    margin = [0, margin]
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    key = zoneData.eid

    zoneData = { zoneEid = zoneData.eid }
    children = [ innerZone ]

    ui_order = zoneData.ui_order
  }

  let zone_animations = innerZone?.animations ?? []
  if (zoneData?.active)
    zone_animations.extend(params?.animActive ?? animActive)
  innerZone.animations <- zone_animations

  return zone
}

return {
  resupplyZoneCtor = resupplyZoneCtor
}
