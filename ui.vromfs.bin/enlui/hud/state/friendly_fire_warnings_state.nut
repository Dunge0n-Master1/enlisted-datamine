import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let totalPenalty = Watched(0)
let currentPenalty = Watched(0)
let showFriendlyFireWarning = Watched(false)

currentPenalty.subscribe(@(penalty) showFriendlyFireWarning(penalty < 0))

let WARNING_VISIBLE_TIME = 5.0

let warningTimer  = @() currentPenalty(0)

ecs.register_es("friendly_fire_warning_state", {
    function onInit(_, comp) {
      if (comp.is_local)
        totalPenalty(comp["scoring_player__friendlyFirePenalty"])
    },
    function onChange(_, comp) {
      if (comp.is_local) {
        let updatedPenalty = comp["scoring_player__friendlyFirePenalty"]
        let prevTotalPenalty = totalPenalty.value
        let diff = updatedPenalty - prevTotalPenalty
        currentPenalty(currentPenalty.value + diff)
        totalPenalty(updatedPenalty)
        gui_scene.resetTimeout(WARNING_VISIBLE_TIME, warningTimer )
      }
    }
  },
  { comps_track = [
      ["scoring_player__friendlyFirePenalty", ecs.TYPE_INT],
    ],
    comps_ro = [["is_local", ecs.TYPE_BOOL]]
  },
  { tags="gameClient"}
)

return {
  friendlyFirePenalty = currentPenalty
  showFriendlyFireWarning
}