import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let { Point3, quat_to_matrix, euler_to_quat, degToRad} = require("%sqstd/math_ex.nut")

let yprKeys = ["item__iconYaw", "item__iconPitch", "item__iconRoll"]

local function transformItem(transform, templateName){
  if (templateName == null)
    return transform
  let template = ecs.g_entity_mgr.getTemplateDB().getTemplateByName(templateName)
  if (template == null)
    return transform

  let ypr = yprKeys.map(@(v) degToRad(template.getCompValNullable(v) ?? 0))
  let pos = transform.getcol(3)
  let trYaw =   quat_to_matrix(euler_to_quat(Point3(-ypr[0], 0, 0))).inverse()
  let trPitch = quat_to_matrix(euler_to_quat(Point3(0, ypr[2], 0))).inverse()
  let trRoll =  quat_to_matrix(euler_to_quat(Point3(0, 0, ypr[1]))).inverse()
  transform = trPitch * trRoll * trYaw
  transform.setcol(3, pos)
  return transform
}

return transformItem