from "%enlSqGlob/ui_library.nut" import *

let ATTRACT_PREFIX = "image_attract_"

let attraction = @(uid, angle, time, opacity = 1.0) [
  { trigger = $"{ATTRACT_PREFIX}{uid}", prop = AnimProp.rotate, from = 0, to = angle, duration = time, easing = Shake6 },
  { trigger = $"{ATTRACT_PREFIX}{uid}", prop = AnimProp.scale, from =[1.0, 1.0], to = [1.2, 1.2], duration = 0.3, easing = CosineFull },
  { trigger = $"{ATTRACT_PREFIX}{uid}", prop = AnimProp.opacity, from = 1, to = opacity, duration = 1.2 * time, easing = InCubic }
]

let transitions = [
  { prop = AnimProp.scale, duration = 0.5, easing = OutCubic }
  { prop = AnimProp.opacity, duration = 0.3, easing = OutCubic }
]

let create = @(sf, uid = 0, image = "", fallbackImage = null,
  size = flex(), clip = false, brightness = 1, opacity = 1, pivot = [0.5, 0.5],
  pos = null, children = null, tint = null) {
    size = size
    clipChildren = clip
    pos = pos
    children = {
      size = size
      rendObj = ROBJ_IMAGE
      image = image
      tint = tint
      children = children
      fallbackImage = fallbackImage
      brightness = brightness
      opacity = opacity
      transform = {
        pivot = pivot
        scale = sf & S_HOVER ? [1.1, 1.1] : [1.0, 1.0]
      }
      transitions = transitions
      animations = attraction(uid, 8, 1, opacity)
    }
    transform = {
      pivot = pivot
      scale = sf & S_HOVER ? [1.1, 1.1] : [1.0, 1.0]
    }
    transitions = transitions
    animations = attraction(uid, 2, 1.2, 1)
  }

return {
  create = kwarg(create)
  attraction
  transitions
  attractToImage = @(uid) anim_start($"{ATTRACT_PREFIX}{uid}")
}
