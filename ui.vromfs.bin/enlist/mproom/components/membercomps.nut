from "%enlSqGlob/ui_library.nut" import *

let { frameNick } = require("%enlSqGlob/ui/decoratorsPresentation.nut")
let { sub_txt } = require("%enlSqGlob/ui/fonts_style.nut")

let statusIconSize = sub_txt.fontSize.tointeger()

let mkStatusImg = @(icon, color) {
  rendObj = ROBJ_IMAGE
  size = [statusIconSize, statusIconSize]
  color
  image = Picture("!ui/skin#{0}:{1}:{1}:K".subst(icon, statusIconSize))
}

let memberName = @(name, frame = "") {
  rendObj = ROBJ_TEXT
  text = frameNick(name, frame)
}.__update(sub_txt)

return {
  memberName
  mkStatusImg
}