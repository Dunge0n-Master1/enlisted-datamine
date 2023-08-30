from "%enlSqGlob/ui_library.nut" import *

let { popupsGen, getPopups } = require("%enlSqGlob/ui/popup/popupsState.nut")
let { replayBgColor } = require("%ui/hud/replay/replayConst.nut")
let { fontBody } = require("%enlSqGlob/ui/fontsStyle.nut")

return function(custom_style) {
  return function() {
    let children = []
    let popups = getPopups()
    foreach (idx, p in popups) {
      let popup = p
      let prevVisIdx = popup.visibleIdx.value
      let curVisIdx = popups.len() - idx
      if (prevVisIdx != curVisIdx) {
        let prefix = curVisIdx > prevVisIdx ? "popupMoveTop" : "popupMoveBottom"
        anim_start(prefix + popup.id)
      }

      children.append({
        size = SIZE_TO_CONTENT
        key = $"popup_{popup.uid}"
        transform = {}
        behavior = Behaviors.RecalcHandler
        onRecalcLayout = @(_initial) popup.visibleIdx(curVisIdx)

        children = {
          rendObj = ROBJ_SOLID
          size = [hdpx(300), hdpx(100)]
          color = replayBgColor
          valign = ALIGN_CENTER
          halign = ALIGN_CENTER
          children = {
            rendObj = ROBJ_TEXT
            text = popup.text
          }.__update(fontBody)
          key = $"popup_block_{popup.uid}"
        }
        animations = [
          { prop=AnimProp.opacity, from=0.0, to=1.0, duration=1.5, play=true, easing=OutCubic }
          { prop=AnimProp.translate, from=[0,-50], to=[0, 0], duration=1, trigger = $"popupMoveTop{popup.id}", play = true, easing=OutCubic }
          { prop=AnimProp.translate, from=[0,0], to=[0,-50], duration=1, trigger = $"popupMoveBottom{popup.id}", easing=OutCubic }
        ]
      })
    }
    return {
      watch = popupsGen
      size = SIZE_TO_CONTENT
      flow = FLOW_VERTICAL
      children = children
    }.__update(custom_style)
  }
}
