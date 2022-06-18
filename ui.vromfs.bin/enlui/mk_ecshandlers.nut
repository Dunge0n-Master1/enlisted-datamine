from "%enlSqGlob/ui_library.nut" import *

let function defComp_ctor(key, comp){
  if (type(comp?[key])=="instance")
    return comp?[key]?.getAll()
  return comp?[key]
}
let function makeEcsHandlers(watched, comps, compCtor=defComp_ctor) {
  let fullCompsList = [].extend(comps?.comps_ro ?? []).extend(comps?.comps_rw ?? []).extend(comps?.comps_track ?? [])

  let function onChange(eid, comp) {
    let entry = {}
    foreach (v in fullCompsList)
      entry[v[0]] <- compCtor(v[0], comp)

    watched.mutate(function(val) {val[eid] <- entry})
  }


  let function onDestroy(_evt, eid, _comp) {
    if (eid in watched.value)
      watched.mutate(@(v) delete v[eid])
  }

  return {
    onChange = onChange
    onInit = onChange
    onDestroy = onDestroy
  }
}

return {
  makeEcsHandlers = makeEcsHandlers
  defComp_ctor = defComp_ctor
}
