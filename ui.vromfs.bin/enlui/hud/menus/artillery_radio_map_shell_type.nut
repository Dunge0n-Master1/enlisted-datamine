from "%enlSqGlob/ui_library.nut" import *

let {artilleryAvailableShellTypes} = require("%ui/hud/state/artillery.nut")
let {hintTextFunc} = require("mapComps.nut")
let {tipCmp} = require("%ui/hud/huds/tips/tipComponent.nut")
let {DEFAULT_TEXT_COLOR} = require("%ui/hud/style.nut")

let tipChangeShell = "map/artilleryChangeShell"

let currentShellTypeIndex = Watched(0)
let currentShellType = Computed(@() artilleryAvailableShellTypes.value?[currentShellTypeIndex.value])

artilleryAvailableShellTypes.subscribe(function(shellTypes) {
  if (currentShellTypeIndex.value >= shellTypes.len())
    currentShellTypeIndex(0)
})

let artilleryChangeShellInputId = "Artillery.ChangeShell"
let function changeShell() {
  let typesCount = artilleryAvailableShellTypes.value.len()
  if (typesCount > 1)
    currentShellTypeIndex((currentShellTypeIndex.value+1) % typesCount)
}

let changeShellTips = @() (artilleryAvailableShellTypes.value.len() > 1)
  ? {
      flow = FLOW_HORIZONTAL
      gap = hdpx(10)
      watch = [artilleryAvailableShellTypes, currentShellType]
      children = [
        hintTextFunc(loc($"map/{currentShellType.value?.name}"), DEFAULT_TEXT_COLOR)
        tipCmp({inputId = artilleryChangeShellInputId, text = loc(tipChangeShell)})
      ]
      hotkeys = [[$"^@{artilleryChangeShellInputId}", {action = changeShell}]]
    }
  : { watch = [artilleryAvailableShellTypes] }

return {
  currentShellType
  currentShellTypeIndex
  changeShellTips
}
