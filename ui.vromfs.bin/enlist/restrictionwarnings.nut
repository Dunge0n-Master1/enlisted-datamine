from "%enlSqGlob/ui_library.nut" import *

let msgbox = require("%enlist/components/msgbox.nut")
let { Alert } = require("%ui/style/colors.nut")
let { remap_nick } = require("%enlSqGlob/remap_nick.nut")
let { is_xbox } = require("%dngscripts/platform.nut")

let getMembersNames = @(members) members.map(@(m) remap_nick(m.state.value.name))

local showCrossnetworkChatRestrictionMsgBox = @() msgbox.show({ text = loc("contacts/msg/crossnetworkChatRestricted", {color = Alert})})
if (is_xbox) {
  let { check_privilege = @(...) null, Communications = -1 } = require_optional("xbox.user")
  showCrossnetworkChatRestrictionMsgBox = @() check_privilege(Communications, true, "")
}

return {
  showSquadMembersCrossPlayRestrictionMsgBox = @(members) msgbox.show({
    text = "{0}\n{1}".subst(
      loc("squad/action_not_available_crossnetwork_play", {color = Alert}),
      ", ".join(getMembersNames(members))
    )})

  showSquadVersionRestrictionMsgBox = @(members) msgbox.show({
    text = "{0}\n{1}".subst(
      loc("squad/action_not_available_version", {color = Alert}),
      ", ".join(getMembersNames(members))
    )})

  showNegativeBalanceRestrictionMsgBox = @() msgbox.show({
    text = loc("gameMode/negativeBalance", {color = Alert})
  })

  showVersionRestrictionMsgBox = @() msgbox.show({
    text = loc("msg/gameMode/unsupportedVersion", {color = Alert})
  })

  showCrossnetworkChatRestrictionMsgBox
}