from "%enlSqGlob/ui_library.nut" import *
let anoDecoratorUi = require("anoDecoratorUi.nut")
let { visibleCampaigns } = require("%enlist/meta/campaigns.nut")
let { smallOffset } = require("%enlSqGlob/ui/viewConst.nut")
let { anoProfileData } = require("anoProfileState.nut")
let { mkCampaignsListUi, mkPlayerStatistics } = require("profilePkg.nut")

return @() {
  size = flex()
  flow = FLOW_VERTICAL
  gap = smallOffset
  children = [
    anoDecoratorUi()
    {
      size = flex()
      flow = FLOW_HORIZONTAL
      gap = smallOffset
      children = [
        mkCampaignsListUi(visibleCampaigns)
        mkPlayerStatistics(anoProfileData, false)
      ]
    }
  ]
}