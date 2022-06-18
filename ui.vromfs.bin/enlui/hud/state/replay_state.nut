import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let isReplay = mkWatched(persist, "isReplay", false)

ecs.register_es("replay_state_ui_es", {
    onInit = @(...) isReplay.update(true),
    onDestroy = @(...) isReplay.update(false)
  },
  { comps_rq=["replayIsPlaying"] },
  { tags="playingReplay" }
)

return {
  isReplay
}
