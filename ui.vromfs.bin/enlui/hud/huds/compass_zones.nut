from "%enlSqGlob/ui_library.nut" import *

let { localPlayerTeam } = require("%ui/hud/state/local_player.nut")
let { watchedHeroEid } = require("%ui/hud/state/watched_hero.nut")
let { capzoneCtor } = require("%ui/hud/components/capzone.nut")
let { capZones, visibleCurrentCapZonesEids } = require("%ui/hud/state/capZones.nut")

let zoneCompSize = [fsh(1.8), fsh(1.8)]

let iconSz= zoneCompSize.map(@(v) v.tointeger())
let defIcon = {rendObj = ROBJ_IMAGE image=Picture("!ui/skin#waypoint.svg:{0}:{1}:K".subst(iconSz[0],iconSz[1])) size = iconSz transform={}}

let zoneComp = function(eid) {
  return function() {
    let zoneWatch = Computed(@() capZones.value?[eid])
    let zone = zoneWatch.value
    let watch = [watchedHeroEid, zoneWatch]
    if (zone == null)
      return {watch}

    let heroTeam = localPlayerTeam.value ?? -1
    let settings = { watchedHeroEidV = watchedHeroEid.value, heroTeam, canHighlight=false, size=zoneCompSize, useBlurBack=true}
    let isDefendZone = (zone.attackTeam >= 0 && zone.attackTeam != heroTeam)
    let zoneIcon = (!isDefendZone && (zone?.title ?? "") == "" && (zone?.icon ?? "") == "")
      ? defIcon.__merge({key=eid}) : null
    return {
      size = zoneCompSize
      watch
      children = [
        capzoneCtor(zone, settings)
        zoneIcon
      ]
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      transform = {}
      pos = [0, fsh(2)]
      data = {eid, clampToBorder = false}
      behaviors = []
    }
  }
}
return {
  compassZoneCtor = @() visibleCurrentCapZonesEids.value.filter(@(v) v).keys().map(zoneComp)
  compassZoneWatch = visibleCurrentCapZonesEids
}