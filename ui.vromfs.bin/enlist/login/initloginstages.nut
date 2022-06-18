from "%enlSqGlob/ui_library.nut" import *

let { sub_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let platform = require("%dngscripts/platform.nut")
let { setStagesConfig } = require("%enlist/login/login_chain.nut")
let defConfig = require("%enlist/login/defaultLoginStages.nut")
let matchingStage = require("%enlist/login/stages/matching.nut")
let pServerStage = require("pServerLoginStage.nut")
let { showStageErrorMsgBox } = require("%enlist/login/login_cb.nut")
let { infoBlock } = require("%enlist/login/ui/loginUiParams.nut")
let { activeTxtColor } = require("%enlSqGlob/ui/viewConst.nut")
let { disableNetwork } = require("%enlSqGlob/login_state.nut")
let textButton = require("%ui/components/textButton.nut")
let buyGameAccess = require("%enlist/login/buyGameAccess.nut")
let {
  isKZVersion, KZLoginStages
} = require("%enlist/login/chineseKongZhongVersion.nut")

if (isKZVersion)
  require("initKongZhongLogin.nut")

let mkOnInterrupt = @(defOnInterrupt) function(state) {
  if (state.stageResult?.error == "Maintenance") {
    showStageErrorMsgBox(loc("Maintenance"), state)
    return
  }

  if (state.stageResult?.error == "WASNOT_BOUGHT_BEFORE") {
    showStageErrorMsgBox(
      loc($"error/{state.stageResult.error}", ""),
      state,
      @(_) textButton.Bordered(
        loc($"{state.stageResult.error}/link/text", ""),
        buyGameAccess
      )
    )
    return
  }

  defOnInterrupt(state)
}

let config = function() {
  if (disableNetwork)
    return defConfig
  let res = clone defConfig
  res.stages = clone (isKZVersion ? KZLoginStages : res.stages)
  let idx = res.stages.indexof(matchingStage)
  if (idx == null || idx >= res.stages.len() - 1){
    res.stages.append(pServerStage)
  }
  else {
    res.stages.insert(idx + 1, pServerStage)
  }

  res.onInterrupt = mkOnInterrupt(res.onInterrupt)
  return res
}()

setStagesConfig(config)

let betaWarning = platform.is_xbox || platform.is_sony ? null : loc("hint/betaInfo")
if (betaWarning != null)
  infoBlock({
    size = [fsh(40), SIZE_TO_CONTENT]
    hplace = ALIGN_RIGHT
    vplace = ALIGN_BOTTOM
    rendObj = ROBJ_TEXTAREA
    behavior = Behaviors.TextArea
    color = activeTxtColor
    text = betaWarning
  }.__update(sub_txt))
