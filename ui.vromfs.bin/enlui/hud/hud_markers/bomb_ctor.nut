import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let {makeArrow} = require("%ui/hud/hud_markers/components/hud_markers_components.nut")
let {active_bombs_Set, active_bombs_GetWatched} = require("%ui/hud/state/active_bombs.nut")
let { watchedTeam, watchedHeroEid } = require("%ui/hud/state/watched_hero.nut")
let {isFriendlyFireMode} = require("%enlSqGlob/missionType.nut")
let { getTeam } = require("%ui/hud/state/get_team.nut")
let is_teams_friendly = require("%enlSqGlob/is_teams_friendly.nut")


let colorRedBlink = Color(255, 141, 29, 220)
let colorRed      = Color(255,  40, 30, 220)

let bombAnim = [{
  prop = AnimProp.color, from = colorRed, to = colorRedBlink,
  duration = 0.3, play = true, loop = true, easing = CosineFull
}]

let children = [
  {
    size = [fsh(4.), fsh(4.)]
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    hplace = ALIGN_CENTER
    vplace = ALIGN_CENTER
    rendObj = ROBJ_IMAGE
    color = colorRed
    image = Picture("!ui/skin#marker_bomb.svg")
    animations = bombAnim
  },
  makeArrow({color = colorRed, anim = bombAnim, yOffs = 0, pos = [0, -fsh(1.8)]})
]

let function bombMarker(eid) {
  let state = active_bombs_GetWatched(eid)
  let watch = [watchedHeroEid, state]
  return function() {
    let {bombOwnerEid, maxDistance} = state.value
    let heroEid = watchedHeroEid.value ?? ecs.INVALID_ENTITY_ID
    let showBombIndicatorToBombOwner =
      bombOwnerEid == heroEid
      && bombOwnerEid != ecs.INVALID_ENTITY_ID
    let showBombIndicatorToPlayer = isFriendlyFireMode()
      || !is_teams_friendly(watchedTeam.value, getTeam(bombOwnerEid))

    if (!(showBombIndicatorToBombOwner || showBombIndicatorToPlayer))
      return {watch}
    return {
      data = {
        eid
        minDistance = 0.7
        maxDistance
        yOffs = 0.1
        distScaleFactor = 0.5
        clampToBorder = true
      }
      watch
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      hplace = ALIGN_CENTER
      vplace = ALIGN_CENTER
      transform = {}
      key = eid
      sortOrder = eid
      children
    }
  }
}
let memoizedMap = mkMemoizedMapSet(bombMarker)
return {
  bomb_ctor = {
    watch = active_bombs_Set
    ctor = @() memoizedMap(active_bombs_Set.value).values()
  }
}