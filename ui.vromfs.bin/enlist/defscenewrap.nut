from "%enlSqGlob/ui_library.nut" import *
let { sidePadding, maxContentWidth, hotkeysBarHeight } = require("%enlSqGlob/ui/designConst.nut")
let { safeAreaVerPadding } = require("%enlSqGlob/safeArea.nut")


let function defSceneWrap (content, params = {}) {
  let bottomPadding = safeAreaVerPadding.value + hotkeysBarHeight
  // We dont need to subscribe on safeAreaVerPadding. In new design safearea reloads ui
  return {
    size = flex()
    maxWidth = maxContentWidth
    hplace = ALIGN_CENTER
    padding = [safeAreaVerPadding.value, sidePadding, bottomPadding, sidePadding]
    children = content
    transform = {}
    animations = [{ prop = AnimProp.opacity, from = 0, to = 1, duration = 0.5, play = true, easing = OutCubic }]
  }.__update(params)
}

return defSceneWrap
