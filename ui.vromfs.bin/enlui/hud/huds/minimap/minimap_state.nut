import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let {logerr} = require("dagor.debug")
let minimapDefaultVisibleRadius = Watched(150)
let mmChildrenCtors = []
let mmChildrenCtorsGeneration = Watched(0)

let function checkCtor(obj){
  if (!(obj?.watch == null || obj?.watch instanceof Watched) || (type(obj?.ctor)!="function")) {
    let src = obj?.ctor.getfuncinfos().src
    logerr($"incorrect mmap obj : ctor = {src}, watch = {obj?.watch.tostring()}")
    return false
  }
  return true
}
local function setMmChildrenCtors(ctors){
  mmChildrenCtors.clear()
  ctors = ctors.filter(@(obj) checkCtor(obj))
  mmChildrenCtors.extend(ctors)
  mmChildrenCtorsGeneration(mmChildrenCtorsGeneration.value+1)
}
let getMmChildrenCtors = @() clone mmChildrenCtors

ecs.register_es("set_minimap_default_visible_radius_es", {
    function onInit(_eid, comp) {
      minimapDefaultVisibleRadius.update(comp["level__minimapDefaultVisibleRadius"])
    }
  },
  {
    comps_rq = ["level"]
    comps_ro = [["level__minimapDefaultVisibleRadius", ecs.TYPE_INT]]
  })

return {
  mmChildrenCtorsGeneration
  getMmChildrenCtors
  setMmChildrenCtors
  minimapDefaultVisibleRadius
  regionsColorsUpdate = Watched({})
}
