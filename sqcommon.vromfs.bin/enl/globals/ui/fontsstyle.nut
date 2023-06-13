from "%darg/ui_imports.nut" import *
let fonts = require("fonts_style.nut")



/**


    !!!THIS IS JUST COPY of fonts_style.nut!!!
    DO NOT ADD ANYTHING HERE!
    WE KEEP IT only for simpler merging of 'new' desgin




*/






//!!!
let fontXXSmall = fonts.tiny_txt //should be 12px, but tiny_txt =13px
//!!!
let fontXSmall = fonts.tiny_txt //should be 14px, but tiny_txt =13px

let fontSmall = fonts.sub_txt //should be 16px

//!!!
let fontMedium = fonts.sub_txt //should be 18px but sub_txt is 16px
let fontLarge = fonts.body_txt // 22px

let fontXLarge = fonts.h2_txt  // 26px

let fontXXLarge = fonts.h1_txt //35px
let fontGiant = fonts.h0_txt // 50px

//let fontLargeBold = fonts.body_bold_txt

//let fontXLargeBold = fonts.h2_bold_txt

//let fontXXLargeBold = fonts.h1_bold_txt

let fontFontawesome = fonts.fontawesome

let fontTactical = fonts.tactical_font


return {
  fontXXSmall, fontXSmall, fontSmall, fontMedium, fontLarge, fontXLarge,
  fontXXLarge, fontGiant,
  //fontLargeBold, fontXLargeBold, fontXXLargeBold,
  fontTactical, fontFontawesome
}
