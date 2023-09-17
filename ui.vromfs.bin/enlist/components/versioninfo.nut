from "%enlSqGlob/ui_library.nut" import *

let { fontSub } = require("%enlSqGlob/ui/fontsStyle.nut")
let {isProductionCircuit, circuit, version, build_number} = require("%dngscripts/appInfo.nut")

let function version_info(){
  let buildNum = build_number.value ?? ""
  let versionNum = version.value ?? ""
  local versionInfo = $"version: {versionNum}"
  if (!isProductionCircuit.value)
    versionInfo = $"build: {buildNum} {versionInfo}@{circuit.value}"
  return {
    text = versionInfo
    rendObj = ROBJ_TEXT
    watch = [circuit, version, isProductionCircuit]
    hplace = ALIGN_RIGHT
    vplace = ALIGN_BOTTOM
    pos = [-hdpx(18), -hdpx(2)]
    opacity = 0.2
    zOrder = Layers.MsgBox
  }.__update(fontSub)
}

return version_info