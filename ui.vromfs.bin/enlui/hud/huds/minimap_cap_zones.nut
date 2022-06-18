from "%enlSqGlob/ui_library.nut" import *

let { capZones, visibleCurrentCapZonesEids } = require("%ui/hud/state/capZones.nut")
let { localPlayerTeam } = require("%ui/hud/state/local_player.nut")
let { watchedHeroEid } = require("%ui/hud/state/watched_hero.nut")
let { capzoneCtor } = require("%ui/hud/components/capzone.nut")

let iconSz= [hdpx(18).tointeger(), hdpx(16).tointeger()]

let defIcon = {rendObj = ROBJ_IMAGE image=Picture("!ui/skin#waypoint.svg:{0}:{1}:K".subst(iconSz[0],iconSz[1])) size = iconSz transform={}}
let capzoneSettings = {canHighlight=false, size=[fsh(2),fsh(2)], useBlurBack=false}


let minimapCapZone = @(zoneWatch, settings, transform) function() {
  let res = { watch = zoneWatch }
  let zone = zoneWatch.value
  if (zone == null)
    return res

  let heroTeam = settings.heroTeam
  let isDefendZone = (zone.attackTeam >= 0 && zone.attackTeam != heroTeam)
  let zoneIcon = (!isDefendZone && (zone?.title ?? "") == "" && (zone?.icon ?? "") == "")
    ? defIcon.__merge({key=zone.eid}) : null

  return res.__update({
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    key = zone.eid
    data = {
      zoneEid = zone.eid
      clampToBorder = true
    }
    transform = transform

    children = [
      capzoneCtor(zone, settings)
      zoneIcon
    ]
  })
}

let function minimapCaptureZones(eids, heroTeam, watchedHeroEidV, transform = {}) {
  let settings = capzoneSettings.__merge({ watchedHeroEidV = watchedHeroEidV, heroTeam = heroTeam })
  return eids.map(@(_, eid) minimapCapZone(Computed(@() capZones.value?[eid]), settings, transform))
    .values()
}

let watchState = Computed(@() {heroTeam = localPlayerTeam.value ?? -1, watchedHeroEid = watchedHeroEid.value, eids = visibleCurrentCapZonesEids.value})
return {
  watch = watchState
  ctor = @(o) minimapCaptureZones(watchState.value.eids, watchState.value.heroTeam, watchState.value.watchedHeroEid, o?.transform ?? {})
}