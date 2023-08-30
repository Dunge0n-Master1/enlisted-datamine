import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let { fontBody } = require("%enlSqGlob/ui/fontsStyle.nut")
let { TEAM_UNASSIGNED, FIRST_GAME_TEAM } = require("team")
let { teams } = require("%ui/hud/state/teams.nut")
let { lightgray } = require("%ui/components/std.nut")
let scoringPlayers = require("%ui/hud/state/scoring_players.nut")
let { localPlayerTeam, localPlayerEid, localPlayerGroupId, localPlayerUserId,
  localPlayerGroupMembers } = require("%ui/hud/state/local_player.nut")
let canForgivePlayers = require("%ui/hud/state/friendly_fire_can_forgive_state.nut")
let {myScore, enemyScore, anyTeamFailTimer} = require("%ui/hud/state/team_scores.nut")
let { visibleZoneGroups, whichTeamAttack } = require("%ui/hud/state/capZones.nut")
let {secondsToStringLoc} = require("%ui/helpers/time.nut")

let mkScoresStatistics = require("%ui/hud/components/mkScoresStatistics.nut")
let { missionType } = require("%enlSqGlob/missionParams.nut")
let JB = require("%ui/control/gui_buttons.nut")
let { removeInteractiveElement, hudIsInteractive, switchInteractiveElement
} = require("%ui/hud/state/interactive_state.nut")
let {verPadding} = require("%enlSqGlob/safeArea.nut")
let { capzoneWidget } = require("%ui/hud/components/capzone.nut")

let { DEFAULT_TEXT_COLOR } = require("%ui/hud/style.nut")
let { get_session_id } = require("app")
let { mkHintRow } = require("%ui/components/uiHotkeysHint.nut")
let { controlHudHint } = require("%ui/components/controlHudHint.nut")
let { isGamepad } = require("%ui/control/active_controls.nut")
let { INVALID_USER_ID } = require("matching.errors")
let { sendNetEvent, CmdVoteToKick } = require("dasevents")
let { voteToKickEnabled } = require("%ui/hud/state/vote_kick_state.nut")
let { isReplay } = require("%ui/hud/state/replay_state.nut")

let showScores = mkWatched(persist, "showScores", false)
let teamsSlotsQuery = ecs.SqQuery("teamsSlotsQuery", {comps_ro = [["teamsSlots", ecs.TYPE_INT_LIST]]})
let getTeamsSlots = @() teamsSlotsQuery.perform(@(_eid, comp) comp.teamsSlots.getAll().map(@(v) v+FIRST_GAME_TEAM))

let function getScoresTeams() {
  let teamsV = {}
  foreach (team in teams.value)
    if ((team?["team__id"] ?? TEAM_UNASSIGNED) != TEAM_UNASSIGNED)
      teamsV[team["team__id"].tostring()] <- { icon = team?["team__icon"], teamId = team["team__id"], armies = team?["team__armies"] }

  return teamsV
}

let titleText = {
  size = [flex(), SIZE_TO_CONTENT]
  rendObj = ROBJ_TEXT
}.__update(fontBody)

let zoneParams = {
  customBack = @(_v) null
  canHighlight = false
  animAppear = []
  animActive = []
  margin = 0
}

let function mkTeamScore(isMyTeam) {
  let scoreWatch = isMyTeam ? myScore : enemyScore
  let isDefend = Computed(@() whichTeamAttack.value != -1
    && (whichTeamAttack.value == localPlayerTeam.value) != isMyTeam)
  let halign = isMyTeam ? ALIGN_LEFT :ALIGN_RIGHT
  return function() {
    if (!isDefend.value)
      return titleText.__merge({
        watch = [scoreWatch, isDefend]
        halign = halign
        text = scoreWatch.value == null ? null
          : loc("teamHeader/score", { score = (1000.0 * scoreWatch.value + 0.5).tointeger() })
      })

    return {
      watch = [visibleZoneGroups, isDefend]
      size = [flex(), SIZE_TO_CONTENT]
      halign = halign
      flow = FLOW_HORIZONTAL
      gap = hdpx(10)
      children = visibleZoneGroups.value.reduce(@(res, v) res.extend(v), [])
        .map(@(zEid) capzoneWidget(zEid, zoneParams))
    }
  }
}

let mkCapzoneTimer = @() titleText.__merge({
  halign = ALIGN_CENTER
  color = lightgray
  text = anyTeamFailTimer.value > 0 ? secondsToStringLoc(anyTeamFailTimer.value) : loc("multiplayerscores/title")
  watch = anyTeamFailTimer
})

let title = {
  size = [flex(), hdpx(40)]
  valign = ALIGN_CENTER
  children = [
    mkTeamScore(true)
    mkCapzoneTimer
    mkTeamScore(false)
  ]
}

const interactiveKey = "scores"
let eventHandlers = {
  ["HUD.Interactive"] = function onHudInteractive(_event) {
    switchInteractiveElement(interactiveKey)
  },
  ["HUD.Interactive:end"] = function onHudInteractiveEnd(event) {
    if (showScores.value && ((event?.dur ?? 0) > 500 || event?.appActive == false)){
      removeInteractiveElement(interactiveKey)
    }
  }
}
showScores.subscribe(function(v) {
  if (!v)
    removeInteractiveElement(interactiveKey)
})

let hintTextFunc = @(text) {
  rendObj = ROBJ_TEXT
  text
  color = DEFAULT_TEXT_COLOR
}.__update(fontBody)

let function makeHintRow(hotkeys, text) {
  return {
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    children = [mkHintRow(hotkeys,{textFunc=hintTextFunc})].append(hintTextFunc(text))
  }
}

let HUD_INTERACTIVE_HOTKEY = "HUD.Interactive"

let function mkHudHint() {
  return @() {
    watch = hudIsInteractive
    valign = ALIGN_CENTER
    flow = FLOW_HORIZONTAL
    gap = hdpx(3)
    children = [
      controlHudHint({
        id = HUD_INTERACTIVE_HOTKEY
        height = ph(100)
      }),
      hintTextFunc(hudIsInteractive.value ? loc("scoring/nonInteractiveMode") : loc("scoring/interactiveMode"))
    ]
  }
}

let interactiveTip = @() {
  watch = [isGamepad, hudIsInteractive, isReplay]
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  flow = FLOW_HORIZONTAL
  gap = fsh(2.5)
  size = [flex(), fontH(250)]

  children = isReplay.value ? null : [
    mkHudHint(),
    hudIsInteractive.value
      ? makeHintRow($"^{JB.A} | M:0", loc("ui/cursor.activate"))
      : null,
    hudIsInteractive.value && isGamepad.value
      ? makeHintRow("^J:L.Thumb.hv", loc("ui/cursor.navigation"))
      : null
  ]
}
let function mkContextMenuButton(playerData) {
  let buttons = []
  let userid = playerData.player?.userid ?? INVALID_USER_ID
  let canKick = (voteToKickEnabled.value
    && !playerData.isLocal
    && !playerData.disconnected
    && !playerData.roomOwner
    && playerData.isAlly
    && userid != INVALID_USER_ID)
  if (canKick)
    buttons.append({
      text = loc("btn/vote_to_kick")
      action = function(_playerUid) {
        showScores(false)
        sendNetEvent(localPlayerEid.value, CmdVoteToKick({
          voteYes=true
          accused=playerData.eid
        }))
      }
    })
  return buttons
}

let scoresMenuUi = {
  size = flex()
  halign = ALIGN_CENTER
  padding = [verPadding.value + fsh(5), 0, verPadding.value, 0]
  flow = FLOW_VERTICAL
  children = [
    { size = [0, flex(1)] }
    @() mkScoresStatistics(scoringPlayers.value, {
      localPlayerEid = localPlayerEid.value
      localPlayerGroupId = localPlayerGroupId.value
      localPlayerUserId = localPlayerUserId.value
      localPlayerGroupMembers = localPlayerGroupMembers.value
      canForgivePlayers = canForgivePlayers.value
      myTeam = isReplay.value ? 1 : localPlayerTeam.value
      teams = getScoresTeams()
      sessionId = get_session_id()
      title = title
      showBg = true
      scrollIsPossible = true
      interactiveTip = interactiveTip
      isInteractive = hudIsInteractive.value || isReplay.value
      showDisconnected = true
      teamsSlots = getTeamsSlots()
      hotkeys = [[$"^{JB.B} | Esc", {
        action = @() showScores.update(false)
        description = loc("Close"),
        inputPassive = true
      }]]
      mkContextMenuButton = mkContextMenuButton
      isReplay = isReplay.value
      missionType = missionType.value
    }).__update({
      eventHandlers = eventHandlers
      watch = [ scoringPlayers, localPlayerTeam, localPlayerEid, isReplay,
        hudIsInteractive, verPadding, localPlayerGroupMembers, canForgivePlayers, voteToKickEnabled]
      behavior = Behaviors.ActivateActionSet
      actionSet = "Scores"
      sound = {
        attach = "ui/stat_on"
        detach = "ui/stat_off"
      }
    })
    { size = [0, flex(3)] }
  ]
}

return {
  showScores
  scoresMenuUi
}