from "%enlSqGlob/ui_library.nut" import *

let {shell_activators_Set, shell_activators_GetWatched} = require("%ui/hud/state/shell_activators.nut")
let {makeArrow} = require("%ui/hud/hud_markers/components/hud_markers_components.nut")

let colorRedBlink = Color(255, 141, 29, 220)
let colorRed      = Color(255,  40, 30, 220)

let activatorAnim = [{
  prop = AnimProp.color, from = colorRed, to = colorRedBlink,
  duration = 0.3, play = true, loop = true, easing = CosineFull
}]
let arrow = makeArrow({color = colorRed, anim = activatorAnim, yOffs = 0, pos = [0, -fsh(1.8)]})
let size = [fsh(4.), fsh(4.)]
let getIcon = memoize(function(ico) {
  return freeze({
    size
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    hplace = ALIGN_CENTER
    vplace = ALIGN_CENTER
    rendObj = ROBJ_IMAGE
    color = colorRed
    image = Picture($"!ui/skin#{ico}")
    animations = activatorAnim
  })
})

let function activatorMarker(eid) {
  let state = shell_activators_GetWatched(eid)
  return @() {
    watch = state
    data = {
      eid
      minDistance = 0.7
      maxDistance = state.value.maxDistance
      yOffs = 0.1
      distScaleFactor = 0.5
      clampToBorder = true
    }
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    hplace = ALIGN_CENTER
    vplace = ALIGN_CENTER
    transform = {}
    key = eid
    sortOrder = eid
    children = [ getIcon(state.value.icon) arrow ]
  }
}

let memoizedMap = mkMemoizedMapSet(activatorMarker)
return {
  activator_ctor = {
    watch = shell_activators_Set
    ctor = @() memoizedMap(shell_activators_Set.value).values()
  }
}