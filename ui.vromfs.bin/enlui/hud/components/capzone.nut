from "%enlSqGlob/ui_library.nut" import *

let {h2_txt} = require("%enlSqGlob/ui/fonts_style.nut")
let { localPlayerTeam } = require("%ui/hud/state/local_player.nut")
let { watchedHeroEid } = require("%ui/hud/state/watched_hero.nut")
let { capZones } = require("%ui/hud/state/capZones.nut")
let capzoneProgress = require("capzoneProgress.nut")
let mkObjectiveProgress = require("mkObjectiveProgress.nut")
let { mkObjectiveIcon } = require("mkObjectiveIcon.nut")

/*
TODO: this is not optimal as we rebuild complicate ui of zone widget on ANY zone changes
better to accpet state to watch on and map zones state to zone states
*/

let ZONE_TEXT_COLOR = Color(80,80,80,20)
let ZONE_BG_COLOR = Color(60, 60, 60, 60)
let ZONE_LOCK_COLOR = Color(160, 160, 160, 160)
let ZONE_LOCK_ENEMY_PRESENT_COLOR = Color(160, 160, 160, 160)

let zoneLockIconSize = [hdpx(21), hdpx(21)]

let baseZoneAppearAnims = [
  { prop=AnimProp.scale, from=[2.5,2.5], to=[1,1], duration=0.4, play=true}
  { prop=AnimProp.opacity, from=0.0, to=1.0, duration=0.2, play=true}
]

let highlightScale = [2.6,2.6]

let animActive = [
  { prop=AnimProp.scale, from=[7.5,7.5], to=[1,1], duration=0.3, play=true}
  { prop=AnimProp.translate, from=[0,sh(20)], to=[0,0], duration=0.4, play=true, easing=OutQuart}
  { prop=AnimProp.opacity, from=0.0, to=1.0, duration=0.25, play=true}
]

let capzonBlurback = memoize(@(height) {
    size = [height, height]
    rendObj = ROBJ_MASK
    image = Picture("ui/skin#white_circle.svg:{0}:{0}:K".subst(height.tointeger()))
    children = [{size = flex() rendObj = ROBJ_WORLD_BLUR color = Color(220, 220, 220, 255)}]
  })

let capzonDarkback = memoize(@(height) {
    size = [height, height]
    rendObj = ROBJ_IMAGE
    image = Picture("ui/skin#white_circle.svg:{0}:{0}:K".subst(height.tointeger()))
    color = Color(0, 0, 0, 120)
  })

let capzoneHasEnemies = @(zone)
  zone?.presenceTeamCount.findindex(@(count, team) team.tointeger() != localPlayerTeam.value && count > 0) != null

let enemyPresenceAnimation = [
  { prop=AnimProp.opacity, from=0.1, to=1.0, duration=1.0, play=true, loop=true, easing=CosineFull }
]


let function capzoneCtor(zoneData, params={}) {
  let { cache = null, animAppear = null, canHighlight=true} = params
  let { eid, active, wasActive, alwaysShow, locked, heroInsideEid, caption, ui_order, ownTeamIcon } = zoneData

  if (cache != null && eid in cache)
    return cache[eid]

  if (zoneData == null || (!wasActive && !alwaysShow))
    return { ui_order = zoneData?.ui_order ?? 0 }
  let size = params?.size ?? [fsh(3), fsh(3)]
  let highlight = canHighlight && active
    && (heroInsideEid != INVALID_ENTITY_ID && heroInsideEid == params?.watchedHeroEidV)

  let highlightedSize = highlight ? [size[0] * highlightScale[0], size[1] * highlightScale[1]] : size
  let iconSz = [highlightedSize[0] / 1.5, highlightedSize[1] / 1.5]
  let blur_back = ("customBack" in params) ? params.customBack(highlightedSize[1])
    : (params?.useBlurBack ?? true) ? capzonBlurback(highlightedSize[1])
    : capzonDarkback(highlightedSize[1])

  let heroTeam = params?.heroTeam ?? INVALID_ENTITY_ID
  let zoneProgress = active ? mkObjectiveProgress(zoneData, heroTeam, highlightedSize) : null
  if (active && ownTeamIcon != null) {
    zoneProgress.__update({
      image = Picture("{0}:{1}:{1}:K".subst(zoneData.ownTeamIcon, highlightedSize[0].tointeger()))
      color = ZONE_BG_COLOR
    })
  }

  let margin = params?.margin ?? (size[0] / 1.5).tointeger()
  let total = (params?.total ?? 0).tofloat()
  let idx = (params?.idx ?? 0).tofloat()
  let hlCenteredOffset = [((total - 1.0) * 0.5 - idx) * (size[0] + margin), size[1]]
  let isEnemyOnLockedZone = locked && capzoneHasEnemies(zoneData)
  let innerZone = {
    flow = FLOW_VERTICAL
    halign = ALIGN_CENTER
    vplace = ALIGN_TOP
    gap = hdpx(20)
    children = [
      {
        halign  = ALIGN_CENTER
        valign = ALIGN_CENTER
        size = highlightedSize
        children = [
          blur_back
          zoneProgress
          !locked ? mkObjectiveIcon(zoneData, iconSz, params.__merge({baseZoneAppearAnims})) : {
            rendObj = ROBJ_IMAGE
            image = Picture("ui/skin#point_lock.svg:{0}:{0}".subst(zoneLockIconSize[1]))
            halign = ALIGN_CENTER
            valign = ALIGN_CENTER
            size = highlight ? [zoneLockIconSize[0] * highlightScale[0], zoneLockIconSize[1] * highlightScale[1]] : zoneLockIconSize
            transform = {pivot = [0.5, 0.5]}
            color = isEnemyOnLockedZone ? ZONE_LOCK_ENEMY_PRESENT_COLOR : ZONE_LOCK_COLOR
            animations = isEnemyOnLockedZone ? enemyPresenceAnimation : null
            key = zoneData?.presenceTeamCount
            fValue = 0
          }
          !highlight ? null : {
            halign = ALIGN_CENTER
            animations = animAppear ?? baseZoneAppearAnims
            children = @() capzoneProgress(iconSz)
          }
        ]
      }
      !highlight ? null : {
        rendObj = ROBJ_TEXT
        //DEBUG: uncomment next line to see actual units count in capturing zone name:
        //text = " ".concat(captureCount.alliesCount, loc(caption), captureCount.enemiesCount)
        text = loc(caption)
        color = ZONE_TEXT_COLOR
        halign  = ALIGN_CENTER
        valign = ALIGN_BOTTOM
        animations = animAppear ?? baseZoneAppearAnims
      }.__update(h2_txt)
    ]
    transform = {
      translate = highlight ? hlCenteredOffset : [0, 0]
    }
    transitions = [{ prop=AnimProp.translate, duration=0.2 }]
  }

  let zone = {
    size
    margin = [0, margin]
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    key = eid

    zoneData = { zoneEid = eid }
    children = [ innerZone ]

    ui_order
  }

  let zone_animations = innerZone?.animations ?? []
  if (active) {
    zone_animations.extend(params?.animActive ?? animActive)
  }
  innerZone.animations <- zone_animations

  if (cache != null)
    cache[eid] <- zone

  return zone
}

let zoneCache = {}
let function capzoneWidget(zoneEid, params={}) {
  let zoneWatch = Computed(@() capZones.value?[zoneEid])
  return @() capzoneCtor(zoneWatch.value, params.__merge({ watchedHeroEidV = watchedHeroEid.value, heroTeam = localPlayerTeam.value }))
    .__update({ watch = [zoneWatch, watchedHeroEid, localPlayerTeam] cache = zoneCache})
}

let capzoneGap = { size = [0, 0] }

return {
  capzoneCtor
  capzoneWidget
  capzoneGap
}
