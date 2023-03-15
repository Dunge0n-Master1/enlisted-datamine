import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let replayState = Watched({})
let canShowReplayHud = Watched(true)
let canShowGameHudInReplay = Watched(true)
let isFpsCamera = Watched(false)
let isOperatorCamera = Watched(false)
let isTpsCamera = Watched(false)
let isTpsFreeCamera = Watched(false)
let curSoldierInfo = Watched(null)
let isFreeInput = Watched(false)
let isReplayAccelerationTo = Watched(false)

const FPS_CAMERA = "FPS_CAMERA"
const TPS_CAMERA = "TPS_CAMERA"
const TPS_FREE_CAMERA = "TPS_FREE_CAMERA"
const OPERATOR_CAMERA = "OPERATOR_CAMERA"

let activeCameraId = Computed(@() isTpsFreeCamera.value ? TPS_FREE_CAMERA
  : isOperatorCamera.value ? OPERATOR_CAMERA
  : isTpsCamera.value ? TPS_CAMERA
  : isFpsCamera.value ? FPS_CAMERA
  : null)

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
  [["onInit", "onChange"]] = @(_, comp) isTpsFreeCamera(comp.camera__active)
}, {
  comps_track = [["camera__active", ecs.TYPE_BOOL], ["camera__target", ecs.TYPE_EID]]
  comps_rq = [["replay_camera__tpsFree"]]
}, { tags = "playingReplay" })

ecs.register_es("replay_camera_is_tps", {
  [["onInit", "onChange"]] = @(_, comp) isTpsCamera(comp.camera__active)
}, {
  comps_track = [["camera__active", ecs.TYPE_BOOL]]
  comps_rq = [["camera__input_enabled"]],
  comps_no = [["replay_camera__tpsFree"]]
}, { tags = "playingReplay" })

ecs.register_es("replay_camera_is_fps", {
  [["onInit", "onChange"]] = @(_, comp) isFpsCamera(comp.isHeroCockpitCam && comp.camera__active)
}, {
  comps_track = [["camera__active", ecs.TYPE_BOOL]]
  comps_ro = [["isHeroCockpitCam", ecs.TYPE_BOOL]]
  comps_no = [["camera__input_enabled"]]
}, { tags = "playingReplay" })

ecs.register_es("replay_camera_is_operator", {
  [["onInit", "onChange"]] = @(_, comp) isOperatorCamera(comp.camera__active)
}, {
  comps_track = [["camera__active", ecs.TYPE_BOOL]]
  comps_rq = [["replay_camera__operator"]]
}, { tags = "playingReplay" })


ecs.register_es("replay_camera_free_input", {
  [["onInit", "onChange"]] = @(_, comp) isFreeInput(comp.camera__input_enabled)
}, {
  comps_track = [["camera__input_enabled", ecs.TYPE_BOOL]],
  comps_rq = ["replayCamera"]
}, { tags = "playingReplay" })


ecs.register_es("replay_camera_soldier_target", {
  [["onInit", "onChange"]] = @(_, comp) curSoldierInfo(comp)
}, {
  comps_track = [["name", ecs.TYPE_STRING], ["soldier__sClass", ecs.TYPE_STRING]],
  comps_rq = ["watchedByPlr"]
}, { tags = "playingReplay" })

ecs.register_es("ui_replay_acceleration_to", {
  onInit = @(_, _comp) isReplayAccelerationTo(true),
  onDestroy = @(_, _comp) isReplayAccelerationTo(false)
}, {
  comps_rq = ["replay__accelerationSpeed"]
}, { tags = "playingReplay" })

return {
  replayCurTime = Computed(@() replayState.value?.replay__curTime ?? 0)
  replayPlayTime = Computed(@() replayState.value?.replay__playTime ?? 0)
  replayTimeSpeed = Computed(@() replayState.value?.replay__speed ?? 0)
  isReplayStopped = Computed(@() (replayState.value?.replay__speed ?? 0) == 0)
  canShowReplayHud
  canShowGameHudInReplay
  isTpsFreeCamera
  curSoldierInfo
  isFreeInput
  FPS_CAMERA
  TPS_CAMERA
  TPS_FREE_CAMERA
  OPERATOR_CAMERA
  activeCameraId
  isReplayAccelerationTo
}
