from "%enlSqGlob/ui_library.nut" import *

let { h2_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let { bigPadding, accentColor } = require("%enlSqGlob/ui/viewConst.nut")
let { leaveQueue, isInQueue } = require("%enlist/quickMatchQueue.nut")
let { joinQueue } = require("quickMatch.nut")
let textButton = require("%ui/components/textButton.nut")
let { leaveRoom, room } = require("%enlist/state/roomState.nut")
let { showCreateRoom } = require("mpRoom/showCreateRoom.nut")
let { BtnActionBgDisabled, MsgMarkedText }  = require("%ui/style/colors.nut")
let JB = require("%ui/control/gui_buttons.nut")
let { curUnfinishedBattleTutorial } = require("%enlist/tutorial/battleTutorial.nut")
let gameLauncher = require("%enlist/gameLauncher.nut")
let { currentGameMode } = require("%enlist/gameModes/gameModeState.nut")
let { isInSquad, isSquadLeader, allMembersState, squadSelfMember,
  myExtSquadData, unsuitableCrossplayConditionMembers, getUnsuitableVersionConditionMembers
} = require("%enlist/squad/squadManager.nut")
let { showCurNotReadySquadsMsg } = require("soldiers/model/notReadySquadsState.nut")
let { curCampaign } = require("%enlist/meta/curCampaign.nut")
let { gameProfile } = require("%enlist/soldiers/model/config/gameProfile.nut")
let { showMsgbox } = require("%enlist/components/msgbox.nut")
let colorize = require("%ui/components/colorize.nut")
let { Contact } = require("%enlist/contacts/contact.nut")
let { remap_nick } = require("%enlSqGlob/remap_nick.nut")
let mkActiveBoostersMark = require("%enlist/mainMenu/mkActiveBoostersMark.nut")
let { showSquadMembersCrossPlayRestrictionMsgBox, showSquadVersionRestrictionMsgBox,
  showNegativeBalanceRestrictionMsgBox } = require("%enlist/restrictionWarnings.nut")

let { hasValidBalance } = require("%enlist/currency/currencies.nut")

let skip_descr = {description = {skip=true}}

let defQuickMatchBtnParams = {
  size = [pw(100), hdpx(80)]
  halign = ALIGN_CENTER
  margin = 0
  borderWidth = hdpx(0)
  textParams = { rendObj=ROBJ_TEXT }.__update(h2_txt)
}

let stdQuickMatchBtnParams = {style = {BgNormal = accentColor}}.__merge(defQuickMatchBtnParams)
let mkButton = @(quickBtnText, quickMatchFn, quickMatchBtnParams) textButton(quickBtnText, quickMatchFn, quickMatchBtnParams)
let disabledQuickMatchBtnParams = {style = {BgNormal   = BtnActionBgDisabled}}.__merge(defQuickMatchBtnParams)
let quickMatchBtnParams = stdQuickMatchBtnParams.__merge({hotkeys = [ ["^J:Y", skip_descr] ]})
let leaveBtnParams = defQuickMatchBtnParams.__merge({hotkeys = [ ["^{0} | Esc".subst(JB.B), skip_descr] ]})

let startBtnWidth = hdpx(400)
let function quickMatchFn() {
  if (room.value)
    leaveRoom(@(...) null)
  showCreateRoom.update(false)
  if (currentGameMode.value?.queue != null)
    joinQueue(currentGameMode.value?.queue)
}

let leaveQuickMatchButton = textButton(loc("Leave queue"), @() leaveQueue(), leaveBtnParams)

let mkJoinQuickMatchButton = @(cb = null)
  mkButton(loc("START"),
    function() {
      if (isSquadLeader.value && unsuitableCrossplayConditionMembers.value.len() != 0) {
        showSquadMembersCrossPlayRestrictionMsgBox(unsuitableCrossplayConditionMembers.value)
        return
      }

      let unsuitableByVersion = getUnsuitableVersionConditionMembers(currentGameMode.value)
      if (unsuitableByVersion.len() != 0) {
        showSquadVersionRestrictionMsgBox(unsuitableByVersion.values())
        return
      }

      if (!hasValidBalance.value) {
        showNegativeBalanceRestrictionMsgBox()
        return
      }

      showCurNotReadySquadsMsg(cb ?? quickMatchFn)
    },
    quickMatchBtnParams
  )

let function mkQuickMatchButton(params = {}) {
  return @() {
    size = [startBtnWidth, SIZE_TO_CONTENT]
    watch = [isInQueue]
    children = isInQueue.value
      ? leaveQuickMatchButton
      : mkJoinQuickMatchButton(params?.onJoinClick)
   }.__merge(params?.style ?? {})
}

let function checkSquadCampaignAndJoinQuickMatch() {
  let campaign = curCampaign.value
  let lockedUserIds = allMembersState.value
    .filter(@(m) !(m?.unlockedCampaigns ?? []).contains(campaign))
    .keys()
  if (lockedUserIds.len() == 0) {
    quickMatchFn()
    return
  }
  showMsgbox({
    text = loc("msg/cantGoBattle/membersCampaignLocked", {
      campaign = colorize(MsgMarkedText, loc(gameProfile.value?.campaigns[campaign].title ?? campaign))
      membersList = colorize(MsgMarkedText,
        ", ".join(lockedUserIds.map(@(userId) remap_nick(Contact(userId.tostring()).value.realnick))))
    })
  })
}

let function mkSquadQuickMatchButton(params){
  let mkQBtn = @(btn) {size = params?.style?.size ?? [flex(), SIZE_TO_CONTENT], minWidth = hdpx(250), children = btn}
  let quickMatchBtn = mkQuickMatchButton(params.__merge({ onJoinClick = checkSquadCampaignAndJoinQuickMatch }))
  let pressWhenReadyBtn = mkQBtn(mkButton(loc("Press when ready"),
    @() showCurNotReadySquadsMsg(@() myExtSquadData.ready(true)),
    stdQuickMatchBtnParams.__merge({ hotkeys = [ ["^J:Y", skip_descr ] ] }))
  )

  let setNotReadyBtn = mkQBtn(mkButton(loc("Set not ready"),
    @() myExtSquadData.ready(false),
    disabledQuickMatchBtnParams.__merge({ hotkeys = [ ["^J:B", skip_descr ] ] }))
  )
  return function() {
    local btn = quickMatchBtn
    if (!isSquadLeader.value && squadSelfMember.value != null)
      btn = myExtSquadData.ready.value ? setNotReadyBtn : pressWhenReadyBtn
    return {
      watch = [
        isSquadLeader,
        squadSelfMember,
        myExtSquadData.ready
      ]
      size = SIZE_TO_CONTENT
      children = btn
    }
  }
}

let startTutorial = @() gameLauncher.startGame({
  game = "enlisted", scene = curUnfinishedBattleTutorial.value
})
let startTutorialBtn = mkButton(loc("TUTORIAL"), startTutorial, quickMatchBtnParams)

let startLocalGameMode = @() gameLauncher.startGame({
  game = "enlisted", scene = currentGameMode.value?.scenes[0]
})
let localGameBtn = mkButton(loc("START"), startLocalGameMode, quickMatchBtnParams)

let btnParams = {style = {size = [startBtnWidth, SIZE_TO_CONTENT]}}
let quickMatchButton = mkQuickMatchButton(btnParams)
let squadMatchButton = mkSquadQuickMatchButton(btnParams)

let startBtn = @() {
  watch = [curUnfinishedBattleTutorial, isInSquad, currentGameMode]
  children = [
    isInSquad.value ? squadMatchButton
      : curUnfinishedBattleTutorial.value != null ? startTutorialBtn
      : currentGameMode.value?.isLocal ? localGameBtn
      : quickMatchButton
    isInSquad.value || (!curUnfinishedBattleTutorial.value && !currentGameMode.value?.isLocal)
      ? mkActiveBoostersMark({ hplace = ALIGN_RIGHT, pos = [hdpx(20), bigPadding] })
      : null
  ]
  size = [startBtnWidth, SIZE_TO_CONTENT]
}

return {
  startBtn
  startBtnWidth
}
