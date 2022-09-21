from "%darg/ui_imports.nut" import *
let { colPart } = require("%enlSqGlob/ui/designConst.nut")

let fontXXSmall = freeze({
  font = Fonts.trebuchet
  fontSize = colPart(0.193) // 12px
})

let fontXSmall = freeze({
  font = Fonts.trebuchet
  fontSize = colPart(0.225) // 14px
})

let fontSmall = freeze({
  font = Fonts.trebuchet
  fontSize = colPart(0.258) // 16px
})

let fontMedium = freeze({
  font = Fonts.trebuchet
  fontSize = colPart(0.29) // 18px
})

let fontLarge = freeze({
  font = Fonts.trebuchet
  fontSize = colPart(0.354) // 22px
})

let fontXLarge = freeze({
  font = Fonts.trebuchet
  fontSize = colPart(0.42) // 26px
})

let fontXXLarge = freeze({
  font = Fonts.trebuchet
  fontSize = colPart(0.564) // 35px
})

let fontGiant = freeze({
  font = Fonts.trebuchet
  fontSize = colPart(0.806) // 50px
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

let fontFontawesome = freeze({
  font = Fonts.fontawesome
  fontSize = colPart(0.338)
})


let fontTactical = freeze({
  font = Fonts.tactical
  fontSize = fontLarge.fontSize
})


return {
  fontXXSmall, fontXSmall, fontSmall, fontMedium, fontLarge, fontXLarge,
  fontXXLarge, fontGiant, fontLargeBold, fontXLargeBold, fontXXLargeBold,
  fontGiantBold, fontTactical, fontFontawesome
}
