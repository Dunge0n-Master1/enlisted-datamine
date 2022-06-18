from "%enlSqGlob/ui_library.nut" import *

let urlText = require("%enlist/components/urlText.nut")
let {gaijinSupportUrl} = require("%enlSqGlob/supportUrls.nut")

return {
  hplace=ALIGN_RIGHT
  vplace=ALIGN_BOTTOM
  margin = [hdpx(20), 0]
  children = gaijinSupportUrl == "" ? null : urlText(loc("support"), gaijinSupportUrl, {opacity=0.7})
}