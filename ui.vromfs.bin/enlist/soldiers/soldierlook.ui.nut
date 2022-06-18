from "%enlSqGlob/ui_library.nut" import *

let faComp = require("%ui/components/faComp.nut")
let { smallPadding, bigPadding } = require("%enlSqGlob/ui/viewConst.nut")
let { comboboxBorderColor } = require("%ui/style/colors.nut")
let { txt, noteTextArea } = require("%enlSqGlob/ui/defcomps.nut")
let {
  soldierReset, soldierResetAll, mkSoldierDisarmed, setSoldierDisarmed, allIdleAnims,
  mkSoldierIdle, setSoldierIdle, allSoldierHeads, mkSoldierHead, setSoldierHead,
  FACE_ID_COUNT, mkSoldierFace, setSoldierFace, mkSoldierSlotsSwap, setSoldierSlotsSwap,
  faceGenOverrides, faceGenRandomize, faceGenAll, faceGenSave
} = require("%enlist/scene/soldier_overrides.nut")
let checkBox = require("%ui/components/checkbox.nut")
let comboBox = require("%ui/components/combobox.nut")
let { Horiz } = require("%ui/components/slider.nut")
let textButton = require("%ui/components/textButton.nut")
let { show } = require("%enlist/components/msgbox.nut")

const debugUiColor = 0xFFAA0000

let idleAnims = Computed(@() [null].extend(allIdleAnims.value))
let soldierHeads = Computed(@() [null].extend(allSoldierHeads.value))
let hasFaceGenOverrides = Computed(@() faceGenOverrides.value.len() > 0)

let mkWatchableField = @(watchable) {
  rendObj = ROBJ_BOX
  size = [ph(100), flex()]
  borderWidth = hdpx(1)
  borderRadius = hdpx(3)
  borderColor = comboboxBorderColor
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  children = @() {
    watch = watchable
    rendObj = ROBJ_TEXT
    text = watchable.value
  }
}

let debugFeatureWarning = {
  rendObj = ROBJ_FRAME
  size = [flex(), SIZE_TO_CONTENT]
  valign = ALIGN_CENTER
  color = debugUiColor
  borderWidth = hdpx(4)
  padding = bigPadding * 2
  gap = bigPadding
  flow = FLOW_HORIZONTAL
  children = [
    faComp("exclamation-triangle", { color = debugUiColor, fontSize = hdpx(24) })
    noteTextArea("This is debug feature, all changes made will be lost on game restart. The changes are applied to the currently selected soldier, so you can individually customize the appearance of the entire squad.")
  ]
}

let optCheckbox = @(label, value, setValue)
  checkBox(value, label, { setValue })

let optCombobox = @(label, value, update, list) {
  size = [flex(), fsh(4)]
  flow = FLOW_HORIZONTAL
  gap = bigPadding
  valign = ALIGN_CENTER
  children = [
    txt(label)
    comboBox({ value, update }, list)
  ]
}

let function optSlider(label, value, minVal, maxVal, setValue) {
  let safeValue = Computed(@() value.value ?? minVal)
  return {
    size = [flex(), fsh(4)]
    flow = FLOW_HORIZONTAL
    gap = bigPadding
    valign = ALIGN_CENTER
    children = [
      txt(label)
      Horiz(safeValue, {
        min = minVal
        max = maxVal
        pageScroll = 1.0 / (maxVal - minVal)
        setValue
        ignoreWheel = false
      })
      mkWatchableField(value)
    ]
  }
}

let warnResetAll = @() show({
  text = "This will clear all soldier override settings. Are you sure?"
  buttons = [
    { text = "Ok", action = soldierResetAll }
    { text = "Cancel", isCancel = true, isCurrent = true }
  ]
})

let function saveFaceGenAndWarn() {
  let fileName = faceGenSave()
  show({
    text = $"All soldiers' face generation properties were saved to file {fileName}.\nYou should manually move it to the proper location."
  })
}

let mkBtnStyle = @(isEnabled) {
  size = [flex(), SIZE_TO_CONTENT]
  margin = 0
  textMargin = fsh(1)
  isEnabled
}

let mkFaceButtons = @(headWatch, faceWatch) @() {
  watch = [hasFaceGenOverrides, headWatch, faceWatch]
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_HORIZONTAL
  gap = smallPadding
  children = [
    textButton("Save all", saveFaceGenAndWarn, mkBtnStyle(hasFaceGenOverrides.value))
    textButton("Fill faces", @() faceGenAll(headWatch.value), mkBtnStyle(headWatch.value != null))
    textButton("Reroll face", @() faceGenRandomize(headWatch.value, faceWatch.value),
      mkBtnStyle(headWatch.value != null && faceWatch.value != null))
  ]
}

let mkResetButtons = @(guid) {
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_HORIZONTAL
  children = [
    textButton("Reset all soldiers", warnResetAll,
      { margin = 0, borderWidth = hdpx(2), borderColor = debugUiColor })
    { size = flex() }
    textButton("Reset", @() soldierReset(guid), { margin = 0 })
  ]
}

let function soldierLook(soldier) {
  let { guid } = soldier
  let soldierHeadId = mkSoldierHead(guid)
  let soldierFaceId = mkSoldierFace(guid)
  return {
    size = flex()
    flow = FLOW_VERTICAL
    gap = smallPadding
    children = [
      debugFeatureWarning
      optCombobox("Idle animation", mkSoldierIdle(guid),
        @(val) setSoldierIdle(guid, val), idleAnims)
      optCombobox("Custom head", soldierHeadId,
        @(val) setSoldierHead(guid, val), soldierHeads)
      optSlider("Custom face", soldierFaceId, -1, FACE_ID_COUNT - 1,
        @(val) setSoldierFace(guid, val))
      mkFaceButtons(soldierHeadId, soldierFaceId)
      optCheckbox("Remove weapon", mkSoldierDisarmed(guid),
        @(val) setSoldierDisarmed(guid, val))
      optCheckbox("Swap primary and secondary slots", mkSoldierSlotsSwap(guid),
        @(val) setSoldierSlotsSwap(guid, val))
      mkResetButtons(guid)
    ]
  }
}

return kwarg(soldierLook)