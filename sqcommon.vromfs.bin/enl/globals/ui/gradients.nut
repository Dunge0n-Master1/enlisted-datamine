from "%enlSqGlob/ui_library.nut" import *

let { mkBitmapPicture } = require("%darg/helpers/bitmap.nut")
let { lerpClamped } = require("%sqstd/math.nut")
let { sqrt } = require("math")


let gradCircCornerSize = 20
let getDistance = @(x, y) sqrt(x * x + y * y)
let mkWhite = @(part) part + (part << 8) + (part << 16) + (part << 24)

let colorParts = @(color) {
  r = (color >> 16) & 0xFF
  g = (color >> 8) & 0xFF
  b = color & 0xFF
  a = (color >> 24) & 0xFF
}

let partsToColor = @(c) Color(c.r+0.5, c.g+0.5, c.b+0.5, c.a+0.5) // will internally round down and cast to integer

let function lerpColorParts(c1, c2, tmp, k) {
  if (k <= 0)
    return c1
  if (k >= 1)
    return c2
  let q = 1-k
  tmp.r = c1.r * q + c2.r * k
  tmp.g = c1.g * q + c2.g * k
  tmp.b = c1.b * q + c2.b * k
  tmp.a = c1.a * q + c2.a * k
  return tmp
}

let mkColoredGradientY = kwarg(@(colorTop, colorBottom, height = 12, isAlphaPremultiplied = true)
  mkBitmapPicture(4, height,
    function(params, bmp) {
      let { w, h } = params
      let c1 = colorParts(colorBottom)
      let c2 = colorParts(colorTop)
      let tmp = {r=0, g=0, b=0, a=0}
      for (local y = 0; y < h; y++) {
        let color = partsToColor(lerpColorParts(c1, c2, tmp, y.tofloat() / (h - 1)))
        for (local x = 0; x < w; x++)
          bmp.setPixel(x, y, color)
      }
    }, isAlphaPremultiplied ? "" : "!")
)

let mkColoredGradientX = kwarg(@(colorLeft, colorRight, width = 12, isAlphaPremultiplied = true)
  mkBitmapPicture(width, 4,
    function(params, bmp) {
      let { w, h } = params
      let c1 = colorParts(colorLeft)
      let c2 = colorParts(colorRight)
      let tmp = {r=0, g=0, b=0, a=0}
      for (local x = 0; x < w; x++) {
        let color = partsToColor(lerpColorParts(c1, c2, tmp, x.tofloat() / (w - 1)))
        for (local y = 0; y < h; y++)
          bmp.setPixel(x, y, color)
      }
    }, isAlphaPremultiplied ? "" : "!")
)

let mkDiagonalColoredGradient = kwarg(@(cTop, cBottom, fromTop = true, width = 12, height = 12)
  mkBitmapPicture(width, height,
    function(params, bmp) {
      let { w, h } = params
      let c1 = colorParts(cTop)
      let c2 = colorParts(cBottom)
      let tmp = {r=0, g=0, b=0, a=0}
      for (local x = 0; x < w; x++)
        for (local y = 0; y < h; y++) {
          let realY = fromTop ? h - y - 1 : y
          let color = partsToColor(lerpColorParts(c1, c2, tmp, (x + realY).tofloat() / (w + h - 2)))
          bmp.setPixel(x, y, color)
        }
    })
)

let mkTwoSidesGradientX = kwarg(@(sideColor, centerColor, width=12, isAlphaPremultiplied = true)
  mkBitmapPicture(width, 4,
    function(params, bmp) {
      let { w, h } = params
      let c1 = colorParts(sideColor)
      let c2 = colorParts(centerColor)
      let tmp = {r=0, g=0, b=0, a=0}
      let middle = 0.5
      for (local x = 0; x < w; x++) {
        let rel = x.tofloat() / (w - 1)
        let v = rel < middle ? rel / middle
          : rel > 1.0 - middle ? (1.0 - rel) / middle
          : 1.0
        let color = partsToColor(lerpColorParts(c1, c2, tmp, v))
        for(local y = 0; y < h; y++)
          bmp.setPixel(x, y, color)
      }
    }, isAlphaPremultiplied ? "" : "!")
)

let mkHorScrollMask = @(imgWidth, offsets)
  mkBitmapPicture(imgWidth, 2,
    function(params, bmp) {
      let { w, h } = params
      for(local x = 0; x < w; x++) {
        let rightGradPos = w - offsets[1] - 1
        let aFactor = x < offsets[0] ? lerpClamped(0, offsets[0], 0, 1.0, x)
          : x >= rightGradPos  ? lerpClamped(rightGradPos, w - 1, 1.0, 0, x)
          : 1
        let part = (0xFF * aFactor).tointeger()
        let color = Color(part, part, part, part)
        for(local y = 0; y < h; y++)
          bmp.setPixel(x, y, color)
      }
    }
  )


let gradRadial = mkBitmapPicture(gradCircCornerSize * 2, gradCircCornerSize * 2,
  function(_, bmp) {
    for (local y = 0; y < gradCircCornerSize * 2; y++)
      for (local x = 0; x < gradCircCornerSize * 2; x++) {
        let distance = getDistance(x - gradCircCornerSize, y - gradCircCornerSize)
        bmp.setPixel(x, y, mkWhite((0xFF * max(0.0, 1.0 - ((distance + 1) / gradCircCornerSize))).tointeger()))
      }
  })


return {
  mkColoredGradientX
  mkColoredGradientY
  mkTwoSidesGradientX
  mkDiagonalColoredGradient
  mkHorScrollMask
  gradRadial
}
