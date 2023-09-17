from "%enlSqGlob/ui_library.nut" import *

let fontTactical = freeze({
  font = Fonts.tactical
  fontSize = hdpxi(21)
})

let fontSub = freeze({
  font = Fonts.trebuchet
  fontSize = hdpxi(16)
})

let fontBody = freeze({
  font = Fonts.trebuchet
  fontSize = hdpxi(22)
})

let fontHeading2 = freeze({
  font = Fonts.trebuchet
  fontSize = hdpxi(26)
})

let fontHeading1 = freeze({
  font = Fonts.trebuchet
  fontSize = hdpxi(34)
})

let fontTitle = freeze({
  font = Fonts.trebuchet
  fontSize = hdpxi(48)
})

let fontGiant = freeze({
  font = Fonts.trebuchet
  fontSize = hdpxi(62)
})


let fontawesome = freeze({
  font = Fonts.fontawesome
  fontSize = hdpxi(21)
})

return {
  fontGiant, fontTitle, fontHeading1, fontHeading2, fontBody, fontSub, fontawesome, fontTactical}
