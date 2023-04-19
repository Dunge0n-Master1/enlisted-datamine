from "%enlSqGlob/ui_library.nut" import *

let { watchedHeroSquadEid } = require("%ui/hud/state/squad_members.nut")
let { simple_map_markers_Set, simple_map_markers_GetWatched } = require("%ui/hud/state/simple_map_markers.nut")

let iconSz = hdpxi(18)
let mkSvg = memoize(function(img) {
  return $"!ui/uiskin/{img}.svg:{iconSz}:{iconSz}:K"
})

let size = [iconSz, iconSz]
let mkMapMarker = function(eid, transform) {
  let data = freeze({
    eid
    minDistance = 0.7
    maxDistance = 2000
    clampToBorder = true
  })
  let marker = simple_map_markers_GetWatched(eid)
  return function() {
    local watch = [marker]
    let {image, visibleToSquad=null} = marker.value
    if (visibleToSquad != null)
      watch.append(watchedHeroSquadEid)
    let isVisible = visibleToSquad == null || visibleToSquad == watchedHeroSquadEid.value
    if (!isVisible)
      return {watch}
    return {
      data
      watch
      transform = {}
      children = {
        rendObj = ROBJ_IMAGE
        size
        color = Color(255, 255, 255)
        image = image ? Picture(mkSvg(image)) : null
        halign = ALIGN_CENTER
        valign = ALIGN_CENTER
        transform
      }
    }
  }
}
let memoizedMapByTransform = memoize(@(transform) mkMemoizedMapSet(@(eid) mkMapMarker(eid, transform)))
return {
  watch = simple_map_markers_Set
  ctor = @(p) memoizedMapByTransform(p?.transform)(simple_map_markers_Set.value).values()
}
