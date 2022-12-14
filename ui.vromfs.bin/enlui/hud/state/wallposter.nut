import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let localPlayerEid = Watched(ecs.INVALID_ENTITY_ID)
let wallPostersMaxCount = Watched(0)
let wallPostersCurCount = Watched(0)
let wallPosterPreview = Watched(false)
let wallPosters = Watched([])

let function resetData() {
  localPlayerEid(ecs.INVALID_ENTITY_ID)
  wallPostersMaxCount(0)
  wallPostersCurCount(0)
  wallPosterPreview(false)
  wallPosters([])
}

let function trackComponents(eid, comp) {
  if (comp.is_local) {
    localPlayerEid(eid)
    wallPostersMaxCount(comp["wallPosters__maxCount"])
    wallPostersCurCount(comp["wallPosters__curCount"])
    wallPosterPreview(comp["wallPoster__preview"])
    let posters = comp["wallPosters"].getAll().map(@(p) p.template)
    wallPosters(posters)
  } else if (localPlayerEid.value == eid) {
    resetData()
  }
}

let function onDestroy(eid, _comp) {
  if (localPlayerEid.value == eid)
    resetData()
}

ecs.register_es("wallposter_state_es", {
    onChange = trackComponents
    onInit = trackComponents
    onDestroy = onDestroy
  },
  {
    comps_track = [
      ["is_local", ecs.TYPE_BOOL],
      ["wallPosters__maxCount", ecs.TYPE_INT],
      ["wallPosters__curCount", ecs.TYPE_INT],
      ["wallPoster__preview", ecs.TYPE_BOOL],
      ["wallPosters", ecs.TYPE_ARRAY]
    ]
    comps_rq = ["player"]
  }
)

return {
  wallPostersMaxCount
  wallPostersCurCount
  wallPosterPreview
  wallPosters
}