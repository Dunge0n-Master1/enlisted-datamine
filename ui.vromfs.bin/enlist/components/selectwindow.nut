from "%enlSqGlob/ui_library.nut" import *

from "%sqstd/underscore.nut" import chunk

let textInput = require("%ui/components/textInput.nut")
let textButton = require("%ui/components/textButton.nut")
let modalPopupWnd = require("%ui/components/modalPopupWnd.nut")
let { makeVertScroll } = require("%ui/components/scrollbar.nut")
let {dtext} = require("%ui/components/text.nut")

let hvrCl = Color(0,0,0)
let nrmClr = Color(180,180,180)
let function mkSelectBtn(name, opt, state, close=null) {
  let function onClick() {
    state(opt)
    close?()
  }
  let size = [fsh(30), SIZE_TO_CONTENT]
  return watchElemState( function(sf) {
    let group = ElemGroup()
    return {
      watch = [state]
      group
      behavior = [Behaviors.Button]
      clipChildren = true
      padding = [hdpx(2), hdpx(10)]
      children = {
        group
        behavior = Behaviors.Marquee
        size = [flex(), SIZE_TO_CONTENT]
        scrollOnHover = true
        children = {
          rendObj = ROBJ_TEXT
          text = name
          color = sf & S_HOVER ? hvrCl : nrmClr
        }
      }
      rendObj = ROBJ_BOX
      fillColor = sf & S_HOVER ? nrmClr : 0
      borderWidth = state.value == opt ? hdpx(1) : 0
      onClick
      size
    }
  })
}

let mkMkColumn = @(options, buttonCtor) {
  flow = FLOW_VERTICAL
  children = options.map(buttonCtor)
}

let mkSelectWindow = kwarg(function(
    uid, optionsState, state, filterState=null, title=null, filterPlaceHolder=null, columns=4, titleStyle=null, mkTxt = @(v) v,
    onAttach=null
  ) {
  assert(state instanceof Watched)
  let titleComp = title!=null ? dtext(title, {hplace = ALIGN_CENTER}.__update(titleStyle ?? {})) : null
  let filter = filterState!=null ? textInput(filterState, {placeholder = filterPlaceHolder ?? loc("filter")}) : null
  let buttonCtor = @(opt) mkSelectBtn(mkTxt(opt), opt, state, @() modalPopupWnd.remove(uid))
  let mkColumn = @(options) mkMkColumn(options, buttonCtor)
  let selectWindow = @() {
    size = [sw(70), sh(80)]
    hplace = ALIGN_CENTER
    vplace = ALIGN_CENTER
    color = Color(0,0,0,120)
    stopMouse = true
    key = uid
    watch = [optionsState]
    onAttach
    flow = FLOW_VERTICAL
    rendObj = ROBJ_FRAME
    borderWidth = hdpx(1)
    gap = hdpx(5)
    children = [
      titleComp
      filter
      makeVertScroll({
        size = [flex(), SIZE_TO_CONTENT]
        flow = FLOW_HORIZONTAL
        children = chunk(optionsState.value, optionsState.value.len()/columns + 1).map(mkColumn)
      })
    ]
    padding = hdpx(20)
  }
  return @() modalPopupWnd.add([0, 0],
    {
      size = [sw(100), sh(100)]
      uid
      fillColor = Color(0,0,0)
      padding = 0
      popupFlow = FLOW_HORIZONTAL
      popupValign = ALIGN_TOP
      popupOffset = 0
      margin = 0
      pos = [0,0]
      children = selectWindow
      popupBg = { rendObj = ROBJ_WORLD_BLUR_PANEL, fillColor = Color(0,0,0,120) }
    }
  )
})

let function mkOpenSelectWindowBtn(state, title, openMenu, mkTxt = @(v) v){
  return @() {
    watch = state
    flow = FLOW_HORIZONTAL
    size = [flex(), SIZE_TO_CONTENT]
    padding = [0, hdpx(5)]
    valign = ALIGN_CENTER
    children = [
      dtext(title, {color = Color(180,180,180), padding=0, margin=0})
      {size = [flex(), 0]}
      textButton.Transp(mkTxt(state.value), openMenu, {textMargin = [hdpx(2), hdpx(8)], margin = 0, minWidth = hdpx(50)})
    ]
  }
}


return {
  mkSelectWindow
  mkOpenSelectWindowBtn
}