from "%enlSqGlob/ui_library.nut" import *

let { isNewDesign } = require("%enlSqGlob/designState.nut")
let { rowHeight, panelStyle, // comboStyle = {},
  textState, bgState, panelScreenOffset, innerBtnStyle = {}
} = require(isNewDesign.value ? "equipDesign.nut" : "equipDesignOld.nut")
let panel = require("%enlist/components/panel.nut")
//let comboBox = require("%ui/components/combobox.nut")
//let { getKindCfg } = require("%enlSqGlob/ui/soldierClasses.nut")
let { setTooltip } = require("%ui/style/cursors.nut")
let { FAButton } = require(isNewDesign.value
  ? "%ui/components/txtButton.nut" : "%ui/components/textButton.nut")
let { premiumImage } = require("%enlist/currency/premiumComp.nut")
let tooltipCtor = require("%ui/style/tooltipCtor.nut")
let { stateChangeSounds } = require("%ui/style/sounds.nut")

let { showNotFoundMsg } = require("%enlist/preset/notFoundMsg.nut")

let { addPopup } = require("%enlSqGlob/ui/popup/popupsState.nut")
let { curSoldierInfo } = require("%enlist/soldiers/model/curSoldiersState.nut")
let { presetEquipList, notFoundPresetItems, applyEquipmentPreset, saveEquipmentPreset,
  PreviewState, PresetTarget
} = require("%enlist/preset/presetEquipUtils.nut")

let frameColors = {
  [PreviewState.OK] = Color(20,255,10),
  [PreviewState.ERROR] = Color(255,150,150),
  [PreviewState.NONE] = null
}

let previewHighlightColor = @(previewState) frameColors[previewState ?? PreviewState.NONE]

let applyPresetTarget = Watched("soldier")
let previewPreset = Watched(null)

let processResult = @(text) addPopup({
  id = "preset_equip"
  text
})

let presetAction = function(presetCfg, presetTarget) {
  if (presetCfg?.onClick != null) {
    presetCfg.onClick()
    return
  }

  if (presetCfg?.fnApply == null) {
    return
  }

  if (presetTarget != PresetTarget.SOLDIER) {
    processResult("[applyEquipmentPreset] not implemented")
    return
  }

  if (notFoundPresetItems.value.len() > 0)
    showNotFoundMsg(notFoundPresetItems.value, @() applyEquipmentPreset(presetCfg, presetTarget))
  else
    applyEquipmentPreset(presetCfg, presetTarget)
}

/*
let presetTargetCombo = function(soldier) {
  let comboItems = [PresetTarget.SOLDIER].map(
    @(i) [i, loc($"btn/preset/{i}", { sKind = loc(getKindCfg(soldier?.sKind).locId) })] )

  return {
    size = [flex(), rowHeight]
    valign = ALIGN_CENTER
    children = comboBox(applyPresetTarget, comboItems, {
      xmbNode = XmbNode()
      style = comboStyle
    })
  }
}
*/

let actionBtn = @(icon, action, hint, onHover = null) FAButton(icon, action, {
  btnWidth = rowHeight
  btnHeight = rowHeight
  onHover = function(on) {
    if (onHover != null)
      onHover(on)
    setTooltip(!on ? null : isNewDesign.value
      ? tooltipCtor({ rendObj = ROBJ_TEXT, text = hint }) : hint)
  }
}.__update(innerBtnStyle))

let btnSavePreset = @(presetCfg) presetCfg?.fnSave == null ? null
  : actionBtn("save",
      function() {
        saveEquipmentPreset(presetCfg)
        processResult(loc("preset/equip/saved"))
      },
      loc("squads/presets/save"))

let btnApplyPreset = @(presetCfg, presetTarget)
  ((presetCfg?.isLockedPrem ?? false) || presetCfg?.fnApply == null) ? null
    : actionBtn("check",
        @() presetAction(presetCfg, presetTarget),
        loc("squads/presets/apply"),
        @(on) previewPreset(on ? presetCfg : null))

let makePresetList = function(presetCfgList, soldier, presetTarget) {
  if (soldier == null)
    return []

  let presetList = presetCfgList.map(function(presetCfg) {
    return watchElemState(@(sf) {
      size = [flex(), rowHeight]
      flow = FLOW_HORIZONTAL
      rendObj = ROBJ_BOX
      behavior = Behaviors.Button
      children = [
        {
          size = [flex(), rowHeight]
          behavior = Behaviors.Button
          onHover = @(on) previewPreset(on ? presetCfg : null)
          onClick = @() presetAction(presetCfg, presetTarget)
          sound = stateChangeSounds
          flow = FLOW_HORIZONTAL
          children = [
            {
              rendObj = ROBJ_TEXT
              valign = ALIGN_CENTER
              behavior = Behaviors.Marquee
              text = presetCfg.locId
              scrollOnHover = true
            }.__update(textState(sf, presetCfg?.isLockedPrem ?? false))
            presetCfg?.isLockedPrem ? premiumImage(rowHeight * 0.7, { pos = [0, hdpx(7)]}) : null
          ]
        }
        sf & S_HOVER ? btnApplyPreset(presetCfg, presetTarget) : null
        sf & S_HOVER ? btnSavePreset(presetCfg) : null
      ]
    }.__update(bgState(sf, presetCfg?.isLockedPrem ?? false)))
  })
  return presetList
}

let presetEquipButtons = @(presetCmpList, soldier, presetTarget) {
  rendObj = ROBJ_BOX
  flow = FLOW_VERTICAL
  halign = ALIGN_CENTER
  size = [flex(), SIZE_TO_CONTENT]
  // children = [presetTargetCombo(soldier)].extend(
  //   makePresetList(presetCmpList, soldier, presetTarget))
  children = makePresetList(presetCmpList, soldier, presetTarget)
}

let content = @() {
  watch = [presetEquipList, curSoldierInfo, applyPresetTarget]
  size = [hdpx(385), SIZE_TO_CONTENT]
  children = presetEquipButtons(presetEquipList.value, curSoldierInfo.value,
    applyPresetTarget.value)
}

const WND_UID = "equipPresetView"
let presetEquipPanel = panel()
let { setPosition } = presetEquipPanel

let mkPresetEquipBlock = function(event) {
  let offset = panelScreenOffset
  let x = event.targetRect.l + offset[0]
  let y = event.targetRect.t + offset[1]
  setPosition([x, y])
  presetEquipPanel.open(content, {
    key = WND_UID
    style = panelStyle
  })

  return WND_UID
}

return {
  closeEquipPresets = @() presetEquipPanel.close()
  mkPresetEquipBlock
  previewPreset
  previewHighlightColor
}
