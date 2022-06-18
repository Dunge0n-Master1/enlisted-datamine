from "%enlSqGlob/ui_library.nut" import *

let textInput = require("%darg/components/textInput.nut")
let colors = require("%ui/style/colors.nut")


let function makeFrame(inputObj, group, sf) {
  let isHover = sf & S_HOVER
  let isKbdFocus = sf & S_KB_FOCUS
  return {
    rendObj = ROBJ_BOX
    borderWidth = [hdpx(1), hdpx(1), 0, hdpx(1)]
    fillColor = 0
    size = [flex(), SIZE_TO_CONTENT]
    borderColor = isHover ? colors.InputFrameLtHovered
                : isKbdFocus ? colors.InputFrameLtFocused
                : colors.InputFrameLt
    group = group
    children = {
      rendObj = ROBJ_BOX
      borderWidth = [0, 0, hdpx(1), 0]
      margin =[0,hdpx(1)]
      fillColor = 0
      size = [flex(), SIZE_TO_CONTENT]
      borderColor = isHover ? colors.InputFrameRbHovered
                : isKbdFocus ? colors.InputFrameRbFocused
                : colors.InputFrameRb
      group = group

      children = inputObj
    }
  }
}


let function makeUnderline(inputObj, group, sf) {
  let isHover = sf & S_HOVER
  let isKbdFocus = sf & S_KB_FOCUS
  return {
    rendObj = ROBJ_BOX
    borderWidth = [0, 0, hdpx(1), 0]
    fillColor = 0
    size = [flex(), SIZE_TO_CONTENT]
    group = group
    borderColor = isHover ? colors.InputFrameRbHovered
              : isKbdFocus ? colors.InputFrameRbFocused
              : colors.InputFrameRb
    children = inputObj
  }
}


let function noFrame(inputObj, _group, _sf) {
  return inputObj
}


let textInputColors = {
  placeHolderColor = Color(80,80,80,80)
  textColor = colors.Active
  backGroundColor = colors.ControlBg
}


let makeTextInput = @(text_state, options, frameCtor)
  textInput(text_state,
    options.__merge({ colors = textInputColors }),
    frameCtor)


let export = class{
  Framed = @(text_state, options={}) makeTextInput(text_state, options, makeFrame)
  Underlined = @(text_state, options={}) makeTextInput(text_state, options, makeUnderline)
  NoFrame = @(text_state, options={}) makeTextInput(text_state, options, noFrame)
  _call = @(_self, text_state, options={}) makeTextInput(text_state, options, makeFrame)
}()


return export
