import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/library_logs.nut" import *
let {degToRad} = require("%sqstd/math_ex.nut")
let {Point3, Quat, euler_to_quat} = require("dagor.math")
let {get_sync_time} = require("net")
let {CmdResetRotAnim, CmdAddRotAnim} = require("animevents")


let function set_rotation(eid, ang_speed_yaw, ang_speed_pitch, ang_speed_roll, local_space = false) { // in degrees, not radians
  let start = Point3(0,0,0)
  local end = Point3(degToRad(ang_speed_yaw), degToRad(ang_speed_pitch), degToRad(ang_speed_roll))
  let endLen = end.length()
  local endScale = 1
  if (endLen > 1) {
    endScale = (1./(endLen*10 + 0.00001))
    end = Point3(end.x*endScale, end.y*endScale, end.z*endScale) //degs
  }

  local startQuat = euler_to_quat(start)
  local endQuat = euler_to_quat(end)

  if (local_space) {
    let transform = ecs.obsolete_dbg_get_comp_val(eid, "transform")
    if (transform) {
      let initialRotationQuat = Quat(transform).normalize()
      startQuat = initialRotationQuat*startQuat
      endQuat = initialRotationQuat*endQuat
    }
  }
  local startTime = get_sync_time()
  if (startTime<0)
    startTime = 0
  if (endLen > 0) {
    ecs.g_entity_mgr.sendEvent(eid, CmdResetRotAnim(startQuat, startTime, ANIM_EXTRAPOLATED))
    ecs.g_entity_mgr.sendEvent(eid, CmdAddRotAnim(endQuat, endScale, true))
  } else
    ecs.g_entity_mgr.sendEvent(eid, CmdResetRotAnim(startQuat, startTime, ANIM_SINGLE))
}

let function reset_rotation(eid, ang_speed_yaw, ang_speed_pitch, ang_speed_roll) {// in degrees, not radians
  let startTime = get_sync_time()
  ecs.g_entity_mgr.sendEvent(eid, CmdResetRotAnim(euler_to_quat(Point3(ang_speed_yaw, ang_speed_pitch, ang_speed_roll)), startTime, ANIM_SINGLE))
}
ecs.register_es("set_rotation_es", {
  [["onInit", "onChange"]] = function onInit(eid, comp) {
    let {ang_speed_yaw, ang_speed_pitch, ang_speed_roll, local_space} = comp
    set_rotation(eid, ang_speed_yaw, ang_speed_pitch, ang_speed_roll, local_space)
  }
},
{
  comps_rq=["set_rotation"]
  comps_track = [
    ["ang_speed_yaw", ecs.TYPE_FLOAT],
    ["ang_speed_pitch", ecs.TYPE_FLOAT],
    ["ang_speed_roll", ecs.TYPE_FLOAT],
    ["local_space", ecs.TYPE_BOOL]
  ]
})

return {set_rotation, reset_rotation}
