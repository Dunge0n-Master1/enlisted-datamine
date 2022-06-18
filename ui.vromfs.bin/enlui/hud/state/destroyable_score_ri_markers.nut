import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let destroyable_ri_markers = Watched({})

let function deleteEid(eid){
  if (eid in destroyable_ri_markers.value)
    destroyable_ri_markers.mutate(@(v) delete v[eid])
}

ecs.register_es(
  "destroyable_ri_markers_es",
  {
    [["onInit", "onChange"]] = function(_evt, eid, comp){
      let addScoreTeam = comp["destroyable_ri__addScoreTeam"]
      destroyable_ri_markers.mutate(@(v) v[eid] <- {addScoreTeam = addScoreTeam})
    }
    onDestroy = @(_evt, eid, _comp) deleteEid(eid)
  },
  {
    comps_track = [
      ["destroyable_ri__addScoreTeam", ecs.TYPE_INT]
    ]
  }
)

return{
  destroyable_ri_markers
}