import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let enemy_attack_markers = Watched({})

let function deleteMarker(eid, _){
  if (eid in enemy_attack_markers.value)
    enemy_attack_markers.mutate(@(v) delete v[eid])
}

let function createMarker(eid, _comp) {
  enemy_attack_markers.mutate(@(v) v[eid] <- {})
}

ecs.register_es(
  "ui_enemy_attack_markers_state",
  {
    onInit = createMarker
    onDestroy = deleteMarker
  },
  {
    comps_rq = ["enemy_attack_marker"]
  }
)

return enemy_attack_markers