import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let {
  Point3, TMatrix, quat_to_matrix, euler_to_quat, degToRad
} = require("%sqstd/math_ex.nut")

let yprKeys = [
  ["item__viewYaw",   "item__iconYaw"  ],
  ["item__viewPitch", "item__iconPitch"],
  ["item__viewRoll",  "item__iconRoll" ]
]

local function transformItemImpl(transform, templateName, placeRelative){
  if (templateName == null)
    return transform
  let template = ecs.g_entity_mgr.getTemplateDB().getTemplateByName(templateName)
  if (template == null)
    return transform

  let ypr = yprKeys.map(@(angleList) degToRad(
      template.getCompValNullable(angleList[0]) ??
      template.getCompValNullable(angleList[1]) ?? 0
    ))

  let pos = transform.getcol(3)
  let trYaw =   quat_to_matrix(euler_to_quat(Point3(-ypr[0], 0, 0))).inverse()
  let trPitch = quat_to_matrix(euler_to_quat(Point3(0, ypr[2], 0))).inverse()
  let trRoll =  quat_to_matrix(euler_to_quat(Point3(0, 0, ypr[1]))).inverse()

  if (placeRelative)
    transform = transform * trPitch * trRoll * trYaw
  else
    transform = trPitch * trRoll * trYaw

  transform.setcol(3, pos)

  let scale = template.getCompValNullable("item__scale")
  if (scale != null) {
    let tScale = TMatrix()
    tScale.setcol(0, Point3(scale,0,0))
    tScale.setcol(1, Point3(0,scale,0))
    tScale.setcol(2, Point3(0,0,scale))
    transform = transform * tScale
  }

  return transform
}

let transformItemRelative = @(transform, templateName)
  transformItemImpl(transform, templateName, true)

let transformItem = @(transform, templateName)
  transformItemImpl(transform, templateName, false)

return {
  transformItem
  transformItemRelative
}
