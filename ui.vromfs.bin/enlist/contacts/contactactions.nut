from "%enlSqGlob/ui_library.nut" import *

let fa = require("%ui/components/fontawesome.map.nut")
let { inviteToSquad, dismissSquadMember, transferSquad, revokeSquadInvite,
  leaveSquad, isInSquad, isSquadLeader, squadMembers, isInvitedToSquad, enabledSquad, canInviteToSquad
} = require("%enlist/squad/squadManager.nut")
let userInfo = require("%enlSqGlob/userInfo.nut")
let {canInviteToRoom, isInMyRoom, inviteToRoom, playersWaitingResponseFor
} = require("%enlist/state/roomState.nut")
let { availableSquadMaxMembers } = require("%enlist/state/queueState.nut")
let openUrl = require("%ui/components/openUrl.nut")
let {appId} = require("%enlSqGlob/clientState.nut")
let platform = require("%dngscripts/platform.nut")
let { approvedUids, myRequestsUids, requestsToMeUids, rejectedByMeUids,
  myBlacklistUids, meInBlacklistUids, psnApprovedUids,
  isInternalContactsAllowed, psnBlockedUids, xboxBlockedUids, friendsUids, blockedUids
} = require("%enlist/contacts/contactsWatchLists.nut")
let { execContactsCharAction, getContactsInviteId } = require("contactsState.nut")
let { canInterractCrossPlatform, consoleCompare, canInterractCrossPlatformByCrossplay
} = require("%enlSqGlob/platformUtils.nut")
let { Contact } = require("contact.nut")
let {get_circuit} = require("app")
let { get_setting_by_blk_path } = require("settings")

let { uid2console } = require("%enlist/contacts/consoleUidsRemap.nut")
let { open_player_profile = @(...) null, PlayerAction = null
} = platform.is_sony? require("sony.social") : null

let { showUserInfo, canShowUserInfo } = require("%enlSqGlob/showUserInfo.nut")
let { canCrossnetworkChatWithAll,
  canCrossnetworkChatWithFriends, crossnetworkPlay } = require("%enlSqGlob/crossnetwork_state.nut")
let { removeNotifyById } = require("%enlist/mainScene/invitationsLogState.nut")

/*************************************** ACTIONS LIST *******************************************/

let myUserId = Computed(@() userInfo.value?.userIdStr ?? "")
let isInMySquad = @(userId, members) members.value?[userId.tointeger()] != null

let achievementTestUrl = "http://achievement-test.gaijin.ops/achievement/?app={0}&nick={1}"
let achievementUrl = get_setting_by_blk_path("achievementsUrl") ?? "https://achievements.gaijin.net/?app={0}&nick={1}"

let actions = {
  INVITE_TO_SQUAD = {
    locId = "Invite to squad"
    icon = fa["handshake-o"]
    mkIsVisible = @(userId) Computed(@() userId != myUserId.value
      && canInviteToSquad.value
      && !isInMySquad(userId, squadMembers)
      && availableSquadMaxMembers.value > 1
      && !isInvitedToSquad.value?[userId.tointeger()]
      && canInterractCrossPlatformByCrossplay(
        Contact(userId).value.realnick,
        crossnetworkPlay.value
      )
      && userId not in meInBlacklistUids.value
      && userId not in blockedUids.value
    )
    action = @(userId) inviteToSquad(userId.tointeger())
  }

  INVITE_TO_ROOM = {
    locId = "Invite to room"
    mkIsVisible = @(userId) Computed(@() canInviteToRoom.value
      && userId.tointeger() not in playersWaitingResponseFor.value
      && !isInMyRoom(userId.tointeger())
      && canInterractCrossPlatformByCrossplay(
        Contact(userId).value.realnick,
        crossnetworkPlay.value
      ))
    action = @(userId) inviteToRoom(userId.tointeger())
  }

  INVITE_TO_FRIENDS = {
    locId = "Invite to friends"
    icon = fa["user-plus"]
    mkIsVisible = @(userId) Computed(@() userId != myUserId.value
      && isInternalContactsAllowed
      && userId not in blockedUids.value
      && userId not in friendsUids.value
      && userId not in myRequestsUids.value
      && userId not in rejectedByMeUids.value
      && userId not in requestsToMeUids.value
    )
    function action(userId) {
      if (platform.is_xbox && canShowUserInfo(userId.tointeger(), Contact(userId).value.realnick))
        showUserInfo(userId) //On xbox no functionality to show friend window, so just show profile
      else
        execContactsCharAction(userId, "contacts_request_for_contact")
    }
  }

  INVITE_TO_PSN_FRIENDS = {
    locId = "contacts/psn/friends/request"
    icon = fa["user-plus"]
    mkIsVisible = @(userId) Computed(@() userId != myUserId.value
      && (platform.is_sony && consoleCompare.psn.isFromPlatform(Contact(userId).value.realnick))
      && userId not in psnApprovedUids.value
      && userId not in blockedUids.value
      && userId not in meInBlacklistUids.value
    )
    action = @(userId) open_player_profile(
      (uid2console.value?[userId] ?? "-1").tointeger(),
      PlayerAction?.REQUEST_FRIENDSHIP,
      "PlayerProfileDialogClosed",
      {}
    )
  }

  CANCEL_INVITE = {
    locId = "Cancel Invite"
    icon = fa["remove"]
    mkIsVisible = @(userId) Computed(@() userId != myUserId.value && userId in myRequestsUids.value)
    action      = @(userId) execContactsCharAction(userId, "contacts_cancel_request")
  }

  APPROVE_INVITE = {
    locId = "Approve Invite"
    icon = fa["user-plus"]
    mkIsVisible = @(userId) Computed(@() userId != myUserId.value
      && (userId in requestsToMeUids.value || userId in rejectedByMeUids.value)
      && canInterractCrossPlatformByCrossplay(
        Contact(userId).value.realnick,
        crossnetworkPlay.value
      )
    )
    action      = function(userId) {
      removeNotifyById(getContactsInviteId(userId))
      execContactsCharAction(userId, "contacts_approve_request")
    }
  }

  REJECT_INVITE = {
    locId = "Reject Invite"
    icon = fa["remove"]
    mkIsVisible = @(userId) Computed(@() userId != myUserId.value
      && userId in requestsToMeUids.value)
    action      = function(userId) {
      removeNotifyById(getContactsInviteId(userId))
      execContactsCharAction(userId, "contacts_reject_request")
    }
  }

  REMOVE_FROM_FRIENDS = {
    locId = "Break approval"
    icon = fa["remove"]
    mkIsVisible = @(userId) Computed(@()
      canInterractCrossPlatform(
        Contact(userId).value.realnick,
        canCrossnetworkChatWithFriends.value
      )
      && userId != myUserId.value
      && userId in friendsUids.value
      && userId not in psnApprovedUids //don't show it at all
    )
    function action(userId) {
      if (platform.is_xbox && canShowUserInfo(userId.tointeger(), Contact(userId).value.realnick))
        showUserInfo(userId) //On xbox no functionality to show friend window, so just show profile
      else
        execContactsCharAction(userId, "contacts_break_approval_request")
    }
  }

  ADD_TO_BLACKLIST = {
    locId = "Add to blacklist"
    icon = fa["remove"]
    mkIsVisible = @(userId) Computed(@()
      canInterractCrossPlatform(
        Contact(userId).value.realnick,
        userId in friendsUids.value
          ? canCrossnetworkChatWithFriends.value
          : canCrossnetworkChatWithAll.value
      )
      && userId != myUserId.value
      && userId not in blockedUids.value
      && userId not in approvedUids.value)
    function action(userId) {
      if (platform.is_sony && consoleCompare.psn.isFromPlatform(Contact(userId).value.realnick))
        open_player_profile(
          (uid2console.value?[userId] ?? "-1").tointeger(),
          PlayerAction?.BLOCK_PLAYER,
          "PlayerProfileDialogClosed",
          {}
        )
      else if (platform.is_xbox && canShowUserInfo(userId.tointeger(), Contact(userId).value.realnick))
        showUserInfo(userId) //On xbox no functionality to show friend invite window, so just show profile
      else
        execContactsCharAction(userId, "contacts_add_to_blacklist")
    }
  }


  REMOVE_FROM_BLACKLIST = {
    locId = "Remove from blacklist"
    icon = fa["remove"]
    mkIsVisible = @(userId) Computed(@() userId != myUserId.value && userId in myBlacklistUids.value)
    action      = @(userId) execContactsCharAction(userId, "contacts_remove_from_blacklist")
  }

  REMOVE_FROM_BLACKLIST_XBOX = {
    locId = "Remove from blacklist"
    icon = fa["remove"]
    mkIsVisible = @(userId) Computed(@() userId != myUserId.value
      && userId in xboxBlockedUids.value
      && canShowUserInfo(userId.tointeger(), Contact(userId).value.realnick)
    )
    action      = showUserInfo
  }

  REMOVE_FROM_BLACKLIST_PSN = {
    locId = "Remove from blacklist"
    icon = fa["remove"]
    mkIsVisible = @(userId) Computed(@() userId != myUserId.value && userId in psnBlockedUids.value)
    action      = @(userId) open_player_profile(
      (uid2console.value?[userId] ?? "-1").tointeger(),
      PlayerAction?.DISPLAY,
      "PlayerProfileDialogClosed",
      {}
    )
  }

  REMOVE_FROM_SQUAD = {
    locId = "Remove from squad"
    mkIsVisible = @(userId) Computed(@() enabledSquad.value
      && userId != myUserId.value && isSquadLeader.value && isInMySquad(userId, squadMembers))
    action      = @(userId) dismissSquadMember(userId.tointeger())
  }

  PROMOTE_TO_LEADER = {
    locId = "Promote to squad chief"
    mkIsVisible = @(userId) Computed(@() enabledSquad.value
      && userId != myUserId.value && isSquadLeader.value && isInMySquad(userId, squadMembers))
    action      = @(userId) transferSquad(userId.tointeger())
  }

  REVOKE_INVITE = {
    locId = "Revoke invite"
    icon = fa["remove"]
    mkIsVisible = @(userId) Computed(@() isSquadLeader.value
      && !isInMySquad(userId, squadMembers) && (isInvitedToSquad.value?[userId.tointeger()] ?? false))
    action      = @(userId) revokeSquadInvite(userId.tointeger())
  }

  LEAVE_SQUAD = {
    locId = "Leave squad"
    mkIsVisible = @(userId) Computed(@() enabledSquad.value && userId == myUserId.value && isInSquad.value)
    action      = @(_userId) leaveSquad()
  }

  COMPARE_ACHIEVEMENTS = {
    locId = "Compare achievements"
    mkIsVisible = @(userId) Computed(@() platform.is_pc && achievementUrl != "" && userId != myUserId.value)
    action      = @(userId)
      openUrl(
        ["moon"].contains(get_circuit())
          ? achievementTestUrl.subst(appId.value, Contact(userId).value.realnick)
          : achievementUrl.subst(appId.value, Contact(userId).value.realnick)
      )
  }

  SHOW_USER_LIVE_PROFILE = {
    locId = "show_user_live_profile"
    mkIsVisible = @(userId) Computed(@() canShowUserInfo(userId.tointeger(), Contact(userId).value.realnick))
    action      = showUserInfo
  }
}

return actions
