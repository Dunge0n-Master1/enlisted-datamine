import "ecs"
let { logerr } = require("dagor.debug")

let function get_can_use_respawnbase_type(templName) {
  if (templName == null)
    return null
  let db = ecs.g_entity_mgr.getTemplateDB()
  let templ = db.getTemplateByName(templName)
  if (templ == null) {
    logerr($"Template '{templName}' not found in templates DB")
    return null
  }
  return {
    canUseRespawnbaseType = templ.getCompValNullable("canUseRespawnbaseType")
    canUseRespawnbaseSubtypes = templ.getCompValNullable("canUseRespawnbaseSubtypes")?.getAll() ?? []
  }
}

return {
  get_can_use_respawnbase_type
}