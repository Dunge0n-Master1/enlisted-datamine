import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let replayState = Watched({})
let isFreeTpsMode = Watched(false)
let canShowReplayHud = Watched(true)
let canShowGameHudInReplay = Watched(true)

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

ecs.register_es("replay_camera_is_free_tps", {
  [["onInit", "onChange"]] = @(_, comp) isFreeTpsMode(comp.camera__active)
}, {
  comps_track = [["camera__active", ecs.TYPE_BOOL], ["camera__target", ecs.TYPE_EID]]
  comps_rq = [["replay_camera__tpsFree"]]
}, {tags="playingReplay"})


return {
  replayCurTime = Computed(@() replayState.value?.replay__curTime ?? 0)
  replayPlayTime = Computed(@() replayState.value?.replay__playTime ?? 0)
  replayTimeSpeed = Computed(@() replayState.value?.replay__speed ?? 0)
  canShowReplayHud
  canShowGameHudInReplay
  isFreeTpsMode
}
