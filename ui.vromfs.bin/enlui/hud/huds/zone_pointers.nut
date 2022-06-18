from "%enlSqGlob/ui_library.nut" import *

let { capZones, visibleCurrentCapZonesEids } = require("%ui/hud/state/capZones.nut")
let { TEAM1_COLOR_FG, DEFAULT_TEXT_COLOR } = require("%ui/hud/style.nut")
let {safeAreaHorPadding, safeAreaVerPadding} = require("%enlSqGlob/safeArea.nut")


let {localPlayerTeam} = require("%ui/hud/state/local_player.nut")
let { watchedHeroEid } = require("%ui/hud/state/watched_hero.nut")

let { capzoneCtor } = require("%ui/hud/components/capzone.nut")
let capzoneSettings = {canHighlight=false}

let visibleZoneEids = Watched({})
let visibleZoneEidsRecalc = keepref(Computed(@()
  visibleCurrentCapZonesEids.value.filter(@(_, eid) capZones.value?[eid]?.heroInsideEid != watchedHeroEid.value)))
visibleZoneEidsRecalc.subscribe(function(v) {
  if (!isEqual(v, visibleZoneEids.value))
    visibleZoneEids(v)
})

let function distanceText(eid) {
  return {
    rendObj = ROBJ_TEXT
    color = DEFAULT_TEXT_COLOR
    hplace = ALIGN_CENTER
    halign = ALIGN_CENTER
    pos = [0, fsh(3.5)]
    size = [fsh(5), SIZE_TO_CONTENT]

    behavior = Behaviors.DistToEntity
    targetEid = eid
    minDistance = 3.0
  }
}

let pointerColor = Color(200,200,200)
let iconSz =[hdpx(32), hdpx(24)]

let defIcon = {
  rendObj = ROBJ_IMAGE
  size = iconSz
  image = Picture(":".concat("!ui/skin#waypoint.svg", iconSz[0].tointeger(), iconSz[1].tointeger()))
}
let mkZoneIcon = memoize(@(eid, title, icon, isDefendZone) (!isDefendZone && (title ?? "") == "" && (icon ?? "") == "")
    ? defIcon.__merge({ key = eid })
    : null
)

let mkPointer = @(capturingAndDefend) freeze({
  rendObj = ROBJ_IMAGE
  image = Picture("!ui/skin#target_pointer")
  size = [fsh(4), fsh(4.8)]
  pos = [fsh(0.05), -fsh(0.34)]
  color = pointerColor
  key = capturingAndDefend
  animations = capturingAndDefend ? [
      { prop=AnimProp.color, from=pointerColor, to=TEAM1_COLOR_FG, duration=0.6, play=true, loop=true, easing=CosineFull}
    ] : null
})

let pointerCapturingAndDefend = mkPointer(true)
let pointer = mkPointer(false)
let animations = [
  { prop=AnimProp.opacity, from=0, to=1, duration=0.5, play=true, easing=InOutCubic}
  { prop=AnimProp.opacity, from=1, to=0, duration=0.3, playFadeOut=true, easing=InOutCubic}
]

let mkZonePointer = @(zoneWatch, settings) function() {
  let res = { watch = zoneWatch }
  let zone = zoneWatch.value
  if (zone == null)
    return res
  let {title=null, icon=null, eid, attackTeam, curTeamCapturingZone, isCapturing} = zone
  let heroTeam = settings.heroTeam
  let isDefendZone = (attackTeam >= 0 && attackTeam != heroTeam)
  let showCapturing = isCapturing
    && (attackTeam == heroTeam || (curTeamCapturingZone != heroTeam && attackTeam!=heroTeam))
  let zoneIcon = mkZoneIcon(eid, title, icon, isDefendZone)
  let key = showCapturing ? $"i{eid}" : eid
  return {
    watch = zoneWatch
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    size = [0,0]

    key
    data = {
      zoneEid = eid
      yOffs = zone?.iconOffsetY ?? 0.0
    }
    transform = {}
    children = {
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      data = {
        eid
        priorityOffset = 10000
        opacityCenterRelativeDist = 0.05
        opacityCenterMinMult = 0.5
      }
      size = [fsh(4.8), fsh(4.8 + 2.0)]
      pos = [0, -fsh(1)]
      behavior = [Behaviors.DistToPriority, Behaviors.OverlayTransparency]
      children = [
        {
          size = [fsh(4.8), fsh(4.8)]
          halign = ALIGN_CENTER
          transform = {}
          children = showCapturing && isDefendZone ? pointerCapturingAndDefend : pointer
        }
        capzoneCtor(zone, settings)
        zoneIcon
        distanceText(eid)
      ]
    }

    animations
  }
}

let function zonePointers() {
  let settings = capzoneSettings.__merge({
    heroTeam = localPlayerTeam.value ?? -1
    watchedHeroEidV = watchedHeroEid.value
  })
  let children = visibleZoneEids.value.keys()
    .map(@(eid) mkZonePointer(Computed(@() capZones.value?[eid]), settings))

  return {
    watch = [visibleZoneEids, localPlayerTeam, watchedHeroEid, safeAreaHorPadding, safeAreaVerPadding]
    size = [sw(100)-safeAreaHorPadding.value*2 - fsh(6), sh(100) - safeAreaVerPadding.value*2-fsh(8)]
    behavior = Behaviors.ZonePointers
    halign = ALIGN_CENTER
    hplace = ALIGN_CENTER
    vplace = ALIGN_CENTER
    valign = ALIGN_CENTER
    children = children
  }
}

return zonePointers
