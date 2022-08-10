from "%enlSqGlob/ui_library.nut" import *

let {dtext} = require("%ui/components/text.nut")
let {defHeight, sticksAliases,mkImageComp, keysImagesMap} = require("%ui/components/gamepadImgByKey.nut")
let {generation} = require("%ui/hud/menus/controls_state.nut")
let {isGamepad} = require("%ui/control/active_controls.nut")
let dainput = require("dainput2")
let format_ctrl_name = dainput.format_ctrl_name

let function mkText(text, _params={}){
  if (text==null || text=="")
    return null
  return dtext(loc(text))
}

let validDevices = [dainput.DEV_kbd, dainput.DEV_pointing, dainput.DEV_gamepad, dainput.DEV_joy]
let function isValidDevice(dev) {
  return validDevices.indexof(dev) != null
}

let ButtonAnd = class{
  function _tostring(){
    return "+"
  }
}
let function buildModifiersList(binding) {
  let res = []
  let mods = binding.mod
  for (local i=0, n=binding.modCnt; i<n; ++i) {
    if (isValidDevice(mods[i].devId)) {
      res.append(format_ctrl_name(mods[i].devId, mods[i].btnId))
      res.append(ButtonAnd())
    }
  }
  return res
}

let inParents = @(locId) "({0})".subst(locId)
let eventTypeMap = {
  [dainput.BTN_pressed] = null,
  [dainput.BTN_pressed_long] = "controls/digital/mode/hold",
  [dainput.BTN_pressed2] = "controls/digital/multiClick/2",
  [dainput.BTN_pressed3] = "controls/digital/multiClick/3",
  [dainput.BTN_released] = "controls/digital/release",
  [dainput.BTN_released_short] = "controls/digital/release_short",
  [dainput.BTN_released_long] = "controls/digital/hold_release"
}

let eventTypeLabels = {
  [dainput.BTN_pressed] = "controls/digital/onPressed",
  [dainput.BTN_pressed_long] = "controls/digital/onHold",
  [dainput.BTN_pressed2] = "controls/digital/multiClick/2",
  [dainput.BTN_pressed3] = "controls/digital/multiClick/3",
  [dainput.BTN_released] = "controls/digital/checkReleased",
  [dainput.BTN_released_short] = "controls/digital/onClick",
  [dainput.BTN_released_long] = "controls/digital/onHoldReleased"
}
let notImportantEventsTexts = [dainput.BTN_released_short, dainput.BTN_released].map(@(v) eventTypeMap[v])

//const inverseTxt = "inverse"
const axesSeparatorTxt = "/"
const axesGroupSeparatorTxt = ";"

let function getSticksText(stickBinding) {
  let b = stickBinding
  let xaxis = format_ctrl_name(b.devId, b.axisXId, false)
  let yaxis = format_ctrl_name(b.devId, b.axisYId, false)
  if (sticksAliases.rx.indexof(xaxis)!=null && sticksAliases.ry.indexof(yaxis)!=null)
    return "J:R.Thumb.hv"
  if (sticksAliases.lx.indexof(xaxis)!=null && sticksAliases.ly.indexof(yaxis)!=null)
    return "J:L.Thumb.hv"
  if (xaxis == "M:X" && yaxis=="M:Y")
    return "M:XY"
  return null
}


let function mkBuildDigitalBindingText(b, eventTypeToText=true) {
  let res = buildModifiersList(b).map(@(v) eventTypeToText? v.tostring() : v)
  res.append(format_ctrl_name(b.devId, b.ctrlId, b.btnCtrl))
  let etype = eventTypeToText ? eventTypeMap?[b.eventType] : b.eventType
  if (etype)
    res.append(etype)
  return res
}
let buildDigitalBindingText = @(b) mkBuildDigitalBindingText(b)

let function textListFromAction(action_name, column, eventTypeToText=true) {
  let ah = dainput.get_action_handle(action_name, 0xFFFF)
  let digitalBinding = dainput.get_digital_action_binding(ah, column)
  let axisBinding = dainput.get_analog_axis_action_binding(ah, column)
  let stickBinding = dainput.get_analog_stick_action_binding(ah, column)

  local res
  if (digitalBinding) {
    res = mkBuildDigitalBindingText(digitalBinding, eventTypeToText)
  }
  else if (axisBinding) {
    let b = axisBinding
    res = buildModifiersList(b)
    if (isValidDevice(b.devId)) {
      let text = format_ctrl_name(b.devId, b.axisId, false)
//      if (b.invAxis)
//        res.append(inverseTxt)
      res.append(text)
    }

    if (dainput.get_action_type(ah) == dainput.TYPE_STEERWHEEL) {
      if (isValidDevice(b.minBtn.devId) || isValidDevice(b.maxBtn.devId)) {
        res.append(format_ctrl_name(b.minBtn.devId, b.minBtn.btnId, true))
        res.append(axesSeparatorTxt)
        res.append(format_ctrl_name(b.maxBtn.devId, b.maxBtn.btnId, true))
      }
    }
    else {
      if (dainput.is_action_stateful(ah)){
        local oneGroupExist = false
        if (isValidDevice(b.incBtn.devId) || isValidDevice(b.decBtn.devId)) {
          res.append(format_ctrl_name(b.decBtn.devId, b.decBtn.btnId, true))
          res.append(axesSeparatorTxt)
          res.append(format_ctrl_name(b.incBtn.devId, b.incBtn.btnId, true))
          oneGroupExist = true
        }
        if (isValidDevice(b.minBtn.devId) || isValidDevice(b.maxBtn.devId)) {
          if (oneGroupExist)
            res.append(axesGroupSeparatorTxt)
          res.append(format_ctrl_name(b.minBtn.devId, b.minBtn.btnId, true))
          res.append(axesSeparatorTxt)
          res.append(format_ctrl_name(b.maxBtn.devId, b.maxBtn.btnId, true))
        }
      }
      else {
        if (isValidDevice(b.maxBtn.devId)) {
          res.append(format_ctrl_name(b.maxBtn.devId, b.maxBtn.btnId, true))
        }
      }
    }
  }
  else if (stickBinding) {
    let b = stickBinding
    res = buildModifiersList(b)
    if (isValidDevice(b.devId)) {
      let sticksText = getSticksText(b)
      if (sticksText != null) {
        res.append(sticksText)
      }
      else {
//        if (b.axisXinv)
//          res.append(inverseTxt)
        res.append(format_ctrl_name(b.devId, b.axisXId, false))

        res.append(axesSeparatorTxt)

//        if (b.axisYinv)
//          res.append(inverseTxt)
        res.append(format_ctrl_name(b.devId, b.axisYId, false))
      }
    }
    if (b.minXBtn.devId)
      res.append(format_ctrl_name(b.minXBtn.devId, b.minXBtn.btnId, true))
    if (b.maxXBtn.devId)
      res.append(format_ctrl_name(b.maxXBtn.devId, b.maxXBtn.btnId, true))
    if (b.minYBtn.devId)
      res.append(format_ctrl_name(b.minYBtn.devId, b.minYBtn.btnId, true))
    if (b.maxYBtn.devId)
      res.append(format_ctrl_name(b.maxYBtn.devId, b.maxYBtn.btnId, true))
  }
  else
    res = []
  return res
}
let eventTypeValues = eventTypeMap.values()

local function buildElems(textlist, params = {imgFunc=null, textFunc=mkText, eventTextFunc = null, eventTypesAsTxt=false, compact=false}){
  let makeImg = params?.imgFunc ?? mkImageComp
  let textFunc = params?.textFunc ?? mkText
  let eventTextFunc = params?.eventTextFunc ?? textFunc
  let eventTypesAsTxt = params?.eventTypesAsTxt ?? false
  let compact = params?.compact
  if (compact) {
    textlist = textlist.filter(@(text) notImportantEventsTexts.indexof(text)==null)
  }
  let elems = textlist.map(function(text){
    return function(){
      if (keysImagesMap.value.values().indexof(text) != null)
        return makeImg(text,{watch=keysImagesMap})

      else if (text instanceof ButtonAnd && !eventTypesAsTxt)
        return makeImg(keysImagesMap.value["__and__"], {height=defHeight/3, watch=keysImagesMap})

      else if (text in keysImagesMap.value && eventTypeValues.indexof(text)==null && !(text in eventTypeMap))
        return makeImg(keysImagesMap.value[text],{watch=keysImagesMap})

      else if (compact && !eventTypesAsTxt && text in keysImagesMap.value)
        return makeImg(keysImagesMap.value?[text], {height=defHeight/2, watch=keysImagesMap})

      else if (eventTypeValues.indexof(text)!=null)
        return eventTextFunc?(inParents(loc(text)))

      else if (type(text)=="string")
        return textFunc?(loc(text))
      else
        return null
    }
  })
  return elems
}

let function mkHasBinding(actionName){
  return Computed(function() {
    let _ = generation // warning disable: -declared-never-used
    return dainput.is_action_binding_set(dainput.get_action_handle(actionName, 0xFFFF), isGamepad.value ? 1 : 0)
  })
}

return {
  isValidDevice
  buildModifiersList
  buildDigitalBindingText
  notImportantEventsTexts
  textListFromAction
  makeSvgImgFromText = mkImageComp
  buildElems
//  inverseTxt
  eventTypeLabels
  getSticksText
  mkHasBinding
  keysImagesMap
}
