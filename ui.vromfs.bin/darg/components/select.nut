from "%darg/ui_imports.nut" import *

let defStyle = require("select.style.nut")

let mkSelItem = @(state, onClickCtor=null, isCurrent=null, textCtor=null, elemCtor = null, style=null) elemCtor==null ? function selItem(p, idx, list){
  let stateFlags = Watched(0)
  isCurrent = isCurrent ?? @(p, _idx) p==state.value
  let onClick = onClickCtor!=null ? onClickCtor(p, idx) : @() state(p)
  let text = textCtor != null ? textCtor(p, idx, stateFlags) : p
  let {textCommonColor, textActiveColor, textHoverColor, borderColor, borderRadius, borderWidth,
        bkgActiveColor, bkgHoverColor, bkgNormalColor, padding} = defStyle.elemStyle.__merge(style ?? {})
  return function(){
    let selected = isCurrent(p, idx)
    local nBw = borderWidth
    if (list.len() > 2) {
      if (idx != list.len()-1 && idx != 0)
        nBw = [borderWidth,0,borderWidth,borderWidth]
      if (idx == 1)
        nBw = [borderWidth,0,borderWidth,0]
    }
    return {
      size = SIZE_TO_CONTENT
      rendObj = ROBJ_BOX
      onElemState = @(sf) stateFlags(sf)
      behavior = Behaviors.Button
      valign = ALIGN_CENTER
      halign = ALIGN_CENTER
      padding
      stopHover = true
      watch = [stateFlags, state]
      children = {
        rendObj = ROBJ_TEXT, text=text,
        color = (stateFlags.value & S_HOVER)
          ? textHoverColor
          : selected
            ? textActiveColor
            : textCommonColor,
        padding = borderRadius
      }
      onClick
      borderColor
      borderWidth = nBw
      borderRadius = list.len()==1 || (borderRadius ?? 0)==0
        ? borderRadius
        : idx==0
          ? [borderRadius, 0, 0, borderRadius]
          : idx==list.len()-1
            ? [0,borderRadius, borderRadius, 0]
            : 0
      fillColor = stateFlags.value & S_HOVER
        ? bkgActiveColor
        : selected
          ? bkgHoverColor
          : bkgNormalColor
      xmbNode = XmbNode()
    }
  }
}  : elemCtor

let select = kwarg(function selectImpl(state, options, onClickCtor=null, isCurrent=null, textCtor=null, elemCtor=null, elem_style=null, root_style=null, flow = FLOW_HORIZONTAL){
  let selItem = mkSelItem(state, onClickCtor, isCurrent, textCtor, elemCtor, elem_style)
  return function(){
    return {
      size = SIZE_TO_CONTENT
      flow = flow
      children = options.map(selItem)
      xmbNode = XmbNode()
    }.__update(root_style ?? defStyle.rootStyle)
  }
})

return select