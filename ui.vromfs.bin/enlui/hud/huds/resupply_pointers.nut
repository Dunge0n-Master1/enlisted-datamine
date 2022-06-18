from "%enlSqGlob/ui_library.nut" import *

let { sub_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let { resupplyZones, heroActiveResupplyZonesEids } = require("%ui/hud/state/resupplyZones.nut")
let {DEFAULT_TEXT_COLOR} = require("%ui/hud/style.nut")
let {safeAreaVerPadding, safeAreaHorPadding} = require("%enlSqGlob/safeArea.nut")


let {localPlayerTeam} = require("%ui/hud/state/local_player.nut")
let { watchedHeroEid } = require("%ui/hud/state/watched_hero.nut")

let { resupplyZoneCtor } = require("%ui/hud/components/resupplyZone.nut")

let function distanceText(eid, radius) {
  return {
    rendObj = ROBJ_TEXT
    color = DEFAULT_TEXT_COLOR
    hplace = ALIGN_CENTER
    halign = ALIGN_CENTER
    pos = [0, fsh(3.5)]
    size = [fsh(5), fontH(100)]

    behavior = Behaviors.DistToSphere
    targetEid = eid
    radius
    minDistance = 0
  }.__update(sub_txt)
}

let pointerColor = Color(200,200,200)

let mkZonePointer = @(zoneWatch) function() {
  let res = { watch = zoneWatch }
  let zone = zoneWatch.value
  if (zone == null)
    return res

  return res.__update({
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    size = [0,0]

    key = zone.eid
    data = {
      zoneEid = zone.eid
    }
    transform = {}
    children = {
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      data = {
        eid = zone.eid
        priorityOffset = 10000
      }
      size = flex()
      pos = [0, -fsh(1)]
      behavior = [Behaviors.DistToPriority, Behaviors.OverlayTransparency]
      children = [
        {
          size = [fsh(4.8), fsh(4.8)]
          halign = ALIGN_CENTER
          transform = {}

          children = {
            rendObj = ROBJ_IMAGE
            image = Picture("!ui/skin#target_pointer")
            size = [fsh(4), fsh(4.8)]
            pos = [fsh(0.0), -fsh(0.35)]
            color = pointerColor
            key = zone.eid
            animations = []
          }
        }
        resupplyZoneCtor(zone)
        distanceText(zone.eid, zone.radius)
      ]
    }

    animations = [
      { prop=AnimProp.opacity, from=0, to=1, duration=0.5, play=true, easing=InOutCubic}
      { prop=AnimProp.opacity, from=1, to=0, duration=0.3, playFadeOut=true, easing=InOutCubic}
    ]
  })
}

let function resupplyPointers() {
  let children = heroActiveResupplyZonesEids.value
    .map(@(eid) mkZonePointer(Computed(@() resupplyZones.value?[eid])))

  return {
    watch = [heroActiveResupplyZonesEids, localPlayerTeam, watchedHeroEid, safeAreaHorPadding, safeAreaVerPadding]
    size = [sw(100)-safeAreaHorPadding.value*2 - fsh(6), sh(100) - safeAreaVerPadding.value*2-fsh(8)]
    behavior = Behaviors.ZonePointers
    halign = ALIGN_CENTER
    hplace = ALIGN_CENTER
    vplace = ALIGN_CENTER
    valign = ALIGN_CENTER
    children = children
  }
}

return resupplyPointers
