import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let state = mkWatched(persist, "vehicleRespawnBases", {eids=[] byType={}})
let trackRespawnBases = mkWatched(persist, "trackRespawnBases", [])

let function doTrack() {
  state.mutate(function (st) {
    foreach (respawnbase in trackRespawnBases.value) {
      let {eid, active, respawnbaseType} = respawnbase

      if (active)
        st.eids.append([eid, respawnbaseType])
      else
        st.eids = st.eids.filter(@(v) v[0] != eid)
    }
    trackRespawnBases([])

    st.byType = {}
    foreach (v in st.eids) {
      let [respEid, respType] = v;
      if (respType in st.byType)
        st.byType[respType].append(respEid)
      else
        st.byType[respType] <- [respEid]
    }
  })
}

let function track(eid, comp) {
  let active          = comp.active
  let respawnbaseType = comp.respawnbaseType

  trackRespawnBases.mutate(@(st) st.append({eid, active, respawnbaseType}))

  // In order to handle multiple repsawnbases activation at the same time
  gui_scene.resetTimeout(0.1, doTrack)
}

ecs.register_es("vehicle_respawn_bases_ui_es",
  {[["onInit", "onChange"]] = track},
  {
    comps_track=[["active", ecs.TYPE_BOOL]]
    comps_ro = [["respawnbaseType", ecs.TYPE_STRING, ""]]
    comps_rq = ["vehicleRespbase"]
  })

return state