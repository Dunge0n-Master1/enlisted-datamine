from "%enlSqGlob/ui_library.nut" import *

let { destroyable_ri_Set, destroyable_ri_GetWatched } = require("%ui/hud/state/destroyable_score_ri_markers.nut")
let { localPlayerTeam } = require("%ui/hud/state/local_player.nut")
let { inPlane } = require("%ui/hud/state/vehicle_state.nut")
let is_teams_friendly = require("%enlSqGlob/is_teams_friendly.nut")
let iconSz = hdpxi(18)

let { HUD_COLOR_ENEMY_INNER } = require("%enlSqGlob/ui/style/unit_colors.nut")
let pic = Picture($"ui/skin#unit_inner.svg:{iconSz}:{iconSz}:K")
let mkMarker = memoize(@(transform) freeze({
  rendObj = ROBJ_IMAGE
  size = [iconSz, iconSz]
  color = HUD_COLOR_ENEMY_INNER
  image = pic
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  transform
}))

let function mkDestoyableRiMarker(eid, transform = null) {
  let markerState = destroyable_ri_GetWatched(eid)
  let data = freeze({
    eid
    minDistance = 0.7
    maxDistance = 2000
    clampToBorder = true
  })
  let marker = mkMarker(transform)
  let watch = [markerState localPlayerTeam]

  return function() {
    let addScoreTeam = markerState.value
    return {
      data
      transform = {}
      watch
      children = is_teams_friendly(localPlayerTeam.value, addScoreTeam) ? marker : null
    }
  }
}

let watchState = Computed(@() inPlane.value ? destroyable_ri_Set.value : null)
let memoizedMapByTransform = memoize(@(transform) mkMemoizedMapSet(@(eid) mkDestoyableRiMarker(eid, transform)))

return {
  watch = watchState
  ctor = @(p) memoizedMapByTransform(p?.transform)(watchState.value ?? {}).values()
}
