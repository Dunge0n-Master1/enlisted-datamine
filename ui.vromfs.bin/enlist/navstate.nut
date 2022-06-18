from "%enlSqGlob/ui_library.nut" import *

#explicit-this

let scenesList = []
let scenesListGeneration = mkWatched(persist, "scenesListGeneration", 0)

let class Scene {
  _scene = null
  _id = null
  constructor(id, scene){
    assert(type(id) == "string", @() $"id should be string, got {type(id)}")
    this._scene=scene
    this._id=id
  }
}
let function getIdx(componentOrId){
  let idx = (type(componentOrId) =="string")
   ? scenesList.findindex(@(v) v?._id == componentOrId)
   : scenesList.indexof(componentOrId)
  return idx
}

let doesSceneExist = @(...) scenesList.len()>0
return {
  scenesListGeneration,
  doesSceneExist,
  function getTopScene(){
    let top = scenesList.top()
    if ("_scene" in top)
      return top._scene
    else
      return top
  }
  function addScene(componentOrScene) {
    let idx = ("_id" in componentOrScene)
      ? scenesList.findindex(@(v) v?._id == componentOrScene._id)
      : scenesList.indexof(componentOrScene)
    if (idx != null)
      scenesList.remove(idx)
    scenesList.append(componentOrScene)
    scenesListGeneration(scenesListGeneration.value+1)
  }
  function removeScene(componentOrId) {
    let idx = getIdx(componentOrId)
    if (idx == null)
      return
    scenesList.remove(idx)
    scenesListGeneration(scenesListGeneration.value+1)
  },
  Scene
}
