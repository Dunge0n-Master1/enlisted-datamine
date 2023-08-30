from "%enlSqGlob/ui_library.nut" import *

let { fontSub } = require("%enlSqGlob/ui/fontsStyle.nut")

let white = Color(255,255,255)
let dark = Color(200,200,200)
let curTextColor = Color(250,250,200,200)
let defTextColor = Color(150,150,150,50)
let menuSize = array(2, (0.4 * hdpx(390)).tointeger())
let imageSize = array(2, (hdpx(390) * 0.35).tointeger())

let getImage = memoize(@(img) Picture(img))

return @(_idx, image, hintText) function(curIdx, idx) {
  let isActive = Computed(@() curIdx.value == idx)
  return watchElemState(function(sf) {
    let isCurrent = (sf & S_HOVER) || isActive.value

    let icon = image ? {
      image = getImage(image)
      size = imageSize
      rendObj = ROBJ_IMAGE
      tint = isCurrent ? white : dark
    } : null

    let text = {
      rendObj = ROBJ_TEXT
      color = isCurrent ? curTextColor : defTextColor
      text = hintText
    }.__update(fontSub)

    return {
      size = menuSize
      watch = isActive
      halign = ALIGN_CENTER
      flow = FLOW_VERTICAL
      children = [
        icon
        text
      ]
    }
  })
}