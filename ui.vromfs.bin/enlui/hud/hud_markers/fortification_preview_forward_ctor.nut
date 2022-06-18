from "%enlSqGlob/ui_library.nut" import *

let arrowPicSize = [fsh(12), fsh(12)]
let arrowPicName = $"!ui/skin#v_arrow.svg:{arrowPicSize[0]}:{arrowPicSize[1]}:K"

let fortificationPreviewForwardIconCtor = @(eid, yawRotation) {
  data = { eid }
  transform = {}

  children = {
    transform = {
      scale = [1, 0.5]
    }
    children = {
      transform = {
        rotate = yawRotation
      }
      children = {
        rendObj = ROBJ_IMAGE
        color = Color(255, 255, 255, 128)
        size = arrowPicSize
        pos = [0, 0]
        image = Picture(arrowPicName)
      }
    }
  }
}

return fortificationPreviewForwardIconCtor