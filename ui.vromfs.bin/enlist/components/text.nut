from "%enlSqGlob/ui_library.nut" import *

let { h2_txt, body_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let function header1(text) {
  return {
    rendObj = ROBJ_TEXT
    size = [flex(), SIZE_TO_CONTENT]
    text
    margin = [0,0,fsh(2),0]
  }.__update(h2_txt)
}


let function header2(text) {
  return {
    rendObj = ROBJ_TEXT
    size = [flex(), SIZE_TO_CONTENT]
    text
    margin = [0,0,fsh(1),0]
  }.__update(body_txt)
}


let function textarea(text) {
  return {
    rendObj = ROBJ_TEXTAREA
    size = [sw(35), SIZE_TO_CONTENT]
    behavior = Behaviors.TextArea
    text
    margin = [0,0,fsh(2),0]
  }
}



return {
  h1 = header1
  h2 = header2
  textarea
}