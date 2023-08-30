from "%enlSqGlob/ui_library.nut" import *

let {fortificationPreviewForwardArrowsGetWatched, fortificationPreviewForwardArrowsSet} = require("%ui/hud/state/fortification_preview_forward_marker.nut")

let arrowPicSize = array(2, hdpxi(130))
let arrow = freeze({
  rendObj = ROBJ_IMAGE
  color = Color(255, 255, 255, 128)
  size = arrowPicSize
  pos = [0, 0]
  image = Picture($"!ui/skin#v_arrow.svg:{arrowPicSize[0]}:{arrowPicSize[1]}:K")
})

let defScale = freeze({
  scale = [1, 0.5]
})
let deftransform = {}

let function ctor(eid) {
  let yawRotation = fortificationPreviewForwardArrowsGetWatched(eid)
  return @(){
    data = { eid }
    watch = yawRotation
    transform = deftransform
    children = {
      transform = defScale
      children = {
        transform = {
          rotate = yawRotation.value
        }
        children = arrow
      }
    }
  }
}

let memoizedMap = mkMemoizedMapSet(ctor)
return {
  fortification_preview_forward_ctor = {
    watch =  fortificationPreviewForwardArrowsSet
    ctor = @() memoizedMap(fortificationPreviewForwardArrowsSet.value).values()
  }
}