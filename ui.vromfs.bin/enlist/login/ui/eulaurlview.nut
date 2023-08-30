from "%enlSqGlob/ui_library.nut" import *

let { fontSub } = require("%enlSqGlob/ui/fontsStyle.nut")
let {showEula} = require("%enlist/eula/eula.nut")
let urlText = require("%enlist/components/urlText.nut")
let {verPadding, horPadding} = require("%enlSqGlob/safeArea.nut")

let eulaUrlView = {
    zOrder = 1
    size = SIZE_TO_CONTENT
    flow = FLOW_HORIZONTAL
    margin = fsh(0.5)
    children = urlText(loc("eula/urlViewText"), null, {
      onClick = @() showEula(null)
      skipDirPadNav = true
    }.__update(fontSub))
}
let bottomEulaUrl = @(){
  size = flex()
  halign = ALIGN_LEFT
  valign = ALIGN_BOTTOM
  children = eulaUrlView
  padding = [verPadding.value+fsh(5), horPadding.value+sw(4)]
  watch=[verPadding]
}
return {
  eulaUrlView = eulaUrlView
  bottomEulaUrl = bottomEulaUrl
}
