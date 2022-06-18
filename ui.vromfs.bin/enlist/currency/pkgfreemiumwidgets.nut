from "%enlSqGlob/ui_library.nut" import *

let { tiny_txt, tiny_bold_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let { bigGap, activeTxtColor } = require("%enlSqGlob/ui/viewConst.nut")
let textButton = require("%ui/components/textButton.nut")
let freemiumWnd = require("freemiumWnd.nut")
let { sendBigQueryUIEvent } = require("%enlist/bigQueryEvents.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { gameProfile } = require("%enlist/soldiers/model/config/gameProfile.nut")
let { curCampaign  } = require("%enlist/meta/curCampaign.nut")


let freemiumImagePath = @(size)
  "!ui/uiskin/currency/enlisted_freemium.svg:{0}:{0}:K"
    .subst(size.tointeger())

let freemiumImage = @(size, override = {}) {
  rendObj = ROBJ_IMAGE
  size = [size, size]
  image = Picture(freemiumImagePath(size))
}.__update(override)

let sendOpenFreemium = @(srcWindow, srcComponent)
  sendBigQueryUIEvent("open_freemium_window", srcWindow, srcComponent)

let freemiumPromo = @(srcWindow = null, srcComponent = null, override = null)
  function() {
    let res = { watch = curCampaign }
    let campaignName = loc(gameProfile.value?.campaigns[curCampaign.value].title
      ?? curCampaign.value)
    return res.__update({
      valign = ALIGN_TOP
      gap = bigGap
      flow = FLOW_HORIZONTAL
      size = [hdpx(375), SIZE_TO_CONTENT]
      children = [
        freemiumImage(hdpx(35))
        {
          flow = FLOW_VERTICAL
          size = [flex(), SIZE_TO_CONTENT]
          children = [
            {
              rendObj = ROBJ_TEXT
              text = utf8ToUpper(loc("freemium/trialVersion"))
            }.__update(tiny_bold_txt)
            {
              rendObj = ROBJ_TEXTAREA
              size = [flex(), SIZE_TO_CONTENT]
              behavior = Behaviors.TextArea
              text = loc("freemium/buyFullVersion", { campaign = campaignName })
              color = activeTxtColor
            }.__update(tiny_txt)
          ]
        }
        textButton.FAButton("shopping-cart", function() {
          freemiumWnd()
          sendOpenFreemium(srcWindow, srcComponent)
        }, { borderWidth = 0, borderRadius = 0, fontSize = hdpx(35) })
      ]
    }).__update(override ?? {})
}

return freemiumPromo