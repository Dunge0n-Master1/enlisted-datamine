from "%enlSqGlob/ui_library.nut" import *

let interactiveElements = mkWatched(persist, "interactiveElements", {})

let function addInteractiveElement(id) {
  if (!(id in interactiveElements.value))
    interactiveElements.mutate(@(v) v[id] <- true)
}

let function removeInteractiveElement(id) {
  if (id in interactiveElements.value)
    interactiveElements.mutate(@(v) delete v[id])
}

let function setInteractiveElement(id, val){
  if (val)
    addInteractiveElement(id)
  else
    removeInteractiveElement(id)
}

let function switchInteractiveElement(id) {
  interactiveElements.mutate(function(v) {
    if (id in v)
      delete v[id]
    else
      v[id] <- true
  })
}

return {
  interactiveElements
  removeInteractiveElement
  addInteractiveElement
  switchInteractiveElement
  setInteractiveElement
  hudIsInteractive = Computed(@() interactiveElements.value.len() > 0)
}

