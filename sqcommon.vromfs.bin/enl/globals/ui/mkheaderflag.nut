from "%enlSqGlob/ui_library.nut" import *


let FLAG_PARAMS = {
  size = SIZE_TO_CONTENT
  flagImage = "!ui/gameImage/base_header_bar.svg"
  offset = hdpx(30)
  tail = 0
  flagColor = Color(255,50,6)
  offsetColor = Color(60,30,30)
  tailColor = Color(117,11,6)
}

let casualFlagStyle = {
  flagColor = Color(98, 98, 80)
  offsetColor = Color(54, 54, 45)
  tailColor = Color(67, 67, 56)
}

let primeFlagStyle = {
  flagColor = Color(191, 43, 9)
  offsetColor = Color(58, 29, 30)
  tailColor = Color(117, 11, 6)
}

let disableFlagStyle = {
  flagColor = Color(96, 96, 96)
  offsetColor = Color(54, 54, 45)
  tailColor =Color(75, 75, 75)
}

let mkFlagOffset = @(p) p.offset <= 0 ? null
  : {
      rendObj = ROBJ_VECTOR_CANVAS
      size = [p.offset, p.offset]
      pos = [0, p.offset]
      vplace = ALIGN_BOTTOM
      lineWidth = 0
      color = 0
      fillColor = p.offsetColor
      commands = [
        [VECTOR_POLY, 0,0, 100,0, 100,100]
      ]
    }

let mkFlagTail = @(p) p.offset <= 0 || p.tail <= 0 ? null
  : {
      rendObj = ROBJ_SOLID
      size = [p.tail, ph(80)]
      pos = [p.offset - p.tail, p.offset]
      vplace = ALIGN_BOTTOM
      color = p.tailColor
    }

local function mkHeaderFlag(content, p = FLAG_PARAMS) {
  p = FLAG_PARAMS.__merge(p)
  return {
    size = p.size
    pos = [-p.offset, 0]
    children = [
      mkFlagTail(p)
      mkFlagOffset(p)
      {
        rendObj = ROBJ_IMAGE
        size = flex()
        image = Picture($"{p.flagImage}:{hdpxi(150)}:4:K?Ac")
        color = p.flagColor
        transform = { rotate = p?.rotate ?? 0 }
      }
      content
    ]
  }
}

let mkRightHeaderFlag = @(content, params) mkHeaderFlag(content, params.__merge({ rotate = 180 }))

return {
  mkHeaderFlag
  casualFlagStyle
  primeFlagStyle
  disableFlagStyle
  mkRightHeaderFlag
}