from "%darg/ui_imports.nut" import *

let fontXXSmall = freeze({
  font = Fonts.trebuchet
  fontSize = fsh(1.111)
})

let fontXSmall = freeze({
  font = Fonts.trebuchet
  fontSize = fsh(1.296)
})

let fontSmall = freeze({
  font = Fonts.trebuchet
  fontSize = fsh(1.481)
})

let fontMedium = freeze({
  font = Fonts.trebuchet
  fontSize = fsh(1.666)
})

let fontLarge = freeze({
  font = Fonts.trebuchet
  fontSize = fsh(2.037)
})

let fontTactical = freeze({
  font = Fonts.tactical
  fontSize = fontLarge.fontSize
})

let fontXLarge = freeze({
  font = Fonts.trebuchet
  fontSize = fsh(2.407)
})

let fontXXLarge = freeze({
  font = Fonts.trebuchet
  fontSize = fsh(3.240)
})

let fontGiant = freeze({
  font = Fonts.trebuchet
  fontSize = fsh(4.629)
})

let fontLargeBold = freeze({
  font = Fonts.trebuchet_bold
  fontSize = fontLarge.fontSize
})

let fontXLargeBold = freeze({
  font = Fonts.trebuchet_bold
  fontSize = fontXLarge.fontSize
})

let fontXXLargeBold = freeze({
  font = Fonts.trebuchet_bold
  fontSize = fontXXLarge.fontSize
})

let fontGiantBold = freeze({
  font = Fonts.trebuchet_bold
  fontSize = fontGiant.fontSize
})


return {
  fontXXSmall, fontXSmall, fontSmall, fontMedium, fontLarge, fontXLarge,
  fontXXLarge, fontGiant, fontLargeBold, fontXLargeBold, fontXXLargeBold,
  fontGiantBold, fontTactical
}
