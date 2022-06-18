from "%enlSqGlob/ui_library.nut" import *

let frameUpdateCounter = Watched(0)

gui_scene.setUpdateHandler(function sceneUpdateHandler(_dt) {
  frameUpdateCounter(frameUpdateCounter.value+1)
})

return {
  frameUpdateCounter
}