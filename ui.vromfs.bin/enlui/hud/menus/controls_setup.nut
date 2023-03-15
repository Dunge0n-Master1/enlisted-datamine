import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let {h2_txt, body_txt, fontawesome} = require("%enlSqGlob/ui/fonts_style.nut")
let {round_by_value} = require("%sqstd/math.nut")
let {DEFAULT_TEXT_COLOR, CONTROL_BG_COLOR, HIGHLIGHT_COLOR} = require("%ui/hud/style.nut")
let cursors = require("%ui/style/cursors.nut")
let JB = require("%ui/control/gui_buttons.nut")
let {safeAreaHorPadding} = require("%enlSqGlob/safeArea.nut")
let msgbox = require("%ui/components/msgbox.nut")
let textButton = require("%ui/components/textButton.nut")
let scrollbar = require("%ui/components/scrollbar.nut")
let checkbox = require("%ui/components/checkbox.nut")
let slider = require("%ui/components/slider.nut")
let mkSliderWithText = require("%ui/components/optionTextSlider.nut")
let settingsHeaderTabs = require("%ui/components/settingsHeaderTabs.nut")
let fa = require("%ui/components/fontawesome.map.nut")
let {dtext} = require("%ui/components/text.nut")
let console = require("console")
let { buildElems, buildDigitalBindingText, isValidDevice,eventTypeLabels,
      textListFromAction, getSticksText } = require("%ui/control/formatInputBinding.nut")

let dainput = require("dainput2")
let {format_ctrl_name} = dainput
let {get_action_handle} = dainput
let { BTN_pressed, BTN_pressed_long, BTN_pressed2, BTN_pressed3,
          BTN_released, BTN_released_long, BTN_released_short } = dainput
let select = require("%ui/components/select.nut")
let locByPlatform = require("%enlSqGlob/locByPlatform.nut")

let game_name = require("app").get_game_name()

let control = require("control")
let DataBlock = require("DataBlock")
let { platformId, is_pc, is_xbox, is_sony } = require("%dngscripts/platform.nut")


let controlsSettingOnlyForGamePad = Watched(is_xbox || is_sony)
let {wasGamepad, isGamepad, ControlsTypes } = require("%ui/control/active_controls.nut")
let {
  setUiClickRumble,
  isUiClickRumbleEnabled,
  setInBattleRumble,
  isInBattleRumbleEnabled,
  isAimAssistExists,
  isAimAssistEnabled,
  setAimAssist,
  stick0_dz,
  set_stick0_dz,
  stick1_dz,
  set_stick1_dz,
  aim_smooth,
  aim_smooth_set,
  use_gamepad_state,
  set_use_gamepad
} = require("%ui/hud/state/controls_online_storage.nut")
let {
  importantGroups, generation, nextGeneration, availablePresets, haveChanges, Preset,
  getActionsList, getActionTags, mkSubTagsFind
} = require("controls_state.nut")
let { voiceChatEnabled } = require("%enlSqGlob/voiceChatGlobalState.nut")
let { EventControlsMenuToggle } = require("dasevents")


let MenuRowBgOdd   = Color(20, 20, 20, 20)
let MenuRowBgEven  = Color(0, 0, 0, 20)
let MenuRowBgHover = Color(40, 40, 40, 40)

let function menuRowColor (sf, isOdd) {
  return (sf & S_HOVER)
         ? MenuRowBgHover
         : isOdd ? MenuRowBgOdd : MenuRowBgEven
}

let function resetC0BindingsForOnlyGamepadsPlatforms(defaultPreset) {
  if (controlsSettingOnlyForGamePad.value) {
    let origBlk = DataBlock()
    dainput.save_user_config(origBlk, true)
    origBlk.removeBlock("c0") //remove mouse/keyboard bindings
    origBlk.removeBlock("c2")
    let basePreset = origBlk.getStr("preset", "")
    if (basePreset == "")
      return
    let splitedPresetPath = basePreset.split("~")
    let presetPath = splitedPresetPath?[0] ?? defaultPreset
    let presetPlatform = splitedPresetPath?[1] ?? ""
    let newBasePresetName = $"{presetPath}~{platformId}"
    if (presetPlatform.tolower() == platformId.tolower() || availablePresets.value.findvalue(@(v) v.preset.indexof(newBasePresetName)!=null) == null)
      return
    else {
      origBlk.setStr("preset", newBasePresetName)
      log($"Reset c0 and c2 bindings in customized preset for only gamepad platform, switch {basePreset} to {newBasePresetName}")
    }
    dainput.load_user_config(origBlk)
    control.save_config()
    haveChanges(true)
  }
}

console.register_command(function(){
  controlsSettingOnlyForGamePad(false)
  let origBlk = DataBlock()
  origBlk.setStr("preset", "content/{0}/config/{0}.default".subst(game_name))
  dainput.load_user_config(origBlk)
  control.save_config()
  haveChanges(true)
}, "input.init_pc_preset")

let findSelectedPreset = function(selected) {
  let defaultPreset = dainput.get_user_config_base_preset()
  resetC0BindingsForOnlyGamepadsPlatforms(defaultPreset)
  return availablePresets.value.findvalue(@(v) selected.indexof(v.preset)!=null) ??
         availablePresets.value.findvalue(@(v) ($"{defaultPreset}~{platformId}").indexof(v.preset)!=null) ??
         Preset(defaultPreset)
}
let selectedPreset = Watched(findSelectedPreset(dainput.get_user_config_base_preset()))
let currentPreset =  Watched(selectedPreset.value)
currentPreset.subscribe(@(v) selectedPreset(findSelectedPreset(v.preset)))
let updateCurrentPreset = @() currentPreset(findSelectedPreset(dainput.get_user_config_base_preset()))

let actionRecording = Watched(null)
let configuredAxis = Watched(null)
let configuredButton = Watched(null)

let showControlsMenu = mkWatched(persist, "showControlsMenu", false)
//gui_scene.xmbMode.subscribe(@(v) vlog($"XMB mode = {v}"))

showControlsMenu.subscribe(@(isShown) ecs.g_entity_mgr.broadcastEvent(EventControlsMenuToggle({isShown})))

let function isGamepadColumn(col) {
  return col == 1
}

let function locActionName(name){
  return name!= null ? loc("/".concat("controls", name), name) : null
}

let function doesDeviceMatchColumn(dev_id, col) {
  if (dev_id==dainput.DEV_kbd || dev_id==dainput.DEV_pointing)
    return !isGamepadColumn(col)
  if (dev_id==dainput.DEV_gamepad || dev_id==dainput.DEV_joy)
    return isGamepadColumn(col)
  return false
}

let btnEventTypesMap = {
  [BTN_pressed] = "pressed",
  [BTN_pressed_long] = "pressed_long",
  [BTN_pressed2] = "pressed2",
  [BTN_pressed3] = "pressed3",
  [BTN_released] = "released",
  [BTN_released_long] = "released_long",
  [BTN_released_short] = "released_short",
}

let findAllowBindingsSubtags = mkSubTagsFind("allowed_bindings=")
let getAllowedBindingsTypes = memoize(function(ah) {
  let allowedbindings = findAllowBindingsSubtags(ah)
  if (allowedbindings==null)
    return btnEventTypesMap.keys()
  return btnEventTypesMap
    .filter(@(name, _eventType) allowedbindings==null || allowedbindings.indexof(name)!=null)
    .keys()
})


local tabsList = []
let isActionDisabledToCustomize = memoize(
  @(action_handler) getActionTags(action_handler).indexof("disabled") != null)

let function makeTabsList() {
  tabsList = [ {id="Options" text=loc("controls/tab/Control")} ]
  let isVoiceChatAvailable = is_pc && voiceChatEnabled.value
  let isReplayAvailable = is_pc
  let bindingTabs = [
    {id="Movement" text=loc("controls/tab/Movement")}
    {id="Weapon" text=loc("controls/tab/Weapon")}
    {id="View" text=loc("controls/tab/View")}
    {id="Squad" text=loc("controls/tab/Squad")}
    {id="Vehicle" text=loc("controls/tab/Vehicle")}
    {id="Plane" text=loc("controls/tab/Plane")}
    {id="Drone" text=loc("controls/tab/Drone")}
    {id="Other" text=loc("controls/tab/Other")}
    {id="UI" text=loc("controls/tab/UI")}
    {id="VoiceChat" text=loc("controls/tab/VoiceChat") isEnabled = @() isVoiceChatAvailable }
    {id="Spectator" text=loc("controls/tab/Spectator")}
    {id="Replay" text=loc("controls/tab/Replay") isEnabled = @() isReplayAvailable }
  ]

  let hasActions = {}
  let total = dainput.get_actions_count()
  for (local i = 0; i < total; i++) {
    let ah = dainput.get_action_handle_by_ord(i)
    if (!dainput.is_action_internal(ah)){
      let tags = getActionTags(ah)
      foreach (tag in tags)
        hasActions[tag] <- true
    }
  }
  tabsList.extend(bindingTabs.filter(@(t) (hasActions?[t.id] ?? false) && (t?.isEnabled?() ?? true)))
}
controlsSettingOnlyForGamePad.subscribe(@(_) makeTabsList())
makeTabsList()


let currentTab = mkWatched(persist, "currentTab", tabsList[0].id)
let selectedBindingCell = mkWatched(persist, "selectedBindingCell")
let selectedAxisCell = mkWatched(persist, "selectedAxisCell")

isGamepad.subscribe(function(isGp) {
  if (!isGp)
    return
  selectedBindingCell(null)
  selectedAxisCell(null)
})

let function isEscape(blk) {
  return blk.getInt("dev", dainput.DEV_none) == dainput.DEV_kbd
      && blk.getInt("btn", 0) == 1
}

let blkPropRemap = {
  minXBtn = "xMinBtn", maxXBtn = "xMaxBtn", minYBtn = "yMinBtn", maxYBtn = "yMaxBtn"
}

let pageAnim =  [
  { prop=AnimProp.opacity, from=0, to=1, duration=0.2, play=true, easing=InOutCubic}
  { prop=AnimProp.opacity, from=1, to=0, duration=0.2, playFadeOut=true, easing=InOutCubic}
]

let function startRecording(cell_data) {
  if (cell_data.singleBtn || cell_data.tag == "modifiers")
    dainput.start_recording_bindings_for_single_button()
  else
    dainput.start_recording_bindings(cell_data.ah)
  actionRecording(cell_data)
}

let function makeBgToggle(initial=true) {
  local showBg = !initial
  let function toggleBg() {
    showBg = !showBg
    return showBg
  }
  return toggleBg
}

let function set_single_button_analogue_binding(ah, col, actionProp, blk) {
  let stickBinding = dainput.get_analog_stick_action_binding(ah, col)
  let axisBinding = dainput.get_analog_axis_action_binding(ah, col)
  let binding = stickBinding ?? axisBinding
  if (binding != null) {
    binding[actionProp].devId = blk.getInt("dev", 0)
    binding[actionProp].btnId = blk.getInt("btn", 0)
    if (blk.paramCount()+blk.blockCount() == 0) {
      // empty blk, so clear bindings
      binding.devId = dainput.DEV_none
      if (axisBinding != null)
        axisBinding.axisId = 0
      if (stickBinding != null) {
        stickBinding.axisXId = 0
        stickBinding.axisYId = 0
      }
    } else if (binding.devId == dainput.DEV_none && (axisBinding != null || stickBinding != null))
      binding.devId = dainput.DEV_nullstub

    if (binding.devId != dainput.DEV_none && binding.maxVal == 0) // restore maxVal when needed
      binding.maxVal = 1
  }
}

let function loadOriginalBindingParametersTo(blk, ah, col) {
  let origBlk = DataBlock()
  dainput.get_action_binding(ah, col, origBlk)

  let actionType = dainput.get_action_type(ah)

  blk.setReal("dzone", origBlk.getReal("dzone", 0.0))
  blk.setReal("nonlin", origBlk.getReal("nonlin", 0.0))
  blk.setReal("maxVal", origBlk.getReal("maxVal", 1.0))
  if ((actionType & dainput.TYPEGRP__MASK) == dainput.TYPEGRP_STICK)
    blk.setReal("sensScale", origBlk.getReal("sensScale", 1.0))
}

let function loadPreviousBindingParametersTo(blk, ah, col) {
  let prevBinding = dainput.get_digital_action_binding(ah, col)

  let actionType = dainput.get_action_type(ah)

  if ((actionType & dainput.TYPEGRP__MASK) == dainput.TYPEGRP_DIGITAL)
    blk.setBool("stickyToggle", prevBinding.stickyToggle)
}

let function checkRecordingFinished() {
  if (dainput.is_recording_complete()) {
    let cellData = actionRecording.value
    actionRecording(null)
    let ah = cellData?.ah

    let blk = DataBlock()
    let ok = dainput.finish_recording_bindings(blk)

    let devId = blk.getInt("dev", dainput.DEV_none)
    if (ok && ah!=null && devId!=dainput.DEV_none && !isEscape(blk)) {
      let col = cellData?.column
      if (doesDeviceMatchColumn(devId, col)) {
        gui_scene.clearTimer(callee())

        local checkConflictsBlk
        if (cellData.singleBtn) {
          checkConflictsBlk = DataBlock()
          dainput.get_action_binding(ah, col, checkConflictsBlk)
          let btnBlk = checkConflictsBlk.addBlock(blkPropRemap?[cellData.actionProp] ?? cellData.actionProp)
          btnBlk.setParamsFrom(blk)
        }
        else {
          checkConflictsBlk = blk
        }

        let function applyBinding() {
          if (cellData.singleBtn) {
            set_single_button_analogue_binding(ah, col, cellData.actionProp, blk)
          }
          else if (cellData.tag == "modifiers") {
            let binding = dainput.get_analog_stick_action_binding(ah, cellData.column)
                          ?? dainput.get_analog_axis_action_binding(ah, cellData.column)

            let btn = dainput.SingleButtonId()
            btn.devId = devId
            btn.btnId = blk.getInt("btn", 0)
            binding.mod = [btn]
          }
          else {
            loadOriginalBindingParametersTo(blk, ah, col)
            loadPreviousBindingParametersTo(blk, ah, col)
            dainput.set_action_binding(ah, col, blk)
            let binding = dainput.get_digital_action_binding(ah, col)
            if (binding?.eventType)
              binding.eventType = getAllowedBindingsTypes(ah)[0]
          }
          nextGeneration()
          haveChanges(true)
        }

        let conflicts = dainput.check_bindings_conflicts(ah, checkConflictsBlk)
        if (conflicts == null) {
          applyBinding()
        } else {
          let actionNames = conflicts.map(@(a) dainput.get_action_name(a.action))
          let localizedNames = actionNames.map(@(a) loc($"controls/{a}"))
          let actionsText = ", ".join(localizedNames)
          let messageText = loc("controls/binding_conflict_prompt", "This conflicts with {actionsText}. Bind anyway?", {
            actionsText = actionsText
          })
          msgbox.show({
            text = messageText
            buttons = [
              { text = loc("Yes"), action = applyBinding }
              { text = loc("No") }
            ]
          })
        }
      } else {
        startRecording(cellData)
      }
    }
  }
}


let function cancelRecording() {
  gui_scene.clearTimer(checkRecordingFinished)
  actionRecording(null)

  let blk = DataBlock()
  dainput.finish_recording_bindings(blk)
}



let mediumText = @(text, params={}) dtext(text, {color = DEFAULT_TEXT_COLOR,}.__update(body_txt, params))

let function recordingWindow() {
  //local text = loc("controls/recording", "Press a button (or move mouse / joystick axis) to bind action to")
  local text
  let cellData = actionRecording.value
  let name = cellData?.name
  if (cellData) {
    let actionType = dainput.get_action_type(cellData.ah)
    if ( (actionType & dainput.TYPEGRP__MASK) == dainput.TYPEGRP_DIGITAL
          || cellData.actionProp!=null || cellData.tag == "modifiers") {
      if (isGamepadColumn(cellData.column))
        text = loc("controls/recording_digital_gamepad", "Press a gamepad button to bind action to")
      else
        text = loc("controls/recording_digital_keyboard", "Press a button on keyboard to bind action to")
    }
    else if (isGamepadColumn(cellData.column)) {
      text = loc("controls/recording_analogue_joystick", "Move stick or press button to bind action to")
    } else {
      text = loc("controls/recording_analogue_mouse", "Move mouse to bind action")
    }
  }
  return {
    size = flex()
    rendObj = ROBJ_WORLD_BLUR_PANEL
    color = Color(120,120,120,250)
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    stopHotkeys = true
    stopMouse = true
    cursor = null
    hotkeys = [["^Esc", cancelRecording]]
    onDetach = cancelRecording
    watch = actionRecording
    flow = FLOW_VERTICAL
    gap = fsh(8)
    children = [
      {size=[0, flex(3)]}
      dtext(locActionName(name), {color = Color(100,100,100)}.__update(h2_txt))
      mediumText(text, {
        function onAttach() {
          gui_scene.clearTimer(checkRecordingFinished)
          gui_scene.setInterval(0.1, checkRecordingFinished)
        }
        function onDetach() {
          gui_scene.clearTimer(checkRecordingFinished)
        }
      })
      {size=[0, flex(5)]}
    ]
  }
}

let function saveChanges() {
  control.save_config()
  haveChanges(false)
}

let function applyPreset(text, target=null) {
  let function doReset() {
    if (target)
      dainput.reset_user_config_to_preset(target.preset, false)
    else
      control.reset_to_default()
    saveChanges()
    nextGeneration()
  }

  msgbox.show({
    text
    children = dtext(loc("controls/preset", {
      preset = target?.name ?? selectedPreset.value.name
    }), {margin = hdpx(50)})
    buttons = [
      { text = loc("Yes"), action = doReset }
      { text = loc("No") }
    ]
  })
}

let function resetToDefault() {
  let text = loc("controls/resetToDefaultsConfirmation")
  applyPreset(text)
}

let function changePreset(target) {
  let text = loc("controls/changeControlsPresetConfirmation")
  applyPreset(text, target)
}

let function clearBinding(cellData){
  haveChanges(true)
  if (cellData.singleBtn) {
    set_single_button_analogue_binding(cellData.ah, cellData.column, cellData.actionProp, DataBlock())
  } else if (cellData.tag == "modifiers") {
    let binding = dainput.get_analog_stick_action_binding(cellData.ah, cellData.column)
                  ?? dainput.get_analog_axis_action_binding(cellData.ah, cellData.column)
    binding.mod = []
  } else {
    let blk = DataBlock()
    loadOriginalBindingParametersTo(blk, cellData.ah, cellData.column)
    dainput.set_action_binding(cellData.ah, cellData.column, blk)
  }
}

let function discardChanges() {
  if (!haveChanges.value)
    return
  control.restore_saved_config()
  nextGeneration()
  haveChanges(false)
}

let function actionButtons() {
  local children = null
  let cellData = selectedBindingCell.value

  if (cellData != null) {
    let actionType = dainput.get_action_type(cellData.ah)
    let actionTypeGroup = actionType & dainput.TYPEGRP__MASK

    if (!isActionDisabledToCustomize(cellData.ah)) {
      children = [
        textButton(loc("controls/clearBinding"), function() {
          clearBinding(cellData)
          nextGeneration()
        }, { hotkeys = [["^J:X"]], skipDirPadNav = true })
      ]

      if (actionTypeGroup == dainput.TYPEGRP_AXIS || actionTypeGroup == dainput.TYPEGRP_STICK) {
        children.append(
          textButton(loc("controls/axisSetup", "Axis setup"),
            function() { configuredAxis(cellData) },
            { hotkeys = [[$"^{JB.A}", { description = loc("controls/axisSetup") }]], skipDirPadNav = true })
        )
      }
      else if (actionTypeGroup == dainput.TYPEGRP_DIGITAL) {
        children.append(
          textButton(loc("controls/buttonSetup", "Button setup"),
            function() { configuredButton(cellData) },
            { hotkeys = [["^J:Y"]], skipDirPadNav = true })

          textButton(loc("controls/bindBinding"),
            function() { startRecording(cellData) },
            { hotkeys = [[$"^{JB.A}", { description = loc("controls/bindBinding") }]], skipDirPadNav = true })
        )
      }
    }
  }
  return {
    watch = selectedBindingCell
    children
    flow = FLOW_HORIZONTAL
  }
}

let function collectBindableColumns() {
  let nColumns = dainput.get_actions_binding_columns()
  let colRange = []
  for (local i=0; i<nColumns; ++i) {
    if (!controlsSettingOnlyForGamePad.value || isGamepadColumn(i))
      colRange.append(i)
  }
  return colRange
}

let function getNotBoundActions() {
  let importantTabs = importantGroups.value

  let colRange = collectBindableColumns()
  let notBoundActions = {}

  for (local i = 0; i < dainput.get_actions_count(); ++i) {
    let ah = dainput.get_action_handle_by_ord(i)
    if (dainput.is_action_internal(ah))
      continue

    let actionGroups = getActionTags(ah)
    local isActionInImportantGroup = false
    foreach (actionGroup in actionGroups) {
      if (importantTabs.indexof(actionGroup) != null && !isActionDisabledToCustomize(ah))
        isActionInImportantGroup = true
    }

    if (actionGroups.indexof("not_important") != null)
      isActionInImportantGroup = false

    if (actionGroups.indexof("important") != null)
      isActionInImportantGroup = true

    if (!isActionInImportantGroup)
      continue

    local someBound = false
    switch (dainput.get_action_type(ah) & dainput.TYPEGRP__MASK) {
      case dainput.TYPEGRP_DIGITAL: {
        let bindings = colRange.map(@(col, _) dainput.get_digital_action_binding(ah, col))
        foreach (val in bindings)
          if (isValidDevice(val.devId) || val.devId == dainput.DEV_nullstub) {
            someBound = true
            break
          }
        break
      }
      case dainput.TYPEGRP_AXIS: {
        let axisBinding = colRange.map(@(col, _) dainput.get_analog_axis_action_binding(ah, col))
        foreach (val in axisBinding) {
          if (val.devId == dainput.DEV_pointing || val.devId == dainput.DEV_joy || val.devId == dainput.DEV_gamepad || val.devId == dainput.DEV_nullstub) {
            // using device axis
            someBound = true
            break
          }

          // using 2 digital buttons
          if (isValidDevice(val.minBtn.devId) && isValidDevice(val.maxBtn.devId)) {
            someBound = true
            break
          }

        }
        break
      }
      case dainput.TYPEGRP_STICK: {
        let stickBinding = colRange.map(@(col, _) dainput.get_analog_stick_action_binding(ah, col))
        foreach (val in stickBinding) {
          if (val.devId == dainput.DEV_pointing || val.devId == dainput.DEV_joy || val.devId == dainput.DEV_gamepad || val.devId == dainput.DEV_nullstub) {
            someBound = true
            break
          }
          if (isValidDevice(val.maxXBtn.devId) && isValidDevice(val.minXBtn.devId)
            && isValidDevice(val.maxYBtn.devId) && isValidDevice(val.minYBtn.devId)) {
            someBound = true
            break
          }
        }
        break
      }
    }

    if (!someBound) {
      let actionName = dainput.get_action_name(ah)
      let actionGroup = actionGroups?[0]
      if (!notBoundActions?[actionGroup])
        notBoundActions[actionGroup] <- { header = loc($"controls/tab/{actionGroup}"), controls = [] }

      notBoundActions[actionGroup].controls.append(loc($"controls/{actionName}", actionName))
    }
  }

  if (notBoundActions.len() == 0)
    return null

  let ret = []
  foreach (action in notBoundActions) {
    ret.append($"\n\n{action.header}:\n")
    ret.append(", ".join(action.controls))
  }

  return "".join(ret)
}

let function onDiscardChanges() {
  msgbox.show({
    text = loc("settings/onCancelChangingConfirmation")
    buttons = [
      { text=loc("Yes"), action = discardChanges }
      { text=loc("No") }
    ]
  })
}

let skipDirPadNav = { skipDirPadNav = true }
let applyHotkeys = { hotkeys = [[$"^{JB.B} | J:Start | Esc", { description={skip=true} }]] }

let onClose = @() showControlsMenu(false)

let function mkWindowButtons(width) {
  let function onApply() {
    let notBoundActions = is_pc ? getNotBoundActions() : null
    if (notBoundActions == null) {
      saveChanges()
      onClose()
      return
    }

    msgbox.show({
      text = "".concat(loc("controls/warningUnmapped"), notBoundActions)
      buttons = [
        { text=loc("Ok"),
          action = function() {
            saveChanges()
            onClose()
          }
        }
        { text = loc("Cancel"), action = @() null }
      ]
    })
  }

  return @() {
    watch = haveChanges
    size = [flex(), SIZE_TO_CONTENT]
    vplace = ALIGN_BOTTOM
    hplace = ALIGN_RIGHT
    flow = FLOW_HORIZONTAL
    halign = ALIGN_RIGHT
    valign = ALIGN_CENTER
    rendObj = ROBJ_SOLID
    color = CONTROL_BG_COLOR

    children = wrap([
      textButton(loc("controls/btnResetToDefaults"), resetToDefault, skipDirPadNav)
      haveChanges.value ? textButton(loc("mainmenu/btnDiscard"), onDiscardChanges, skipDirPadNav) : null
      {size = [flex(), 0]}
      actionButtons
      textButton(loc(haveChanges.value ? "mainmenu/btnApply" : "Ok"), onApply, skipDirPadNav.__merge(applyHotkeys, {hplace = ALIGN_RIGHT}))
    ], {width, flowElemProto = {size = [flex(), SIZE_TO_CONTENT] halign = ALIGN_RIGHT}})
  }
}


let function bindingTextFunc(text) {
  return {
    text
    color = DEFAULT_TEXT_COLOR
    rendObj = ROBJ_TEXT
    padding = hdpx(4)
  }.__update(body_txt)
}


let function mkActionRowLabel(name, group=null){
  return {
    rendObj = ROBJ_TEXT
    color = DEFAULT_TEXT_COLOR
    text = locActionName(name)
    margin = [0, fsh(1), 0, 0]
    size = [flex(1.5), SIZE_TO_CONTENT]
    halign = ALIGN_RIGHT
    group
  }.__update(body_txt)
}

let function mkActionRowCells(label, columns){
  let children = [label].extend(columns)
  if (columns.len() < 2)
    children.append({size=[flex(0.75), 0]})
  return children
}

let function makeActionRow(_ah, name, columns, xmbNode, showBgGen) {
  let group = ElemGroup()
  let isOdd = showBgGen()
  let label = mkActionRowLabel(name, group)
  let children = mkActionRowCells(label, columns)
  return watchElemState(@(sf) {
    xmbNode
    key = name
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    behavior = Behaviors.Button
    skipDirPadNav = true
    children
    rendObj = ROBJ_SOLID
    color = menuRowColor(sf, isOdd)
    group
  })
}


let bindingColumnCellSize = [flex(1), fontH(240)]

let function isCellSelected(cell_data, selection) {
  let selected = selection.value
  return (selected!=null) && selected.column==cell_data.column && selected.ah==cell_data.ah
    && selected.actionProp==cell_data.actionProp && selected.tag==cell_data.tag
}

let function showDisabledMsgBox(){
  return msgbox.show({
    text = loc("controls/bindingDisabled")
    buttons = [
      { text = loc("Ok")}
    ]
  })
}


let function bindedComp(elemList, group=null){
  return {
     group = group ?? ElemGroup()
     behavior = Behaviors.Marquee
     scrollOnHover = true
     size = SIZE_TO_CONTENT
     maxWidth = pw(100)
     flow = FLOW_HORIZONTAL
     valign = ALIGN_CENTER
     children = buildElems(elemList, {textFunc = bindingTextFunc, eventTypesAsTxt = true})
  }
}


let function bindingCell(ah, column, action_prop, list, tag, selection, name=null, xmbNode=null) {
  let singleBtn = action_prop!=null
  let cellData = {
    ah=ah, column=column, actionProp=action_prop, singleBtn=singleBtn, tag=tag, name=name
  }

  let group = ElemGroup()
  let isForGamepad = isGamepadColumn(column)

  return watchElemState(function(sf) {
    let hovered = (sf & S_HOVER)
    let selected = isCellSelected(cellData, selection)
    let isBindable = isForGamepad || !isGamepad.value
    return {
      watch = [selection, isGamepad]
      size = bindingColumnCellSize

      behavior = isBindable ? Behaviors.Button : null
      group
      xmbNode = isBindable ? xmbNode : null
      padding = fsh(0.5)

      children = {
        rendObj = ROBJ_BOX
        fillColor = selected ? Color(0,0,0,255)
                  : hovered ? Color(40, 40, 40, 80)
                  : Color(0, 0, 0, 40)
        borderWidth = selected ? hdpx(2) : 0
        borderColor = DEFAULT_TEXT_COLOR
        halign = ALIGN_CENTER
        valign = ALIGN_CENTER
        clipChildren = true

        size = flex()
        children = bindedComp(list, group)
      }

      function onDoubleClick() {
        let actionType = dainput.get_action_type(ah)
        if (isActionDisabledToCustomize(ah))
          return showDisabledMsgBox()

        if ((actionType & dainput.TYPEGRP__MASK) == dainput.TYPEGRP_DIGITAL
          || cellData.singleBtn || cellData.tag == "modifiers" || cellData.tag == "axis")
          startRecording(cellData)
        else
          configuredAxis(cellData)
      }

      onClick = isGamepad.value ? null : isActionDisabledToCustomize(ah) ? showDisabledMsgBox : @() selection(cellData)
      onHover = isGamepad.value ? @(on) selection(on ? cellData : null) : null

      function onDetach() {
        if (isCellSelected(cellData, selection))
          selection(null)
      }
    }
  })
}

let colorTextHdr = Color(120,120,120)
let function bindingColHeader(typ){
  return {
    size = bindingColumnCellSize
    rendObj = ROBJ_TEXT
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    text = loc("/".concat("controls/type", platformId, typ),typ)
    color = colorTextHdr
  }
}


let function mkBindingsHeader(colRange){
  let cols = colRange.map(@(v) bindingColHeader(isGamepadColumn(v)
                                                  ? loc("controls/type/pc/gamepad")
                                                  : loc("controls/type/pc/keyboard")))
  return {
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_HORIZONTAL
    children = mkActionRowCells(mkActionRowLabel(null), cols)
    valign = ALIGN_CENTER
    gap = fsh(2)
    rendObj = ROBJ_SOLID
    color = Color(0,0,0)
  }
}

let function bindingsPage(section_name) {
  let scrollHandler = ScrollHandler()
  let filteredActions = getActionsList().filter(@(ah) getActionTags(ah).indexof(section_name) != null)
  let xmbRootNode = XmbContainer({wrap=true})


  return function() {
    let colRange = collectBindableColumns()
    let toggleBg = makeBgToggle()

    let actionRows = []
    let header = mkBindingsHeader(colRange)

    foreach (ah in filteredActions) {
      let actionName = dainput.get_action_name(ah)
      let actionType = dainput.get_action_type(ah)

      switch (actionType & dainput.TYPEGRP__MASK) {
        case dainput.TYPEGRP_DIGITAL: {
          let bindings = colRange.map(@(col) dainput.get_digital_action_binding(ah, col))
          let colTexts = bindings.map(buildDigitalBindingText)
          let colComps = colTexts.map(@(col_text, idx) bindingCell(ah, colRange[idx], null, col_text, null, selectedBindingCell, actionName, XmbNode()))
          actionRows.append(makeActionRow(ah, actionName, colComps, XmbNode({isGridLine=true}), toggleBg))
          break
        }
        case dainput.TYPEGRP_AXIS:
        case dainput.TYPEGRP_STICK: {
          let colTexts = colRange.map(@(col, _) textListFromAction(actionName, col))
          let colComps = colTexts.map(@(col_text, idx) bindingCell(ah, colRange[idx], null, col_text, null, selectedBindingCell, actionName, XmbNode()))
          actionRows.append(makeActionRow(ah, actionName, colComps, XmbNode({isGridLine=true}), toggleBg))
          break
        }
      }
    }

    let bindingsArea = scrollbar.makeVertScroll({
      xmbNode = xmbRootNode
      flow = FLOW_VERTICAL
      size = [flex(), SIZE_TO_CONTENT]
      clipChildren = true
      children = actionRows
      scrollHandler
    })

    return {
      size = flex()
      padding = [fsh(1), 0]
      flow = FLOW_VERTICAL
      key = section_name
      animations = pageAnim
      children = [is_pc ? header : null, bindingsArea]
    }
  }
}

let function optionRowContainer(children, isOdd, params) {
  return watchElemState(@(sf) params.__merge({
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    //behavior = Behaviors.Button
    skipDirPadNav = true
    children = children
    rendObj = ROBJ_SOLID
    color = menuRowColor(sf, isOdd)
    gap = fsh(2)
    padding = [0, fsh(2)]
  }))
}

let function optionRow(labelText, comp, isOdd) {
  let label = {
    rendObj = ROBJ_TEXT
    color = DEFAULT_TEXT_COLOR
    text = labelText
    margin = fsh(1)
    size = [flex(1), SIZE_TO_CONTENT]
    //halign = ALIGN_CENTER
    halign = ALIGN_RIGHT
  }.__update(body_txt)

  let children = [
    label
    {
      size = [flex(), fontH(200)]
      //halign = ALIGN_CENTER
      halign = ALIGN_LEFT
      valign = ALIGN_CENTER
      children = comp
    }
  ]

  return optionRowContainer(children, isOdd, {key=labelText})
}

let invertFields = {
  [0] = "axisXinv",
  [1] = "axisYinv",
  [-1] = "invAxis",
}

local function invertCheckbox(action_names, column, axis) {
  if (type(action_names) != "array")
    action_names = [action_names]

  let bindings = action_names.map(function(aname) {
    let ah = dainput.get_action_handle(aname, 0xFFFF)
    return dainput.get_analog_stick_action_binding(ah, column)
        ?? dainput.get_analog_axis_action_binding(ah, column)
  }).filter(@(b) b!=null)

  if (!bindings.len())
    return null

  let curInverses = bindings.map(@(b) b[invertFields[axis]])

  let valAnd = curInverses.reduce(@(a,b) a && b, true)
  let valOr = curInverses.reduce(@(a,b) a || b, false)

  let val = Watched((valAnd == valOr) ? valAnd : null)

  let function setValue(new_val) {
    val(new_val)
    foreach (b in bindings)
      b[invertFields[axis]] = new_val
    haveChanges(true)
  }

  return checkbox(val, null, { setValue = setValue, override = { size = flex(), valign = ALIGN_CENTER } useHotkeys=true xmbNode=XmbNode()})
}
let mkRounded = @(val) round_by_value(val, 0.01)

local function axisSetupSlider(action_names, column, prop, params) {
  let group = ElemGroup()
  if (type(action_names) != "array")
    action_names = [action_names]

  let bindings = action_names.map(function(aname) {
    let ah = dainput.get_action_handle(aname, 0xFFFF)
    return dainput.get_analog_stick_action_binding(ah, column)
        ?? dainput.get_analog_axis_action_binding(ah, column)
  }).filter(@(binding) binding!=null)

  if (!bindings.len())
    return null

  let curSens = bindings.map(@(b) b[prop]).filter(@(prop) prop!=null)
  if (!curSens.len())
    return null
  let val = Watched(curSens[0]) // take the first one, because they will all be equal
  let opt = params.__merge({
    var = val,
    function setValue(new_val) {
      val(new_val)
      foreach (b in bindings)
        b[prop] = new_val
      haveChanges(true)
    }
  })
  return mkSliderWithText(opt, group, XmbNode(), params?.morphText ?? mkRounded)
}


let sensRanges = [
  {min = 0.05, max = 5.0, step = 0.05} // mouse
  {min = 0.05, max = 5.0, step = 0.05} // gamepad
  {min = 0.05, max = 5.0, step = 0.05} // mouse/kbd aux
]

let function sensitivitySlider(action_names, column) {
  let params = sensRanges[column].__merge({
//    scaling = slider.scales.logarithmic
  })
  return axisSetupSlider(action_names, column, "sensScale", params)
}

let function haveSensMulSlider(prop) {
  let sensScale = control.get_sens_scale()
  return sensScale[prop] >= 0.0
}

let function sensMulSlider(prop) {
  let sensScale = control.get_sens_scale()
  let var = Watched(sensScale[prop])
  let opt = {
    var,
    function setValue(new_val) {
      var(new_val)
      sensScale[prop] = new_val
      haveChanges(true)
    }
    min = 0.05
    max = 5.0
    step = 0.05
  }
  return mkSliderWithText(opt, null, XmbNode())
}


let function smoothMulSlider(action_name) {
  let act = get_action_handle(action_name, 0xFFFF)
  if (act == 0xFFFF)
    return null
  let opt = {
    var = aim_smooth
    min = 0.0
    max = 0.5
    step = 0.05
    function setValue(new_val) {
      aim_smooth_set(new_val)
      dainput.set_analog_stick_action_smooth_value(act, new_val)
      haveChanges(true)
    }
  }
  return mkSliderWithText(opt, null, XmbNode())
}


let function showDeadZone(val){
  return "{0}%".subst(round_by_value(val*100, 0.5))
}

let showRelScale = @(val) "{0}%".subst(round_by_value(val*10, 0.5))

const minDZ = 0.0
const maxDZ = 0.4
const stepDZ = 0.01
let function deadZoneScaleSlider(val, setVal){
  let opt = { var = val, min = minDZ, max = maxDZ, step=stepDZ, scaling = slider.scales.linear,
    setValue = function(param){
      setVal(param)
      haveChanges(true)
    }
  }
  return mkSliderWithText(opt, null, XmbNode(), showDeadZone)
}
let isUserConfigCustomized = Watched(false)
let function checkUserConfigCustomized(){
  isUserConfigCustomized(dainput.is_user_config_customized())
}
let function updateAll(...) { updateCurrentPreset(); checkUserConfigCustomized()}
generation.subscribe(updateAll)
haveChanges.subscribe(updateAll)
let showPresetsSelect = Computed(@() availablePresets.value.len()>0)

let onClickCtor = @(p, _idx) @() p.preset != selectedPreset.value.preset || isUserConfigCustomized.value ? changePreset(p) : null //fixme do not reset if it is current
let isCurrent = @(p, _idx) p.preset==selectedPreset.value.preset
let textCtor = @(p, _idx, _stateFlags) p?.name!=null ? loc(p?.name) : null
let selectPreset = select({state=selectedPreset, options=availablePresets.value, onClickCtor=onClickCtor, isCurrent=isCurrent, textCtor=textCtor})

let currentControls = @(){
  size = flex()
  watch = [showPresetsSelect, isUserConfigCustomized]
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  gap = {size = [hdpx(10),0]}
  children = showPresetsSelect.value
            ? [selectPreset].append(isUserConfigCustomized.value
                ? dtext(loc("controls/modifiedControls"), {color = DEFAULT_TEXT_COLOR})
                : null)
            : null
}
let function pollSettings() {
  if (isUserConfigCustomized.value)
    return
  updateAll()
}

let controlsTypesMap = {
  [ControlsTypes.AUTO] = loc("options/auto"),
  [ControlsTypes.KB_MOUSE] = loc("controls/type/pc/keyboard"),
  [ControlsTypes.GAMEPAD] = loc("controls/type/pc/gamepad")
}

let function options() {
  let onlyGamePad = controlsSettingOnlyForGamePad.value
  let toggleBg = makeBgToggle()
  let showGamepadOpts = wasGamepad.value
  let isGyroAvailable = availablePresets.value.findvalue(
    @(v) (v?.name.indexof(loc("".concat("gyro~",platformId))) != null)
  )

  let bindingsArea = scrollbar.makeVertScroll({
    flow = FLOW_VERTICAL
    size = [flex(), SIZE_TO_CONTENT]
    clipChildren = true
    children = [
      [true, loc("controls/curControlPreset"), currentControls],
      [!onlyGamePad, loc("controls/pc/useGamepad"),
        select({state=use_gamepad_state, options=[ControlsTypes.AUTO, ControlsTypes.KB_MOUSE, ControlsTypes.GAMEPAD],
          onClickCtor=@(p, _idx) @() p != use_gamepad_state.value ? set_use_gamepad(p) : null,
//          isCurrent=@(p, idx) p==use_gamepad_state.value,
          textCtor=@(p, _idx, _stateFlags) controlsTypesMap?[p] ?? loc(p)})
      ],
      [!onlyGamePad, loc("controls/mouseAimXInvert"), invertCheckbox(["Human.Aim", "Spectator.Aim", "Vehicle.Aim"], 0, 0)],
      [!onlyGamePad, loc("controls/mouseAimYInvert"), invertCheckbox(["Human.Aim", "Spectator.Aim", "Vehicle.Aim"], 0, 1)],
      [isGyroAvailable, locByPlatform("controls/gyroAimXInvert"), invertCheckbox(["Human.AimDelta", "Spectator.AimDelta", "Vehicle.AimDelta"], 1, 0)],
      [isGyroAvailable, locByPlatform("controls/gyroAimYInvert"), invertCheckbox(["Human.AimDelta", "Spectator.AimDelta", "Vehicle.AimDelta"], 1, 1)],
      [showGamepadOpts, loc("controls/joyAimXInvert"), invertCheckbox(["Human.Aim", "Spectator.Aim", "Vehicle.Aim"], 1, 0)],
      [showGamepadOpts, loc("controls/joyAimYInvert"), invertCheckbox(["Human.Aim", "Spectator.Aim", "Vehicle.Aim"], 1, 1)],
      [!onlyGamePad, loc("controls/mouseAimSensitivity"), sensitivitySlider(["Human.Aim", "Spectator.Aim", "Vehicle.Aim"], 0)],
      [isGyroAvailable, locByPlatform("controls/gyroAimSensitivity"), sensitivitySlider(["Human.AimDelta", "Spectator.AimDelta", "Vehicle.AimDelta"], 1)],
      [showGamepadOpts, loc("controls/joyAimSensitivity"), sensitivitySlider(["Human.Aim", "Spectator.Aim", "Vehicle.Aim"], 1)],
      [haveSensMulSlider("humanAiming"), loc("controls/sensScale/humanAiming"), sensMulSlider("humanAiming")],
      [haveSensMulSlider("humanTpsCam"), loc("controls/sensScale/humanTpsCam"), sensMulSlider("humanTpsCam")],
      [haveSensMulSlider("humanFpsCam"), loc("controls/sensScale/humanFpsCam"), sensMulSlider("humanFpsCam")],
      [haveSensMulSlider("vehicleCam"), loc("controls/sensScale/vehicleCam"), sensMulSlider("vehicleCam")],
      [haveSensMulSlider("planeCam"), loc("controls/sensScale/planeCam"), sensMulSlider("planeCam")],
      [showGamepadOpts, locByPlatform("gamepad/stick0_deadzone"), deadZoneScaleSlider(stick0_dz, set_stick0_dz)],
      [showGamepadOpts, locByPlatform("gamepad/stick1_deadzone"), deadZoneScaleSlider(stick1_dz, set_stick1_dz)],
      [showGamepadOpts && isAimAssistExists,
        loc("options/aimAssist"),
        checkbox(isAimAssistEnabled, null,
          { setValue = setAimAssist, useHotkeys = true, override={size=flex() valign = ALIGN_CENTER xmbNode=XmbNode()}})
      ],
      [showGamepadOpts, loc("controls/uiClickRumble"),
        checkbox(isUiClickRumbleEnabled, null,
          { setValue = setUiClickRumble, override = { size = flex(), valign = ALIGN_CENTER } useHotkeys=true xmbNode=XmbNode()})],
      [showGamepadOpts, loc("controls/inBattleRumble"),
        checkbox(isInBattleRumbleEnabled, null,
          { setValue = setInBattleRumble, override = { size = flex(), valign = ALIGN_CENTER } useHotkeys=true xmbNode=XmbNode()})],

      [true, loc("controls/aimSmooth"), smoothMulSlider("Human.Aim")],
    ].map(@(v) v[0] ? optionRow.call(null, v[1],v[2], toggleBg()) : null)
  })

  return {
    key = "options"
    size = flex()
    flow = FLOW_VERTICAL
    onAttach = function() {
      gui_scene.clearTimer(pollSettings)
      gui_scene.setInterval(0.5, pollSettings) //not enough to listen to changes and generations!!
    }
    onDetach = @() gui_scene.clearTimer(pollSettings)
    watch = [controlsSettingOnlyForGamePad, wasGamepad, generation]
    xmbNode = XmbContainer()
    children = [bindingsArea]
    animations = pageAnim
  }
}


let function sectionHeader(text) {
  return optionRowContainer({
    rendObj = ROBJ_TEXT
    text
    color = DEFAULT_TEXT_COLOR
    padding = [fsh(3), fsh(1), fsh(1)]
  }.__update(h2_txt), false, {
    halign = ALIGN_CENTER
  })
}


let function axisSetupWindow() {
  let cellData = configuredAxis.value
  let stickBinding = dainput.get_analog_stick_action_binding(cellData.ah, cellData.column)
  let axisBinding = dainput.get_analog_axis_action_binding(cellData.ah, cellData.column)
  let binding = stickBinding ?? axisBinding
  let actionTags = getActionTags(cellData.ah)

  let actionName = dainput.get_action_name(cellData.ah)
  let actionType = dainput.get_action_type(cellData.ah)

  let title = {
    rendObj = ROBJ_TEXT
    color = DEFAULT_TEXT_COLOR
    text = loc($"controls/{actionName}", actionName)
    margin = fsh(2)
  }.__update(h2_txt)

  let function buttons() {
    let children = []
    if (selectedAxisCell.value)
      children.append(
        textButton(loc("controls/bindBinding"),
          function() { startRecording(selectedAxisCell.value) },
          { hotkeys = [[$"^{JB.A}", { description = loc("controls/bindBinding") }]] })
        textButton(loc("controls/clearBinding"),
          function() {
            clearBinding(selectedAxisCell.value)
            nextGeneration()
          },
          { hotkeys = [["^J:X"]] })
       )

    children.append(textButton(loc("mainmenu/btnOk", "OK"),
      function() { configuredAxis(null) },
      { hotkeys = [[$"^{JB.B} | J:Start | Esc", { description={skip=true} }]] }))

    return {
      watch = selectedAxisCell

      size = [flex(), SIZE_TO_CONTENT]
      flow = FLOW_HORIZONTAL
      halign = ALIGN_RIGHT
      children
    }
  }

  let modifiersList = []
  for (local i=0, n=binding.modCnt; i<n; ++i) {
    let mod = binding.mod[i]
    modifiersList.append(format_ctrl_name(mod.devId, mod.btnId))
    if (i < n-1)
      modifiersList.append("+")
  }

  local toggleBg = makeBgToggle()
  let rows = [
    optionRow(loc("Modifiers"), bindingCell(cellData.ah, cellData.column, null, modifiersList, "modifiers", selectedAxisCell), toggleBg())
  ]

  local axisBindingTextList
  if (stickBinding) {
    axisBindingTextList = getSticksText(stickBinding)
  } else if (axisBinding) {
    axisBindingTextList = format_ctrl_name(axisBinding.devId, axisBinding.axisId, false)
  }

  toggleBg = makeBgToggle()

  rows.append(
    sectionHeader(loc("controls/analog-axis-section", "Analog axis"))

    optionRow(loc("controls/analog/axis", "Axis"), bindingCell(cellData.ah, cellData.column, null, axisBindingTextList ? [axisBindingTextList] : [], "axis", selectedAxisCell), toggleBg())

    stickBinding != null
      ? optionRow(loc("controls/analog/sensitivity", "Sensitivity"), sensitivitySlider(actionName, cellData.column), toggleBg())
      : null

    dainput.get_action_type(cellData.ah) != dainput.TYPE_STICK_DELTA
      ? optionRow(loc("controls/analog/deadzoneThres", "Deadzone"), axisSetupSlider(actionName, cellData.column, "deadZoneThres", {min=0, max=0.4,step=0.01, morphText=showDeadZone}), toggleBg())
      : null
    dainput.is_action_stateful(cellData.ah)
      ? optionRow(loc("controls/analog/relIncScale", "changeStep"), axisSetupSlider(actionName, cellData.column, "relIncScale", {min=0.1, max=10.0, step=0.1, morphText=showRelScale}), toggleBg())
      : null
    dainput.get_action_type(cellData.ah) != dainput.TYPE_STICK_DELTA
      ? optionRow(loc("controls/analog/nonlinearity"), axisSetupSlider(actionName, cellData.column, "nonLin", {min=0, max=4, step=0.5}), toggleBg())
      : null

    dainput.get_action_type(cellData.ah) != dainput.TYPE_STICK_DELTA && stickBinding != null
      ? optionRow(loc("controls/analog/axisSnapAngK", "Axis snap factor"), axisSetupSlider(actionName, cellData.column, "axisSnapAngK", {min=0, max=1, step=0.025, morphText=showDeadZone}), toggleBg())
      : null

    stickBinding
      ? optionRow(loc("controls/analog/isInvertedX", "Invert X"), invertCheckbox(actionName, cellData.column, 0), toggleBg())
      : null
    stickBinding
      ? optionRow(loc("controls/analog/isInvertedY", "Invert Y"), invertCheckbox(actionName, cellData.column, 1), toggleBg())
      : null
    axisBinding
      ? optionRow(loc("controls/analog/isInverted"), invertCheckbox(actionName, cellData.column, -1), toggleBg())
      : null
  )

//  if (!isGamepadColumn(cellData.column) || dainput.is_action_stateful(cellData.ah))
//  {
  toggleBg = makeBgToggle()

  if (!actionTags.contains("_noDigitalButtons_")){
    rows.append(sectionHeader(loc("controls/digital-buttons-section", "Digital buttons")))

    if (axisBinding) {
      if (actionType == dainput.TYPE_STEERWHEEL || dainput.is_action_stateful(cellData.ah)) {
        local texts = null
        if (isValidDevice(axisBinding.minBtn.devId))
          texts = [format_ctrl_name(axisBinding.minBtn.devId, axisBinding.minBtn.btnId, true)]
        else
          texts = []
        let cell = bindingCell(cellData.ah, cellData.column, "minBtn", texts, null, selectedAxisCell)
        rows.append(optionRow(loc($"controls/{actionName}/min", loc("controls/min")), cell, toggleBg()))
      }

      local texts = null
      if (isValidDevice(axisBinding.maxBtn.devId))
        texts = [format_ctrl_name(axisBinding.maxBtn.devId, axisBinding.maxBtn.btnId, true)]
      else
        texts = []
      let cell = bindingCell(cellData.ah, cellData.column, "maxBtn", texts, null, selectedAxisCell)
      rows.append(optionRow(loc($"controls/{actionName}/max", loc("controls/max")), cell, toggleBg()))

      if (dainput.is_action_stateful(cellData.ah)){
        local textsAdd = isValidDevice(axisBinding.decBtn.devId)
          ? [format_ctrl_name(axisBinding.decBtn.devId, axisBinding.decBtn.btnId, true)]
          : []
        local cellAdd = bindingCell(cellData.ah, cellData.column, "decBtn", textsAdd, null, selectedAxisCell)
        rows.append(optionRow(loc($"controls/{actionName}/dec", loc("controls/dec")), cellAdd, toggleBg()))
        textsAdd = isValidDevice(axisBinding.incBtn.devId)
          ? [format_ctrl_name(axisBinding.incBtn.devId, axisBinding.incBtn.btnId, true)]
          : []
        cellAdd = bindingCell(cellData.ah, cellData.column, "incBtn", textsAdd, null, selectedAxisCell)
        rows.append(optionRow(loc($"controls/{actionName}/inc", loc("controls/inc")), cellAdd, toggleBg()))

      }
    }
    else if (stickBinding) {
      let directions = [
        {locSuffix="X/min", axisId="axisXId", dirBtn="minXBtn"}
        {locSuffix="X/max", axisId="axisXId", dirBtn="maxXBtn"}
        {locSuffix="Y/max", axisId="axisYId", dirBtn="maxYBtn"}
        {locSuffix="Y/min", axisId="axisYId", dirBtn="minYBtn"}
      ]
      foreach (dir in directions) {
        let btn = stickBinding[dir.dirBtn]
        let texts = isValidDevice(btn.devId) ? [format_ctrl_name(btn.devId, btn.btnId, true)] : []

        rows.append(optionRow(loc($"controls/{actionName}{dir.locSuffix}", loc($"controls/{dir.locSuffix}")),
          bindingCell(cellData.ah, cellData.column, dir.dirBtn, texts, null, selectedAxisCell), toggleBg()))
      }
    }
  }
//  }

  let children = [
    title

    scrollbar.makeVertScroll({
      flow = FLOW_VERTICAL
      key = "axis"
      size = [flex(), SIZE_TO_CONTENT]
      padding = [fsh(1), 0]
      clipChildren = true

      children = rows
    })

    buttons
  ]

  return {
    watch = actionRecording
    size = flex()
    behavior = Behaviors.Button
    stopMouse = true
    stopHotkeys = true
    skipDirPadNav = true
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    rendObj = ROBJ_WORLD_BLUR
    color = Color(190,190,190,255)

    function onClick() {
      configuredAxis(null)
    }

    children = {
      size = [sw(80), sh(80)]
      rendObj = ROBJ_WORLD_BLUR
      color = Color(120,120,120,255)
      flow = FLOW_VERTICAL
      halign = ALIGN_CENTER

      stopMouse = true
      stopHotkeys = true

      children
    }
  }
}


let function actionTypeSelect(_cell_data, watched, value) {
  return watchElemState(function(sf) {
    return {
      behavior = Behaviors.Button
      function onClick() {
        watched(value)
      }
      watch = [watched]
      flow = FLOW_HORIZONTAL
      children = [
        {
          size = [fontH(150), fontH(150)]
          halign = ALIGN_CENTER
          rendObj = ROBJ_TEXT
          text = (watched.value == value) ? fa["circle"] : fa["circle-o"]
          color = (sf & S_HOVER) ? HIGHLIGHT_COLOR : DEFAULT_TEXT_COLOR
        }.__update(fontawesome)
        {
          rendObj = ROBJ_TEXT
          color = (sf & S_HOVER) ? HIGHLIGHT_COLOR : DEFAULT_TEXT_COLOR
          text = loc(eventTypeLabels[value])
        }.__update(body_txt)
      ]
    }
  })
}

let selectEventTypeHdr = {
  rendObj = ROBJ_TEXT
  text = loc("controls/actionEventType", "Action on")
  color = DEFAULT_TEXT_COLOR
  halign = ALIGN_RIGHT
}.__update(body_txt)

let function buttonSetupWindow() {
  let cellData = configuredButton.value
  let binding = dainput.get_digital_action_binding(cellData.ah, cellData.column)
  let eventTypeValue = Watched(binding.eventType)
  let modifierType = Watched(binding.unordCombo)
  let needShowModType = Watched(binding.modCnt > 0)
  modifierType.subscribe(function(new_val) {
    binding.unordCombo = new_val
    haveChanges(true)
  })

  let currentBinding = {
    flow = FLOW_HORIZONTAL
    children = bindedComp(buildDigitalBindingText(binding))
  }
  eventTypeValue.subscribe(function(new_val) {
    binding.eventType = new_val
    haveChanges(true)
  })

  let actionName = dainput.get_action_name(cellData.ah)
  let title = {
    rendObj = ROBJ_TEXT
    color = DEFAULT_TEXT_COLOR
    text = loc($"controls/{actionName}", actionName)
    margin = fsh(3)
  }.__update(h2_txt)

  let stickyToggle = Watched(binding.stickyToggle)
  stickyToggle.subscribe(function(new_val) {
    binding.stickyToggle = new_val
    haveChanges(true)
  })

  let buttons = {
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_HORIZONTAL
    halign = ALIGN_RIGHT
    children = [
      textButton(loc("mainmenu/btnOk", "OK"), function() {
        configuredButton(null)
      }, {
          hotkeys = [
            [$"^{JB.B} | J:Start | Esc", { description={skip=true} }],
          ]
      })
    ]
  }

  let isStickyToggle = {
    margin = [fsh(1), 0, 0, fsh(0.4)]
    children = checkbox(stickyToggle,
      {
        color = DEFAULT_TEXT_COLOR
        text = loc("controls/digital/mode/isStickyToggle")
      }.__update(body_txt)
    )
  }

  let selectEventType = @() {
    flow = FLOW_VERTICAL
    watch = eventTypeValue
    children = getAllowedBindingsTypes(cellData.ah)
      .map( @(eventType) actionTypeSelect(cellData, eventTypeValue, eventType) )
      .append(isStickyToggle)
  }

  let triggerTypeArea = {
    flow = FLOW_HORIZONTAL
    valign = ALIGN_TOP
    gap = fsh(2)
    children = [
      selectEventTypeHdr
      selectEventType
    ]
  }

  let selectModifierType = @() {
    watch = needShowModType
    hplace = ALIGN_CENTER
    valign = ALIGN_CENTER
    children = needShowModType.value ? [
      checkbox(modifierType, {text = loc("controls/unordCombo")})
    ] : null
  }
  let children = [
    title
    {
      halign = ALIGN_CENTER
      flow = FLOW_VERTICAL
      children = [currentBinding, selectModifierType]
    }
    triggerTypeArea
    {size = flex(10) }
    buttons
  ]

  return {
    size = flex()
    behavior = Behaviors.Button
    skipDirPadNav = true
    stopMouse = true
    stopHotkeys = true
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    rendObj = ROBJ_WORLD_BLUR
    color = Color(190,190,190,255)

    function onClick() {
      configuredAxis(null)
    }

    children = {
      size = [sw(80), sh(80)]
      rendObj = ROBJ_WORLD_BLUR
      color = Color(120,120,120,255)
      flow = FLOW_VERTICAL
      halign = ALIGN_CENTER
      gap = hdpx(70)

      children = children
    }
  }
}

let saSize = Computed(@() sw(100)-2*safeAreaHorPadding.value)

let function controlsSetup() {
  let width = min(sw(90), saSize.value)
  let menu = {
    transform = {}
    hplace = ALIGN_CENTER
    vplace = ALIGN_CENTER
    size = [width, sh(85)]
    rendObj = ROBJ_WORLD_BLUR
    fillColor = Color(0,0,0,180)
    flow = FLOW_VERTICAL
    //stopHotkeys = true
    stopMouse = true

    children = [
      settingsHeaderTabs({sourceTabs = tabsList, currentTab}),
      {
        size = flex()
        padding=[hdpx(5),hdpx(10)]
        children = currentTab.value == "Options" ? options : bindingsPage(currentTab.value)
      },
      mkWindowButtons(width)
    ]
  }

  let root = {
    key = "controls"
    size = [sw(100), sh(100)]
    cursor = cursors.normal
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    watch = [
      actionRecording, configuredAxis, configuredButton, currentTab, saSize,
      generation, controlsSettingOnlyForGamePad, haveChanges
    ]

    children = [
      {
        size = [sw(100), sh(100)]
        stopHotkeys = true
        stopMouse = true
        rendObj = ROBJ_WORLD_BLUR
        color = Color(130,130,130)
      }
      actionRecording.value==null ? menu : null
      configuredAxis.value!=null ? axisSetupWindow : null
      configuredButton.value!=null ? buttonSetupWindow : null
      actionRecording.value!=null ? recordingWindow : null
    ]

    transform = {
      pivot = [0.5, 0.25]
    }
    animations = pageAnim
    sound = {
      attach="ui/menu_enter"
      detach="ui/menu_exit"
    }

    behavior = Behaviors.ActivateActionSet
    actionSet = "StopInput"
  }

  return root
}


return {
  controlsMenuUi = controlsSetup
  showControlsMenu
}
