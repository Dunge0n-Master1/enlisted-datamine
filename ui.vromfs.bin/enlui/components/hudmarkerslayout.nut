from "%enlSqGlob/ui_library.nut" import *

let {horPadding, verPadding} = require("%enlSqGlob/safeArea.nut")

let function mkViewport(padding){
  return {
    sortOrder = -999
    size = [sw(100) - horPadding.value*2 - padding, sh(100) - verPadding.value*2 - padding]
    data = {
      isViewport = true
    }
  }
}

local function layout(state, ctors, padding){
  let child = mkViewport(padding)
  if (type(ctors) != "array")
    ctors = [ctors]

  return function() {
    let children = [child]
    foreach(ctor in ctors)
      foreach (eid, info in state.value) {
        let res = ctor(eid, info)
        children.extend(type(res) == "array" ? res : [res])
      }
    return {
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      size = flex()
      children = children
      watch = state
      behavior = Behaviors.Projection
      sortChildren = true
    }
  }
}

let function makeMarkersLayout(stateAndCtors, padding){
  let layers = []
  foreach (state, ctors in stateAndCtors)
    layers.append(layout(state, ctors, padding))

  return @(){
    size = [sw(100), sh(100)]
    children = layers
    watch = [horPadding, verPadding]
  }
}

return {
  makeMarkersLayout
}
