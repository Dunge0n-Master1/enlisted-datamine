from "%enlSqGlob/ui_library.nut" import *

let {logerr} = require("dagor.debug")
let {fontawesome} = require("%enlSqGlob/ui/fonts_style.nut")
let fa = require("%ui/components/fontawesome.map.nut")
let defParams = {
  rendObj = ROBJ_INSCRIPTION
  validateStaticText = false
}.__update(fontawesome)

let function faComp(symbol, params = null) {
  let symType = type(symbol)
  if (symType == "string" && symbol in fa && params == null)
    return {
      text = fa[symbol]
    }.__update(defParams)
  else if (symType == "table")
    return defParams.__merge(symbol)
  else if (symType == "string" && symbol in fa && type(params) == "table")
    return defParams.__merge({text=fa[symbol]}, params)
  log($"faComp, {symbol}", getstackinfos(2))
  logerr("incorrect faComp arguments")
  return null
}

return faComp