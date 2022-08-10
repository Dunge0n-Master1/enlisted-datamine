from "%enlSqGlob/ui_library.nut" import *

let { body_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let { txt } = require("%enlSqGlob/ui/defcomps.nut")
let { PORTRAIT_SIZE, mkRatingBlock, mkPortraitIcon } = require("decoratorPkg.nut")
let { getPortrait, frameNick } = require("%enlSqGlob/ui/decoratorsPresentation.nut")
let { titleTxtColor, defBgColor } = require("%enlSqGlob/ui/viewConst.nut")
let { borderColor } = require("profilePkg.nut")
let { anoProfileData } = require("anoProfileState.nut")

let decoratorBlock = @() {
  flow = FLOW_HORIZONTAL
  size = [flex(), SIZE_TO_CONTENT]
  gap = fsh(5)
  valign = ALIGN_TOP
  children = [
    {
      rendObj = ROBJ_BOX
      borderWidth = hdpx(1)
      size = [PORTRAIT_SIZE, PORTRAIT_SIZE]
      fillColor = defBgColor
      borderColor = borderColor(0)
      behavior = Behaviors.Button
      children = mkPortraitIcon(getPortrait(anoProfileData.value?.player.portrait))
    }
    {
      flow = FLOW_VERTICAL
      gap = fsh(2)
      valign = ALIGN_TOP
      children = [
        txt({
          text = frameNick(anoProfileData.value?.player.name, anoProfileData.value?.player.nickFrame)
          color = titleTxtColor
        }).__update(body_txt)
      ]
    }
  ]
}

return @(){
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_HORIZONTAL
  children = [
    decoratorBlock()
    mkRatingBlock(Watched({
      rank = anoProfileData.value.player.rank
      rating = anoProfileData.value.player.rating
    }))
  ]
}

