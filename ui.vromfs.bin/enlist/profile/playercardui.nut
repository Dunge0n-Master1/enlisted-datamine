from "%enlSqGlob/ui_library.nut" import *
let decoratorUi = require("decoratorUi.nut")
let { unlockedCampaigns } = require("%enlist/meta/campaigns.nut")
let { userstatStats } = require("%enlSqGlob/userstats/userstat.nut")
let { smallOffset } = require("%enlSqGlob/ui/viewConst.nut")
let { mkCampaignsListUi, mkPlayerStatistics } = require("profilePkg.nut")

return {
  size = flex()
  flow = FLOW_VERTICAL
  gap = smallOffset
  children = [
    decoratorUi
    {
      size = flex()
      flow = FLOW_HORIZONTAL
      gap = smallOffset
      children = [
        mkCampaignsListUi(unlockedCampaigns)
        mkPlayerStatistics(userstatStats)
      ]
    }
  ]
}
