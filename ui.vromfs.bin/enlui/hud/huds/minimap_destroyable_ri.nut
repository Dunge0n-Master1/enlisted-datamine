from "%enlSqGlob/ui_library.nut" import *

let { destroyable_ri_markers } = require("%ui/hud/state/destroyable_score_ri_markers.nut")
let { localPlayerTeam } = require("%ui/hud/state/local_player.nut")
let { inPlane } = require("%ui/hud/state/vehicle_state.nut")
let is_teams_friendly = require("%enlSqGlob/is_teams_friendly.nut")
let iconSz = hdpx(18).tointeger()

let { HUD_COLOR_ENEMY_INNER } = require("%enlSqGlob/ui/style/unit_colors.nut")

let function mkDestoyableRiMarker(eid, marker, options = null) {
  let {addScoreTeam} = marker

  return @() {
    data = {
      eid = eid
      minDistance = 0.7
      maxDistance = 2000
      clampToBorder = true
    }
    transform = {}
    children = is_teams_friendly(localPlayerTeam.value, addScoreTeam) ? [{
      rendObj = ROBJ_IMAGE
      size = [iconSz, iconSz]
      color = HUD_COLOR_ENEMY_INNER
      image = Picture($"ui/skin#unit_inner.svg:{iconSz}:{iconSz}:K")
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      transform = options?.transform
    }] : null
  }
}

let watchState = Computed(@() {heroTeam = localPlayerTeam.value ?? -1, eids = destroyable_ri_markers.value, visible = inPlane.value})
return {
  watch = watchState
  ctor = @(p)  watchState.value.visible
               ? watchState.value.eids.map(@(info, eid) mkDestoyableRiMarker(eid, info, p)).values()
               : []
}
