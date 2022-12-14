from "%enlSqGlob/ui_library.nut" import *
import "%dngscripts/ecs.nut" as ecs


let function createVehicle(
  template, transform, callback = null, customazation = null, extraTemplates = []
) {
  if (template == null)
    return ecs.INVALID_ENTITY_ID

  let { vehCamouflage = null, objTexSet = null } = customazation
  let updateParams = {}
  if (vehCamouflage != null)
    updateParams.animchar__objTexReplace <- vehCamouflage
  if (objTexSet != null)
    updateParams.animchar__objTexSet <- objTexSet

  let entityParams = { transform }.__update(updateParams)

  template = "+".join([template].extend(extraTemplates))

  return ecs.g_entity_mgr.createEntity(template, entityParams, callback)
}

return {
  createVehicle = kwarg(createVehicle)
}
