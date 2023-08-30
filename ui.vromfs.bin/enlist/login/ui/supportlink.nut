from "%enlSqGlob/ui_library.nut" import *

let urlText = require("%enlist/components/urlText.nut")
let { gaijinSupportUrl, legalsUrl } = require("%enlSqGlob/supportUrls.nut")

return {
  hplace=ALIGN_LEFT
  vplace=ALIGN_BOTTOM
  flow = FLOW_HORIZONTAL
  margin = hdpx(20)
  gap = hdpx(20)
  children = [
    gaijinSupportUrl == "" ? null : urlText(loc("support"), gaijinSupportUrl, {opacity=0.7})
    urlText(loc("Legals"), legalsUrl, {opacity=0.7})
  ]
}