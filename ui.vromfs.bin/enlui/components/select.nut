from "%enlSqGlob/ui_library.nut" import *

let colors = require("%ui/style/colors.nut")
let baseSelect = require("%darg/components/select.nut")
let baseSelectStyle = require("%darg/components/select.style.nut")

let rootStyle = clone baseSelectStyle.rootStyle
let elemStyle = baseSelectStyle.elemStyle.__merge({
  textCommonColor = colors.BtnTextNormal
  textActiveColor = colors.BtnTextActive
  textHoverColor = colors.BtnTextHover

  borderColor = colors.comboboxBorderColor

  bkgActiveColor = colors.BtnBgSelected
  bkgHoverColor = colors.BtnBgHover
  bkgNormalColor = colors.BtnBgNormal

})

return kwarg(function select(state, options, onClickCtor=null, isCurrent=null, textCtor=null, elem_style=null, root_style=null) {
  return baseSelect({
    state, options,
    onClickCtor,
    isCurrent,
    textCtor,
    elem_style=elemStyle.__merge(elem_style ?? {}),
    root_style = rootStyle.__merge(root_style ?? {})
  })
})
