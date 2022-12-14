from "%enlSqGlob/ui_library.nut" import *
import "%dngscripts/ecs.nut" as ecs

let { body_txt, sub_txt, fontawesome } = require("%enlSqGlob/ui/fonts_style.nut")
let fa = require("%ui/components/fontawesome.map.nut")
let { INVALID_USER_ID, INVALID_SESSION_ID } = require("matching.errors")
let { remap_others } = require("%enlSqGlob/remap_nick.nut")
let { round_by_value } = require("%sqstd/math.nut")
let { BattleHeroesAward, awardPriority, isSoldierKindAward } = require("%enlSqGlob/ui/battleHeroesAwards.nut")
let { addContextMenu, closeLatestContextMenu } = require("%ui/components/contextMenu.nut")
let { setTooltip, withTooltip } = require("%ui/style/cursors.nut")
let style = require("%ui/hud/style.nut")
let mkBattleHeroAwardIcon = require("%enlSqGlob/ui/battleHeroAwardIcon.nut")
let mkAwardsTooltip = require("%ui/hud/components/mkAwardsTooltip.nut")
let complain = require("%ui/complaints/complainWnd.nut")
let forgive = require("%ui/requestForgiveFriendlyFire.nut")
let { frameNick } = require("%enlSqGlob/ui/decoratorsPresentation.nut")
let { mkRankIcon, getRankConfig, rankIconSize
} = require("%enlSqGlob/ui/rankPresentation.nut")
let { SetReplayTarget } = require("dasevents")
let armiesPresentation = require("%enlSqGlob/ui/armiesPresentation.nut")
let { getObjectName } = require("%enlSqGlob/ui/itemsInfo.nut")

let LINE_H = hdpxi(40)
let NUM_COL_WIDTH = hdpx(45)
let SCORE_COL_WIDTH = hdpx(65)
let TEAM_ICON_SIZE = (0.7 * LINE_H).tointeger()
let bigGap = hdpx(10)
let smallPadding = hdpx(4)
let iconSize = (LINE_H - smallPadding).tointeger()
let tooltipBattleHeroAwardIconSize = [hdpx(70), hdpx(70)]

let canComplain = @(playerData) playerData.sessionId != INVALID_SESSION_ID && !playerData.isLocal

let canShowUserProfile = @(playerData) playerData.sessionId != INVALID_SESSION_ID
  && !playerData.isLocal


let TEAM0_TEXT_COLOR_HOVER = Color(210,220,255,120)
let TEAM1_TEXT_COLOR_HOVER = Color(255,220,220,120)
let MY_SQUAD_TEXT_COLOR_HOVER = Color(210,255,220,120)
let INVALID_COLOR = Color(100,100,100,100)
let INVALID_COLOR_HOVER = Color(160,160,160,100)

const disconnectedMultiplier = 0.5
const deserterMultiplier = 0.3
let function playerColor(playerData, sf = 0) {
  let isHover = sf & S_HOVER

  if (playerData.isLocal)
    return isHover ? MY_SQUAD_TEXT_COLOR_HOVER : style.MY_SQUAD_TEXT_COLOR

  if (playerData.player.possessed == ecs.INVALID_ENTITY_ID)
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

let mkHeaderIcon = memoize(function(image) {
  return freeze({
    size = [iconSize, iconSize]
    rendObj = ROBJ_IMAGE
    image = Picture(image.endswith(".svg") ? $"!{image}:{iconSize}:{iconSize}:K" : image)
  })
})

let deserterIcon = @(playerData, sf) {
  vplace = ALIGN_CENTER
  rendObj = ROBJ_TEXT
  font = fontawesome.font
  text = fa["chain-broken"]
  color = playerColor(playerData, sf)
  fontSize = hdpx(20)
  padding = [hdpx(2), 0]
}

let getFramedNick = @(player)
  frameNick( //TEMP FIX: Recieve already corrent name from server
    remap_others(player.name),
    player?.decorators__nickFrame
  )

let squadMemberIconSize = hdpxi(18)
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

let friendlyFireIconSize = hdpxi(18)
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

let function mkArmiesIcons(armies) {
  let icons = {}
  foreach (armyId in armies) {
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
      size = [TEAM_ICON_SIZE, TEAM_ICON_SIZE]
      image = Picture($"!ui/skin#{icon}:{TEAM_ICON_SIZE}:{TEAM_ICON_SIZE}:K")
    })
  }
}

let function mkPlayerRank(playerData, isInteractive) {
  let { player_info__military_rank = 0 } = playerData?.player
  return player_info__military_rank <= 0 ? null
    : mkRankIcon(player_info__military_rank, rankIconSize, {
        hplace = ALIGN_RIGHT
        vplace = ALIGN_CENTER
        margin = [0, bigGap]
        behavior = isInteractive ? Behaviors.Button : null
        onHover = @(on) setTooltip(on ? loc(getRankConfig(player_info__military_rank).locId) : null)
      })
}

let queryPlayerGetSquad = ecs.SqQuery("query_player_get_squad", {
  comps_ro = [["respawner__squad", ecs.TYPE_EID]]
})

let querySoldierSquadMembers = ecs.SqQuery("query_soldier_squad_members", {
  comps_ro = [["squad__allMembers", ecs.TYPE_EID_LIST]]
})

let queryAliveSoldierName = ecs.SqQuery("query_alive_soldier_name", {
  comps_ro = [["name", ecs.TYPE_STRING], ["surname", ecs.TYPE_STRING]],
  comps_no=["deadEntity"]
})


let function openReplayContextMenu(event, playerData) {
  let buttons = [{
    locId = "btn/replay/spectate"
    action = @() ecs.g_entity_mgr.sendEvent(playerData.eid, SetReplayTarget({}))
  }]

  let respSquad = queryPlayerGetSquad.perform(playerData.eid, @(_eid, comp) comp.respawner__squad)
  let allMembers = querySoldierSquadMembers.perform(respSquad, @(_eid, comp) comp.squad__allMembers.getAll()) ?? []
  if (allMembers.len() > 1)
    foreach (member in allMembers)
      queryAliveSoldierName.perform(member, @(eid, comp)
        buttons.append({
          text = loc("btn/replay/spectateHuman", { name = getObjectName(
            { name = comp.name, surname = comp.surname })})
          action = @() ecs.g_entity_mgr.sendEvent(eid, SetReplayTarget({}))
        })
      )

  addContextMenu(event.screenX + 1, event.screenY + 1, fsh(30), buttons)
}

let function openContextMenu(event, playerData, localPlayerEid, params) {
  if (playerData?.player == null)
    return

  if (params?.isReplay) {
    openReplayContextMenu(event, playerData)
    return
  }

  let buttons = []

  if (playerData.canForgive)
    buttons.append({
      locId = "btn/forgive"
      action = @() forgive(localPlayerEid, playerData.eid)
    })

  let playerUid = playerData.player?.userid ?? INVALID_USER_ID

  buttons.extend((params?.mkContextMenuButton(playerData) ?? [])
    .filter(@(item) item?.mkIsVisible(playerUid.tostring()).value ?? true)
    .map(@(item) item.__merge({action = @() item.action(playerUid.tostring())})))

  if (canShowUserProfile(playerData) && params?.showProfileCb)
    buttons.append({
      locId = "show_another_user_profile"
      action = @() params.showProfileCb({
        player = {
          name = playerData.player.name
          userid = playerUid.tointeger()
          nickFrame = playerData.player.decorators__nickFrame
          portrait = playerData.player.decorators__portrait
          rank = playerData.player?.player_info__military_rank
          rating = playerData.player?.player_info__rating ?? 0
        }
      })
    })

  if (canComplain(playerData))
    buttons.append({
      locId = "btn/complain"
      action = @() complain(
        playerData.sessionId,
        playerUid,
        getFramedNick(playerData.player)
      )
    })

  addContextMenu(event.screenX + 1, event.screenY + 1, fsh(30), buttons)
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
  + (data?["scoring_player__enemyBuiltUtilityDestructions"] ?? 0)
  + (data?["scoring_player__landings"] ?? 0) )

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

let function selectDisplayedAward(isBattleHero, awards) {
  if (isBattleHero)
    return BattleHeroesAward.PLAYER_BATTLE_HERO
  let priorityAward = awards.reduce(@(a,b) awardPriority[a] > awardPriority[b] ? a : b)
  return isSoldierKindAward(priorityAward) && awards.len() > 1
    ? BattleHeroesAward.MULTISPECIALIST
    : priorityAward
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

let COLUMN_PLAYER_NUM = {
  width = NUM_COL_WIDTH
  mkHeader = @(_) null
  mkContent = @(playerData, _params, idx) rowText(playerData?.isInMatchingSlots ? idx.tostring() : null, flex(), playerData)
}
let COLUMN_PLAYER_NAME = {
  width = flex()
  mkHeader = @(p) [
    (p.armies?.len() ?? 0) > 0 ? mkArmiesIcons(p.armies)
      : p.teamIcon == null ? null
      : {
          rendObj = ROBJ_IMAGE
          hplace = ALIGN_CENTER
          vplace = ALIGN_CENTER
          size = [TEAM_ICON_SIZE, TEAM_ICON_SIZE]
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
      onDetach = closeLatestContextMenu
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
let COLUMN_KILLS = {
  width = NUM_COL_WIDTH
  headerIcon = "ui/skin#statistics_kills_icon.svg"
  field = "scoring_player__kills"
  locId = "scoring/kills"
}
let COLUMN_VEHICLE_KILLS = {
  width = NUM_COL_WIDTH
  headerIcon = "ui/skin#kills_technics_icon.svg"
  locId = "scoring/killsVehicles"
  mkContent = @(playerData, _params, _idx) rowText((playerData.player?["scoring_player__tankKills"] ?? 0)
    + (playerData.player?["scoring_player__planeKills"] ?? 0), flex(), playerData)
}
let COLUMN_ASSISTS = {
  width = NUM_COL_WIDTH
  headerIcon = "ui/skin#kills_assist_icon.svg"
  mkContent = @(playerData, _params, _idx)
    rowText(round_by_value(countAssistActions(playerData.player), 0.01), flex(), playerData)
  locId = "scoring/killsAssist"
}
let COLUMN_ENGINEER = {
  width = NUM_COL_WIDTH
  headerIcon = "ui/skin#engineer.svg"
  mkContent = @(playerData, _params, _idx) rowText(countEngineerActions(playerData.player), flex(), playerData)
  locId = "scoring/engineerActions"
}
let COLUMN_KILLS_IN_CAPZONE = {
  width = NUM_COL_WIDTH
  headerIcon = "ui/skin#zone_defense_icon.svg"
  mkContent = @(playerData, _params, _idx) rowText(countCapzoneKills(playerData.player), flex(), playerData)
  locId = "scoring/killsCapzoneDefenseOrAttack"
}
let COLUMN_CAPTURES = {
  width = NUM_COL_WIDTH
  headerIcon = "ui/skin#captured_zones_icon.svg"
  locId = "scoring/captures"
  mkContent = @(playerData, _params, _idx)
    rowText(round_by_value(playerData.player?["scoring_player__captures"] ?? 0, 0.1),
      flex(), playerData)
}
let COLUMN_DEATH = {
  width = NUM_COL_WIDTH
  headerIcon = "!ui/skin#lb_deaths.png"
  field = "scoring_player__squadDeaths"
  locId = "scoring/deathsSquad"
}
let COLUMN_SCORE = {
  width = SCORE_COL_WIDTH
  headerIcon = "!ui/skin#lb_score.png"
  field = "score"
  locId = "scoring/total"
}
let COLUMN_GUN_GAME_LEVEL = {
  width = NUM_COL_WIDTH
  headerIcon = "ui/skin#research/secondary_weap_slot_upgrade_icon.svg"
  locId = "scoring/gunGameLevel"
  mkContent = @(playerData, _params, _idx)
    rowText(1 + (playerData.player?["scoring_player__gunGameLevelup"] ?? 0),
      flex(), playerData)
}

let allColumns = [
  COLUMN_PLAYER_NUM
  COLUMN_PLAYER_NAME
  COLUMN_KILLS
  COLUMN_VEHICLE_KILLS
  COLUMN_ASSISTS
  COLUMN_ENGINEER
  COLUMN_KILLS_IN_CAPZONE
  COLUMN_CAPTURES
  COLUMN_DEATH
  COLUMN_SCORE
  COLUMN_GUN_GAME_LEVEL
]
allColumns.each(function(c) {
  c.mkHeader <- c?.mkHeader ?? @(_) mkHeaderIcon(c.headerIcon)
  c.mkContent <- c?.mkContent
    ?? @(playerData, _params, _idx) rowText(playerData.player?[c.field].tostring() ?? "0", flex(), playerData)
})

let columnsDefault = [
  COLUMN_PLAYER_NUM
  COLUMN_PLAYER_NAME
  COLUMN_KILLS
  COLUMN_VEHICLE_KILLS
  COLUMN_ASSISTS
  COLUMN_ENGINEER
  COLUMN_KILLS_IN_CAPZONE
  COLUMN_CAPTURES
  COLUMN_DEATH
  COLUMN_SCORE
]

let columnsGunGame = [
  COLUMN_PLAYER_NUM
  COLUMN_PLAYER_NAME
  COLUMN_KILLS
  COLUMN_ASSISTS
  COLUMN_GUN_GAME_LEVEL
  COLUMN_DEATH
  COLUMN_SCORE
]

let columnsByGameMode = {
  gun_game = columnsGunGame
}

let function getScoreTableColumns(key) {
  return columnsByGameMode?[key] ?? columnsDefault
}

return {
  LINE_H
  getScoreTableColumns
}