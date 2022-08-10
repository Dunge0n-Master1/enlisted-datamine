from "%enlSqGlob/ui_library.nut" import *

let formatters = require("textFormatters.nut")
let mkFormatAst = require("%darg/helpers/mkFormatAst.nut")
let { isPlatformRelevant } = require("%dngscripts/platform.nut")
let { split } = require("%sqstd/string.nut")
let { defStyle } = formatters

let filter = @(object) ("platform" in object) && !isPlatformRelevant(split(object.platform, ","))
let defParams = { formatters, style = defStyle, filter }
let formatText = mkFormatAst(defParams)

let function mkFormatText(style, overrides = null) {
  let params = clone defParams
  params.style = params.style.__merge(style)
  if (typeof formatters == "table")
    params.formatters = params.formatters.__merge(overrides)
  return mkFormatAst(params)
}

return {
  mkFormatText
  formatText
  defStyle
}
