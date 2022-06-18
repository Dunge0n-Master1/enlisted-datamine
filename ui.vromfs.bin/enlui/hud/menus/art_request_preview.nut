import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let {currentShellType} = require("artillery_radio_map_shell_type.nut")

let isArtRequest = Computed(function() {
  if (!currentShellType.value)
    return false

  let artilleryTemplate = ecs.g_entity_mgr.getTemplateDB().getTemplateByName(currentShellType.value.name)

  if (!artilleryTemplate)
    return false

  return artilleryTemplate.getCompValNullable("artillery_he") != null
})

return {
  isArtRequest
}
