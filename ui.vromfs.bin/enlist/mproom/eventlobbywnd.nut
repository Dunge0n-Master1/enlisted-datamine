from "%enlSqGlob/ui_library.nut" import *

let { addContextMenu } = require("%ui/components/contextMenu.nut")
let { showMsgbox, showMessageWithContent } = require("%enlist/components/msgbox.nut")
let { body_txt, h2_txt} = require("%enlSqGlob/ui/fonts_style.nut")
let {
  roomMembers, room, startSession, connectToHost, canOperateRoom, leaveRoom,
  lobbyStatus, LobbyStatus, isLocalDedicated, canStartWithLocalDedicated, roomTeamArmies,
  cancelSessionStart, myInfoUpdateInProgress
} = require("enlRoomState.nut")
let { startBtnWidth } = require("%enlist/startBtn.nut")
let JB = require("%ui/control/gui_buttons.nut")
let mkActiveBoostersMark = require("%enlist/mainMenu/mkActiveBoostersMark.nut")
let {
  bigPadding, maxContentWidth, accentColor, defTxtColor, commonBtnHeight, rowBg, isWide
} = require("%enlSqGlob/ui/viewConst.nut")
let { BtnActionBgDisabled, BtnActionTextNormal }  = require("%ui/style/colors.nut")
let { smallCampaignIcon } = require("%enlist/gameModes/roomsPkg.nut")
let { isEditEventRoomOpened } = require("%enlist/gameModes/createEventRoomState.nut")
let {
  verticalGap, localPadding, localGap, armieChooseBlockWidth
} = require("%enlist/gameModes/eventModeStyle.nut")
let { gameProfile } = require("%enlist/soldiers/model/config/gameProfile.nut")
let {
  myCampaign, setMyArmy, curTeam, setMyTeam, canChangeTeam, isReady, setReady,
  hasBalanceCheckedByEntrance, myArmy
} = require("myRoomMemberParams.nut")
let squads_list = require("%enlist/soldiers/squads_list.ui.nut")
let { mkMenuScene } = require("%enlist/mainMenu/mkMenuScene.nut")
let { selectArmyBlock, footer, mkPanel } = require("%enlist/gameModes/eventModesPkg.nut")
let { mkEventRoomInfo } = require("%enlist/gameModes/eventRoomInfo.nut")
let membersSpeaking = require("%ui/hud/state/voice_chat.nut")
let { mkArmySimpleIcon } = require("%enlist/soldiers/components/armyPackage.nut")
let armiesPresentation = require("%enlSqGlob/ui/armiesPresentation.nut")
let faComp = require("%ui/components/faComp.nut")
let { makeVertScroll, thinStyle } = require("%ui/components/scrollbar.nut")
let textButton = require("%ui/components/textButton.nut")
let { Bordered } = textButton
let checkbox = require("%ui/components/checkbox.nut")
let lobbyCampaignBlock = require("lobbyCampaignBlock.nut")
let memberStatuses = require("roomMemberStatuses.nut")
let { setTooltip } = require("%ui/style/cursors.nut")
let mkPlayerTooltip = require("mkPlayerTooltip.nut")
let serverTime = require("%enlSqGlob/userstats/serverTime.nut")
let { get_session_id } = require("app")
let complain = require("%ui/complaints/complainWnd.nut")
let userInfo = require("%enlSqGlob/userInfo.nut")
let { abs } = require("%sqstd/math.nut")
let spinner = require("%ui/components/spinner.nut")
let { safeAreaBorders } = require("%enlist/options/safeAreaState.nut")
let { memberName, mkStatusImg } = require("components/memberComps.nut")
let { getPenaltyExpiredTime } = require("%enlSqGlob/client_user_rights.nut")
let { secondsToHoursLoc } = require("%ui/helpers/time.nut")
let { curArmy } = require("%enlist/soldiers/model/state.nut")
let { requestModManifest, MOD_DOWNLOAD_URL, receivedModInfos
} = require("%enlist/gameModes/sandbox/customMissionState.nut")
let modsDownloadInfo = require("%enlist/gameModes/sandbox/modsDownloadInfo.ui.nut")
let { is_console } = require("%dngscripts/platform.nut")

let startBtnSize = [hdpx(400), hdpx(80)]
let spinnerSize = hdpx(60)

let needModDownloadButton = Computed(function() {
  if (is_console || canOperateRoom.value)
    return false
  let modId = room.value?.public.modId
  if (modId != null && receivedModInfos.value.findindex(@(mods) mods.id == modId) == null)
    return true
  return false
})


let teamBlockWidth = Computed(function(){
  let centralBlockWidth = maxContentWidth - safeAreaBorders.value[1] * 2 - localPadding * 2
    - armieChooseBlockWidth - startBtnSize[0]
  return  (centralBlockWidth - localPadding) / 2
})

let isDisbalanced = Computed(function(){
  let roomData = room.value
  let playersTeam0 = roomMembers.value.filter(@(player) player?.public.team == 0
    && player?.public.status == "IN_LOBBY_READY") ?? []
  let playersTeam1 = roomMembers.value.filter(@(player) player?.public.team == 1
    && player?.public.status == "IN_LOBBY_READY") ?? []
  let playersOfCurTeam = roomMembers.value
    .filter(@(player) player?.public.team == curTeam.value) ?? []
  let playersOfEnemyTeam = roomMembers.value
    .filter(@(player) player?.public.team == (1 - curTeam.value)) ?? []
  let maxDisbalance = roomData?.public.maxDisbalance ?? 0
  let disbalanceOfReadyPlayers = maxDisbalance != 0
    && abs(playersTeam0.len() - playersTeam1.len()) >= maxDisbalance
  return disbalanceOfReadyPlayers && playersOfCurTeam.len() > playersOfEnemyTeam.len()
})

let mkStatus = @(text){
  rendObj = ROBJ_TEXTAREA
  size = [flex(), SIZE_TO_CONTENT]
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  color = accentColor
  behavior = Behaviors.TextArea
  text
}.__update(body_txt)

let mkStatusWithSpinner = @(text){
  flow = FLOW_HORIZONTAL
  hplace = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = [
    spinner({ height = spinnerSize })
    {
      rendObj = ROBJ_TEXT
      color = accentColor
      text
    }.__update(body_txt)
  ]
}

let mkStatusDisbalance = @(public)
  mkStatus(loc("multiplayer/playersTeamDisbalance", {maxDisbalance = public?.maxDisbalance ?? 0}))

let mkStatusPlayers = @(public)
  mkStatus(loc("multiplayer/playersTeamLessThanMin", {minSize = public?.playersToStart ?? 0}))

let mkStatusWaiting = @(public) function(){
  let countDownTimer = (public?.sessionLaunchTime ?? 0) -  serverTime.value
  return {
    watch = serverTime
    size = [flex(), SIZE_TO_CONTENT]
    children = countDownTimer > 0
      ? mkStatus(loc("lobby/creatingBattleIn", {timeToStart = countDownTimer}))
      : mkStatusWithSpinner(loc("lobby/creatingBattle"))
  }
}

let statusCtor = {
  launched = "lobby/gameInProgress"
  ready_to_launch = "lobby/rdyToStart"
  game_in_progress = "memberStatus/inBattle"
  game_in_progress_no_launched = "memberStatus/inBattle"
  creating_game = @(public) mkStatusWaiting(public)
  teams_disbalanced = @(public) mkStatusDisbalance(public)
  not_enough_players = @(public) mkStatusPlayers(public)
  waiting_before_launch = @(public) mkStatusWaiting(public)
}.map(@(status) typeof status == "function" ? status : @(_) mkStatus(loc(status)))


let myArmiesList = Computed(@() (gameProfile.value?.campaigns[myCampaign.value].armies ?? []).map(@(a) a.id))

let teamBlockHeaderHeight = hdpxi(68)
let rowHeight = hdpx(28)
let teamsColors = [Color(157, 38, 38), Color(40, 93, 147)]
let armyIconSize = hdpx(20)
let armyIconHeaderSize = hdpxi(40)
let playersListHeaderHeight = verticalGap
let cellGap = isWide ? localGap : hdpx(5)
const WND_UID = "CHOOSE_CAMPAIGN_BLOCK"

let isMirrored = @(team) team == 1

let joinBtn = @(sf, team){
  size = [hdpx(150), commonBtnHeight]
  rendObj = ROBJ_BOX
  hplace = isMirrored(team) ? ALIGN_LEFT : ALIGN_RIGHT
  valign = ALIGN_CENTER
  borderWidth = sf & S_HOVER ? hdpx(1) : 0
  halign = ALIGN_CENTER
  children = {
    rendObj = ROBJ_TEXT
    text = loc("Join")
  }
}

let function armmyIconsBlock(shoudBeMirrowed, armies = []){
  let armyIcons = armies.map(@(armyId) (armiesPresentation?[armyId].icon ?? armyId))
  let iconsToShow = []
  armyIcons.each(@(val) iconsToShow.contains(val) ? null : iconsToShow.append(val) )
  return {
    valign = ALIGN_CENTER
    flow = FLOW_HORIZONTAL
    hplace = shoudBeMirrowed ? ALIGN_RIGHT : ALIGN_LEFT
    gap = -hdpx(15)
    children = iconsToShow.map(@(val){
      rendObj = ROBJ_IMAGE
      size = [armyIconHeaderSize, armyIconHeaderSize]
      image = Picture($"!ui/skin#{val}:{armyIconHeaderSize}:{armyIconHeaderSize}:K")
    })
  }
}

let teamBlockHeader = @(sf, team) function(){
  let children = [
    armmyIconsBlock(isMirrored(team), roomTeamArmies.value?[team] ?? [])
    team == curTeam.value || !canChangeTeam.value ? {size = flex()} : joinBtn(sf, team)
  ]
  return {
    watch = [roomTeamArmies, curTeam, canChangeTeam]
    size = [flex(), teamBlockHeaderHeight]
    gap = localGap
    valign = ALIGN_CENTER
    children = isMirrored(team) ? children : children.reverse()
  }
}

let function mkTeamBlockHeader(team){
  let function joinTeam(){
    if (!canChangeTeam.value)
      return

    setMyTeam(team)
  }
  return watchElemState(@(sf){
    rendObj = ROBJ_IMAGE
    behavior = Behaviors.Button
    onClick = @() joinTeam()
    size = [flex(), teamBlockHeaderHeight]
    image = Picture(isMirrored(team)
      ? $"!ui/gameImage/base_header_bar.svg:{hdpxi(150)}:{4}:K?Ac"
      : $"!ui/gameImage/base_header_bar_left.svg:{hdpxi(150)}:{4}:K?Ac"
      )
    padding = bigPadding
    valign = ALIGN_CENTER
    color = teamsColors[team]
    children = teamBlockHeader(sf, team)
  })
}

let speakIcon = faComp("microphone")

let function mkMemberStatus(status, name) {
  let { icon = null, iconColor = defTxtColor } = memberStatuses?[status]
  let isSpeaking = Computed(@() membersSpeaking.value?[name] ?? false)
  return @() {
    watch = isSpeaking
    children = isSpeaking.value ? speakIcon
      : icon != null ? mkStatusImg(icon, iconColor)
      : null
  }
}

let function mkCell(column, player) {
  let { content, width = rowHeight, halign = ALIGN_CENTER } = column
  return {
    size = [width, rowHeight]
    halign
    valign = ALIGN_CENTER
    children = content(player)
  }
}

let columns = [
  {
    content = @(player) memberName(player.nameText, player.public?.nickFrame)
    width = flex()
    halign = ALIGN_RIGHT
  }
  {
    content = @(player) "army" in player.public ? mkArmySimpleIcon(player.public.army, armyIconSize, { margin = 0 }) : null
  }
  {
    content = @(player) "campaign" in player.public ? smallCampaignIcon(player.public.campaign) : null
  }
  {
    content = @(player) mkMemberStatus(player.public?.status, player.name)
  }
]

let columnsMirrored = columns
  .map(@(col) "halign" not in col ? col
    : col.__merge({
        halign = col.halign == ALIGN_RIGHT ? ALIGN_LEFT
          : col.halign == ALIGN_LEFT ? ALIGN_RIGHT
          : ALIGN_CENTER
      }))
  .reverse()


let function playersListRow(player, idx, team) {
  let cols = isMirrored(team) ? columnsMirrored : columns
  return watchElemState(@(sf) {
    rendObj = ROBJ_SOLID
    watch = membersSpeaking
    size = [flex(), rowHeight]
    flow = FLOW_HORIZONTAL
    behavior = Behaviors.Button
    onClick = function(event) {
      let { userId } = userInfo.value
      if (player.userId == userId)
        return

      addContextMenu(event.screenX + 1, event.screenY + 1, fsh(30), [{
        text = loc("btn/complain")
        action = @() complain(get_session_id() ?? 0, player.userId, player.name)
      }])
    }
    onHover = @(on) setTooltip(on ? mkPlayerTooltip(player) : null)
    padding = [0, cellGap]
    halign = isMirrored(team) ? ALIGN_LEFT : ALIGN_RIGHT
    valign = ALIGN_CENTER
    color = rowBg(sf, idx, false)
    gap = cellGap
    children = cols.map(@(c) mkCell(c, player))
  })
}


let mkTeamBlockPlayersList = @(team) function(){
  let scrollAlign = isMirrored(team) ? ALIGN_LEFT : ALIGN_RIGHT
  let width = teamBlockWidth.value
  return {
    watch = [roomMembers, teamBlockWidth]
    flow = FLOW_VERTICAL
    size = flex()
    children = [
      {
        size = [flex(), playersListHeaderHeight]
      }
      makeVertScroll({
        size = [width, SIZE_TO_CONTENT]
        flow = FLOW_VERTICAL
        children = roomMembers.value.filter(@(val) val.public?.team == team)
          .map(@(player, idx) playersListRow(player, idx, team))
      },{
        scrollAlign
        styling = thinStyle
      })
    ]
  }
}

let teamBlock = @(team){
  size = flex()
  flow = FLOW_VERTICAL
  behavior = Behaviors.Button
  halign = ALIGN_CENTER
  children = [
    mkTeamBlockHeader(team)
    mkTeamBlockPlayersList(team)
  ]
}

let teamChooseBlockUi = @(){
  watch = roomTeamArmies
  size = flex()
  flow = FLOW_HORIZONTAL
  halign = ALIGN_CENTER
  gap = localPadding
  valign = ALIGN_CENTER
  children = roomTeamArmies.value.map(@(_, team) teamBlock(team))
}

let leftBlock = @() {
  watch = [myArmiesList, canChangeTeam, curArmy]
  size = [armieChooseBlockWidth, flex()]
  flow = FLOW_VERTICAL
  halign = ALIGN_CENTER
  gap = bigPadding
  children = [
    canChangeTeam.value ? selectArmyBlock(myArmiesList.value, myArmy.value, setMyArmy) : null
    squads_list
  ]
}

let centralBlock = {
  size = flex()
  flow = FLOW_VERTICAL
  halign = ALIGN_CENTER
  padding = [0, localPadding]
  gap = localGap
  children = teamChooseBlockUi
}

let mkStatusBlock = @(roomData, status) @(){
  watch = isDisbalanced
  size = [flex(), SIZE_TO_CONTENT]
  children = isDisbalanced.value
    ? statusCtor.teams_disbalanced(roomData?.public)
    : statusCtor?[status](roomData?.public)
}

let battleButtonParams = {
  size = startBtnSize
  halign = ALIGN_CENTER
  margin = 0
  borderWidth = hdpx(0)
  textParams = { rendObj=ROBJ_TEXT }.__update(h2_txt)
  style = { BgNormal = accentColor }
  hotkeys = [["^J:Y", { description = { skip = true }}]]
}

let mkDisabledStyle = @(isClickable) {
    BgNormal = BtnActionBgDisabled
  }.__update(isClickable ? {} : {
      TextDisabled = BtnActionTextNormal
      BgDisabled = BtnActionBgDisabled
    })

let getInactiveBattleButtonParams = @(isClickable)
  battleButtonParams.__merge({
    isEnabled = isClickable
    style = mkDisabledStyle(isClickable)
  })

let infoSpinner = spinner({ height = spinnerSize, opacity = 0.5, color = 0xFF000000 }).__update({
  transform = {}
  animations = [{ prop = AnimProp.opacity, from = 0, to = 1, duration = 0.5, play = true, easing = InCubic }]
})

let infoUpdateSpinner = @() {
  watch = myInfoUpdateInProgress
  vplace = ALIGN_CENTER
  children = myInfoUpdateInProgress.value ? infoSpinner : null
}

let mkButtonWithActiveBoostersMark = @(button) {
  size = [startBtnWidth, SIZE_TO_CONTENT]
  children = [
    button
    button == null ? null : mkActiveBoostersMark({ hplace = ALIGN_RIGHT, pos = [hdpx(20), bigPadding] })
    infoUpdateSpinner
  ]
}

let function showPenaltyWarn(expTime) {
  let timeText = Computed(function(){
    let time = expTime - serverTime.value
    if (time <= 0)
      return loc("loneFighterNoPenalty")
    return loc("loneFighterPenalty", {
      time = secondsToHoursLoc(time)
    })
  })
  showMessageWithContent({
    content = @() {
      watch = timeText
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      halign = ALIGN_CENTER
      text = timeText.value
    }.__update(body_txt)
    buttons = [{ text = loc("Ok"), isCancel = true }]
  })
}

let mkBattleButton = function(text, onClick){
  local action = onClick
  let penaltyExpTime = getPenaltyExpiredTime("USERSTATS", "USERSTATS", "LONE_FIGHTERS") ?? 0
  if (room.value?.public.mode == "LONE_FIGHTERS" && penaltyExpTime.value != 0){
    action = @() showPenaltyWarn(penaltyExpTime.value)
  }
  return mkButtonWithActiveBoostersMark(textButton(text, action, battleButtonParams))
}
let mkInactiveBattleButton = @(text, onClick)
  mkButtonWithActiveBoostersMark(
    textButton(text, onClick, getInactiveBattleButtonParams(onClick != null)))

let localDedicCheckbox = checkbox(isLocalDedicated,
  {
    text = loc("Start local dedicated")
    color = defTxtColor
  }.__update(body_txt))


let readyButton = mkBattleButton(loc("contact/Ready"), function(){
  let penaltyExpTime = getPenaltyExpiredTime("USERSTATS", "USERSTATS", "LONE_FIGHTERS") ?? 0
  if (room.value?.public.mode == "LONE_FIGHTERS" && penaltyExpTime.value != 0){
    showPenaltyWarn(penaltyExpTime.value)
    return
  }
  setReady(true)
})

let notReadyButton = mkInactiveBattleButton(loc("contact/notReady"), @() setReady(false))
let disbalanceButton = mkInactiveBattleButton(loc("lobby/disbalance"), null)

let function leaveRoomConfirm() {
  showMsgbox({
    text = loc("msg/leaveRoomConfirm")
    buttons = [
      { text = loc("Yes"),
        action = function(){
          hasBalanceCheckedByEntrance(false)
          leaveRoom()
        },
        isCurrent = true }
      { text = loc("Cancel"), isCancel = true }
    ]
  })
}

let function notEnoughPlayersMsg(public) {
  showMsgbox({
    text = mkStatus(loc("multiplayer/playersTeamLessThanMin", {minSize = public?.minSize ?? 0}))
    buttons = [
      { text = loc("Ok"), isCancel = true }
    ]
  })
}

let backButton = {
  size = [flex(), commonBtnHeight]
  children = Bordered(loc("BackBtn"), leaveRoomConfirm, {
    margin = 0,
    size = [flex(), commonBtnHeight]
    hotkeys = [[$"^{JB.B} | Esc",
      { action = leaveRoomConfirm , description = { skip = true } }]]
  })
}


let function startSessionWithMsg() {
  let hasAllReady = roomMembers.value.findvalue(@(m) !(m?.public.isReady ?? false)) == null
  let penaltyExpTime = getPenaltyExpiredTime("USERSTATS", "USERSTATS", "LONE_FIGHTERS") ?? 0
  if (room.value?.public.mode == "LONE_FIGHTERS" && penaltyExpTime.value != 0){
    showPenaltyWarn(penaltyExpTime.value)
    return
  }
  if (hasAllReady)
    startSession()
  else
    showMsgbox({
      text = loc("msg/notAllPlayersReady")
      buttons = [
        { text = loc("Yes"), action = startSession, isCurrent = true }
        { text = loc("Cancel"), isCancel = true }
      ]
    })
}

let mkStartButton = @(status, canOperate, roomData) function() {
  local children = null
  let readyBtn = isReady.value ? notReadyButton : readyButton
  if (status == LobbyStatus.ReadyToStart || status == LobbyStatus.TeamsDisbalanced)
    children = canOperate
        ? [
            canStartWithLocalDedicated.value ? localDedicCheckbox : null
            mkBattleButton(loc("lobby/startGameBtn"), startSessionWithMsg)
          ]
      : isDisbalanced.value
        ? disbalanceButton
      : readyBtn
  else if (status == LobbyStatus.GameInProgressNoLaunched)
    children = mkBattleButton(loc("lobby/playBtn"), connectToHost)
  else if (status == LobbyStatus.NotEnoughPlayers)
    children = canOperate ? mkInactiveBattleButton(loc("not_enough_players"),
      @() notEnoughPlayersMsg(roomData?.public))
    : readyBtn
  else if (status == LobbyStatus.WaitForDedicatedStart)
    children = canOperate
      ? {
          size = [SIZE_TO_CONTENT, startBtnSize[1]]
          hplace = ALIGN_CENTER
          vplace = ALIGN_CENTER
          color = accentColor
          rendObj = ROBJ_TEXT
          text = loc("Wait for dedicated start")
        }
      : readyBtn
  else if (status != LobbyStatus.GameInProgress)
    children = canOperate ? null : readyBtn

  return {
    watch = [canStartWithLocalDedicated, isReady, roomMembers, curTeam, isDisbalanced]
    size = [startBtnSize[0], SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    halign = ALIGN_CENTER
    children
  }
}

let changeAttributesRoomBtn = {
  size = [flex(), commonBtnHeight]
  children = Bordered(loc("changeAttributesRoom"), @() isEditEventRoomOpened(true), {
    margin = 0,
    size = flex()
    hotkeys = [["^J:X", {  description = { skip = true } }]]
  })
}

let cancelButton = {
  size = [flex(), commonBtnHeight]
  children = Bordered(loc("Cancel"), @() cancelSessionStart(), {
    margin = 0,
    size = flex()
    hotkeys = [[$"^{JB.B} | Esc",
      { action = cancelSessionStart , description = { skip = true } }]]
  })
}

let membersCount = Computed(@()
  roomMembers.value.filter(@(player) player.public?.host == null).len())

let function rightBlock() {
  let roomData = room.value
  let status = lobbyStatus.value
  let {
    WaitingBeforeLauch, ReadyToStart, NotEnoughPlayers, TeamsDisbalanced
  } = LobbyStatus

  let canOperate = canOperateRoom.value
  let isWaitLauch = status == WaitingBeforeLauch
  let hasBackBtn = !canOperate || !isWaitLauch
  let hasCancelBtn = canOperate && isWaitLauch

  let isGameInPrepare = status == ReadyToStart
    || status == NotEnoughPlayers
    || status == TeamsDisbalanced
  let canChangeRoom = canOperate && isGameInPrepare

  return {
    watch = [room, membersCount, lobbyStatus, canOperateRoom, needModDownloadButton]
    size = [startBtnSize[0], flex()]
    flow = FLOW_VERTICAL
    gap = verticalGap
    children = [
      lobbyCampaignBlock
      mkPanel({
        size = flex()
        children = mkEventRoomInfo(roomData.public.__merge({
          membersCnt = membersCount.value
        }))
      })
      {
        flow = FLOW_VERTICAL
        gap = bigPadding
        children = [
          mkStatusBlock(roomData, status)
          mkStartButton(status, canOperate, roomData)
          needModDownloadButton.value
            ? Bordered(loc("mods/downloadFromLobby"), function() {
                let { modId, modVersion } = room.value.public
                let urlToDownload = MOD_DOWNLOAD_URL.subst(modId, modVersion)
                requestModManifest(urlToDownload)
              }, { size = [flex(), commonBtnHeight], margin = 0})
            : null
          canChangeRoom ? changeAttributesRoomBtn : null
          hasCancelBtn ? cancelButton
            : hasBackBtn ? backButton
            : null
        ]
      }
    ]
  }
}
let lobbyContent = {
  size = flex()
  flow = FLOW_HORIZONTAL
  maxWidth = maxContentWidth
  hplace = ALIGN_CENTER
  gap = bigPadding
  transform = {}
  children = [
    leftBlock
    centralBlock
    rightBlock
  ]
}

let topBar = {
  size = flex()
}

let lobbyWindow = mkMenuScene(topBar, lobbyContent, footer)

let function createdRoomWnd() {
  return {
    size = [flex(), flex()]
    halign = ALIGN_CENTER
    rendObj = ROBJ_WORLD_BLUR_PANEL
    fillcolor = Color(250,250,150,255)
    children = [
      lobbyWindow
      modsDownloadInfo
    ]
  }
}

return createdRoomWnd