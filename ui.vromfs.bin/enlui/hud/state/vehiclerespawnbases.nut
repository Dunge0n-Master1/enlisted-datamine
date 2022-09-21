import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let state = Watched({eids=[] byType={}})
let trackRespawnBases = Watched([])

let function doTrack() {
  state.mutate(function (st) {
    foreach (respawnbase in trackRespawnBases.value) {
      let {eid, active, respawnbaseType, respawnbaseSubtype} = respawnbase

      if (active)
        st.eids.append([eid, respawnbaseType, respawnbaseSubtype])
      else
        st.eids = st.eids.filter(@(v) v[0] != eid)
    }
    trackRespawnBases([])

    st.byType = {}
    foreach (v in st.eids) {
      let [_, respType, respSubtype] = v;
      if (respType not in st.byType)
        st.byType[respType] <- {}
      st.byType[respType][respSubtype] <- true
    }
  })
}

let function track(eid, comp) {
  let active          = comp.active
  let respawnbaseType = comp.respawnbaseType
  let respawnbaseSubtype = comp.respawnbaseSubtype

  trackRespawnBases.mutate(@(st) st.append({eid, active, respawnbaseType, respawnbaseSubtype}))

  // In order to handle multiple repsawnbases activation at the same time
  gui_scene.resetTimeout(0.1, doTrack)
}

ecs.register_es("vehicle_respawn_bases_ui_es",
  {[["onInit", "onChange"]] = track},
  {
    comps_track=[["active", ecs.TYPE_BOOL]]
    comps_ro = [
      ["respawnbaseType", ecs.TYPE_STRING, ""],
      ["respawnbaseSubtype", ecs.TYPE_STRING, ""]
    ]
    comps_rq = ["vehicleRespbase"]
  })

return state