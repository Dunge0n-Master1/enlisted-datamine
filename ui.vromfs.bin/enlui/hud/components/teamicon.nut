from "%enlSqGlob/ui_library.nut" import *

let logo_size=fsh(6)

let function image_from_attr(image_name, size) {
  assert(type(image_name)=="string" || image_name==null, "image_name should be string")
  if (image_name==null)
    return null
  if (image_name.endswith("svg"))
    return Picture("{0}:{1}:{1}:K".subst(image_name,size.tointeger()))
  return Picture("{0}".subst(image_name))
}

let mk_team_image = @(state, size = logo_size) @() {
  rendObj = ROBJ_IMAGE
  watch = state
  size = [size, size]
  image = image_from_attr(state.value, size)
}

return mk_team_image