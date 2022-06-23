from "%enlSqGlob/ui_library.nut" import *

let { body_txt, sub_txt, tiny_txt, fontawesome } = require("%enlSqGlob/ui/fonts_style.nut")
let scrollbar = require("%darg/components/scrollbar.nut")
let remap_nick = require("%enlSqGlob/remap_nick.nut")
let { INVALID_GROUP_ID, INVALID_USER_ID, INVALID_SESSION_ID } = require("matching.errors")
let { setTooltip, withTooltip } = require("%ui/style/cursors.nut")
let style = require("%ui/hud/style.nut")
let { round_by_value } = require("%sqstd/math.nut")
let contextMenu = require("%ui/components/contextMenu.nut")
let mkBattleHeroAwardIcon = require("%enlSqGlob/ui/battleHeroAwardIcon.nut")
let { BattleHeroesAward, awardPriority, isSoldierKindAward } = require("%enlSqGlob/ui/battleHeroesAwards.nut")
let mkAwardsTooltip = require("%ui/hud/components/mkAwardsTooltip.nut")
let canComplain = @(playerData) playerData.sessionId != INVALID_SESSION_ID && !playerData.isLocal
let complain = require("%ui/complaints/complainWnd.nut")
let forgive = require("%ui/requestForgiveFriendlyFire.nut")
let { crossnetworkPlay, CrossplayState } = require("%enlSqGlob/crossnetwork_state.nut")
let { showUserInfo, canShowUserInfo } = require("%enlSqGlob/showUserInfo.nut")
let { frameNick } = require("%enlSqGlob/ui/decoratorsPresentation.nut")
let fa = require("%darg/components/fontawesome.map.nut")
let armiesPresentation = require("%enlSqGlob/ui/armiesPresentation.nut")
let { mkRankIcon, getRankConfig } = require("%enlSqGlob/ui/rankPresentation.nut")

let bigGap = hdpx(10)

let HEADER_H = hdpx(40).tointeger()
let LINE_H = HEADER_H
let MAX_ROWS_TO_SCROLL = 20
let NUM_COL_WIDTH = hdpx(45)
let SCORE_COL_WIDTH = hdpx(65)
let TEAM_ICON_SIZE = (0.7 * HEADER_H).tointeger()

let smallPadding = hdpx(4)
let tooltipBattleHeroAwardIconSize = [hdpx(70), hdpx(70)]
let iconSize = (LINE_H - smallPadding).tointeger()
let borderWidth = hdpx(1)
let statisticsRowBgDarken = Color(0, 0, 0, 50)
let statisticsRowBgDisabled = Color(0, 0, 0, 20)
let statisticsRowBgLighten = Color(10, 10, 10, 50)
let statisticsRowBgHover = Color(25, 25, 25, 35)

let yourTeamColor = Color(18, 68, 91)
let enemyTeamColor = Color(107, 48, 45)

let TEAM0_TEXT_COLOR_HOVER = Color(210,220,255,120)
let TEAM1_TEXT_COLOR_HOVER = Color(255,220,220,120)
let MY_SQUAD_TEXT_COLOR_HOVER = Color(210,255,220,120)
let INVALID_COLOR = Color(100,100,100,100)
let INVALID_COLOR_HOVER = Color(160,160,160,100)

let statisticsScrollHandler = ScrollHandler()

let mkHeaderIcon = @(image) {
  size = [iconSize, iconSize]
  rendObj = ROBJ_IMAGE
  image = Picture(image.slice(-4) == ".svg" ? $"!{image}:{iconSize}:{iconSize}:K" : image)
}

let crossPlayInfo = @(){
  watch = crossnetworkPlay
  rendObj = ROBJ_TEXT
  color = style.DEFAULT_TEXT_COLOR
  text = crossnetworkPlay.value == CrossplayState.OFF ?  loc("crossplay/off")
    : crossnetworkPlay.value == CrossplayState.CONSOLES ? loc("crossplay/consoles")
    : null
}.__update(tiny_txt)

const disconnectedMultiplier = 0.5
const deserterMultiplier = 0.3
let function playerColor(playerData, sf = 0) {
  let isHover = sf & S_HOVER

  if (playerData.isLocal)
    return isHover ? MY_SQUAD_TEXT_COLOR_HOVER : style.MY_SQUAD_TEXT_COLOR

  if (playerData.player.possessed == INVALID_ENTITY_ID)
    return isHover ? INVALID_COLOR_HOVER : INVALID_COLOR

  let disconnected = playerData.disconnected || !playerData?.isInMatchingSlots

  if (playerData.isAlly)
    return mul_color(
      isHover ? TEAM0_TEXT_COLOR_HOVER : style.TEAM0_TEXT_COLOR,
      disconnected ? disconnectedMultiplier : playerData.isDeserter ? deserterMultiplier : 1
    )

  return mul_color(
    isHover ? TEAM1_TEXT_COLOR_HOVER : style.TEAM1_TEXT_COLOR,
    disconnected ? disconnectedMultiplier : playerData.isDeserter ? deserterMultiplier : 1
  )
}

let rowText = @(txt, w, playerData, sf = 0) {
  size = [w, LINE_H]
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = {
      vplace = ALIGN_CENTER
      rendObj = ROBJ_TEXT
      text = txt
      color = playerColor(playerData, sf)
    }.__update(sub_txt)
}

let squadMemberIconSize = hdpx(18).tointeger()
let friendlyFireIconSize = hdpx(18).tointeger()

let friendlyFireIcon = {
  size = [SIZE_TO_CONTENT, LINE_H]
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = [
    {
      rendObj = ROBJ_IMAGE
      size = [friendlyFireIconSize, friendlyFireIconSize]
      image = Picture("ui/skin#friendly_fire.svg:{0}:{0}:K".subst(friendlyFireIconSize))
      color = Color(255,0,0)
    }
  ]
}

let deserterIcon = @(playerData, sf) {
  vplace = ALIGN_CENTER
  rendObj = ROBJ_TEXT
  font = fontawesome.font
  text = fa["chain-broken"]
  color = playerColor(playerData, sf)
  fontSize = hdpx(20)
  padding = [hdpx(2), 0]
}

let mkMemberIcon = @(txt, playerData, sf = 0) {
  size = [SIZE_TO_CONTENT, LINE_H]
  halign = ALIGN_CENTER
  hplace = ALIGN_RIGHT
  valign = ALIGN_CENTER
  vplace = ALIGN_CENTER
  children = [
    {
      rendObj = ROBJ_IMAGE
      size = [squadMemberIconSize, squadMemberIconSize]
      image = Picture("ui/skin#squad_member.svg:{0}:{0}:K".subst(squadMemberIconSize))
      color = playerColor(playerData, sf)
    }
    {
      rendObj = ROBJ_TEXT
      padding = [0,0,hdpx(1),hdpx(1)]
      text = txt
      color = Color(0,0,0)
    }.__update(sub_txt)
  ]
}

let getFramedNick = @(player) frameNick(remap_nick(player.name), player?["decorators__nickFrame"])

let function openContextMenu(event, playerData, localPlayerEid, params) {
  if (playerData?.player == null)
    return

  let buttons = []
  if (canComplain(playerData))
    buttons.append({
      text = loc("btn/complain")
      action = @() complain(
        playerData.sessionId,
        playerData.player?.userid ?? INVALID_USER_ID,
        getFramedNick(playerData.player)
      )
    })

  if (playerData.canForgive)
    buttons.append({
      text = loc("btn/forgive")
      action = @() forgive(localPlayerEid, playerData.eid)
    })

  if (canShowUserInfo(playerData.player.userid.tointeger(), playerData.player.name) && !playerData.isLocal)
    buttons.append({
      text = loc("show_user_live_profile")
      action = @() showUserInfo(playerData.player.userid)
    })

  if (params?.mkContextMenuButton != null)
    buttons.extend(params.mkContextMenuButton(playerData))

  if (buttons.len())
    contextMenu(event.screenX + 1, event.screenY + 1, fsh(30), buttons)
}

let function selectDisplayedAward(isBattleHero, awards) {
  if (isBattleHero)
    return BattleHeroesAward.PLAYER_BATTLE_HERO
  let priorityAward = awards.reduce(@(a,b) awardPriority[a] > awardPriority[b] ? a : b)
  return isSoldierKindAward(priorityAward) && awards.len() > 1
    ? BattleHeroesAward.MULTISPECIALIST
    : priorityAward
}

let mkPlayerName = @(playerData, stateFlags) {
  children = [
    rowText(
      getFramedNick(playerData.player),
      SIZE_TO_CONTENT,
      playerData,
      stateFlags
    ).__update({ padding = [0, smallPadding], halign = ALIGN_LEFT })
  ]
}

let function mkBattleHeroAwardWidget(player, isAlly) {
  local awards = player?.awards ?? []
  if (awards.len() == 0)
    return null
  let isBattleHero = isAlly && (player?.isBattleHero ?? false)
  let displayedAward = selectDisplayedAward(isBattleHero, awards)
  if (isBattleHero)
    awards = [{icon = BattleHeroesAward.PLAYER_BATTLE_HERO, text = "debriefing/tooltipScoreTableBattleHero" }].extend(awards)
  if (displayedAward == BattleHeroesAward.MULTISPECIALIST)
    awards = [{icon = BattleHeroesAward.MULTISPECIALIST, text = "debriefing/tooltipScoreTableMultispecialist" }].extend(awards)
  return withTooltip(mkBattleHeroAwardIcon(displayedAward, [LINE_H,LINE_H]),
    @() mkAwardsTooltip(awards, tooltipBattleHeroAwardIconSize))
}

let function mkArmiesIcons(armies) {
  let icons = {}
  foreach(armyId in armies) {
    let { icon = null } = armiesPresentation?[armyId]
    if (icon != null)
      icons[icon] <- true
  }
  return {
    margin = [0, 0, 0, bigGap]
    vplace = ALIGN_CENTER
    flow = FLOW_HORIZONTAL
    gap =  -0.35 * TEAM_ICON_SIZE
    children = icons.keys().map(@(icon) {
      rendObj = ROBJ_IMAGE
      image = Picture($"!ui/skin#{icon}:{TEAM_ICON_SIZE}:{TEAM_ICON_SIZE}:K")
    })
  }
}

let function mkPlayerRank(playerData, isInteractive) {
  let { player_info__military_rank = 0 } = playerData?.player
  return player_info__military_rank <= 0 ? null : mkRankIcon(player_info__military_rank, {
    hplace = ALIGN_RIGHT
    vplace = ALIGN_CENTER
    margin = [0, bigGap]
    behavior = isInteractive ? Behaviors.Button : null
    onHover = @(on) setTooltip(on ? loc(getRankConfig(player_info__military_rank).locId) : null)
  })
}

let countAssistActions = @(data)
  ( (data?["scoring_player__assists"] ?? 0)
  + (data?["scoring_player__tankKillAssists"] ?? 0)
  + (data?["scoring_player__planeKillAssists"] ?? 0)
  + (data?["scoring_player__tankKillAssistsAsCrew"] ?? 0)
  + (data?["scoring_player__planeKillAssistsAsCrew"] ?? 0)
  + (data?["scoring_player__crewKillAssists"] ?? 0)
  + (data?["scoring_player__crewTankKillAssists"] ?? 0)
  + (data?["scoring_player__crewPlaneKillAssists"] ?? 0)
  + (data?["scoring_player__hostedOnSoldierSpawns"] ?? 0)
  + (data?["scoring_player__reviveAssists"] ?? 0)
  + (data?["scoring_player__healAssists"] ?? 0)
  + (data?["scoring_player__barrageBalloonDestructions"] ?? 0)
  + (data?["scoring_player__builtMedBoxRefills"] ?? 0)
  + (data?["scoring_player__vehicleRepairs"] ?? 0)
  + (data?["scoring_player__vehicleExtinguishes"] ?? 0)
  + (data?["scoring_player__enemyBuiltFortificationDestructions"] ?? 0)
  + (data?["scoring_player__enemyBuiltGunDestructions"] ?? 0)
  + (data?["scoring_player__enemyBuiltUtilityDestructions"] ?? 0) )

let countEngineerActions = @(data)
  ( (data?["scoring_player__builtRallyPointUses"] ?? 0)
  + (data?["scoring_player__builtStructures"] ?? 0)
  + (data?["scoring_player__builtGunKills"] ?? 0)
  + (data?["scoring_player__builtGunKillAssists"] ?? 0)
  + (data?["scoring_player__builtGunTankKills"] ?? 0)
  + (data?["scoring_player__builtGunTankKillAssists"] ?? 0)
  + (data?["scoring_player__builtGunPlaneKills"] ?? 0)
  + (data?["scoring_player__builtGunPlaneKillAssists"] ?? 0)
  + (data?["scoring_player__builtBarbwireActivations"] ?? 0)
  + (data?["scoring_player__builtCapzoneFortificationActivations"] ?? 0)
  + (data?["scoring_player__builtAmmoBoxRefills"] ?? 0) )

let countCapzoneKills = @(data)
  ( (data?["scoring_player__attackKills"] ?? 0)
  + (data?["scoring_player__defenseKills"] ?? 0) )

let columns = [
  {
    width = NUM_COL_WIDTH
    mkHeader = @(_) null
    mkContent = @(playerData, _params, idx) rowText(playerData?.isInMatchingSlots ? idx.tostring() : null, flex(), playerData)
  }
  {
    width = flex()
    mkHeader = @(p) [
      (p.armies?.len() ?? 0) > 0 ? mkArmiesIcons(p.armies)
        : p.teamIcon == null ? null
        : {
            rendObj = ROBJ_IMAGE
            hplace = ALIGN_CENTER
            vplace = ALIGN_CENTER
            image = Picture("{0}:{1}:{1}:K".subst(p.teamIcon, TEAM_ICON_SIZE))
            margin = [0, 0, 0, bigGap]
          }
      {
        rendObj = ROBJ_TEXT
        margin = [0, bigGap, 0, bigGap]
        text = p.teamText
      }.__update(body_txt)
      p.addChild
    ]
    headerOverride = { flow = FLOW_HORIZONTAL, halign = ALIGN_LEFT }
    mkContent = @(playerData, params, _idx) watchElemState(function(sf) {
      let isInteractive = (playerData?.player && params?.isInteractive)
      return {
        size = flex()
        flow = FLOW_HORIZONTAL
        behavior = isInteractive ? Behaviors.Button : null
        onClick = @(event) openContextMenu(event, playerData, params.localPlayerEid, params)
        children = [
          {
            flow = FLOW_HORIZONTAL
            padding = [0, smallPadding]
            size = flex()
            children = [
              playerData.isDeserter ? deserterIcon(playerData, sf) : null
              playerData.canForgive ? friendlyFireIcon : null
              mkBattleHeroAwardWidget(playerData.player, playerData?.isAlly ?? true)
              mkPlayerName(playerData, sf)
            ]
          }
          playerData.isGroupmate
            ? mkMemberIcon((playerData.player.memberIndex + 1).tostring(), playerData, sf)
                .__update({ padding = [0, bigGap] })
            : null
          mkPlayerRank(playerData, isInteractive)
        ]
      }
    })
  }
  {
    width = NUM_COL_WIDTH
    headerIcon = "ui/skin#statistics_kills_icon.svg"
    field = "scoring_player__kills"
    locId = "scoring/kills"
  }
  {
    width = NUM_COL_WIDTH
    headerIcon = "ui/skin#kills_technics_icon.svg"
    locId = "scoring/killsVehicles"
    mkContent = @(playerData, _params, _idx) rowText((playerData.player?["scoring_player__tankKills"] ?? 0)
      + (playerData.player?["scoring_player__planeKills"] ?? 0), flex(), playerData)
  }
  {
    width = NUM_COL_WIDTH
    headerIcon = "ui/skin#kills_assist_icon.svg"
    mkContent = @(playerData, _params, _idx)
      rowText(round_by_value(countAssistActions(playerData.player), 0.01), flex(), playerData)
    locId = "scoring/killsAssist"
  }
  {
    width = NUM_COL_WIDTH
    headerIcon = "ui/skin#engineer.svg"
    mkContent = @(playerData, _params, _idx) rowText(countEngineerActions(playerData.player), flex(), playerData)
    locId = "scoring/engineerActions"
  }
  {
    width = NUM_COL_WIDTH
    headerIcon = "ui/skin#zone_defense_icon.svg"
    mkContent = @(playerData, _params, _idx) rowText(countCapzoneKills(playerData.player), flex(), playerData)
    locId = "scoring/killsCapzoneDefenseOrAttack"
  }
  {
    width = NUM_COL_WIDTH
    headerIcon = "ui/skin#captured_zones_icon.svg"
    locId = "scoring/captures"
    mkContent = @(playerData, _params, _idx)
      rowText(round_by_value(playerData.player?["scoring_player__captures"] ?? 0, 0.1),
        flex(), playerData)
  }
  {
    width = NUM_COL_WIDTH
    headerIcon = "!ui/skin#lb_deaths"
    field = "scoring_player__squadDeaths"
    locId = "scoring/deathsSquad"
  }
  {
    width = SCORE_COL_WIDTH
    headerIcon = "!ui/skin#lb_score"
    field = "score"
    locId = "scoring/total"
  }
]
columns.each(function(c) {
  c.mkHeader <- c?.mkHeader ?? @(_) mkHeaderIcon(c.headerIcon)
  c.mkContent <- c?.mkContent
    ?? @(playerData, _params, _idx) rowText(playerData.player?[c.field].tostring() ?? "0", flex(), playerData)
})


local function playerElem(params, idx, playerData = null, borderColor = 0x00000000, slots=null, isMyTeam = false) {
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

let paneHeader = @(params) {
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

local function mkTeamPanel(players, params, minRows, bordersColor, slots, isMyTeam) {
  slots = slots ?? players.len()
  let ret = {
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    children = players.map(@(player, idx) playerElem(params, idx, player, bordersColor, slots, isMyTeam))
      .extend(array(max(0, minRows - players.len()))
        .map(@(_, idx) playerElem(params, idx + players.len(), null, bordersColor, slots, isMyTeam)))
    clipChildren = true
  }
  ret.children.append({
    size = [flex(), hdpx(1)]
    rendObj = ROBJ_SOLID
    color = bordersColor
  })

  return ret
}

let function mkTwoColumnsTable(allies, enemies, params, minRows) {
  let hasAllies = true//allies.len() > 0
  let hasEnemies = true//enemies.len() > 0
  if (!hasAllies && !hasEnemies)
    return null
  let myTeamStr = params.myTeam.tostring()
  let scrollWidth = params.scrollIsPossible && minRows > MAX_ROWS_TO_SCROLL ? fsh(1) : 0
  let myTeamData = params?.teams[myTeamStr]
  let alliesHeader = !hasAllies ? null : paneHeader({
    armies = myTeamData?.armies,
    teamIcon = myTeamData?.icon,
    teamText = loc("debriefing/your_team"),
    addChild = params.additionalHeaderChild?(true)
    teamColor = yourTeamColor
    isInteractive = params?.isInteractive ?? false
  })

  let enemyTeamData = getEnemyTeam(params?.teams, myTeamStr)
  let enemiesHeader = !hasEnemies ? null : paneHeader({
    armies = enemyTeamData?.armies,
    teamIcon = enemyTeamData?.icon,
    teamText = loc("debriefing/enemy_team"),
    addChild = params.additionalHeaderChild?(false)
    teamColor = enemyTeamColor
    isInteractive = params?.isInteractive ?? false
  })

  let enemySlots = params?.teamsSlots[getEnemyTeam(params?.teams, myTeamStr)?.teamId]
  let alliesSlots = params?.teamsSlots[params.myTeam]

  let maxRows = max(enemies.len(), allies.len(), enemySlots ?? 0, alliesSlots ?? 0 )
  let teams = []
  if (hasAllies)
    teams.append(mkTeamPanel(allies,  params, maxRows, yourTeamColor, alliesSlots, true))
  if (hasEnemies)
    teams.append(mkTeamPanel(enemies, params, maxRows, enemyTeamColor, enemySlots, false))

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
    params.scrollIsPossible && minRows > MAX_ROWS_TO_SCROLL
      ? scrollbar.makeVertScroll({
          size = [params.width - scrollWidth, SIZE_TO_CONTENT]
          flow = FLOW_HORIZONTAL
          gap = smallPadding
          children = teams
        },
        {
          size = [flex(), MAX_ROWS_TO_SCROLL * LINE_H]
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
  localPlayerEid = INVALID_ENTITY_ID
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
        children = mkTwoColumnsTable(allies, enemies, params, minRows)
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
