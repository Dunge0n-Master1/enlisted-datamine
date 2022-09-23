from "%enlSqGlob/ui_library.nut" import *

let { body_txt, sub_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let { connectToHost, lobbyStatus, startSession, leaveRoom, destroyRoom, roomMembers, room,
  chatId, canOperateRoom, LobbyStatus, roomTeamArmies, startSessionWithLocalDedicated,
  canStartWithLocalDedicated
} = require("enlRoomState.nut")
let { curTeam } = require("myRoomMemberParams.nut")
let textButton = require("%ui/components/textButton.nut")
let msgbox = require("%enlist/components/msgbox.nut")
let colors = require("%ui/style/colors.nut")
let chatRoom = require("%enlist/chat/chatRoom.nut")
let matching_errors = require("matching.errors")
let roomSettings = require("%enlist/roomSettings.nut")
let membersSpeaking = require("%ui/hud/state/voice_chat.nut")
let { remap_nick } = require("%enlSqGlob/remap_nick.nut")
let JB = require("%ui/control/gui_buttons.nut")
let { mkArmyIcon, mkArmyName } = require("%enlist/soldiers/components/armyPackage.nut")

let function startSessionCb(response) {
  let function reportError(text) {
    console_print(text)
    msgbox.show({text=text})
  }

  if (response?.accept == false) // server rejected invite
    reportError("Failed to start session in room: {0}".subst(response?.reason ?? ""))
  else if (response.error != 0)
    reportError("Failed to start session in room: Battle servers not found")

}

let function leaveRoomCb(response) {
  if (response.error) {
    msgbox.show({
      text = "Failed to leave room: {0}".subst(matching_errors.error_string(response.error))
    })
  }
}

let function doLeaveRoom() {
  leaveRoom(leaveRoomCb)
}

let function destroyRoomCb(response) {
  if (response.error) {
    msgbox.show({
      text = "Failed to destroy room: {0}".subst(matching_errors.error_string(response.error))
    })
  }
}

let function doDestroyRoom() {
  destroyRoom(destroyRoomCb)
}

let function memberName(member) {
  let colorSpeaking = Color(20, 220, 20, 255)
  let colorSilent = colors.TextHighlight
  return function() {
    let prefix = member.squadNum == 0 ? "" : $"[{member.squadNum}] "
    let text = prefix + remap_nick(member.name)

    return {
      watch = [membersSpeaking]
      color = membersSpeaking.value?[member.name] ? colorSpeaking : colorSilent
      rendObj = ROBJ_TEXT
      text
      margin = fsh(1)
      hplace = ALIGN_LEFT
      validateStaticText = false
    }.__update(body_txt)
  }
}

let teamIconSize = hdpx(30)
let teamIcon = @(team) function() {
  let armyId = roomTeamArmies.value?[team][0]
  return {
    watch = roomTeamArmies
    size = array(2, teamIconSize)
    children = armyId == null ? null
      : mkArmyIcon(armyId, teamIconSize, { margin = 0 })
  }
}

let memberInfo = @(member) {
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  children = [
    teamIcon(member?.public.team ?? 0)
    memberName(member)
  ]
}


let function listContent() {
  let players = roomMembers.value.
    filter(@(member) !member.public?.host)
  players.sort(@(a, b) (a.public?.squadId ?? 0) <=> (b.public?.squadId ?? 0))

  local squadNum = 0
  local prevSquadId = null
  foreach (player in players) {
    let squadId = player.public?.squadId
    if (squadId == null)
      player.squadNum <- 0
    else {
      if (squadId != prevSquadId) {
        squadNum += 1
        prevSquadId = squadId
      }
      player.squadNum <- squadNum
    }
  }

  let children = players.map(@(member) memberInfo(member))

  return {
    watch = [roomMembers]
    flow = FLOW_VERTICAL
    halign = ALIGN_CENTER
    size = [flex(), SIZE_TO_CONTENT]
    children = children
  }
}


//dlogsplit(room.value.public)
let header = {
  vplace = ALIGN_TOP
  rendObj = ROBJ_SOLID
  color = colors.HeaderOverlay
  size = [flex(), fsh(4)]
  flow = FLOW_HORIZONTAL
  gap = hdpx(1)
  children = function() {
    local scene = null
    if (room.value?.roomId) {
      scene = room.value.public?.title
      if (scene == null) {
        scene = room.value.public?.scene
        if (scene != null)
          scene = scene.split("/")
        if (scene.len()>0)
          scene = scene[scene.len()-1]
      }
    }
    return {
      watch = [room]
      margin = [fsh(1), fsh(3)]
      rendObj = ROBJ_TEXT
      text = room.value?.roomId != null ?
        "{roomName}. {loccreator}{:} {creator}, {server}{:} {cluster}, {scene}".subst(room.value.public.__merge({
            scene, [":"]=":",loccreator=loc("Creator")
            server=loc("server")
            creator = remap_nick(room.value.public?.creator ?? "")
          })
        )
        :
        null
//      loc("lobby/roomName","Name: ") + (room.value?.roomId != null ? room.value.public.roomName : "")
    }.__update(sub_txt)
  }
}


let function membersListRoot() {
  return {
    size = [sw(20), sh(60)]
    hplace = ALIGN_LEFT
    pos = [sw(10), sh(10)]

    rendObj = ROBJ_FRAME
    color = colors.Inactive
    borderWidth = [2, 0]
    padding = [2, 0]

    key = "members-list"

    children = {
      size = flex()
      clipChildren = true

      children = {
        size = flex()
        flow = FLOW_VERTICAL

        behavior = Behaviors.WheelScroll

        children = listContent
      }
    }
  }
}


let function statusText() {
  local text = ""
  let curLobbyStatus = lobbyStatus.value
  if (curLobbyStatus == LobbyStatus.ReadyToStart)
    text = loc("lobbyStatus/ReadyToStart", {num_players = roomSettings.minPlayers.value, start_game_btn=loc("lobby/startGameBtn")})
  else if (curLobbyStatus == LobbyStatus.NotEnoughPlayers)
    text = loc("lobbyStatus/NotEnoughPlayers")
  else if (curLobbyStatus == LobbyStatus.CreatingGame)
    text = loc("lobbyStatus/CreatingGame")
  else if (curLobbyStatus == LobbyStatus.GameInProgress)
    text = loc("lobbyStatus/GameInProgress")
  else if (curLobbyStatus == LobbyStatus.GameInProgressNoLaunched)
    text = loc("lobbyStatus/GameInProgressNoLaunched", {play=loc("lobby/playBtn")})
  else if (curLobbyStatus == LobbyStatus.WaitForDedicatedStart)
    text = loc("Wait for dedicated start")

  return {
    size = [sw(100), SIZE_TO_CONTENT]
    vplace = ALIGN_TOP
    pos = [0, fsh(5.8)]
    halign = ALIGN_CENTER
    watch = [
      lobbyStatus
    ]
    children = {
      rendObj = ROBJ_TEXT
      text = text
      color = Color(200,200,50)
    }.__update(body_txt)
  }
}


let startGameButton = textButton(loc("lobby/startGameBtn"), startSession,
  {
    hotkeys=[["^J:X"]]
    sound = {
      click  = "ui/enlist/start_game_click"
      hover  = "ui/enlist/button_highlight"
      active = "ui/enlist/button_action"
    }
  })

let actionButtons = @() {
  watch = [lobbyStatus, canOperateRoom]
  flow = FLOW_HORIZONTAL
  children = [
    lobbyStatus.value == LobbyStatus.ReadyToStart ? startGameButton : null,
    lobbyStatus.value == LobbyStatus.GameInProgressNoLaunched
      ? textButton(loc("lobby/playBtn"), connectToHost)
      : null,
    canOperateRoom.value && canStartWithLocalDedicated.value
        && lobbyStatus.value == LobbyStatus.ReadyToStart
      ? textButton("Start with local dedic", @() startSessionWithLocalDedicated(startSessionCb))
      : null,
    textButton(loc("lobby/leaveBtn"), doLeaveRoom, {hotkeys=[["^{0} | Esc".subst(JB.B)]]}),
    (canOperateRoom.value
      ? textButton(loc("lobby/destroyRoomBtn"), doDestroyRoom, {hotkeys=[["^J:Y"]]})
      : null)
  ]
}

let mkArmyBtn = @(armyId, isSelected, onClick)
  watchElemState(@(sf) {
    rendObj = ROBJ_BOX
    size = SIZE_TO_CONTENT
    borderWidth = (isSelected || (sf & S_HOVER)) ? [0, 0, hdpx(4), 0] : 0
    behavior = isSelected ? null : Behaviors.Button
    sound = {
      hover = "ui/enlist/button_highlight"
      click = "ui/enlist/button_click"
    }
    onClick
    children = {
      flow = FLOW_HORIZONTAL
      gap = hdpx(5)
      padding = hdpx(10)
      size = SIZE_TO_CONTENT
      vplace = ALIGN_BOTTOM
      children = [
        mkArmyIcon(armyId)
        mkArmyName(armyId, isSelected, sf)
      ]
    }
  })

let armyButtons = @() {
  watch = [roomTeamArmies, curTeam]
  flow = FLOW_HORIZONTAL
  gap = hdpx(20)
  children = roomTeamArmies.value.map(
    @(armies, team) mkArmyBtn(armies?[0] ?? "", team == curTeam.value, @() curTeam(team)))
}

let allButtons = {
  size = [flex(), SIZE_TO_CONTENT]
  vplace = ALIGN_BOTTOM
  gap = hdpx(10)
  flow = FLOW_VERTICAL
  halign = ALIGN_CENTER
  children = [
    armyButtons
    actionButtons
  ]
}

let function chatRoot() {
  return {
    size = [sw(55), sh(60)]
    pos = [sw(35), sh(10)]
    hplace = ALIGN_LEFT
    children = chatRoom(chatId.value)
    watch = chatId
  }
}


let function roomScreen() {
  return {
    size = [flex(), flex()]
    halign = ALIGN_CENTER
    rendObj = ROBJ_WORLD_BLUR_PANEL
    color = Color(150,150,150,255)
    children = [
      header
      membersListRoot
      chatRoot
      statusText
      allButtons
    ]
  }
}

return roomScreen
