from "%enlSqGlob/ui_library.nut" import *

let { body_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let { gameProfile } = require("%enlist/soldiers/model/config/gameProfile.nut")
let { curCampaign } = require("%enlist/meta/curCampaign.nut")
let { hasCampaignSelection }  = require("campaign_sel_state.nut")
let campaignSelectWnd = require("%enlist/campaigns/campaign_select_wnd.nut")
let { shadowStyle, titleTxtColor, defTxtColor } = require("%enlSqGlob/ui/viewConst.nut")

let text = @(text, sf) {
  rendObj = ROBJ_TEXT
  color = sf & S_ACTIVE ? defTxtColor
    : sf & S_HOVER ? titleTxtColor
    : Color(128,128,128,128)
  text
}.__update(body_txt, shadowStyle)

let campaignInfo = watchElemState(function(sf){
  let res = { watch = [curCampaign, gameProfile, hasCampaignSelection] }
  if (!hasCampaignSelection.value)
    return res

  let campaign = curCampaign.value
  return res.__update({
    behavior = Behaviors.Button
    onClick = @() campaignSelectWnd.open()
    children = text(loc(gameProfile.value?.campaigns[campaign].title ?? campaign), sf)
  })
})

return campaignInfo
