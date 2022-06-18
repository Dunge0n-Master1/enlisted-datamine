from "%enlSqGlob/ui_library.nut" import *

let userLogScene = require("userLogScene.nut")
let { hasUserLogs } = require("%enlist/featureFlags.nut")
let squareIconButton = require("%enlist/components/squareIconButton.nut")


return @() {
  watch = hasUserLogs
  children = !hasUserLogs.value ? null
    : squareIconButton({
        onClick = @() userLogScene()
        tooltipText = loc("tooltips/userLogs")
        iconId = "bell"
      })
}
