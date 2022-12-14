from "%enlSqGlob/ui_library.nut" import *

let {body_txt} = require("%enlSqGlob/ui/fonts_style.nut")
let { get_setting_by_blk_path } = require("settings")
let { fabs } = require("math")
let { mkOnlineSaveData } = require("%enlSqGlob/mkOnlineSaveData.nut")
let mkSliderWithText = require("%ui/components/optionTextSlider.nut")
let optionCheckBox = require("%ui/components/optionCheckBox.nut")
let optionCombo = require("%ui/components/optionCombo.nut")
let optionSlider = require("%ui/components/optionSlider.nut")
let optionButton = require("%ui/components/optionButton.nut")
let optionHSelect = require("%ui/components/optionHSelect.nut")
let optionTextArea = require("%ui/components/optionTextArea.nut")
let optionSpinner = require("%ui/components/optionSpinner.nut")

let getOnlineSaveData = memoize(@(saveId, defValueFunc, validateFunc = @(v) v) mkOnlineSaveData(saveId, defValueFunc, validateFunc), 1)

let function defCmp(a, b) {
  if (typeof a != "float")
    return a == b
  let absSum = fabs(a) + fabs(b)
  return absSum < 0.00001 ? true : fabs(a - b) < 0.0001 * absSum
}

let loc_opt = @(s) loc($"option/{s}")

let function optionPercentTextSliderCtor(opt, group, xmbNode) {
  return mkSliderWithText(opt, group, xmbNode, @(v) "{0}%".subst(v * (opt?.mult ?? 1)))
}

let optionDisabledText = @(text) {
  size = [flex(), SIZE_TO_CONTENT]
  clipChildren = true
  rendObj = ROBJ_TEXT //do not made this stext as it can eat all atlas
  text
  color = Color(90,90,90)
}.__update(body_txt)

let mkDisableableCtor = @(disableWatch, enabledCtor, disabledCtor = optionDisabledText)
  function(opt, group, xmbNode) {
    let enabledWidget = enabledCtor(opt, group, xmbNode)
    return @() {
      watch = disableWatch
      size = flex()
      valign = ALIGN_CENTER
      children = disableWatch.value == null ? enabledWidget
        : disabledCtor(disableWatch.value)
    }
  }

let function optionCtor(opt){
  if (opt?.originalVal == null)
    opt.originalVal <- (type(opt?.blkPath)==type("")
      ? get_setting_by_blk_path(opt.blkPath)
      : opt?.var
        ? opt.var.value
        : null
    ) ?? opt?.defVal
  if ("convertFromBlk" in opt)
    opt.originalVal = opt.convertFromBlk(opt.originalVal)

  if ("var" not in opt)
    opt.var <- Watched(opt.originalVal)
  if ("isEqual" not in opt)
    opt.isEqual <- defCmp
  if ("typ" not in opt && "defVal" in opt)
    opt.typ <- type(opt.defVal)
  return freeze(opt)
}

let function isOption(opt){
  if ("isSeparator" in opt)
    return true
  if ("name" not in opt || "var" not in opt || "widgetCtor" not in opt)
    return false
  return true
}

return {
  defCmp
  optionCtor
  isOption
  loc_opt
  getOnlineSaveData
  mkSliderWithText
  optionPercentTextSliderCtor
  optionSlider
  optionCombo
  optionHSelect
  optionCheckBox
  optionButton
  optionTextArea
  optionDisabledText
  mkDisableableCtor
  optionSpinner
}
