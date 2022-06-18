import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let math = require("%sqstd/math_ex.nut")
let Point3 = math.Point3
let quat_to_matrix = math.quat_to_matrix
let euler_to_quat = math.euler_to_quat
let degToRad = math.degToRad

local function transformItem(transform, templateName){
  if (templateName != null) {
    let template = ecs.g_entity_mgr.getTemplateDB().getTemplateByName(templateName)
    if (template == null)
      return transform
    let ypr = ["Yaw", "Pitch", "Roll"].map(pipe(@(v) $"item__icon{v}", @(v) template.getCompValNullable(v) ?? 0, degToRad))
    let pos = transform.getcol(3)
    let trYaw =   quat_to_matrix(euler_to_quat(Point3(-ypr[0], 0, 0))).inverse()
    let trPitch = quat_to_matrix(euler_to_quat(Point3(0, ypr[2], 0))).inverse()
    let trRoll =  quat_to_matrix(euler_to_quat(Point3(0, 0, ypr[1]))).inverse()
    transform = trPitch * trRoll * trYaw
    transform.setcol(3, pos)
  }
  return transform
}

return transformItem