from "%enlSqGlob/ui_library.nut" import *

let { h2_txt, tiny_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let {defTxtColor, noteTxtColor, bigPadding, textBgBlurColor, smallPadding,
  hoverBgColor, defBgColor, hoverTxtColor, activeTxtColor} = require("%enlSqGlob/ui/viewConst.nut")

let txt = @(text) {
  rendObj = ROBJ_TEXT
  color = defTxtColor
}.__update(typeof text != "table" ? { text = text } : text)

let note = @(text) {
  rendObj = ROBJ_TEXT
  color = noteTxtColor
}.__update(typeof text != "table" ? { text = text } : text, tiny_txt)

let noteTextArea = @(text) {
  size = [flex(), SIZE_TO_CONTENT]
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  color = noteTxtColor
}.__update(typeof text != "table" ? { text } : text, tiny_txt)

let function bigTextWithNote(noteText, mainText) {
  let mainTextParams = (typeof mainText == "table") ? mainText : { text = mainText }
  return {
    flow = FLOW_HORIZONTAL
    children = [
      note(noteText)
      {
        rendObj = ROBJ_TEXT
        color = defTxtColor
        margin = [0, bigPadding]
      }.__update(h2_txt, mainTextParams)
    ]
  }
}

let sceneHeaderText = @(text) {
  rendObj = ROBJ_TEXT
  text
  color = defTxtColor
}.__update(h2_txt)

let sceneHeader = @(text) {
  rendObj = ROBJ_WORLD_BLUR_PANEL
  color = textBgBlurColor
  padding = [0, smallPadding]
  children = sceneHeaderText(text)
}

let function btn(params){
  let sFlags = params?.stateFlags ?? Watched(0)
  let group = params?.group ?? ElemGroup()
  let text = params?.text
  let fillColorCtr = params?.fillColorCtr ?? @(flags) (flags & S_HOVER) ? hoverBgColor : defBgColor
  let colorCtr = params?.colorCtr ?? @(flags) (flags & S_HOVER) ? hoverTxtColor : defTxtColor
  return @() {
    watch = [sFlags]
    onElemState = @(sf) sFlags.update(sf)
    group = group
    rendObj = ROBJ_BOX
    size = SIZE_TO_CONTENT
    padding = hdpx(2)
    children = {
      color = colorCtr(sFlags.value)
      rendObj = ROBJ_TEXT text=text
    }
    fillColor = fillColorCtr(sFlags.value)
    borderWidth = 0
    behavior = [Behaviors.Button]
    halign = ALIGN_CENTER
  }.__update(params)
}


local function mCtor(ctor, selCtor, watch, checkSelected=@(_opt, idx, watch) watch.value==idx, onSelect=null, clickHandler = null, dblClickHandler = null){
  return function (opt, idx) {
    let group = ElemGroup()
    let stateFlags = Watched(0)
    onSelect = onSelect ?? @(_opt, idx) watch(idx)
    clickHandler = clickHandler ?? @(_opt, _idx) null
    dblClickHandler = dblClickHandler ?? @(_opt, _idx) null
    return @(){
      children = checkSelected(opt,idx,watch) ? selCtor(opt, idx, group, stateFlags) : ctor(opt, idx, group, stateFlags)
      size = SIZE_TO_CONTENT
      behavior = Behaviors.Button
      onElemState=@(sf) stateFlags(sf)
      watch = stateFlags
      onClick = @() onSelect(opt, idx) || clickHandler(opt, idx)
      onDoubleClick = @() dblClickHandler(opt,idx)
    }
  }
}

let function genericSelList(params = {}){
  //ctors for selected and regular elems
  //watch is int (index in options), list is list of anything
  let watch = params.watch
  let options = params.options
  let ctor = params.ctor
  let selCtor = params?.selCtor ?? ctor
  let checkSelected = params?.checkSelected ?? @(_opt, idx, obs) obs.value==idx
  let onSelect = params?.onSelect
  return function(){
    let ct = mCtor(ctor, selCtor, watch, checkSelected, onSelect, params?.clickHandler, params?.dblClickHandler)
    return {
      flow = FLOW_HORIZONTAL
      children = options.map(ct)
      gap = hdpx(1)
      size = SIZE_TO_CONTENT
      watch = watch
    }.__update(params?.style ?? {})
  }
}

let function select(watch, options, objStyle = {flow=FLOW_HORIZONTAL, gap=hdpx(5) rendObj=ROBJ_SOLID color=Color(0,0,0,50)}){
  return genericSelList({
    watch=watch, options=options, style = objStyle
    checkSelected = @(opt, _idx, watch) watch.value==opt
    ctor = @(opt, idx, _group, _stateFlags) txt({text=opt, key=idx})
    selCtor = @(opt, idx, _group, _stateFlags) txt({text=opt color = Color(255,255,255), key=idx})
    onSelect = @(opt, _idx) watch(opt)
  })
}

let function autoscrollText(allParams) {
  let { text, size = [flex(), SIZE_TO_CONTENT], group = null, color = null, vplace = null, textParams = {}, params = {} } = allParams
  return {
    size
    group
    vplace
    clipChildren = true
    children = {
      size
      behavior = group ? Behaviors.Marquee : [Behaviors.Marquee, Behaviors.Button]
      skipDirPadNav = group == null
      group
      scrollOnHover = true
      children = txt({ text, color }.__update(textParams))
    }.__merge(params)
  }
}

let progressBar = kwarg(function(value, height = hdpx(7), width = flex(),
  color = activeTxtColor, bgColor = defBgColor, addValue = 0,
  addValueColor = activeTxtColor, addValueAnimations = null, customStyle = {}
) {
  let valueProgress = clamp(100.0 * value, 0, 100)
  return {
    rendObj = ROBJ_BOX
    size = [width, height]
    flow = FLOW_HORIZONTAL
    margin = [smallPadding, 0]
    fillColor = bgColor
    borderColor = color
    borderWidth = hdpx(1)
    children = [
      {
        rendObj = ROBJ_SOLID
        size = [pw(valueProgress), flex()]
        color = color
      }
      addValue > 0
        ? {
            rendObj = ROBJ_SOLID
            size = [pw(clamp(100.0 * addValue, 0, 100 - valueProgress)), flex()]
            color = addValueColor
            transform = { pivot = [0, 0] }
            animations = addValueAnimations
          }
        : null
    ]
  }.__update(customStyle)
})

return {
  txt
  note
  noteTextArea
  autoscrollText
  bigTextWithNote
  sceneHeader
  sceneHeaderText
  btn
  horSelect = @(watch, options, style={gap=hdpx(5) rendObj=ROBJ_SOLID color=Color(0,0,0,50)})
    select(watch, options, style.__merge({flow=FLOW_HORIZONTAL}))
  verSelect = @(watch, options, style={gap=hdpx(5) rendObj=ROBJ_SOLID color=Color(0,0,0,50)})
    select(watch, options, style.__merge({flow=FLOW_VERTICAL}))
  select = genericSelList
  progressBar
}