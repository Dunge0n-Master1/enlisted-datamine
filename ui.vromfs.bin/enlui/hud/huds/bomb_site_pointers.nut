from "%enlSqGlob/ui_library.nut" import *

let bombSites = require("%ui/hud/state/bombSites.nut")
let {DEFAULT_TEXT_COLOR} = require("%ui/hud/style.nut")
let {safeAreaHorPadding, safeAreaVerPadding} = require("%enlSqGlob/safeArea.nut")

let {localPlayerTeam} = require("%ui/hud/state/local_player.nut")

let bombSiteCtor = require("%ui/hud/components/bombSite.nut")

let visibleBombSiteEids = Watched({})
let visibleBombSiteEidsRecalc = keepref(Computed(@()
  bombSites.value.filter(@(b) b.active).map(@(_) true)))
visibleBombSiteEidsRecalc.subscribe(function(v) {
  if (!isEqual(v, visibleBombSiteEids.value))
    visibleBombSiteEids(v)
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

let pointer = @(key) {
  size = [fsh(4.8), fsh(4.8)]
  halign = ALIGN_CENTER
  transform = {}

  children = {
    rendObj = ROBJ_IMAGE
    image = Picture("!ui/skin#target_pointer.png")
    size = [fsh(4), fsh(4.8)]
    pos = [fsh(0.05), -fsh(0.34)]
    color = Color(200,200,200)
    key
  }
}

let mkBombSitePointer = @(bombSiteWatch, settings) function() {
  let res = { watch = bombSiteWatch }
  let bombSite = bombSiteWatch.value
  if (bombSite == null)
    return res

  return res.__update({
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER

    key = bombSite.eid
    data = {
      zoneEid = bombSite.eid
      yOffs = bombSite.iconOffsetY
    }
    transform = {}
    children = {
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      data = {
        eid = bombSite.eid
        priorityOffset = 10000
        opacityCenterRelativeDist = 0.05
        opacityCenterMinMult = 0.5
      }
      size = [fsh(4.8), fsh(4.8 + 2.0)]
      pos = [0, -fsh(1)]
      behavior = [Behaviors.DistToPriority, Behaviors.OverlayTransparency]
      children = [
        pointer(bombSite.eid)
        bombSiteCtor(bombSite, settings)
        distanceText(bombSite.eid)
      ]
    }

    animations = [
      { prop=AnimProp.opacity, from=0, to=1, duration=0.5, play=true, easing=InOutCubic}
      { prop=AnimProp.opacity, from=1, to=0, duration=0.3, playFadeOut=true, easing=InOutCubic}
    ]
  })
}

let function bombPointers() {
  let settings = {
    heroTeam = localPlayerTeam.value ?? -1
  }
  let children = visibleBombSiteEids.value.keys()
    .map(@(eid) mkBombSitePointer(Computed(@() bombSites.value?[eid]), settings))

  return {
    watch = [visibleBombSiteEids, localPlayerTeam, safeAreaHorPadding, safeAreaVerPadding]
    size = [sw(100)-safeAreaHorPadding.value*2 - fsh(6), sh(100) - safeAreaVerPadding.value*2-fsh(8)]
    behavior = Behaviors.ZonePointers
    halign = ALIGN_CENTER
    hplace = ALIGN_CENTER
    vplace = ALIGN_CENTER
    valign = ALIGN_CENTER
    children = children
  }
}

return bombPointers