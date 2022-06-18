import "%dngscripts/ecs.nut" as ecs
let camera = require_optional("camera")
if (camera == null)
  return

let DataBlock = require("DataBlock")
let animevents = require("animevents")
let app = require("net")
let math = require("%sqstd/math_ex.nut")
let dir_to_quat = math.dir_to_quat


let anim_trackQuery = ecs.SqQuery("anim_trackQuery", {comps_rq = ["screen_fade", "anim_track_on"] })
let function start(comp) {
  let fileName = comp["camtracks__file"]
  let tracksBlk = DataBlock()
  tracksBlk.load(fileName)
  let tracks = tracksBlk % "track"

  if (tracks.len() == 0)
    return

  let fadeInTime = comp["camtracks__fade_in_time"]
  let fadeOutTime = comp["camtracks__fade_out_time"]


  anim_trackQuery.perform(function(fadeEid, _comp) {
    let cameraEid = camera.get_cur_cam_entity()
    ecs.g_entity_mgr.sendEvent(fadeEid, animevents.CmdResetAttrFloatAnim(ecs.calc_hash("screen_fade"), app.get_sync_time(), ANIM_CYCLIC))
    ecs.g_entity_mgr.sendEvent(cameraEid, animevents.CmdResetPosAnim(tracks[0].from_pos, app.get_sync_time(), ANIM_CYCLIC))
    ecs.g_entity_mgr.sendEvent(cameraEid, animevents.CmdResetRotAnim(dir_to_quat(tracks[0].from_dir), app.get_sync_time(), ANIM_CYCLIC))
    ecs.g_entity_mgr.sendEvent(cameraEid, animevents.CmdResetAttrFloatAnim(ecs.calc_hash("fov"), app.get_sync_time(), ANIM_CYCLIC))

    foreach (track in tracks) {
      ecs.g_entity_mgr.sendEvent(fadeEid, animevents.CmdAddAttrFloatAnim(1.0, 0, true))
      ecs.g_entity_mgr.sendEvent(fadeEid, animevents.CmdAddAttrFloatAnim(0.0, fadeInTime, true))
      ecs.g_entity_mgr.sendEvent(fadeEid, animevents.CmdAddAttrFloatAnim(0.0, track.duration - fadeOutTime - fadeInTime, true))
      ecs.g_entity_mgr.sendEvent(fadeEid, animevents.CmdAddAttrFloatAnim(1.0, fadeOutTime, true))
      ecs.g_entity_mgr.sendEvent(cameraEid, animevents.CmdAddPosAnim(track.from_pos, 0, true))
      ecs.g_entity_mgr.sendEvent(cameraEid, animevents.CmdAddPosAnim(track.to_pos, track.duration, true))
      ecs.g_entity_mgr.sendEvent(cameraEid, animevents.CmdAddRotAnim(dir_to_quat(track.from_dir), 0, true))
      ecs.g_entity_mgr.sendEvent(cameraEid, animevents.CmdAddRotAnim(dir_to_quat(track.to_dir), track.duration, true))
      ecs.g_entity_mgr.sendEvent(cameraEid, animevents.CmdAddAttrFloatAnim(track.from_fov, 0, true))
      ecs.g_entity_mgr.sendEvent(cameraEid, animevents.CmdAddAttrFloatAnim(track.to_fov, track.duration, true))
    }
  })

  comp["camtracks__playing"] = true
}


let function startCameraTracks(_eid, comp) {
  if (!comp["camtracks__playing"])
    start(comp)
}

let function stopCameraTracks(_eid, comp) {

  let fadeOutTime = comp["camtracks__fade_out_time"]

  if (comp["camtracks__playing"]) {
    let cameraEid = camera.get_cur_cam_entity()
    ecs.g_entity_mgr.sendEvent(cameraEid, animevents.CmdStopAnim())

    anim_trackQuery.perform(function(fadeEid, _comp) {
      ecs.g_entity_mgr.sendEvent(fadeEid, animevents.CmdResetAttrFloatAnim(ecs.calc_hash("screen_fade"), app.get_sync_time(), ANIM_SINGLE))
      ecs.g_entity_mgr.sendEvent(fadeEid, animevents.CmdAddAttrFloatAnim(1.0, 0, true))
      ecs.g_entity_mgr.sendEvent(fadeEid, animevents.CmdAddAttrFloatAnim(0.0, fadeOutTime, true))
    })

    comp["camtracks__playing"] = false
  }
}


ecs.register_es("camtrack_executor_es", {
    [ecs.sqEvents.EventStartCameraTracks] = startCameraTracks,
    [ecs.sqEvents.EventStopCameraTracks] = stopCameraTracks,
  },
  {
    comps_rw = [
      ["camtracks__playing", ecs.TYPE_BOOL],
    ]
    comps_ro = [
      ["camtracks__file", ecs.TYPE_STRING],
      ["camtracks__fade_in_time", ecs.TYPE_FLOAT],
      ["camtracks__fade_out_time", ecs.TYPE_FLOAT],
    ]
  }
)

