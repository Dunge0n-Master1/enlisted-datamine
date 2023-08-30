from "%enlSqGlob/ui_library.nut" import *

let { frameNick } = require("%enlSqGlob/ui/decoratorsPresentation.nut")
let { fontSub } = require("%enlSqGlob/ui/fontsStyle.nut")

let statusIconSize = fontSub.fontSize.tointeger()

let mkStatusImg = @(icon, color) {
  rendObj = ROBJ_IMAGE
  size = [statusIconSize, statusIconSize]
  color
  image = Picture("!ui/skin#{0}:{1}:{1}:K".subst(icon, statusIconSize))
}

let memberName = @(name, frame = "") {
  rendObj = ROBJ_TEXT
  text = frameNick(name, frame)
}.__update(fontSub)

return {
  memberName
  mkStatusImg
}