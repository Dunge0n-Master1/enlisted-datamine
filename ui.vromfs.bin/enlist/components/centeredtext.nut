from "%enlSqGlob/ui_library.nut" import *

let {h2_txt} = require("%enlSqGlob/ui/fonts_style.nut")
let function centeredText(text, options={}) {
  return {
    rendObj = ROBJ_TEXT
    text
    key = options?.key ?? text

    hplace = ALIGN_CENTER
    vplace = ALIGN_CENTER
  }.__update(h2_txt)
}


return centeredText
