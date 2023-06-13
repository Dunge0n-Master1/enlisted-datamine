from "%darg/ui_imports.nut" import *
let { colPart } = require("%enlSqGlob/ui/designConst.nut")

let tactical_font = freeze({
  font = Fonts.tactical
  fontSize = colPart(0.354)//fsh(1.944) //21px
})

let tiny_txt = freeze({
  font = Fonts.trebuchet
  fontSize = colPart(0.193) //fsh(1.203) //13px
})

let sub_txt = freeze({
  font = Fonts.trebuchet
  fontSize = colPart(0.258) //fsh(1.481) //16px
})
let body_txt = freeze({
  font = Fonts.trebuchet
  fontSize = colPart(0.354) //fsh(2.037) //22px
})
let h2_txt = freeze({
  font = Fonts.trebuchet
  fontSize = colPart(0.42)//fsh(2.407) //26px
})
let h1_txt = freeze({
  font = Fonts.trebuchet
  fontSize = colPart(0.564)//fsh(3.2) //34.5px
})
let h0_txt = freeze({
  font = Fonts.trebuchet
  fontSize = colPart(0.806)//fsh(4.6) //49.68px
})
let giant_txt = freeze({
  font = Fonts.trebuchet
  fontSize = colPart(1)//fsh(5.7) //61.56px
})

let body_bold_txt = freeze({
  font = Fonts.trebuchet_bold
  fontSize = body_txt.fontSize
})
let h2_bold_txt = freeze({
  font = Fonts.trebuchet_bold
  fontSize = h2_txt.fontSize
})
let h1_bold_txt = freeze({
  font = Fonts.trebuchet_bold
  fontSize = h1_txt.fontSize
})
let tiny_bold_txt = freeze({
  font = Fonts.trebuchet_bold
  fontSize = tiny_txt.fontSize
})

let fontawesome = freeze({
  font = Fonts.fontawesome
  fontSize = colPart(0.338)//fsh(1.944) //21px
})

return {
  giant_txt, h0_txt, h1_txt, h2_txt, body_txt, sub_txt, tiny_txt,
  body_bold_txt, h2_bold_txt, tiny_bold_txt, h1_bold_txt,
  fontawesome, tactical_font}
