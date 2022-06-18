from "%enlSqGlob/ui_library.nut" import *

let {sub_txt} = require("%enlSqGlob/ui/fonts_style.nut")
let {isGamepad} = require("%ui/control/active_controls.nut")
let {textListFromAction, buildElems, makeSvgImgFromText} = require("%ui/control/formatInputBinding.nut")
let { HUD_TIPS_HOTKEY_FG } = require("%ui/hud/style.nut")
let hotkeyColor = HUD_TIPS_HOTKEY_FG
let textColor = Color(180,180,180,180)

let style = {
  hotkeyColor
  textColor
}
let controlOpenTag=@"{controls{"
let closeTag = @"}}"

let token = @(tokenType, value) { type = tokenType, value }

let function tokenizeRow(text) {
  let res = []
  local start = 0
  local end = 0
  do {
    start = text.indexof(controlOpenTag, end)
    if (start == null)
      break
    let close = text.indexof(closeTag, start + controlOpenTag.len())
    if (close == null)
      break
    if (start > end)
      res.append(token("text", text.slice(end, start)))
    res.append(token("control", text.slice(start + controlOpenTag.len(), close)))
    end = close + closeTag.len()
  } while(start != null)

  if (end < text.len() - 1)
    res.append(token("text", text.slice(end)))

  return res
}

let function tokenizeTextWithShortcuts(text){
  let rows = text.split("\r\n")
  return rows.map(tokenizeRow)
}


let function textFunc(text){
  return {
    text
    color = hotkeyColor, rendObj = ROBJ_TEXT
    padding = [0, hdpx(4)]
    vplace = ALIGN_CENTER
  }.__update(sub_txt)
}
let function makeControlText(text){
  return (text==null || text=="") ? null
  : {
    rendObj = isGamepad.value ? null : ROBJ_FRAME
    borderWidth = hdpx(1)
    color = hotkeyColor
    vplace = ALIGN_CENTER
    children = textFunc(text)
  }
}

let imgHeight = calc_str_box("A", sub_txt)[1]

let function mkControlImg(text, params = {}){
  return (text!=null && text!="")
    ? {size= [ SIZE_TO_CONTENT, imgHeight*1.15] valign = ALIGN_CENTER children = @() makeSvgImgFromText(text, {height=imgHeight}.__update(params))}
    : null
}
let defP = {
  textFunc = makeControlText
  eventTextFunc = textFunc
  imgFunc = mkControlImg
  compact = false
  eventTypesAsTxt = true
}
local function controlView(textList, params = null) {
  params = defP.__merge(params ?? {})
  return {
    flow = FLOW_HORIZONTAL
    gap = hdpx(2)
    children = buildElems(textList, params)
  }
}

let function controlHint(control, params = null) {
  let column = isGamepad.value ? 1 : 0
  let textList = textListFromAction(control, column)
  if (textList.filter(@(v) v!="").len() == 0)
    return null
  return controlView(textList, params)
}

let dtext = @(text){
  color = textColor
  rendObj = ROBJ_TEXT
  text
}.__update(sub_txt)

let EmptyControl = {}
let tokensView = {
  control = function(tok) {
    let v = tok.value
    let text = tok?.text ?? ""
    let controlComp = controlHint(v)
    if (controlComp==null)
      return EmptyControl
    let name = loc($"controls/{v}")
    return {
      flow = FLOW_HORIZONTAL
      valign = ALIGN_CENTER
      size = [flex(), SIZE_TO_CONTENT]
      children = [
        controlComp
        {
          size = [flex(), SIZE_TO_CONTENT]
          clipChildren = true
          children = {
            size = [flex(), SIZE_TO_CONTENT]
            behavior = Behaviors.Marquee
            children = dtext($" - {name}{text}")
            delay = [1,2]
            speed = hdpx(20)
          }
        }
      ]
    }
  }

  text = @(v) dtext(loc(v.value))
}

let function viewControlToken(token_to_process) {
  let ctor = tokensView[token_to_process.type]
  return ctor ? ctor(token_to_process) : null
}

let function glueTokens(hintsTokens){
  //better not to glue, but split differently instead
  let res = []
  foreach (h in hintsTokens){
    let tt = []
    foreach (idx, tok in h){
      if (tok?.type != "text" || idx == 0)
        tt.append(tok)
      else{
        tt[idx-1] = tt[idx-1].__merge({text = tok?.value})
      }
    }
    res.append(tt)
  }
  return res
}

let function makeHintsRows(hintsTokens) {
  return glueTokens(hintsTokens).map(function(textRow) {
    let children = textRow.map(viewControlToken)
    if (children.contains(EmptyControl) || children==null || children.len()==0) {
      return null
    }
    return {
      size = [flex(), SIZE_TO_CONTENT]
      flow = FLOW_HORIZONTAL
      valign = ALIGN_CENTER
      children
    }
  })
}


return {
  tokenizeTextWithShortcuts
  makeHintsRows
  controlHint
  controlView
  style
}