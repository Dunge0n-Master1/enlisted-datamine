from "%enlSqGlob/ui_library.nut" import *

let { wallPosterPreview } = require("%ui/hud/state/wallposter.nut")
let { tipCmp } = require("%ui/hud/huds/tips/tipComponent.nut")
let { DEFAULT_TEXT_COLOR } = require("%ui/hud/style.nut")

let function wallposterTips() {
  let res = { watch = wallPosterPreview }
  if (!wallPosterPreview.value)
    return res
  return res.__update({
    hplace = ALIGN_CENTER
    vplace = ALIGN_BOTTOM
    flow = FLOW_HORIZONTAL
    children = [
      tipCmp({
        text = loc("wallposter/place")
        inputId = "Wallposter.Place"
        textColor = DEFAULT_TEXT_COLOR
      })
      tipCmp({
        text = loc("wallposter/cancel")
        inputId = "Wallposter.Cancel"
        textColor = DEFAULT_TEXT_COLOR
      })
      {
        size = [0, 0] // in order to override empty ui component formal warning
        hooks = HOOK_ATTACH
        actionSet = "Wallposter"
      }
    ]
  })
}

return [
  wallposterTips
]
