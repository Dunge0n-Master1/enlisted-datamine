from "%darg/ui_imports.nut" import *

let tactical_font = freeze({ font = Fonts.tactical, fontSize = fsh(1.944) })

let tiny_txt = freeze({
  font = Fonts.trebuchet
  fontSize = fsh(1.203)
})

let sub_txt = freeze({
  font = Fonts.trebuchet
  fontSize = fsh(1.481)
})
let body_txt = freeze({
  font = Fonts.trebuchet
  fontSize = fsh(2.037)
})
let h2_txt = freeze({
  font = Fonts.trebuchet
  fontSize = fsh(2.407)
})
let h1_txt = freeze({
  font = Fonts.trebuchet
  fontSize = fsh(3.2)
})
let h0_txt = freeze({
  font = Fonts.trebuchet
  fontSize = fsh(4.6)
})
let giant_txt = freeze({
  font = Fonts.trebuchet
  fontSize = fsh(5.7)
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
  fontSize = fsh(1.944)
})

return {
  giant_txt, h0_txt, h1_txt, h2_txt, body_txt, sub_txt, tiny_txt,
  body_bold_txt, h2_bold_txt, tiny_bold_txt, h1_bold_txt,
  fontawesome, tactical_font}
