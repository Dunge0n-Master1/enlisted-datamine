import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let { transformItem } = require("transformItem.nut")
let { Point3, TMatrix } = require("dagor.math")


let function setItemTransformFunc(transform, data) {
  if (data == null)
    return transform

  let newTm = TMatrix(transform)
  let templ = ecs.g_entity_mgr.getTemplateDB().getTemplateByName(data)
  let zoom = templ?.getCompValNullable("distanceOffset") ?? 0
  newTm[3] = Point3(transform[3].x + zoom, transform[3].y, transform[3].z)
  return transformItem(newTm, data)
}

return {
  setItemTransformFunc
}
