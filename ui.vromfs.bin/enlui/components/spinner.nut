from "%enlSqGlob/ui_library.nut" import *

let { fullTransparentBgColor, defBdColor } = require("%enlSqGlob/ui/designConst.nut")
let { PI } = require("%sqstd/math.nut")


return function(height = hdpxi(40), opacity = 0.3, color = 0x03202020) {
  let acceleration = 0.05
  let fullCircle = 2 * PI
  local angle = 0.0
  local dir = true
  let lineWidth = height / 5
  let innerHeight = height - lineWidth
  let halfHeight = innerHeight / 2
  return {
    size = [height, height]
    hplace = ALIGN_CENTER
    vplace = ALIGN_CENTER
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    opacity
    children = [
      {
        rendObj = ROBJ_VECTOR_CANVAS
        size = [innerHeight, innerHeight]
        color
        fillColor = fullTransparentBgColor
        commands = [
          [VECTOR_WIDTH, lineWidth],
          [VECTOR_ELLIPSE, 50, 50, 50, 50]
        ]
      }
      {
        rendObj = ROBJ_VECTOR_CANVAS
        size = [innerHeight, innerHeight]
        fillColor = fullTransparentBgColor
        function draw(ctx, _rect) {
          angle += acceleration
          if (angle >= fullCircle) {
            angle -= fullCircle
            dir = !dir
          }

          ctx.sector(halfHeight, halfHeight, halfHeight, halfHeight, dir ? angle : fullCircle,
            dir ? 0.0 : angle, lineWidth, defBdColor, defBdColor, fullTransparentBgColor)
        }
        transform = {}
        animations = [{ prop = AnimProp.rotate, from = 0, to = 360, duration = 3,
          play = true, loop = true }]
      }
    ]
  }
}