from "%enlSqGlob/ui_library.nut" import *

let progressBar = @(color, scale, halign, hitTrigger = null, additionalAnim = null) {
  rendObj = ROBJ_SOLID
  size = flex()
  color = color
  transform = {
    scale = [scale, 1.0]
    pivot = [halign == ALIGN_RIGHT ? 1 : 0, 0]
  }
  transitions = [
    { prop=AnimProp.scale, duration=0.25, easing=OutCubic }
  ]
  animations = hitTrigger
    ? [
        { prop = AnimProp.color, from = Color(255,10,10,50), easing = OutCubic,
          duration = 0.5, trigger = hitTrigger
        }
      ]
    : (additionalAnim ? [additionalAnim] : null)
}

let regenArrow = @(color, scale, place) {
  rendObj = ROBJ_VECTOR_CANVAS
  size = flex()
  color = color
  opacity = 0.3

  commands = [
    [VECTOR_LINE, (1.0 - place * scale) * 100, 0, (1.0 - place * scale) * 100, 100]
  ]

  transitions = [
    { prop=AnimProp.scale, duration=0.25, easing=OutCubic }
  ]
}
let transitions = [
  { prop=AnimProp.opacity, duration=0.2, easing=InOutCubic }
]

local function healthBar(hp, maxHp, scaleHp = 0, hitTrigger=null, maxHpTrigger=null, colorFg = null) {

  if (hp == null || maxHp <= 0)
    return null
  if (hp <= 0)
    hp = maxHp + hp // this is needed for downed HP. do not change to max(hp, 0)

  let isVisible = hp < maxHp
  let baseScale = scaleHp <= 0 ? 1.0 : maxHp.tofloat() / scaleHp
  let ratio = clamp(hp.tofloat() / maxHp.tofloat(), 0.0, 1.0)
  let regenRatio = clamp(hp.tofloat() / maxHp, 0.0, 1.0)
  let colorBg = Color(30+50*(1.0-ratio), 50*ratio, 30*ratio, 80)
  let colorRegen = Color(50, 10, 10, 80)
  colorFg = colorFg ?? ((ratio >= 1) ? Color(105, 255, 105, 80) : Color(255, 105, 105, 80))
  let halign = ALIGN_RIGHT
  return {
    size = flex()
    halign
    opacity = isVisible ? 1.0 : 0.0
    children = [
      progressBar(colorBg, baseScale, halign, hitTrigger)
      progressBar(colorRegen, baseScale * regenRatio, halign)
      progressBar(colorFg, baseScale * ratio, halign)
      regenRatio > ratio ? regenArrow(colorFg, baseScale, regenRatio) : null
    ]

    transitions
    animations = maxHpTrigger
      ? [
          { prop = AnimProp.opacity, from = 0.5, to = 1.0, easing = DoubleBlink,
            duration = 1.0, trigger = maxHpTrigger
          }
        ]
      : null
  }
}

return kwarg(healthBar)
