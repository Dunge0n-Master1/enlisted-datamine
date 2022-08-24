from "frp" import Computed, Watched
let { kwarg } = require("functools.nut")

let function watchedTable2TableOfWatched(state=null, defValue=null, plainOut=true, name=null){
  let isWatchedStateProvided = state != null
  let def = defValue==null ? state?.value : defValue
  let watchedState = state != null ? state : Watched(def)
  assert(state==null || state instanceof Watched, "state has to be Watched or omitted")
  assert(typeof def == "table", "default value of state should be provided as table")
  if (defValue!=null && state!=null && state.value != defValue)
    watchedState(def)
  let exportState = def.map(@(_, key) Computed(@() watchedState.value[key]))
  let resetState = Watched(def)
  if (name==null) {
    let ret = {
      resetState
    }
    if (!isWatchedStateProvided)
      ret.watchedState <- watchedState
    return ret.__update(plainOut ? exportState : {exportState})
  }
  else {
    let ret = {[$"{name}Reset"] = resetState}
    if (!isWatchedStateProvided)
      ret.__update({[$"{name}State"] = watchedState})
    return ret.__update(plainOut ? exportState : {[name] = exportState})
  }
}

return {
  watchedTable2TableOfWatched = kwarg(watchedTable2TableOfWatched)
}