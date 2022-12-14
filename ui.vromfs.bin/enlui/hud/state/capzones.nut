import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let { mkFrameIncrementObservable } = require("%ui/ec_to_watched.nut")
let { TEAM_UNASSIGNED, FIRST_GAME_TEAM } = require("team")
let {localPlayerTeamInfo} = require("%ui/hud/state/teams.nut")
let {localPlayerTeam} = require("%ui/hud/state/local_player.nut")
let {EventHeroChanged, EventLevelLoaded} = require("gameevents")
let {EventZoneIsAboutToBeCaptured, EventZoneCaptured, EventCapZoneEnter, EventCapZoneLeave, CmdStartNarrator} = require("dasevents")
let { controlledHeroEid } = require("%ui/hud/state/controlled_hero.nut")
let { watchedHeroEid } = require("%ui/hud/state/watched_hero.nut")
let {playerEvents} = require("%ui/hud/state/eventlog.nut")
let {showMinorCaptureZoneEventsInHud, showMajorCaptureZoneEventsInHud} = require("%enlSqGlob/wipFeatures.nut")
let {allZonesInGroupCapturedByTeam, isLastSectorForTeam} = require("%enlSqGlob/zone_cap_group.nut")
let is_teams_friendly = require("%enlSqGlob/is_teams_friendly.nut")

let {isTwoChainsCapzones, isTwoChainsCapzonesSetValue} = mkFrameIncrementObservable(false, "isTwoChainsCapzones")
let {capZones, capZonesModify, capZonesSetKeyVal, capZonesDeleteKey} = mkFrameIncrementObservable({}, "capZones")
let isReverseZoneUiOrder = Computed(@() isTwoChainsCapzones.value && localPlayerTeam.value != FIRST_GAME_TEAM)
let whichTeamAttack = Computed(@()
  capZones.value.reduce(@(team, zone) (zone.active && !zone.trainZone) ? zone.attackTeam : team, -1))
let trainCapzoneProgress = Watched(0.0)
let trainZoneEid = Computed(@() capZones.value.findvalue(@(z) z?.trainZone)?.eid ?? ecs.INVALID_ENTITY_ID)
let nextTrainCapzoneEid = Watched(ecs.INVALID_ENTITY_ID)

let curCapZone = Computed(function(){
  let hero = watchedHeroEid.value
  let zoneEid = capZones.value.findvalue(@(zone) zone.heroInsideEid == hero)?.eid
  if (zoneEid == null)
    return null

  return capZones.value?[zoneEid]
})

let forwardUiOrder = @(a, b) a.ui_order <=> b.ui_order
let forwardOrder = @(a, b) forwardUiOrder(a, b) || a.title <=> b.title
let reverseOrder = @(a, b) -forwardOrder(a, b)

let visibleCurrentCapZonesEids = Computed(function(prev) {
  let eids = capZones.value.map(function(z, eid) {
    let state = (z.active && !z.alwaysHide) || eid == nextTrainCapzoneEid.value
    if (!state)
      throw null
    return state
  })
  if (!isEqual(eids, prev))
    return eids
  return prev
})

let minimapVisibleCurrentCapZonesEids = Computed(function(prev) {
  let eids = capZones.value.map(function(z, eid) {
    let state = (z.alwaysVisibleOnMinimap && z.active) || (z.active && !z.alwaysHide) || eid == nextTrainCapzoneEid.value
    if (!state)
      throw null
    return state
  })
  if (!isEqual(eids, prev))
    return eids
  return prev
})

let visibleZoneGroups = Computed(function(prev){
  let zones = []
  let groups = {}
  foreach (zone in capZones.value)
    if ((zone.active || zone.wasActive || zone.alwaysShow) && !(zone.alwaysHide || zone.isBattleContract)) {
      zones.append(zone)
      let groupId = zone?.groupName ?? ""
      if (!(groupId in groups))
        groups[groupId] <- { zones = [], ui_order = zone.ui_order }
      let group = groups[groupId]
      group.zones.append(zone)
      group.ui_order = min(group.ui_order, zone.ui_order)
    }
  let zoneComparator = isReverseZoneUiOrder.value ? reverseOrder : forwardOrder
  let groupComparator = isReverseZoneUiOrder.value ? @(a, b) -forwardUiOrder(a, b) : forwardUiOrder
  let hasGroups = groups.len() != zones.len()
  local groupsSorted = (hasGroups ? groups.values() : [{zones, ui_order = 0}])
  groupsSorted.sort(groupComparator)
  groupsSorted.each(@(g) g.zones.sort(zoneComparator))
  groupsSorted = groupsSorted.map(@(g) g.zones.map(@(z) z.eid))

  if (!isEqual(groupsSorted, prev))
    return groupsSorted
  return prev
})


let function playEvent(e, major=false){
  if (e==null)
    return
  if ((major && showMajorCaptureZoneEventsInHud) || showMinorCaptureZoneEventsInHud)
    playerEvents.pushEvent(e)
}

// TODO should be refactored to avoid using internal field names as keys, as the naming convention might change
let attr2gui = {
  "active":"active"
  "capzone__curTeamCapturingZone":"curTeamCapturingZone"
  "capzone__progress":"progress"
  "capzone__capTeam":"capTeam"
  "ui_order":"ui_order"
  "capzone__alwaysShow":"alwaysShow"
  "capzone__title":"title"
  "capzone__titleSize":"titleSize"
  "capzone__caption":"caption"
  "capzone__icon":"icon"
  "capzone__iconOffsetY" : "iconOffsetY"
  "capzone__owningTeam":"owningTeam"
  "capzone__ownTeamIcon":"ownTeamIcon"
  "capzone__isMultipleTeamsPresent":"isMultipleTeamsPresent"
  "capzone__presenceTeamCount": "presenceTeamCount"
  "capzone__canCaptureOnVehicle": "canCaptureOnVehicle"
  "zone__excludeDowned": "excludeDowned"
  "progress__totalTime" : "progressTotalTime"
  "progress__endTime" : "progressEndTime"
  "progress__pausedAt" : "progressPausedAt"
  "progress__isPositive" : "progressIsPositive"
  "capzone__isBombPlanted" : "isBombPlanted"
  "capzone__locked" : "locked"
  "capzone__endLockTime" : "endLockTime"
}

let queryCapZones =  ecs.SqQuery("queryCapZones", {comps_ro = [["capzone__capTeam", ecs.TYPE_INT], ["active", ecs.TYPE_BOOL, false], ["capzone__alwaysShow", ecs.TYPE_BOOL, false], ["capzone__alwaysHide", ecs.TYPE_BOOL, false]]})

let function isFriendlyTeam(other_team, hero_team) {
  return other_team == hero_team || is_teams_friendly(other_team, hero_team)
}

let function queryCapturedZones(hero_team) {
  local captured = 0
  local total = 0
  queryCapZones.perform(function(_eid, comp) {
    let alwaysShow = comp["capzone__alwaysShow"]
    let alwaysHide = comp["capzone__alwaysHide"]
    let active = comp["active"]
    if ((active || alwaysShow) && !alwaysHide) {
      let zoneTeam = comp["capzone__capTeam"]
        if (zoneTeam != TEAM_UNASSIGNED) {
          if (isFriendlyTeam(zoneTeam, hero_team))
            ++captured
        }
      ++total
    }
  })
  return {
    captured = captured
    total = total
  }
}

let function playNarrator(phrase) {
  if (phrase in (localPlayerTeamInfo.value?["team__narrator"] ?? {})) {
    ecs.g_entity_mgr.broadcastEvent(CmdStartNarrator({phrase, replace=false}))
    return true
  }
  return false
}

let function playMajorEvent(e, narrator="") {
  playEvent(e, true)
  playNarrator(narrator)
}
let function playMinorEvent(e, narrator="") {
  playEvent(e, false)
  playNarrator(narrator)
}

let function tryPlayMajorEvent(e, narrator) {
  if (!playNarrator(narrator))
    return false
  playEvent(e, true)
  return true
}

let function isHalfZonesCaptured(captured, total) {
  return total >= 2 && captured * 2 >= total && (captured - 1) * 2 < total
}

let function narratorOnPointCaptured(captured, total, title) {
  if (title != "" && tryPlayMajorEvent({event="zone_captured", text=loc($"We have captured zone {title}"), myTeamScores=true}, $"point{title}Captured"))
    return
  if (captured + 1 == total) {
    if (tryPlayMajorEvent({event="one_zone_to_capture", text=loc("Most of all zones are captured, one left!"), myTeamScores=true}, "onePointToCapture"))
      return
  }
  else if (isHalfZonesCaptured(captured, total)) {
    if (tryPlayMajorEvent({event="half_zones_captured", text=loc("We have captured half of all zones!"), myTeamScores=true}, "halfPointsCaptured"))
      return
  }
  playMajorEvent({event="zone_captured", text=loc("We have captured zone!"), myTeamScores=true}, "pointCaptured")
}

let function narratorOnPointCapturedEnemy(captured, total, title) {
  if (title != "" && tryPlayMajorEvent({event="zone_captured", text=loc($"Enemy have captured zone {title}"), myTeamScores=false}, $"point{title}CapturedEnemy"))
    return
  if (captured + 1 == total) {
    if (tryPlayMajorEvent({event="one_zone_to_capture", text=loc("Most of all zones are captured by enemy, only one left to defend!"), myTeamScores=false}, "onePointToDefend"))
      return
  }
  else if (isHalfZonesCaptured(captured, total)) {
    if (tryPlayMajorEvent({event="half_zones_captured", text=loc("Enemy have captured half of all zones!"), myTeamScores=false}, "halfPointsCapturedEnemy"))
      return
  }
  playMajorEvent({event="zone_captured", text=loc("Enemy have captured zone!"), myTeamScores=false}, "pointCapturedEnemy")
}

let function narratorOnZoneCaptured(evt, eid, comp) {
  if (evt.zone != eid)
    return
  if (comp.capzone__alwaysHide)
    return
  let heroTeam = localPlayerTeam.value
  let capTeam = evt.team
  let isAllies = isFriendlyTeam(capTeam, heroTeam)

  if (comp["capzone__narrator_zoneCapturedEnable"]) {
    let narrator = isAllies ? comp["capzone__narrator_zoneCaptured"] : comp["capzone__narrator_zoneCapturedEnemy"]
    let message = isAllies ? comp["capzone__narrator_zoneCapturedMessage"] : comp["capzone__narrator_zoneCapturedEnemyMessage"]
    playMajorEvent({event="zone_captured", text=loc(message), myTeamScores=false}, narrator)
    return
  }

  let title = comp["capzone__title"]
  let zones = queryCapturedZones(heroTeam)
  let zoneGroupName = comp["groupName"]
  let checkAllZonesInGroup = comp["capzone__checkAllZonesInGroup"]

  if (checkAllZonesInGroup && allZonesInGroupCapturedByTeam(eid, capTeam, zoneGroupName)) {
    if (isAllies) {
      if (isLastSectorForTeam(capTeam)) {
        playMajorEvent({event="last_sector_left", text=loc("One last sector left!"), myTeamScores=true}, "oneSectorLeft")
        return
      }
    }
    if (isAllies)
      playMajorEvent({event="sector_captured", text=loc("We have captured sector!"), myTeamScores=true}, "sectorCapturedAlly")
    else
      playMajorEvent({event="sector_captured", text=loc("Enemy has captured sector!"), myTeamScores=false}, "sectorCapturedEnemy")
    return
  }

  if (zones.captured >= zones.total) {
    if (zones.captured == zones.total) {
      if (isAllies)
        playMajorEvent({event="all_zones_captured", text=loc("We have captured all zones!"), myTeamScores=true}, "allPointsCapturedAlly")
      else
        playMajorEvent({event="all_zones_captured", text=loc("Enemy have captured all zones!"), myTeamScores=false}, "allPointsCapturedEnemy")
    }
    return
  }

  if (isAllies)
    narratorOnPointCaptured(zones.captured, zones.total, title)
  else
    narratorOnPointCapturedEnemy(zones.captured, zones.total, title)
}

let function notifyOnZoneVisitor(cur_team_capturing_zone, prev_team_capturing_zone, hero_team, attack_team) {
  //cur_team_capturing_zone: -1 - empty | -2 - more than one team | team_id
  if (prev_team_capturing_zone == cur_team_capturing_zone)
    return //no changes
  if (attack_team < 0)
    return // no events currently
  let isHeroAttacker = attack_team == hero_team
  if (isHeroAttacker) {
    if (isFriendlyTeam(cur_team_capturing_zone, hero_team))
      playMinorEvent({event="zone_capture_start", text=loc("We have started capturing zone."), myTeamScores=true}, "pointCapturingAlly")
    else if (cur_team_capturing_zone < 0)
      playMinorEvent({event="zone_capture_stop", text=loc("We have lost domination on zone and stopped capturing"), myTeamScores=false})
    else
      playMinorEvent({event="zone_capture_enemy", text=loc("Enemy is taking back control of target zone"), myTeamScores=false})
  } else {
    if (prev_team_capturing_zone > 0 && isFriendlyTeam(cur_team_capturing_zone, hero_team))
      playMinorEvent({event="zone_defend_start", text=loc("Our troops are back on defence, fighting the enemy"), myTeamScores=true})
    else if (cur_team_capturing_zone > 0)
      playMinorEvent({event="zone_defend_stop", text=loc("Enemy troops are breaking through!"), myTeamScores=false}, "pointCapturingEnemy")
  }
}

let mkOwnTeamId = memoize(@(owningTeam) $"team{owningTeam}")
let mkOwnTeamIco = @(ownTeamIconObj, owningTeam) ownTeamIconObj.getAll()?[mkOwnTeamId(owningTeam)]

let function onCapzonesInitialized(_evt, eid, comp) {
  let owningTeam = comp["capzone__owningTeam"]
  let zone = {
    eid
//    zone_type= ecs.g_entity_mgr.getEntityTemplateName(eid)
    curTeamCapturingZone  = comp["capzone__curTeamCapturingZone"]
    prevTeamCapturingZone = comp["capzone__curTeamCapturingZone"]
    capTeam  = comp["capzone__capTeam"]
    progress = comp["capzone__progress"]
    active   = comp["active"]
    title    = comp["capzone__title"]
    titleSize= comp["capzone__titleSize"]
    icon     = comp["capzone__icon"]
    iconOffsetY = comp["capzone__iconOffsetY"]
    ui_order = comp["ui_order"] || 0
    caption  = comp["capzone__caption"]
    presenceTeamCount = comp["capzone__presenceTeamCount"]?.getAll() ?? {}
    isCapturing = false
    attackTeam = comp["capzone__checkAllZonesInGroup"] ?
                 comp["capzone__mustBeCapturedByTeam"] : comp["capzone__onlyTeamCanCapture"]
    heroInsideEid = ecs.INVALID_ENTITY_ID
    alwaysShow = comp["capzone__alwaysShow"]
    alwaysHide = comp["capzone__alwaysHide"]
    alwaysVisibleOnMinimap = comp["capzone__alwaysVisibleOnMinimap"]
    ownTeamIcon = mkOwnTeamIco(comp["capzone__ownTeamIcon"], owningTeam)
    owningTeam = owningTeam
    groupName = comp["groupName"]
    isMultipleTeamsPresent = comp["capzone__isMultipleTeamsPresent"]
    canCaptureOnVehicle = comp["capzone__canCaptureOnVehicle"]
    excludeDowned = comp["zone__excludeDowned"] != null
    progressTotalTime = comp["progress__totalTime"]
    progressEndTime = comp["progress__endTime"]
    progressPausedAt = comp["progress__pausedAt"]
    progressIsPositive = comp["progress__isPositive"]
    bombPlantingTeam = comp["capzone__plantingTeam"]
    isBombSite = comp["capzone__bombSiteEid"] != ecs.INVALID_ENTITY_ID
    isBombPlanted = comp["capzone__isBombPlanted"]
    humanTriggerable = comp["humanTriggerable"] != null
    trainTriggerable = comp["trainTriggerable"] != null
    trainZone = comp["trainZone"] != null
    trainOffenseTeam = comp["capzone__trainOffenseTeam"]
    advantageWeights = comp["capzone__advantageWeights"]?.getAll() ?? {}
    locked = comp["capzone__locked"]
    endLockTime = comp["capzone__endLockTime"]
    unlockAfterTime = comp["capzone__unlockAfterTime"]
    capzoneTwoChains = comp["capzoneTwoChains"] != null
    isBattleContract = comp["battle_contract"] != null
  }
  zone.wasActive <- zone.active
  capZonesSetKeyVal(eid, zone)
  if (zone.capzoneTwoChains)
    isTwoChainsCapzonesSetValue(true)
}


let queryCapturerZones = ecs.SqQuery("queryCapturerZones",
  {comps_ro = [["isDowned", ecs.TYPE_BOOL, false], ["isInVehicle", ecs.TYPE_BOOL, false], ["capturer__capZonesIn", ecs.TYPE_EID_LIST]]})

let function onHeroChanged(evt, _eid, _comp){
  let newHeroEid = evt[0]
  queryCapturerZones.perform(newHeroEid, function(_, visitorComp) {
    let zonesUpdate = {}
    let capturer__capZonesIn = visitorComp.capturer__capZonesIn.getAll()
    foreach (zoneEid, zone in capZones.value) {
      let heroInsideEid = (zone.active
                            && (visitorComp.isInVehicle ? zone.canCaptureOnVehicle : zone.humanTriggerable)
                            && (!zone.excludeDowned || !visitorComp.isDowned)
                            && capturer__capZonesIn.indexof(zoneEid) != null)
                            ? newHeroEid : ecs.INVALID_ENTITY_ID
      if (heroInsideEid != zone.heroInsideEid)
        zonesUpdate[zoneEid] <- zone.__merge({ heroInsideEid })
    }
    if (zonesUpdate.len()>0)
      capZonesModify(@(v) v.__update(zonesUpdate))
  })
}

let function onCapZoneChanged(_evt, eid, comp) {
  let changedZoneVals = {}
  foreach (attrName, v in comp){
    let zonePropName = attr2gui?[attrName]
    if (attrName == "capzone__ownTeamIcon") {
      let ico = mkOwnTeamIco(v, comp["capzone__owningTeam"])
      changedZoneVals.ownTeamIcon <- ico
    }
    else if (attrName in attr2gui) {
      changedZoneVals[zonePropName] <- v?.getAll() ?? v
    }
  }
  let attackTeam = comp["capzone__checkAllZonesInGroup"] ?
                     comp["capzone__mustBeCapturedByTeam"] : comp["capzone__onlyTeamCanCapture"]
  let title = comp["capzone__title"]
  let alwaysHide = comp["capzone__alwaysHide"]
  let heroTeam = localPlayerTeam.value
  let controlledHero = controlledHeroEid.value
  capZonesModify(function(zones){
    let zone = zones?[eid]
    if (zone==null)
      return zones

    if (zone?["attackTeam"] != attackTeam)
      changedZoneVals["attackTeam"] <- attackTeam
    if (zone?["alwaysHide"] != alwaysHide)
      changedZoneVals["alwaysHide"] <- alwaysHide
    let newZone = zone.__merge(changedZoneVals)
    if ("curTeamCapturingZone" in changedZoneVals){
      notifyOnZoneVisitor(changedZoneVals.curTeamCapturingZone, zone.prevTeamCapturingZone, heroTeam, zone.attackTeam)
      newZone.prevTeamCapturingZone = zone.curTeamCapturingZone
    }
    if (zone.active && !zone.isBombSite && !zone.trainTriggerable && zone.attackTeam < 0 && "capTeam" in changedZoneVals) {
      let {capTeam} = changedZoneVals
      if (capTeam >= FIRST_GAME_TEAM && zone.capTeam < FIRST_GAME_TEAM) {
        let isHeroTeam = capTeam == heroTeam
        let isAllies = isFriendlyTeam(capTeam, heroTeam)
        let isHero = isHeroTeam && (queryCapturerZones(controlledHero, @(_, compCapZones) compCapZones.capturer__capZonesIn.getAll().indexof(eid) != null) ?? false)
        let event = {event="zone_capture_start", text=loc("Zone is being captured"), myTeamScores=isHeroTeam}
        if (!isHero && !tryPlayMajorEvent(event, "pointCapturingPlayer") && !tryPlayMajorEvent(event, isAllies ? $"point{title}CapturingAlly" : $"point{title}CapturingEnemy"))
          playMajorEvent(event, isAllies ? "pointCapturingAlly" : "pointCapturingEnemy")
      }
    }
    newZone.isCapturing = newZone.curTeamCapturingZone != TEAM_UNASSIGNED
      && (newZone.progress != 1.0 || newZone.isMultipleTeamsPresent)
      && newZone.active
    if (changedZoneVals?.active)
      newZone.wasActive = true
    zones[eid] <- newZone
    return zones
  })
}



let function onZonePresenseChange(eid, visitor_eid, leave) {
  let hero_eid = controlledHeroEid.value
  capZonesModify(function(v) {
    let zone = v?[eid]
    if (!zone || visitor_eid != hero_eid)
      return v
    v[eid] = zone.__merge({ heroInsideEid = leave ? ecs.INVALID_ENTITY_ID : hero_eid })
    return v
  })
}

ecs.register_es("capzones_ui_state_hero_changed",
  { [EventHeroChanged] = onHeroChanged }, // broadcast
  {}, { tags="gameClient" }
)

ecs.register_es("capzones_ui_state_es",
  {
    onChange = onCapZoneChanged,
    [[EventLevelLoaded, "onInit"]] = onCapzonesInitialized,
    onDestroy = @(_, eid, __) capZonesDeleteKey(eid),
    [EventCapZoneEnter] = @(evt, eid, _comp) onZonePresenseChange(eid, evt.visitor, false),
    [EventCapZoneLeave] = @(evt, eid, _comp) onZonePresenseChange(eid, evt.visitor, true),
    [EventZoneCaptured] = narratorOnZoneCaptured,
    [EventZoneIsAboutToBeCaptured] = narratorOnZoneCaptured,
  },
  {
    comps_ro = [
      ["capzone__iconOffsetY", ecs.TYPE_FLOAT, 0.0],
      ["capzone__canCaptureOnVehicle", ecs.TYPE_BOOL, false],
      ["zone__excludeDowned", ecs.TYPE_TAG, null],
      ["capzone__plantingTeam", ecs.TYPE_INT, TEAM_UNASSIGNED],
      ["humanTriggerable", ecs.TYPE_TAG, null],
      ["trainTriggerable", ecs.TYPE_TAG, null],
      ["capzone__titleSize", ecs.TYPE_FLOAT, -1.0],
      ["capzone__trainOffenseTeam", ecs.TYPE_INT, TEAM_UNASSIGNED],
      ["capzone__advantageWeights", ecs.TYPE_OBJECT, null],
      ["capzone__narrator_zoneCaptured", ecs.TYPE_STRING, ""],
      ["capzone__narrator_zoneCapturedMessage", ecs.TYPE_STRING, ""],
      ["capzone__narrator_zoneCapturedEnemy", ecs.TYPE_STRING, ""],
      ["capzone__narrator_zoneCapturedEnemyMessage", ecs.TYPE_STRING, ""],
      ["capzone__narrator_zoneCapturedEnable", ecs.TYPE_BOOL, false],
      ["capzone__unlockAfterTime", ecs.TYPE_FLOAT, -1],
      ["capzoneTwoChains", ecs.TYPE_TAG, null],
      ["battle_contract", ecs.TYPE_TAG, null]
    ],
    comps_track = [
      ["capzone__onlyTeamCanCapture", ecs.TYPE_INT, TEAM_UNASSIGNED],
      ["capzone__progress", ecs.TYPE_FLOAT],
      ["active", ecs.TYPE_BOOL],
      ["capzone__owningTeam", ecs.TYPE_INT, TEAM_UNASSIGNED],
      ["capzone__curTeamCapturingZone", ecs.TYPE_INT, TEAM_UNASSIGNED],
      ["capzone__capTeam", ecs.TYPE_INT],
      ["capzone__alwaysShow", ecs.TYPE_BOOL, false],
      ["capzone__alwaysHide", ecs.TYPE_BOOL, false],
      ["capzone__alwaysVisibleOnMinimap", ecs.TYPE_BOOL, false],
      ["capzone__title", ecs.TYPE_STRING, ""],
      ["capzone__icon", ecs.TYPE_STRING, ""],
      ["capzone__caption", ecs.TYPE_STRING, ""],
      ["ui_order", ecs.TYPE_INT, 0],
      ["capzone__ownTeamIcon", ecs.TYPE_OBJECT],
      ["capzone__checkAllZonesInGroup", ecs.TYPE_BOOL, false],
      ["capzone__mustBeCapturedByTeam",ecs.TYPE_INT, TEAM_UNASSIGNED],
      ["capzone__isMultipleTeamsPresent",ecs.TYPE_BOOL, false],
      ["groupName",ecs.TYPE_STRING, ""],
      ["capzone__presenceTeamCount", ecs.TYPE_OBJECT, null],
      ["progress__totalTime", ecs.TYPE_FLOAT, -1],
      ["progress__endTime", ecs.TYPE_FLOAT, -1],
      ["progress__pausedAt", ecs.TYPE_FLOAT, -1],
      ["progress__isPositive", ecs.TYPE_BOOL, true],
      ["capzone__isBombPlanted", ecs.TYPE_BOOL, false],
      ["capzone__bombSiteEid", ecs.TYPE_EID, ecs.INVALID_ENTITY_ID],
      ["trainZone", ecs.TYPE_TAG, null],
      ["capzone__locked", ecs.TYPE_BOOL, false],
      ["capzone__endLockTime", ecs.TYPE_FLOAT, -1],
    ],
  },
  { tags="gameClient" }
)

let queryTrainCheckpointProgress = ecs.SqQuery("queryTrainCheckpointProgress", {comps_ro = [["capzone__trainProgress", ecs.TYPE_FLOAT]]})

ecs.register_es("capzones_ui_state_train_progress",
  {
    onUpdate = @(_, comp) queryTrainCheckpointProgress(comp.train_progress__nextCapzoneEid, function(eid, comp) {
      nextTrainCapzoneEid(eid)
      trainCapzoneProgress(comp.capzone__trainProgress)
    })
  },
  { comps_ro = [["train_progress__nextCapzoneEid", ecs.TYPE_EID]] },
  { updateInterval=1.0, tags="ui", after="*", before="*" }
)


let getZoneWatch = memoize(@(eid) Computed(@() capZones.value?[eid]))

return {
  capZones
  getZoneWatch
  visibleCurrentCapZonesEids
  visibleZoneGroups
  minimapVisibleCurrentCapZonesEids
  whichTeamAttack
  curCapZone
  nextTrainCapzoneEid
  trainZoneEid
  trainCapzoneProgress
  isTwoChainsCapzones
}
