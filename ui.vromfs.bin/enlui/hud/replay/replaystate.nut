import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let replayState = Watched({})
let canShowReplayHud = Watched(true)
let replayHudDisableByCam = Watched(false)

ecs.register_es("replay_state_time_ui_es", {
    [[ "onInit", "onChange" ]] = @(_evt, _eid, comp) replayState(comp)
  },
  {
    comps_track = [
      ["replay__curTime", ecs.TYPE_FLOAT],
      ["replay__speed", ecs.TYPE_FLOAT],
    ],
    comps_ro = [
      ["replay__playTime", ecs.TYPE_FLOAT],
    ],
  }
)

ecs.register_es("replay_camera_input_ui_es", {
  [["onInit", "onChange"]] = function(_, comp) {
    if (!replayHudDisableByCam.value && !canShowReplayHud.value)
      return
    canShowReplayHud(!comp.camera__input_enabled)
    replayHudDisableByCam(comp.camera__input_enabled)
  }
}, {
  comps_track = [["camera__input_enabled", ecs.TYPE_BOOL]]
  comps_rq = [["replayCamera"]]
}, {tags="playingReplay"})


return {
  replayCurTime = Computed(@() replayState.value?.replay__curTime ?? 0)
  replayPlayTime = Computed(@() replayState.value?.replay__playTime ?? 0)
  replayTimeSpeed = Computed(@() replayState.value?.replay__speed ?? 0)
  canShowReplayHud
  replayHudDisableByCam
}
