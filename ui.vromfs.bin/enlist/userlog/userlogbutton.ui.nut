from "%enlSqGlob/ui_library.nut" import *


let { setTooltip } = require("%ui/style/cursors.nut")
let { fastAccessIconHeight, defTxtColor, hoverTxtColor
} = require("%enlSqGlob/ui/designConst.nut")
let userLogScene = require("userLogScene.nut")
let { hasUserLogs } = require("%enlist/featureFlags.nut")


return @() {
  watch = hasUserLogs
  children = !hasUserLogs.value ? null
    : watchElemState(@(sf) {
        rendObj = ROBJ_IMAGE
        size = [fastAccessIconHeight, fastAccessIconHeight]
        image = Picture("ui/skin#fastAccessIcons/bell_icon.svg:{0}:{0}:K"
          .subst(fastAccessIconHeight))
        color = sf & S_HOVER ? hoverTxtColor : defTxtColor
        behavior = Behaviors.Button
        onClick = @() userLogScene()
        onHover = @(on) setTooltip(on ? loc("tooltips/userLogs") : null)
      })
}
