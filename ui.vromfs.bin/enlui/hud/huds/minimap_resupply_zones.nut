from "%enlSqGlob/ui_library.nut" import *

let {logerr} = require("dagor.debug")
let { resupplyZones, heroActiveResupplyZonesEids } = require("%ui/hud/state/resupplyZones.nut")
let { endswith } = require("string")

let markerSize = fsh(2)
let iconSize = markerSize/1.5

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

let darkback = memoize(@(height) {
  size = [height, height]
  rendObj = ROBJ_IMAGE
  image = Picture("ui/uiskin/white_circle.svg:{0}:{0}:K".subst(height.tointeger()))
  color = Color(0, 0, 0, 120)
})

let function mkResupplyMarker(eid, _options = null) {
  let zone = resupplyZones.value?[eid]
  let icon = {
    rendObj = ROBJ_IMAGE
    size = [iconSize.tointeger(), iconSize.tointeger()]
    image = getPicture(zone?.icon, iconSize)
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    transform = {rotate = -90}
  }

  return {
    data = { eid = eid }
    transform = {}
    size = [markerSize.tointeger(), markerSize.tointeger()]
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    children = [
      darkback(markerSize)
      icon
    ]
  }
}

return {
  watch = heroActiveResupplyZonesEids
  ctor = @(p) heroActiveResupplyZonesEids.value.reduce(@(res, eid) res.append(mkResupplyMarker(eid, p)), [])
}