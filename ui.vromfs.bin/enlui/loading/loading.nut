from "%enlSqGlob/ui_library.nut" import *

let {verPadding} = require("%enlSqGlob/safeArea.nut")
let {levelIsLoading, dbgLoading} = require("%ui/hud/state/appState.nut")
let {mkAnimatedEllipsis} = require("loadingComponents.nut")

let color = Color(160,160,160,160)

let fontSize = hdpx(25)
let animatedEllipsis = mkAnimatedEllipsis(fontSize, color)

let animatedLoading = @(){
  vplace = ALIGN_BOTTOM
  hplace = ALIGN_RIGHT
  size = SIZE_TO_CONTENT
  flow = FLOW_HORIZONTAL
  watch = verPadding
  valign = ALIGN_CENTER
  pos = [-fsh(7),-verPadding.value-fsh(3)]
  children = [
    {
      rendObj = ROBJ_TEXT
      text = loc("Loading")
      fontSize = fontSize
      color = color
    }
    {size=[hdpx(4),0]}
    animatedEllipsis
  ]
}

let simpleLoading = {
  size = flex()
  children = animatedLoading
}

let loadingComp = {value = simpleLoading}
let loadingUiGeneration = Watched(0)

let function setLoadingComp(v){
  loadingComp.value = v
  loadingUiGeneration(loadingUiGeneration.value+1)
}

let showLoading = Computed(@() levelIsLoading.value || dbgLoading.value)

let loadingUI = @() {
  watch = [levelIsLoading, showLoading]
  size = flex()
  children = showLoading.value ? loadingComp.value : null
}

return {loadingUI, setLoadingComp, showLoading}
