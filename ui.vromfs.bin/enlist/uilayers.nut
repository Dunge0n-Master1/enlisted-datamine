from "%enlSqGlob/ui_library.nut" import *

let Layer = require("components/layer.nut")
return {
  underUiLayer = Layer({name="enlistUnderUi"}) //like something in scene
//  infosUiLayer = Layer({name="enlistInfosUi"}) //like itemDetail
  aboveUiLayer = Layer({name="enlistAboveUi"}) //like waiting queue
}
