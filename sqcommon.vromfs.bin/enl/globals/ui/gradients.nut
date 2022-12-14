from "%enlSqGlob/ui_library.nut" import *

let { mkBitmapPicture } = require("%darg/helpers/bitmap.nut")

let colorParts = @(color) {
  r = (color >> 16) & 0xFF
  g = (color >> 8) & 0xFF
  b = color & 0xFF
  a = (color >> 24) & 0xFF
}
let partsToColor = @(c) Color(c.r, c.g, c.b, c.a)
let lerpColorParts = @(c1, c2, value) value <= 0 ? c1
  : value >= 1 ? c2
  : c1.map(@(v1, k) v1 + ((c2[k] - v1) * value + 0.5).tointeger())


let mkColoredGradientY = @(colorTop, colorBottom, height = 12)
  mkBitmapPicture(4, height,
    function(params, bmp) {
      let { w, h } = params
      let c1 = colorParts(colorBottom)
      let c2 = colorParts(colorTop)
      for (local y = 0; y < h; y++) {
        let color = partsToColor(lerpColorParts(c1, c2, y.tofloat() / (h - 1)))
        for (local x = 0; x < w; x++)
          bmp.setPixel(x, y, color)
      }
    })

let mkColoredGradientX = @(colorLeft, colorRight, width = 12, isAlphaPremultiplied = true)
  mkBitmapPicture(width, 4,
    function(params, bmp) {
      let { w, h } = params
      let c1 = colorParts(colorLeft)
      let c2 = colorParts(colorRight)
      for (local x = 0; x < w; x++) {
        let color = partsToColor(lerpColorParts(c1, c2, x.tofloat() / (w - 1)))
        for (local y = 0; y < h; y++)
          bmp.setPixel(x, y, color)
      }
    }, isAlphaPremultiplied ? "" : "!")

let mkDiagonalColoredGradient = @(cTop, cBottom, fromTop = true, width = 12, height = 12)
  mkBitmapPicture(width, height,
    function(params, bmp) {
      let { w, h } = params
      let c1 = colorParts(cTop)
      let c2 = colorParts(cBottom)
      for (local x = 0; x < w; x++)
        for (local y = 0; y < h; y++) {
          let realY = fromTop ? h - y - 1 : y
          let color = partsToColor(lerpColorParts(c1, c2, (x + realY).tofloat() / (w + h - 2)))
          bmp.setPixel(x, y, color)
        }
    })


let mkTwoSidesGradientX = @(sideColor, centerColor, isAlphaPremultiplied = true)
  mkBitmapPicture(12, 4,
    function(params, bmp) {
      let { w, h } = params
      let c1 = colorParts(sideColor)
      let c2 = colorParts(centerColor)
      let middle = 0.5
      for (local x = 0; x < w; x++) {
        let rel = x.tofloat() / (w - 1)
        let v = rel < middle ? rel / middle
          : rel > 1.0 - middle ? (1.0 - rel) / middle
          : 1.0
        let color = partsToColor(lerpColorParts(c1, c2, v))
        for(local y = 0; y < h; y++)
          bmp.setPixel(x, y, color)
      }
    }, isAlphaPremultiplied ? "" : "!")


return {
  mkColoredGradientX
  mkColoredGradientY
  mkTwoSidesGradientX
  mkDiagonalColoredGradient
}
