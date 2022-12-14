from "%enlSqGlob/ui_library.nut" import *

let { curSectionDetails } = require("%enlist/mainMenu/sectionsState.nut")
let { addScene, removeScene } = require("%enlist/navState.nut")

let cameras = Watched([])
let sceneToCamera = {}
let curCamera = Computed(@() (cameras.value.len() ? cameras.value.top() : null)
  ?? curSectionDetails.value?.camera
  ?? "soldiers")

let function sceneWithCameraAdd(content, camera) {
  addScene(content)
  let idx = cameras.value.indexof(sceneToCamera?[content])
  sceneToCamera[content] <- camera
  cameras.mutate(function(v) {
    if (idx != null)
      v.remove(idx)
    v.append(camera)
  })
}

let function sceneWithCameraRemove(content) {
  removeScene(content)
  let idx = cameras.value.indexof(sceneToCamera?[content])
  if (idx != null) {
    delete sceneToCamera[content]
    cameras.mutate(@(v) v.remove(idx))
  }
}

return {
  curCamera
  sceneWithCameraAdd
  sceneWithCameraRemove
}