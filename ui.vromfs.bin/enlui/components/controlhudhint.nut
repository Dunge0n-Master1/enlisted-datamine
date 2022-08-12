from "%enlSqGlob/ui_library.nut" import *

let {sub_txt} = require("%enlSqGlob/ui/fonts_style.nut")
let { generation } = require("%ui/hud/menus/controls_state.nut")
let { HUD_TIPS_HOTKEY_FG } = require("%ui/hud/style.nut")
let {
  textListFromAction, buildElems, mkHasBinding, keysImagesMap
} = require("%ui/control/formatInputBinding.nut")
let { isGamepad, isTouch } = require("%ui/control/active_controls.nut")

let function container(children, params={}){
  return {
    children = {
      speed = [60,800]
      delay = 0.3
      children
      flow = FLOW_HORIZONTAL
      gap = hdpx(3)
      behavior = [Behaviors.Marquee]
      scrollOnHover = true
      maxWidth = pw(100)
      size = SIZE_TO_CONTENT
      halign = ALIGN_LEFT valign = ALIGN_CENTER
    }
    clipChildren = true
    size = SIZE_TO_CONTENT
  }.__update(params)
}

local function controlHudHint(params, _group = null) {
  if (typeof params == "string")
    params = {id = params}
  let frame = params?.frame ?? true
  let font = params?.text_params?.font ?? sub_txt?.font
  let fontSize = params?.text_params?.fontSize ?? sub_txt.fontSize
  let color = params?.color ?? HUD_TIPS_HOTKEY_FG
  let width = params?.width ?? SIZE_TO_CONTENT
  let height = params?.height ?? fontH(100)
  let frameC = freeze({
    rendObj = ROBJ_FRAME
    color
    size = flex()
    opacity = 0.3
    borderWidth = hdpx(1)
  })

  let function makeControlText(text) {
    return {
      text, fontSize, font, color, rendObj = ROBJ_TEXT padding = hdpx(4)
    }
  }

  let hasBinding = mkHasBinding(params.id)
  return function(){
    local disableFrame = params?.disableFrame ?? isGamepad.value
    let column = isGamepad.value ? 1 : 0
    let textList = textListFromAction(params.id, column)
    local hasTexts = false
    foreach (e in textList) {
      if (keysImagesMap.value?[e] == null){
        hasTexts=true
        break
      }
    }
    disableFrame = disableFrame || !hasTexts
    let controlElems = buildElems(textList, {textFunc = makeControlText, compact = true})
    let elems = container(controlElems, params?.text_params ?? {})
    return {
      size = [width, height]
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      minWidth = height
      font
      fontSize
      clipChildren = width != SIZE_TO_CONTENT
      rendObj = ROBJ_FRAME
      children = [
        elems
        frame && !disableFrame
          ? frameC
          : null
      ]
      watch = [isGamepad, hasBinding, generation, keysImagesMap]
    }
  }
}

let defTextFunc = @(text){
  size = SIZE_TO_CONTENT
  rendObj = ROBJ_FRAME
  color = mul_color(HUD_TIPS_HOTKEY_FG,0.3)
  padding = hdpx(1)
  borderWidth = hdpx(1)
  children = [
    {rendObj=ROBJ_WORLD_BLUR size = flex() fillColor = Color(0,0,0,30)}
    {
      text color = HUD_TIPS_HOTKEY_FG, rendObj = ROBJ_TEXT
      margin = [hdpx(1),hdpx(2)]
      size = SIZE_TO_CONTENT
    }.__update(sub_txt)
  ]
}

local function mkShortHudHintFromList(controlElems, watch = null){
  local modifier = null
  let hasModifier = controlElems.len()==2
  if (hasModifier) {
    modifier = controlElems[1]
    controlElems = [controlElems[0]]
  }
  modifier = {hplace = ALIGN_RIGHT, size = SIZE_TO_CONTENT, children = modifier, padding = [0,0,0,hdpx(15)], pos=[0,-hdpx(2)]}
  controlElems.append(modifier)
  return {
    watch = [isGamepad,isTouch].extend(watch ?? [])
    size = SIZE_TO_CONTENT
    flow = hasModifier ? null : FLOW_HORIZONTAL
    valign = hasModifier ? null : ALIGN_CENTER
    children = isTouch.value ? null : controlElems
    vplace = ALIGN_CENTER
  }
}

local function shortHudHint(params = {textFunc=defTextFunc, alternateId=null}){
  const eventTypeToText = false
  if (type(params)=="string")
    params = { id = params}
  let textFunc = params?.textFunc ?? defTextFunc
  let hasBinding = mkHasBinding(params.id)
  let hasAltBinding = params?.alternateId != null ? mkHasBinding(params.alternateId) : null
  return function(){
    let column = isGamepad.value ? 1 : 0
    local textList = textListFromAction(params.id, column, eventTypeToText)
    if (textList.len()==0 && params?.alternateId != null) {
      textList = textListFromAction(params.alternateId, column, eventTypeToText)
    }
    let controlElems = buildElems(textList, {textFunc, compact = true})
    return mkShortHudHintFromList(controlElems, [hasBinding, hasAltBinding, generation])
  }
}

return {
  controlHudHint
  shortHudHint
  mkShortHudHintFromList
  mkHasBinding
}
