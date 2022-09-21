from "%enlSqGlob/ui_library.nut" import *

let {body_txt} = require("%enlSqGlob/ui/fonts_style.nut")
let {CONTROL_BG_COLOR} = require("%ui/hud/style.nut")
let cursors = require("%ui/style/cursors.nut")

let JB = require("%ui/control/gui_buttons.nut")


let optionLabel = require("%ui/components/optionLabel.nut")
let textButton = require("%ui/components/textButton.nut")
let scrollbar = require("%ui/components/scrollbar.nut")
let active_controls = require("%ui/control/active_controls.nut")
let settingsHeaderTabs = require("settingsHeaderTabs.nut")


let windowButtons = @(params) function() {
  return {
    size = [flex(), SIZE_TO_CONTENT]
    vplace = ALIGN_BOTTOM
    hplace = ALIGN_RIGHT
    flow = FLOW_HORIZONTAL
    halign = ALIGN_RIGHT
    valign = ALIGN_CENTER
    rendObj = ROBJ_SOLID
    color = CONTROL_BG_COLOR

    children = params?.buttons || [
      textButton(loc("mainmenu/btnApply"), params.applyHandler(params.options))
      textButton(loc("mainmenu/btnCancel"), params.cancelHandler)
    ]

    eventHandlers = {
      [JB.B] = @(_event) params.cancelHandler(),
    }
  }
}

let function optionRowContainer(children) {
  let stateFlags = Watched(0)
  return @() {
    watch = stateFlags
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    behavior = Behaviors.Button
    onElemState = @(sf) stateFlags(sf)
    skipDirPadNav = true
    children
    rendObj = ROBJ_BOX
    margin = [0, fsh(8)]
    fillColor = stateFlags.value & S_HOVER ? Color(60, 60, 70, 150) : Color(20, 20, 20, 150)
    borderWidth = stateFlags.value & S_HOVER ? [hdpx(2), 0] : 0
    borderColor = Color(20,90,120,10)
    gap = fsh(2)
  }
}

let function makeOptionRow(opt) {
  let group = ElemGroup()
  let xmbNode = XmbNode()
  if ("rowCtor" in opt)
    return opt.rowCtor(opt, group) ?? {}

  let widget = opt.widgetCtor(opt, group, xmbNode)
  if (!widget)
    return {}

  let baseHeight = fsh(4.8)
  let height = baseHeight
  let label = optionLabel(opt, group)

  let row = {
    padding = [0, hdpx(12)]
    size = [flex(), height]
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    gap = fsh(2)
    children = [
      label
      widget
    ]
  }

  return optionRowContainer(row)
}

let sepColor = Color(120,120,120)
let sepLine = freeze({size = [flex(), hdpx(2)], rendObj = ROBJ_SOLID, color=sepColor})

let function mkSeparator(opt){
  let hasName = "name" in opt
  return freeze({
    size = [flex(), SIZE_TO_CONTENT]
    valign = ALIGN_CENTER
    flow = FLOW_VERTICAL
    padding = [hdpx(20), hdpx(20), 0, hdpx(20)]
    gap = hdpx(10)
    children = hasName ? [
      {
        rendObj = ROBJ_TEXT text = opt?.name color = sepColor
        fontFxColor = Color(0, 0, 0, 90)
        fontFxFactor = min(hdpx(48), 64)
        fontFx = FFT_GLOW
        fontFxOffsX = hdpx(1)
        fontFxOffsY = hdpx(1)
      }.__update(body_txt)
      sepLine
    ] : sepLine
  })
}
let isSeparator = @(v) v?.isSeparator

let function optionsPage(params) {
  let xmbNode = XmbContainer({wrap=true})
  let {options, currentTab} = params

  return function() {
    let optionControls = options.filter(@(v) v.tab == currentTab.value)
      .filter(@(val, idx, arr) !isSeparator(val) || ((idx+1 < arr.len()) && !isSeparator(arr?[idx+1])))
      .map(@(v) isSeparator(v) ? mkSeparator(v) : makeOptionRow(v))

    return {
      size = flex()
      watch = params.currentTab
      behavior = Behaviors.Button
      onClick = params?.onPageClick

      children = scrollbar.makeVertScroll({
        flow = FLOW_VERTICAL
        xmbNode
        key = params.currentTab.value
        size = [flex(), SIZE_TO_CONTENT]
        padding = [fsh(1), 0]
        gap = hdpx(4)
        clipChildren = true
        animations = [
          { prop=AnimProp.opacity, from=0, to=1, duration=0.2, play=true, easing=InOutCubic}
          { prop=AnimProp.opacity, from=1, to=0, duration=0.2, playFadeOut=true, easing=InOutCubic}
        ]

        children = optionControls
      },{
        rootBase = class{
          behavior = [Behaviors.Pannable]
          wheelStep = 0.82
        }
      })
    }
  }
}


let function settingsMenu(params) {

  return @(){
    size = [sw(100), sh(100)]
    cursor = cursors.normal
    watch = [active_controls.isGamepad]
    key = params?.key
    children = {
      //parallaxK = active_controls.isGamepad.value ? -0.1 : 0
      //behavior = [Behaviors.Parallax]
      transform = {}
      hplace = ALIGN_CENTER
      vplace = ALIGN_CENTER
      size = params?.size ?? [fsh(90), sh(80)]
      rendObj = ROBJ_WORLD_BLUR
      color = Color(120,120,120,255)
      flow = FLOW_VERTICAL
      //stopHotkeys = true
      stopMouse = true
      behavior = Behaviors.ActivateActionSet
      actionSet = "StopInput"

      children = [
        settingsHeaderTabs(params)
        optionsPage(params)
        windowButtons(params)
      ]
    }
    animations = [
      { prop=AnimProp.opacity, from=0, to=1, duration=0.2, play=true, easing=InOutCubic}
      { prop=AnimProp.opacity, from=1, to=0, duration=0.2, playFadeOut=true, easing=InOutCubic}
    ]
  }
}


return settingsMenu
