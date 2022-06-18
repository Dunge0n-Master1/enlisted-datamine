from "%enlSqGlob/ui_library.nut" import *

let { curSectionDetails } = require("%enlist/mainMenu/sectionsState.nut")
let { addScene, removeScene } = require("%enlist/navState.nut")

let scenes = []
let cameras = Watched([])

let curCamera = Computed(@() (cameras.value.len() ? cameras.value.top() : null)
  ?? curSectionDetails.value?.camera
  ?? "soldiers")

let function sceneWithCameraAdd(content, camera) {
  if (scenes.findindex(@(c) c == content) != null)
    return
  addScene(content)
  scenes.append(content)
  cameras.mutate(@(v) v.append(camera))
}

let function sceneWithCameraRemove(content) {
  let idx = scenes.findindex(@(c) c == content)
  if (idx == null)
    return
  removeScene(content)
  scenes.remove(idx)
  cameras.mutate(@(v) v.remove(idx))
}

return {
  curCamera,  sceneWithCameraAdd, sceneWithCameraRemove
}