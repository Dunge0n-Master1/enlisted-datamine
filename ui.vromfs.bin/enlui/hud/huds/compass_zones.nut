from "%enlSqGlob/ui_library.nut" import *

let { watchedTeam } = require("%ui/hud/state/watched_hero.nut")
let { capzoneWidget } = require("%ui/hud/components/capzone.nut")
let { getZoneWatch, visibleCurrentCapZonesEids } = require("%ui/hud/state/capZones.nut")

let zoneCompSize = [fsh(1.8), fsh(1.8)]

let iconSz= zoneCompSize.map(@(v) v.tointeger())
let defIcon = {rendObj = ROBJ_IMAGE image=Picture("!ui/skin#waypoint.svg:{0}:{1}:K".subst(iconSz[0],iconSz[1])) size = iconSz transform={}}

let defTransform = freeze({})
let settings = { canHighlight=false, size=zoneCompSize, useBlurBack=true}

let zoneComp = memoize(function(eid) {
  let zoneWatch = getZoneWatch(eid)
  let data = {eid, clampToBorder = false}
  let pos = [0, fsh(2)]
  let capZ = capzoneWidget(eid, settings)

  return function() {
    let zone = zoneWatch.value
    let watch = [watchedTeam, zoneWatch]
    if (zone == null)
      return {watch}

    let heroTeam = watchedTeam.value ?? -1
    let isDefendZone = (zone.attackTeam >= 0 && zone.attackTeam != heroTeam)
    let zoneIcon = (!isDefendZone && (zone?.title ?? "") == "" && (zone?.icon ?? "") == "")
      ? defIcon.__merge({key=eid}) : null

    return {
      size = zoneCompSize
      watch
      children = [
        capZ
        zoneIcon
      ]
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      transform = defTransform
      pos
      data
    }
  }
})

return {
  compassZoneCtor = @() visibleCurrentCapZonesEids.value.filter(@(v) v).keys().map(zoneComp)
  compassZoneWatch = visibleCurrentCapZonesEids
}