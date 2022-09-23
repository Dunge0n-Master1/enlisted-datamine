from "%enlSqGlob/ui_library.nut" import *

let { isMsgboxInList, showMsgbox } = require("%enlist/components/msgbox.nut")
let { isSquadLeader, allMembersState } = require("%enlist/squad/squadState.nut")
let { Contact } = require("%enlist/contacts/contact.nut")
let { curCampaign } = require("%enlist/meta/curCampaign.nut")
let { gameProfile } = require("%enlist/soldiers/model/config/gameProfile.nut")
let colorize = require("%ui/components/colorize.nut")
let { MsgMarkedText } = require("%ui/style/colors.nut")
let { remap_nick } = require("%enlSqGlob/remap_nick.nut")

const MSG_UID = "member_locked_campaign_msgbox"
let viewedWarnings = mkWatched(persist, "viewedWarnings", {})
let curCampViewed = Computed(@() viewedWarnings.value?[curCampaign.value])

isSquadLeader.subscribe(function(v) {
  if (!v)
    viewedWarnings.mutate(@(w) w.clear())
})

let needWarningUserId = keepref(Computed(function() {
  let campaign = curCampaign.value
  if (!isSquadLeader.value || campaign == null)
    return null
  let userId = allMembersState.value.findindex(@(m, uId)
    "unlockedCampaigns" in m && !m.unlockedCampaigns.contains(campaign) && !(curCampViewed.value?[uId] ?? false))
  return userId
}))

let function showWarningMsgbox(userId) {
  if (userId == null || isMsgboxInList(MSG_UID))
    return

  let name = remap_nick(Contact(userId.tostring()).value.realnick)
  let campaign = curCampaign.value
  showMsgbox({
    uid = MSG_UID
    text = loc("msg/memberCampaignLocked", {
      player = colorize(MsgMarkedText, name)
      campaign = colorize(MsgMarkedText, loc(gameProfile.value?.campaigns[campaign].title ?? campaign))
    })
    buttons = [{ text = loc("Ok"),
      action = @() viewedWarnings.mutate(@(v) v[campaign] <- (v?[campaign] ?? {}).__merge({ [userId] = true }))
      isCurrent = true
      isCancel = true
    }]
  })
}

needWarningUserId.subscribe(showWarningMsgbox)
