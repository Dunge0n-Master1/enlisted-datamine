from "%enlSqGlob/ui_library.nut" import *

let { fontXLarge } = require("%enlSqGlob/ui/fontsStyle.nut")
let { titleTxtColor, accentColor, defTxtColor, startBtnWidth, colPart, leftAppearanceAnim
//  ,DEF_APPEARANCE_TIME
} = require("%enlSqGlob/ui/designConst.nut")
let { isInBattleState } = require("%enlSqGlob/inBattleState.nut")
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
let { contacts } = require("%enlist/contacts/contact.nut")
let { remap_nick } = require("%enlSqGlob/remap_nick.nut")
let mkActiveBoostersMark = require("%enlist/mainMenu/mkActiveBoostersMark.nut")
let { showSquadMembersCrossPlayRestrictionMsgBox,
  showSquadVersionRestrictionMsgBox
} = require("%enlist/restrictionWarnings.nut")
let { Flat } = require("%ui/components/txtButton.nut")
let mkGlare = require("%enlist/components/mkGlareAnim.nut")


let defStartTxtStyle = {
  defTextColor = titleTxtColor
  hoverTextColor = accentColor
  activeTextColor = titleTxtColor
}

let leaveMatchTxtStyle = {
  defTextColor = defTxtColor
  hoverTextColor = titleTxtColor
  activeTextColor = defTxtColor
  txtParams = {
    rendObj = ROBJ_TEXTAREA
    behavior = Behaviors.TextArea
    size = [pw(70), SIZE_TO_CONTENT]
    halign = ALIGN_CENTER
  }.__update(fontXLarge)
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


let blinkAnimation = [{prop = AnimProp.color, from = 0x00F27272 , to = 0x44AA7272, duration = 3,
  loop = true, play = true, easing = CosineFull }]


let btnHeight = hdpxi(94)
let function btnCtor(txt, action, params = {}) {
  let { defTextColor, hoverTextColor, activeTextColor, txtParams = fontXLarge } = params.txtStyle
  let { bgStyle, hotkeys = null } = params
  return Flat(txt, action, {
    btnWidth = startBtnWidth
    btnHeight
    hotkeys
    style = {
      defTxtColor = defTextColor
      hoverTxtColor = hoverTextColor
      activeTxtColor = activeTextColor
    }
    txtParams
    bgComp = function(sf, _isEnabled = true) {
      let { defBg, hoverBg, activeBg } = bgStyle
      let isActive = sf & S_ACTIVE
      return {
        key = $"{isActive}"
        size = flex()
        rendObj = ROBJ_IMAGE
        image = sf & S_ACTIVE ? activeBg
          : sf & S_HOVER ? hoverBg
          : defBg
        animations = [
          { prop = AnimProp.opacity, from = 0.0, to = 1.0, duration = 0.3, play = true }
          { prop = AnimProp.opacity, from = 1.0, to = 0.0, duration = 0.3, playFadeOut = true }
        ]
      }
    }
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


let function checkPlayAvailability() {
  if (isSquadLeader.value && unsuitableCrossplayConditionMembers.value.len() != 0) {
    showSquadMembersCrossPlayRestrictionMsgBox(unsuitableCrossplayConditionMembers.value)
    return
  }

  let unsuitableByVersion = getUnsuitableVersionConditionMembers(currentGameMode.value)
  if (unsuitableByVersion.len() != 0) {
    showSquadVersionRestrictionMsgBox(unsuitableByVersion.values())
    return
  }

  let campaign = curCampaign.value
  let lockedUserIds = allMembersState.value
    .filter(@(m) !(m?.unlockedCampaigns ?? []).contains(campaign))
    .keys()
  if (lockedUserIds.len() > 0) {
    showMsgbox({
      text = loc("msg/cantGoBattle/membersCampaignLocked", {
        campaign = colorize(MsgMarkedText,
          loc(gameProfile.value?.campaigns[campaign].title ?? campaign))
        membersList = colorize(MsgMarkedText,
          ", ".join(lockedUserIds.map(@(userId)
            remap_nick(contacts.value[userId.tostring()]?.realnick))))
      })
    })
    return
  }

  showCurNotReadySquadsMsg(quickMatchFn)
}


let function mkJoinQuickMatchButton() {
  return btnCtor(loc("START"), checkPlayAvailability,
    {
      bgStyle = defStartBgStyle
      txtStyle = defStartTxtStyle
      hotkeys = [["^J:Y", { skip = true }]]
      animations = blinkAnimation
    })
}


let quickMatchButton = @() {
  watch = isInQueue
  children = isInQueue.value
    ? leaveQuickMatchButton
    : mkJoinQuickMatchButton()
}


let quickMatchBtn = btnCtor(loc("START"), checkPlayAvailability,
  {
    bgStyle = defStartBgStyle
    txtStyle = defStartTxtStyle
    hotkeys = [["^J:Y", checkPlayAvailability ]]
    animations = blinkAnimation
  })

let pressWhenReadyBtn = btnCtor(loc("Press when ready"),
  @() showCurNotReadySquadsMsg(@() myExtSquadData.ready(true)),
  {
    bgStyle = defStartBgStyle
    txtStyle = leaveMatchTxtStyle.__merge({ defTextColor = titleTxtColor })
    hotkeys = [["^J:Y", @() showCurNotReadySquadsMsg(@() myExtSquadData.ready(true)) ]]
    animations = blinkAnimation
  })

let setNotReadyBtn = btnCtor(loc("Set not ready"), @() myExtSquadData.ready(false),
  {
    bgStyle = leaveMatchBgStyle
    txtStyle = leaveMatchTxtStyle
    hotkeys = [[$"^{JB.B}" ]]
  })

isInBattleState.subscribe(function(inBattle) {
  if (!inBattle) {
    myExtSquadData.ready(false)
  }
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
    animations = blinkAnimation
  })

let startLocalGameMode = @() gameLauncher.startGame({
  game = "enlisted", scene = currentGameMode.value?.scenes[0]
})

let localGameBtn = btnCtor(loc("START"), startLocalGameMode,
  {
    bgStyle = defStartBgStyle
    txtStyle = defStartTxtStyle
    hotkeys = [["^J:Y", startLocalGameMode]]
    animations = blinkAnimation
  })


let startBtn = @() {
  watch = [curUnfinishedBattleTutorial, isInSquad, currentGameMode]
  children = [
    isInSquad.value ? squadMatchButton
      : curUnfinishedBattleTutorial.value != null ? startTutorialBtn
      : currentGameMode.value?.isLocal ? localGameBtn
      : quickMatchButton
    isInSquad.value || (!curUnfinishedBattleTutorial.value && !currentGameMode.value?.isLocal)
      ? mkActiveBoostersMark({ hplace = ALIGN_RIGHT, vplace = ALIGN_CENTER, pos = [hdpxi(20), 0] })
      : null
    mkGlare({
      nestWidth = startBtnWidth
      glareWidth = colPart(2)
      glareDuration = 0.7
      glareOpacity = 0.5
      glareDelay = 5
    })
  ]
}.__update(leftAppearanceAnim(0.1))

return startBtn
