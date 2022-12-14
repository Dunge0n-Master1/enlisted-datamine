import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let {EventHeroChanged} = require("gameevents")

let respawnSelection = Watched(ecs.INVALID_ENTITY_ID)

ecs.register_es("respawn_selection_ui_es", {
  [["onChange", "onInit"]] = function(_eid, comp) {
    if (comp.is_local)
      respawnSelection.update(comp["respawner__chosenRespawn"])
  },
  [EventHeroChanged] = function onHeroChanged(evt, _eid, _comp) {
    respawnSelection.update(evt[0])
  }
}, {
  comps_ro = [["is_local", ecs.TYPE_BOOL]]
  comps_track = [["respawner__chosenRespawn", ecs.TYPE_EID]]
},
{tags="gameClient"})


return respawnSelection
