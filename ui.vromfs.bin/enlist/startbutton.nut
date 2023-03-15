from "%enlSqGlob/ui_library.nut" import *

let { fontXLarge } = require("%enlSqGlob/ui/fontsStyle.nut")
let { bigPadding, titleTxtColor, accentColor, defTxtColor, startBtnWidth, colPart,
  leftAppearanceAnim
} = require("%enlSqGlob/ui/designConst.nut")
let { leaveQueue, isInQueue } = require("%enlist/quickMatchQueue.nut")
let { joinQueue } = require("quickMatch.nut")
let { leaveRoom, room } = require("%enlist/state/roomState.nut")
let { showCreateRoom } = require("mpRoom/showCreateRoom.nut")
let { MsgMarkedText }  = require("%ui/style/colors.nut")
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
let { showSquadMembersCrossPlayRestrictionMsgBox,
  showSquadVersionRestrictionMsgBox } = require("%enlist/restrictionWarnings.nut")


let defStartTxtStyle = {
  defTextColor = titleTxtColor
  hoverTextColor = accentColor
  activeTextColor = titleTxtColor
}

let leaveMatchTxtStyle = {
  defTextColor = defTxtColor
  hoverTextColor = titleTxtColor
  activeTextColor = defTxtColor
}


let defBtnBg = Picture("ui/uiskin/startBtn/start_btn_regular.avif")
let hoverBtnBg = Picture("ui/uiskin/startBtn/start_btn_hover.avif")
let activeBtnBg = Picture("ui/uiskin/startBtn/start_btn_active.avif")
let defPressedBtnBg = Picture("ui/uiskin/startBtn/start_btn_pressed_regular.avif")
let hoverPressedBtnBg = Picture("ui/uiskin/startBtn/start_btn_pressed_hover.avif")
let activePressedBtnBg = Picture("ui/uiskin/startBtn/start_btn_pressed_active.avif")


let defStartBgStyle = {
  defBg = defBtnBg
  hoverBg = hoverBtnBg
  activeBg = activeBtnBg
}

let leaveMatchBgStyle = {
  defBg = defPressedBtnBg
  hoverBg = hoverPressedBtnBg
  activeBg = activePressedBtnBg
}


let function mkBtnHoverImage(sf, bgStyle) {
  if (sf == 0)
    return null

  let { hoverBg, activeBg } = bgStyle
  let isActive = sf & S_ACTIVE
  return {
    key = $"{isActive}"
    size = flex()
    rendObj = ROBJ_IMAGE
    image = isActive ? activeBg : hoverBg
    animations = [
      { prop = AnimProp.opacity, from = 0.0, to = 1.0, duration = 0.3, play = true }
      { prop = AnimProp.opacity, from = 1.0, to = 0.0, duration = 0.3, playFadeOut = true }
    ]
  }
}


let function btnCtor(txt, action, params = {}) {
  let { defTextColor, hoverTextColor, activeTextColor } = params.txtStyle
  let { hotkeys = null } = params
  return watchElemState(@(sf) {
    size = [startBtnWidth, colPart(1.54)]
    rendObj = ROBJ_IMAGE
    behavior = Behaviors.Button
    image = params.bgStyle.defBg
    onClick = action
    hotkeys
    children = [
      mkBtnHoverImage(sf, params.bgStyle)
      {
        key = $"txt_{sf}"
        size = [flex(), SIZE_TO_CONTENT]
        rendObj = ROBJ_TEXT
        text = txt
        color = sf & S_ACTIVE ? activeTextColor
          : sf & S_HOVER ? hoverTextColor
          : defTextColor
        halign = ALIGN_CENTER
        vplace = ALIGN_CENTER
        animations = [
          { prop = AnimProp.opacity, from = 1.0, to = 0.0, duration = 0.3, playFadeOut = true }
        ]
      }.__update(fontXLarge)
    ]
  })
}

let function quickMatchFn() {
  if (room.value)
    leaveRoom()
  showCreateRoom.update(false)
  if (currentGameMode.value?.queue != null)
    joinQueue(currentGameMode.value?.queue)
}

let leaveQuickMatchButton = btnCtor(loc("Leave queue"), @() leaveQueue(),
  {
    bgStyle = leaveMatchBgStyle
    txtStyle = leaveMatchTxtStyle
    hotkeys = [[$"^{JB.B} | Esc", @() leaveQueue()]]
  })

let function mkJoinQuickMatchButton(cb = null) {
  let function action() {
    if (isSquadLeader.value && unsuitableCrossplayConditionMembers.value.len() != 0) {
      showSquadMembersCrossPlayRestrictionMsgBox(unsuitableCrossplayConditionMembers.value)
      return
    }

    let unsuitableByVersion = getUnsuitableVersionConditionMembers(currentGameMode.value)
    if (unsuitableByVersion.len() != 0) {
      showSquadVersionRestrictionMsgBox(unsuitableByVersion.values())
      return
    }

    showCurNotReadySquadsMsg(cb ?? quickMatchFn)
  }
  return btnCtor(loc("START"), action,
    {
      bgStyle = defStartBgStyle
      txtStyle = defStartTxtStyle
      hotkeys = [["^J:Y", { skip = true }]]
    })
}

let quickMatchButton = @() {
  watch = isInQueue
  children = isInQueue.value
    ? leaveQuickMatchButton
    : mkJoinQuickMatchButton()
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
      campaign = colorize(MsgMarkedText,
        loc(gameProfile.value?.campaigns[campaign].title ?? campaign))
      membersList = colorize(MsgMarkedText,
        ", ".join(lockedUserIds.map(@(userId)
          remap_nick(Contact(userId.tostring()).value.realnick))))
    })
  })
}


let quickMatchBtn = btnCtor(loc("START"), checkSquadCampaignAndJoinQuickMatch,
    {
      bgStyle =defStartBgStyle
      txtStyle =defStartTxtStyle
      hotkeys = [["^J:Y", checkSquadCampaignAndJoinQuickMatch ]]
    })
  let pressWhenReadyBtn = btnCtor(loc("Press when ready"),
    @() showCurNotReadySquadsMsg(@() myExtSquadData.ready(true)),
    {
      bgStyle = defStartBgStyle
      txtStyle = defStartTxtStyle
      hotkeys = [["^J:Y", @() showCurNotReadySquadsMsg(@() myExtSquadData.ready(true)) ]]
    })

  let setNotReadyBtn = btnCtor(loc("Set not ready"), @() myExtSquadData.ready(false),
    {
      bgStyle = leaveMatchBgStyle
      txtStyle = leaveMatchTxtStyle
      hotkeys = [[$"^{JB.B}" ]]
    })


let function squadMatchButton(){
  local btn = isInQueue.value ? leaveQuickMatchButton : quickMatchBtn
    if (!isSquadLeader.value && squadSelfMember.value != null)
      btn = myExtSquadData.ready.value ? setNotReadyBtn : pressWhenReadyBtn
  return {
    watch = [isInQueue, isSquadLeader, squadSelfMember, myExtSquadData.ready]
    children = btn
  }
}


let startTutorial = @() gameLauncher.startGame({
  game = "enlisted", scene = curUnfinishedBattleTutorial.value
})
let startTutorialBtn = btnCtor(loc("TUTORIAL"), startTutorial,
  {
    bgStyle = defStartBgStyle
    txtStyle = defStartTxtStyle
    hotkeys = [["^J:Y", startTutorial]]
  })

let startLocalGameMode = @() gameLauncher.startGame({
  game = "enlisted", scene = currentGameMode.value?.scenes[0]
})

let localGameBtn = btnCtor(loc("START"), startLocalGameMode,
  {
    bgStyle = defStartBgStyle
    txtStyle = defStartTxtStyle
    hotkeys = [["^J:Y", startLocalGameMode]]
  })


let startBtn = @() {
  watch = [curUnfinishedBattleTutorial, isInSquad, currentGameMode]
  children = [
    isInSquad.value ? squadMatchButton()
      : curUnfinishedBattleTutorial.value != null ? startTutorialBtn
      : currentGameMode.value?.isLocal ? localGameBtn
      : quickMatchButton
    isInSquad.value || (!curUnfinishedBattleTutorial.value && !currentGameMode.value?.isLocal)
      ? mkActiveBoostersMark({ hplace = ALIGN_RIGHT, pos = [hdpx(20), bigPadding] })
      : null
  ]
}.__update(leftAppearanceAnim())

return startBtn
