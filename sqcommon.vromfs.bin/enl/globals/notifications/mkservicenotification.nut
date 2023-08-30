from "%enlSqGlob/ui_library.nut" import *

let { opaqueBgColor } = require("%enlSqGlob/ui/viewConst.nut")
let { fontBody, fontSub } = require("%enlSqGlob/ui/fontsStyle.nut")


let animations = @(leftAppearance) [ leftAppearance
  ? { prop = AnimProp.translate, from = [-sw(50), 0], to = [0, 0],
      duration = 0.3, play = true
    }
  : { prop = AnimProp.translate, from = [sw(50), 0], to = [0, 0],
      duration = 0.3, play = true
    }
  { prop = AnimProp.color, from = Color(150,20,20), to = Color(225,35,35)
    easing = CosineFull, duration = 1, loop = true, play = true
  }
]

let function serviceMessages(messageTbl, params = {}){
  if (messageTbl.len() <= 0)
    return null

  let isInBattle = params?.isInBattle ?? false
  return {
    rendObj = ROBJ_SOLID
    size = [flex(), SIZE_TO_CONTENT]
    padding = hdpx(7)
    animations = animations((params?.hplace ?? ALIGN_LEFT) == ALIGN_LEFT)
    transform = {}
    children = {
      rendObj = ROBJ_SOLID
      size = [flex(), SIZE_TO_CONTENT]
      flow = FLOW_VERTICAL
      color = opaqueBgColor
      padding = fsh(2)
      gap = fsh(1.5)
      children = [
        isInBattle ? null : {
          rendObj = ROBJ_IMAGE
          size = [hdpx(40), hdpx(34)]
          hplace = ALIGN_CENTER
          image = Picture($"ui/uiskin/attention.avif")
        }
        {
          rendObj = ROBJ_TEXTAREA
          size = [flex(), SIZE_TO_CONTENT]
          behavior = Behaviors.TextArea
          maxHeight = isInBattle ? fsh(24) : hdpx(400)
          ellipsis = true
          textOverflowY = TOVERFLOW_LINE
          text = "\n".join(messageTbl.map(@(n) n.message))
        }.__update(isInBattle ? fontSub : fontBody)
      ]
    }.__update(params)
  }
}

return serviceMessages