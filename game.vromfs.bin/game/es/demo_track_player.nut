import "%dngscripts/ecs.nut" as ecs
let camera = require_optional("camera")
if (camera == null)
  return
let { Point3, dir_to_quat } = require("dagor.math")
let { get_cur_cam_entity, set_scene_camera_entity } = camera
let { get_sync_time } = require("net")
let {CmdResetAttrFloatAnim, CmdAddAttrFloatAnim, CmdResetPosAnim, CmdAddPosAnim, CmdAddRotAnim, CmdResetRotAnim} = require("animevents")


let function side_dir_to_quat(dir) {
  let up = Point3(0, 1, 0)
  let side = up % dir
  return dir_to_quat(side)
}


local tracks = []


local fadeInTime = 2.0
local fadeOutTime = 2.0
let initialPauseInBlackScreen = 0.01 // sec
local curTrackIndex = 0
local fade_eid = null
local camera_eid = null
local prev_camera_eid = null

local cb_timer = null


let function start_camera_tracks() {
  if (tracks.len() == 0)
    return

//  screen.fadeIn(fadeInTime)

  local curTrack = tracks[curTrackIndex]

  local cnt = 0
  while (typeof curTrack == "function") {
    curTrack()
    curTrackIndex++
    if (curTrackIndex >= tracks.len()) {
      curTrackIndex = 0
      cnt++
      if (cnt == 2)
        break
    }
    curTrack = tracks[curTrackIndex]
  }

  curTrack.begin_time_sec <- get_sync_time()
  curTrack.end_time_sec <- get_sync_time() + curTrack.duration
  curTrackIndex++
  if (curTrackIndex >= tracks.len())
    curTrackIndex = 0

  if (fadeOutTime + fadeInTime > 0) {
    if (curTrack.duration < fadeOutTime + fadeInTime) {
      ecs.g_entity_mgr.sendEvent(fade_eid, CmdResetAttrFloatAnim(ecs.calc_hash("screen_fade"), get_sync_time(), ANIM_SINGLE))
      ecs.g_entity_mgr.sendEvent(fade_eid, CmdAddAttrFloatAnim(1.0, 0, true))
      ecs.g_entity_mgr.sendEvent(fade_eid, CmdAddAttrFloatAnim(1.0, curTrack.duration, true))
    }
    else {
      ecs.g_entity_mgr.sendEvent(fade_eid, CmdResetAttrFloatAnim(ecs.calc_hash("screen_fade"), get_sync_time(), ANIM_SINGLE))
      ecs.g_entity_mgr.sendEvent(fade_eid, CmdAddAttrFloatAnim(1.0, 0, true))
      ecs.g_entity_mgr.sendEvent(fade_eid, CmdAddAttrFloatAnim(0.0, fadeInTime, true))
      ecs.g_entity_mgr.sendEvent(fade_eid, CmdAddAttrFloatAnim(0.0, curTrack.duration - fadeOutTime - fadeInTime, true))
      ecs.g_entity_mgr.sendEvent(fade_eid, CmdAddAttrFloatAnim(1.0, fadeOutTime, true))
    }
  }
  else {
    ecs.g_entity_mgr.sendEvent(fade_eid, CmdResetAttrFloatAnim(ecs.calc_hash("screen_fade"), get_sync_time(), ANIM_SINGLE))
    ecs.g_entity_mgr.sendEvent(fade_eid, CmdAddAttrFloatAnim(0, 0, true))
  }
  if (curTrack?.from_pos)
    ecs.g_entity_mgr.sendEvent(camera_eid, CmdResetPosAnim(curTrack.from_pos, get_sync_time(), ANIM_SINGLE))
  if (curTrack?.to_pos)
    ecs.g_entity_mgr.sendEvent(camera_eid, CmdAddPosAnim(curTrack.to_pos, curTrack.duration, true))
  if (curTrack?.from_dir)
    ecs.g_entity_mgr.sendEvent(camera_eid, CmdResetRotAnim(side_dir_to_quat(curTrack.from_dir), get_sync_time(), ANIM_SINGLE))
  if (curTrack?.to_dir)
    ecs.g_entity_mgr.sendEvent(camera_eid, CmdAddRotAnim(side_dir_to_quat(curTrack.to_dir), curTrack.duration, true))

  cb_timer = ecs.set_callback_timer(callee(), curTrack.duration, false)
}


let function stop_camera_tracks() {
  ecs.clear_callback_timer(cb_timer)

  ecs.g_entity_mgr.sendEvent(fade_eid, CmdResetAttrFloatAnim(ecs.calc_hash("screen_fade"), get_sync_time(), ANIM_SINGLE))
  ecs.g_entity_mgr.sendEvent(fade_eid, CmdAddAttrFloatAnim(0, 0, true))

  if (prev_camera_eid)
    set_scene_camera_entity(prev_camera_eid)
}


let screenFadeQuery = ecs.SqQuery("screenFadeQuery", {comps_rw = ["screen_fade", "anim_track_on"] })
let linearCamerasQuery = ecs.SqQuery("linearCamerasQuery", { comps_ro = [["linear_cam_anim", ecs.TYPE_BOOL]] })

let function create_fade_entity(next_function) {
  screenFadeQuery.perform(function(eid, comp){
      comp.screen_fade = 1.0
      comp.anim_track_on = true
      fade_eid = eid
      ecs.set_callback_timer(next_function, initialPauseInBlackScreen, false)
    }
  )
}

let function create_camera_entity(next_function) {
  linearCamerasQuery.perform(function(eid, _comp) {
    ecs.g_entity_mgr.destroyEntity(eid)
  })

  ecs.g_entity_mgr.createEntity("linear_cam_anim", { "camera__active" : [true, ecs.TYPE_BOOL] },
    function (eid) {
      camera_eid = eid
      prev_camera_eid = get_cur_cam_entity()
      set_scene_camera_entity(camera_eid)
      next_function()
    }
  )
}

let function trackPlayerStart(tracks_, fadeInTime_=0, fadeOutTime_=0) {
  curTrackIndex = 0
  tracks = tracks_
  fadeInTime = fadeInTime_
  fadeOutTime = fadeOutTime_
  create_camera_entity(
    function() {
      create_fade_entity(start_camera_tracks)
    }
  )
}

return {
  trackPlayerStart
  trackPlayerStop = stop_camera_tracks
}
