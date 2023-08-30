from "%enlSqGlob/ui_library.nut" import *

let {logerr} = require("dagor.debug")
let { resupply_zones_GetWatched, heroActiveResupplyZonesEids } = require("%ui/hud/state/resupplyZones.nut")

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
    logerr("no image found")
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

let mkResupplyMarker = memoize(function(eid) {
  let zoneWatch = resupply_zones_GetWatched(eid)
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

return {
  watch = heroActiveResupplyZonesEids
  ctor = @(_) heroActiveResupplyZonesEids.value.keys().map(mkResupplyMarker)
}