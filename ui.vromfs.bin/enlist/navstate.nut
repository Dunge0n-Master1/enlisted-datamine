from "%enlSqGlob/ui_library.nut" import *


let scenesList = []

let scenesListGeneration = mkWatched(persist, "scenesListGeneration", 0)

let getTopScene = @() scenesList.len() > 0 ? scenesList.top() : null

let doesSceneExist = @(...) scenesList.len() > 0

let function addScene(componentOrScene) {
  let idx = scenesList.indexof(componentOrScene)
  if (idx != null)
    scenesList.remove(idx)
  scenesList.append(componentOrScene)
  scenesListGeneration(scenesListGeneration.value + 1)
}

let function removeScene(componentOrScene) {
  let idx = scenesList.indexof(componentOrScene)
  if (idx == null)
    return null
  scenesList.remove(idx)
  scenesListGeneration(scenesListGeneration.value + 1)
}

return {
  scenesListGeneration
  doesSceneExist
  getTopScene
  addScene
  removeScene
}
