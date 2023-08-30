from "%enlSqGlob/ui_library.nut" import *

let { logerr } = require("dagor.debug")
let { landing_zones_GetWatched, landing_zones_Set } = require("%ui/hud/state/aircraft_respawn_landing_zones_state.nut")

let markerSize = hdpxi(21)
let iconSize = (markerSize/1.5).tointeger()

let getPicture = memoize(function getPicture(name) {
  if ((name ?? "") == "")
    return null

  local imagename = null
  if (name.indexof("/") != null) {
    imagename = name.endswith(".svg") ? "{0}:{1}:{1}:K".subst(name, iconSize) : name
  }

  if (!imagename) {
    logerr($"Image found {name}")
    return null
  }

  return Picture(imagename)
})

let darkback = freeze({
  size = [markerSize, markerSize]
  rendObj = ROBJ_IMAGE
  image = Picture("ui/uiskin/white_circle.svg:{0}:{0}:K".subst(markerSize))
  color = Color(0, 0, 0, 120)
})

let sizeIco = [iconSize, iconSize]

let ico = memoize(@(iconWatch) @(){
  rendObj = ROBJ_IMAGE
  size = sizeIco
  watch = iconWatch
  image = getPicture(iconWatch.value)
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  transform = {rotate = -90}
})

let size = [markerSize.tointeger(), markerSize.tointeger()]

let mkMarker = memoize(function(eid) {
  let zoneWatch = landing_zones_GetWatched(eid)
  let icoWatch = Computed(@() zoneWatch.value?.icon)
  let icon = ico(icoWatch)
  return freeze({
    data = { eid }
    transform = {}
    size
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    children = [
      darkback
      icon
    ]
  })
})

let memoizedMap = mkMemoizedMapSet(mkMarker)

return {
  watch = landing_zones_Set
  ctor = @(_) memoizedMap(landing_zones_Set.value).values()
}