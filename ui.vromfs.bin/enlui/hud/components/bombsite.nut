from "%enlSqGlob/ui_library.nut" import *

let {logerr} = require("dagor.debug")
let { endswith } = require("string")

let appearAnims = [
  { prop=AnimProp.scale, from=[2.5,2.5], to=[1,1], duration=0.4, play=true}
  { prop=AnimProp.opacity, from=0.0, to=1.0, duration=0.2, play=true}
]

let transformCenterPivot = {pivot = [0.5, 0.5]}

let function getPicture(name, iconSz) {
  if ((name ?? "") == "")
    return null

  let imagename = endswith(name,".svg") ? "{0}:{1}:{1}:K".subst(name, iconSz.tointeger()) : name

  if (!imagename) {
    logerr("no image found")
    return null
  }

  return Picture(imagename)
}

let blurback = @(height) {
  size = [height, height]
  rendObj = ROBJ_MASK
  image = Picture("ui/uiskin/white_circle.svg:{0}:{0}:K".subst(height.tointeger()))
  children = [{size = flex() rendObj = ROBJ_WORLD_BLUR color = Color(220, 220, 220, 255)}]
}

let function bombSiteCtor(bomb_site, params={}) {
  if (bomb_site == null || !(bomb_site?.active))
    return null

  let size = params?.size ?? [fsh(3), fsh(3)]

  let iconSz = [size[0] / 1.5, size[1] / 1.5]
  let blur_back = blurback(size[1])

  local icon = null
  let iconPic = getPicture(bomb_site?.icon, iconSz[0])
  if (iconPic) {
    icon = {
      rendObj = ROBJ_IMAGE
      size = iconSz
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      transform = transformCenterPivot
      image = iconPic
      animations = appearAnims
    }
  }

  let innerZone = {
    halign = ALIGN_CENTER
    vplace = ALIGN_CENTER
    children = [
      {
        halign = ALIGN_CENTER
        valign = ALIGN_CENTER
        size
        children = [
          blur_back
          icon
        ]
      }
    ]
    transform = {}
    transitions = [{ prop=AnimProp.translate, duration=0.2 }]
  }

  return {
    size
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    children = [ innerZone ]
  }
}

return bombSiteCtor