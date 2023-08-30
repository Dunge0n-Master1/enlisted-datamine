from "%enlSqGlob/ui_library.nut" import *

let {fontBody} = require("%enlSqGlob/ui/fontsStyle.nut")
let {ControlBgOpaque, BtnTextHover, BtnTextActive, BtnTextHilite, BtnTextNormal, BtnBgNormal, BtnBgHover, BtnBgActive} = require("%ui/style/colors.nut")
let { makeHorizScroll } = require("%ui/components/scrollbar.nut")
let { safeAreaHorPadding } = require("%enlSqGlob/safeArea.nut")

let saSize = Computed(@() sw(100)-2*safeAreaHorPadding.value)

let function tabCtor(tab, is_current, handler) {
  let grp = ElemGroup()
  let stateFlags = Watched(0)

  return function() {
    let isHover = stateFlags.value & S_HOVER
    let isFocus = stateFlags.value & S_KB_FOCUS
    local fillColor, textColor, borderColor
    if (is_current || isFocus) {
      textColor = isHover ? BtnTextHover : BtnTextActive
      fillColor = isHover ? BtnBgHover : BtnBgActive
    } else {
      textColor = isHover ? BtnTextHilite : BtnTextNormal
      fillColor = BtnBgNormal
    }
    borderColor = isHover ? BtnTextHilite : BtnTextNormal

    return {
      key = tab
      rendObj = ROBJ_BOX
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      size = SIZE_TO_CONTENT
      watch = stateFlags
      group = grp

      behavior = Behaviors.Button
      skipDirPadNav = true

      sound = {
        click  = "ui/button_click"
        hover  = "ui/menu_highlight"
        active = "ui/button_action"
      }

      fillColor
      borderColor
      borderWidth = [0, 0, hdpx(1), 0]

      onClick = handler
      onElemState = @(sf) stateFlags.update(sf)

      children = {
        rendObj = ROBJ_TEXT
        margin = [fsh(1), fsh(2)]
        color = textColor

        text = tab.text
        group = grp
      }.__update(fontBody)
    }
  }
}


let function tabsHolder(_params, children) {
  let width = min(sw(90), saSize.value)
  return makeHorizScroll({
    rendObj = ROBJ_BOX
    flow = FLOW_HORIZONTAL
    padding = [0, hdpx(3)]
    gap = hdpx(3)
    children

    fillColor = ControlBgOpaque
    borderColor = Color(100, 100, 100, 120)
    borderWidth = [0, 0, hdpx(1), 0]
  }, {
    size = [width, SIZE_TO_CONTENT]
    root = {
      key = "settingsHeaderRoot"
      behavior = Behaviors.Pannable
      wheelStep = 1
    }
  })
}


return function(params = {/*tabs:List<tabs>, currentTab:string, onChange:closure*/}) {
  let children = params.tabs.map(function(item) {
    return tabCtor(item, item.id == params.currentTab, @() params.onChange(item))
  })
  return tabsHolder(params, children)
}
