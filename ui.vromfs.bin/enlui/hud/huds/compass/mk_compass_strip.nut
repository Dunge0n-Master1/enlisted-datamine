from "%enlSqGlob/ui_library.nut" import *

let {body_txt} = require("%enlSqGlob/ui/fonts_style.nut")
let {DEFAULT_TEXT_COLOR} = require("%ui/hud/style.nut")
let userPoints = require("%ui/hud/huds/compass/compass_user_point.nut")

let lookDirection = {
  data = {
    relativeAngle = 0 // or 'angle' or 'eid'
  }

  transform = {}
  halign = ALIGN_CENTER
  valign = ALIGN_TOP

  rendObj = ROBJ_VECTOR_CANVAS
  size = [hdpx(4), hdpx(8)]
  lineWidth = 2.0
  color = DEFAULT_TEXT_COLOR
  commands = [
    [VECTOR_LINE, 0, -100, 50,  20],
    [VECTOR_LINE, 50, 20, 100, -100],
  ]
}


let function compassElem(text, angle, scale, lineHeight=hdpx(10)) {

  let res = {
    data = {
      angle = angle // or 'relativeAngle' or 'eid'
    }

    transform = {}
    halign = ALIGN_CENTER
    valign = ALIGN_TOP
    flow = FLOW_VERTICAL

    children = [
      {
        rendObj = ROBJ_VECTOR_CANVAS
        size = [lineHeight, lineHeight]
        lineWidth = max(hdpx(2.8 * scale), hdpx(1.1))
        color = DEFAULT_TEXT_COLOR
        commands = [
          [VECTOR_LINE, 50, 0, 50, 100 * scale],
        ]
      }
    ]
  }

  if (text)
    res.children.append(
      {
        rendObj = ROBJ_TEXT
        color = DEFAULT_TEXT_COLOR
        opacity = (scale + 1.0) * 0.5
        text
      }.__update(body_txt, {fontSize = hdpx(22 * scale)})
    )

  return res
}

let compassFovSettings = {
        fov = 140         // degrees
        fadeOutZone = 30  // degrees
      }

const bigCharScaleDef = 0.85
const medCharScaleDef = 0.7
const smallCharScaleDef = 0.5
const microCharScaleDef = 0.3

let compassCardinalDir = @(text, angle, scale) compassElem(text, angle, bigCharScaleDef*scale)
let compassNumberedDir = @(angle, scale) compassElem(angle.tostring(), angle, smallCharScaleDef*scale)
let compassNotchDir = @(angle, scale) compassElem(null, angle, microCharScaleDef*scale)

let defaultSize = [hdpx(400), hdpx(30)]
let defaultPos = [0, fsh(4)]
local mkCompassStrip = kwarg(function mkCompassStripImlp(size = defaultSize,
      pos = defaultPos, compassObjects=[], globalScale = 1.0,
      hplace = ALIGN_CENTER, showCompass = null, step = 15, subStep = null
  ) {
  showCompass = showCompass ?? Watched(true)
  let children = ([userPoints].extend(compassObjects)).map(@(v) @(){
        size = flex()
        data = compassFovSettings
        behavior = Behaviors.PlaceOnCompassStrip
        watch = v.watch
        halign = ALIGN_CENTER
        children = v.childrenCtor()
      }
    )
  return function(){
    let dirChildren = [lookDirection]
    let cardinalDirections = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
    let minStep = subStep ?? step
    for (local angle = 0; angle < 360; angle += minStep) {
      let isCardinal = angle % 45 == 0
      let isNumbered = angle % step == 0
      let cardinalDir = angle % 45 == 0 ? angle / 45 : null
      dirChildren.append(isCardinal ? compassCardinalDir(cardinalDirections[cardinalDir], angle, globalScale) :
                         isNumbered ? compassNumberedDir(angle, globalScale) :
                                      compassNotchDir(angle, globalScale))
    }
    return {
      pos = pos
      size = size
      hplace = hplace
      watch = showCompass
      children = !showCompass.value? null : [
        {
          size = flex()
          data = compassFovSettings
          behavior = Behaviors.PlaceOnCompassStrip
          halign = ALIGN_CENTER

          children = dirChildren
        }
      ].extend(children)
    }
  }
})


return mkCompassStrip
