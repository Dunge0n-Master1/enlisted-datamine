import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let { tiny_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let scrollbar = require("%ui/components/scrollbar.nut")
let { INVALID_GROUP_ID, INVALID_SESSION_ID } = require("matching.errors")
let { setTooltip } = require("%ui/style/cursors.nut")
let style = require("%ui/hud/style.nut")
let { crossnetworkPlay, CrossplayState } = require("%enlSqGlob/crossnetwork_state.nut")
let { getScoreTableColumns, LINE_H } = require("scoreTableColumns.nut")

let HEADER_H = LINE_H
const MAX_ROWS_TO_SCROLL = 20
const MAX_ROWS_IN_REPLAY = 14

let smallPadding = hdpx(4)
let borderWidth = hdpx(1)
let statisticsRowBgDarken = Color(0, 0, 0, 50)
let statisticsRowBgDisabled = Color(0, 0, 0, 20)
let statisticsRowBgLighten = Color(10, 10, 10, 50)
let statisticsRowBgHover = Color(25, 25, 25, 35)

let yourTeamColor = Color(18, 68, 91)
let enemyTeamColor = Color(107, 48, 45)

let statisticsScrollHandler = ScrollHandler()

let crossPlayInfo = @(){
  watch = crossnetworkPlay
  rendObj = ROBJ_TEXT
  color = style.DEFAULT_TEXT_COLOR
  text = crossnetworkPlay.value == CrossplayState.OFF ?  loc("crossplay/off")
    : crossnetworkPlay.value == CrossplayState.CONSOLES ? loc("crossplay/consoles")
    : null
}.__update(tiny_txt)

local function playerElem(columns, params, idx, playerData = null, borderColor = 0x00000000, slots=null, isMyTeam = false) {
  playerData = clone(playerData ?? {})
  let isInMatchingSlots = slots==null ? true : idx<slots
  playerData.isInMatchingSlots <- isInMatchingSlots
  local bgColor = (idx % 2) ? statisticsRowBgDarken : statisticsRowBgLighten
  if (!isInMatchingSlots)
    bgColor = statisticsRowBgDisabled
  idx ++
  let player = playerData?.player
  let stateFlags = Watched(0)

  return @() {
    key = player? playerData?.eid : null
    watch = stateFlags
    size = [flex(), LINE_H]
    flow = FLOW_HORIZONTAL
    gap = -borderWidth
    behavior = (player && params?.isInteractive) ? Behaviors.Button : null
    onElemState = @(sf) stateFlags(sf)
    children = columns.map(function (c) {
      if ((c?.showAlliesOnly ?? false) == true && isMyTeam == false)
        return null
      return {
        size = [c.width, flex()]
        rendObj = ROBJ_BOX
        fillColor = stateFlags.value & S_HOVER ? statisticsRowBgHover : bgColor
        borderWidth = [0, borderWidth, 0, borderWidth]
        borderColor
        children = player ? c.mkContent(playerData, params, idx) : null
      }
    })
  }
}

let paneHeader = @(columns, params) {
  rendObj = ROBJ_SOLID
  size = [flex(), HEADER_H]
  flow = FLOW_HORIZONTAL
  halign = ALIGN_RIGHT
  color = params.teamColor
  gap = -borderWidth
  children = columns.map(function(c) {
      let children = c.mkHeader(params)
      local override = c?.headerOverride ?? {}
      if (c?.locId != null)
        override = override.__merge({
          behavior = params.isInteractive ? Behaviors.Button : null
          inputPassive = true
          onHover = @(on) setTooltip(on ? loc(c.locId) : null)
        })
      return children == null ? null : {
        size = [c.width, flex()]
        valign = ALIGN_CENTER
        halign = ALIGN_CENTER
        children = children
      }.__update(override)
    })
}

let getEnemyTeam = @(teams, playerTeam) teams?.findvalue(@(_, teamId) teamId != playerTeam)

local function mkTeamPanel(columns, players, params, minRows, bordersColor, slots, isMyTeam) {
  slots = slots ?? players.len()
  let ret = {
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    children = players.map(@(player, idx) playerElem(columns, params, idx, player, bordersColor, slots, isMyTeam))
      .extend(array(max(0, minRows - players.len()))
        .map(@(_, idx) playerElem(columns, params, idx + players.len(), null, bordersColor, slots, isMyTeam)))
    clipChildren = true
  }
  ret.children.append({
    size = [flex(), hdpx(1)]
    rendObj = ROBJ_SOLID
    color = bordersColor
  })

  return ret
}

let function mkTwoColumnsTable(columns, allies, enemies, params, minRows) {
  let myTeamStr = params.myTeam.tostring()
  let enemyTeamData = getEnemyTeam(params?.teams, myTeamStr)
  let enemySlots = params?.teamsSlots[enemyTeamData?.teamId]
  let alliesSlots = params?.teamsSlots[params.myTeam]
  let hasAllies = allies.len() > 0 || alliesSlots != null
  let hasEnemies = enemies.len() > 0 || enemySlots != null
  if (!hasAllies && !hasEnemies)
    return null
  let { isReplay = false} = params
  let maxRowsCount = isReplay ? MAX_ROWS_IN_REPLAY : MAX_ROWS_TO_SCROLL

  let scrollWidth = params.scrollIsPossible && minRows > maxRowsCount ? fsh(1) : 0
  let myTeamData = params?.teams[myTeamStr]
  let alliesHeader = !hasAllies ? null : paneHeader(columns, {
    armies = myTeamData?.armies,
    teamIcon = myTeamData?.icon,
    teamText = isReplay ? loc(myTeamData?.armies[0]) : loc("debriefing/your_team"),
    addChild = params.additionalHeaderChild?(true)
    teamColor = yourTeamColor
    isInteractive = params?.isInteractive ?? false
  })

  let enemiesHeader = !hasEnemies ? null : paneHeader(columns, {
    armies = enemyTeamData?.armies,
    teamIcon = enemyTeamData?.icon,
    teamText = isReplay ? loc(enemyTeamData?.armies[0]) : loc("debriefing/enemy_team"),
    addChild = params.additionalHeaderChild?(false)
    teamColor = enemyTeamColor
    isInteractive = params?.isInteractive ?? false
  })

  let maxRows = max(enemies.len(), allies.len(), enemySlots ?? 0, alliesSlots ?? 0 )
  let teams = []
  if (hasAllies)
    teams.append(mkTeamPanel(columns, allies, params, maxRows, yourTeamColor, alliesSlots, true))
  if (hasEnemies)
    teams.append(mkTeamPanel(columns, enemies, params, maxRows, enemyTeamColor, enemySlots, false))

  return [
    {
      size = [params.width - scrollWidth, SIZE_TO_CONTENT]
      flow = FLOW_HORIZONTAL
      gap = smallPadding
      hplace = ALIGN_LEFT
      children = [
        alliesHeader
        enemiesHeader
      ]
    }
    params.scrollIsPossible && minRows > maxRowsCount
      ? scrollbar.makeVertScroll({
          size = [params.width - scrollWidth, SIZE_TO_CONTENT]
          flow = FLOW_HORIZONTAL
          gap = smallPadding
          children = teams
        },
        {
          size = [flex(), maxRowsCount * LINE_H]
          scrollHandler = statisticsScrollHandler
        })
      : {
          size = [flex(), SIZE_TO_CONTENT]
          flow = FLOW_HORIZONTAL
          gap = smallPadding
          children = teams
        }
  ]
}

let sortStatistics = @(a, b)
  (a.player?.scoreIndex ?? 0) <=> (b.player?.scoreIndex ?? 0)
  || a.player.disconnected <=> b.player.disconnected
  || (b.player?.score ?? 0) <=> (a.player?.score ?? 0)
  || (a.player?.lastUpdate ?? 0) <=> (b.player?.lastUpdate ?? 0)
  || (b.player?["scoring_player__kills"] ?? 0) <=> (a.player?["scoring_player__kills"] ?? 0) //compatibility with prev debriefing
  || a.eid <=> b.eid

let STATISTICS_VIEW_PARAMS = {
  localPlayerEid = ecs.INVALID_ENTITY_ID
  localPlayerGroupId = INVALID_GROUP_ID
  localPlayerGroupMembers = null
  myTeam = 1
  width = fsh(132)
  showBg = false
  scrollIsPossible = false
  additionalHeaderChild = null //@(isMyTeam) {}
  hotkeys = null
  title = null
  interactiveTip = null
  sessionId = INVALID_SESSION_ID
  showDisconnected = false
}

local function mkTable(players, params = STATISTICS_VIEW_PARAMS) {
  params = STATISTICS_VIEW_PARAMS.__merge(params)

  let { myTeam, localPlayerEid, localPlayerGroupId, localPlayerGroupMembers } = params
  let hasGroupId = localPlayerGroupId != INVALID_GROUP_ID
  let allies = []
  let enemies = []
  let columns = getScoreTableColumns(params.missionType)
  foreach (eid, player in players) {
    let res = {
      player
      eid
      isAlly = (player.team == myTeam)
      isLocal = (eid == localPlayerEid)
      isGroupmate = (player?.groupId == localPlayerGroupId && hasGroupId) && (localPlayerGroupMembers ?? {}).len() > 1
      sessionId = params.sessionId
      disconnected = params.showDisconnected ? (player?.disconnected ?? false) : false
      isDeserter = player?.isDeserter ?? false
      roomOwner = player?.player__roomOwner ?? false
      canForgive = params?.canForgivePlayers?[eid.tostring()] ?? false
      haveSessionResult = params?.result != null
    }

    if (res.isAlly)
      allies.append(res)
    else
      enemies.append(res)
  }
  allies.sort(sortStatistics)
  enemies.sort(sortStatistics)

  let minRows = max(allies.len(), enemies.len())
  return {
    key = "scores"
    flow = FLOW_VERTICAL
    hotkeys = params.hotkeys
    children = [
      crossPlayInfo
      { size = [params.width, SIZE_TO_CONTENT], children = params.title }
      {
        size = [params.width, SIZE_TO_CONTENT]
        flow = FLOW_VERTICAL
        halign = ALIGN_BOTTOM
        children = mkTwoColumnsTable(columns, allies, enemies, params, minRows)
      }
      params.interactiveTip
    ]
  }.__update(!params.showBg ? {} : {
    rendObj = ROBJ_WORLD_BLUR
    padding = [0, hdpx(10), hdpx(10), hdpx(10)]
    color = Color(150, 150, 150, 255)
  })
}

return mkTable
