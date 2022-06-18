import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let { TEAM_UNASSIGNED, FIRST_GAME_TEAM } = require("team")
let {localPlayerTeamInfo} = require("%ui/hud/state/teams.nut")
let {localPlayerTeam} = require("%ui/hud/state/local_player.nut")
let {EventHeroChanged} = require("gameevents")
let {EventZoneIsAboutToBeCaptured, EventZoneCaptured, EventCapZoneEnter, EventCapZoneLeave, CmdStartNarrator} = require("dasevents")
let { controlledHeroEid } = require("%ui/hud/state/controlled_hero.nut")
let { watchedHeroEid } = require("%ui/hud/state/watched_hero.nut")
let {playerEvents} = require("%ui/hud/state/eventlog.nut")
let {showMinorCaptureZoneEventsInHud, showMajorCaptureZoneEventsInHud} = require("%enlSqGlob/wipFeatures.nut")
let {allZonesInGroupCapturedByTeam, isLastSectorForTeam} = require("%enlSqGlob/zone_cap_group.nut")
let {is_entity_in_capzone} = require("ecs.utils")
let is_teams_friendly = require("%enlSqGlob/is_teams_friendly.nut")

let isTwoChainsCapzones = mkWatched(persist, "isTwoChainsCapzones", false)
let capZones = mkWatched(persist, "capZones", {})
let isReverseZoneUiOrder = Computed(@() isTwoChainsCapzones.value && localPlayerTeam.value != FIRST_GAME_TEAM)
let whichTeamAttack = Computed(@()
  capZones.value.reduce(@(team, zone) (zone.active && !zone.trainZone) ? zone.attackTeam : team, -1))
let trainCapzoneProgress = Watched(0.0)
let trainZoneEid = Computed(@() capZones.value.findvalue(@(z) z?.trainZone)?.eid ?? INVALID_ENTITY_ID)
let nextTrainCapzoneEid = Watched(INVALID_ENTITY_ID)

let curCapZone = Computed(function(){
  let zoneEid = capZones.value.findvalue(@(zone) zone.heroInsideEid == watchedHeroEid.value)?.eid
  if (zoneEid == null)
    return null

  return capZones.value?[zoneEid]
})

let forwardUiOrder = @(a, b) a.ui_order <=> b.ui_order
let forwardOrder = @(a, b) forwardUiOrder(a, b) || a.title <=> b.title
let reverseOrder = @(a, b) -forwardOrder(a, b)

let getForwardSortedZoneEids = @(zones) zones.sort(forwardOrder).map(@(z) z.eid)
let getReverseSortedZoneEids = @(zones) zones.sort(reverseOrder).map(@(z) z.eid)

let visibleCurrentCapZonesEids = Computed(function(prev) {
  let eids = capZones.value.map(function(z, eid) {
    let state = (z.active && !z.alwaysHide) || eid == nextTrainCapzoneEid.value
    if (!state)
      throw null
    return state
  })
  if (prev==FRP_INITIAL || !isEqual(eids, prev))
    return eids
  return prev
})
let visibleZoneGroups = Computed(function(prev){
  let visible = []
  let groups = {}
  foreach (zone in capZones.value)
    if ((zone.active || zone.wasActive || zone.alwaysShow) && !zone.alwaysHide) {
      visible.append(zone)
      let groupId = zone?.groupName ?? ""
      if (!(groupId in groups))
        groups[groupId] <- { zones = [], ui_order = zone.ui_order }
      let group = groups[groupId]
      group.zones.append(zone)
      group.ui_order = min(group.ui_order, zone.ui_order)
    }
  let getSortedZoneEids = isReverseZoneUiOrder.value ? getReverseSortedZoneEids : getForwardSortedZoneEids
  let groupComparator = isReverseZoneUiOrder.value ? @(a, b) -forwardUiOrder(a, b) : forwardUiOrder
  let groupsSorted = groups.len() == visible.len()
    ? [getSortedZoneEids(visible)]
    : groups.values()
        .sort(groupComparator)
        .map(@(g) getSortedZoneEids(g.zones))

  if (prev==FRP_INITIAL || !isEqual(groupsSorted, prev))
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
    heroInsideEid = INVALID_ENTITY_ID
    alwaysShow = comp["capzone__alwaysShow"]
    alwaysHide = comp["capzone__alwaysHide"]
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
    isBombSite = comp["capzone__bombSiteEid"] != INVALID_ENTITY_ID
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
  }
  zone.wasActive <- zone.active
  capZones.mutate(@(v) v[eid] <- zone)
  if (zone.capzoneTwoChains)
    isTwoChainsCapzones(true)
}


let queryCapturerZones = ecs.SqQuery("queryCapturerZones",
  {comps_ro = [["isDowned", ecs.TYPE_BOOL, false], ["isInVehicle", ecs.TYPE_BOOL, false]]})

let function onHeroChanged(evt, _eid, _comp){
  let newHeroEid = evt[0]
  queryCapturerZones.perform(newHeroEid, function(_, visitorComp) {
    let zonesUpdate = {}
    foreach (zoneEid, zone in capZones.value) {
      let heroInsideEid = (is_entity_in_capzone(newHeroEid, zoneEid)
                            && zone.active
                            && (visitorComp.isInVehicle ? zone.canCaptureOnVehicle : zone.humanTriggerable)
                            && (!zone.excludeDowned || !visitorComp.isDowned))
                            ? newHeroEid : INVALID_ENTITY_ID
      if (heroInsideEid != zone.heroInsideEid)
        zonesUpdate[zoneEid] <- zone.__merge({ heroInsideEid })
    }
    if (zonesUpdate.len())
      capZones.mutate(@(v) v.__update(zonesUpdate))
  })
}

let function onCapZoneChanged(_evt, eid, comp) {
  let zone = capZones.value?[eid]
  if (zone==null)
    return
  let changedZoneVals = {}
  foreach(attrName, v in comp){
    let zonePropName = attr2gui?[attrName]
    if (attrName == "capzone__ownTeamIcon") {
      let ico = mkOwnTeamIco(v, comp["capzone__owningTeam"])
      if (zone.ownTeamIcon != ico)
        changedZoneVals.ownTeamIcon <- ico
    }
    else if (attrName in attr2gui && zone[zonePropName] != v) {
      changedZoneVals[zonePropName] <- v?.getAll() ?? v
    }
  }
  let attackTeam = comp["capzone__checkAllZonesInGroup"] ?
                     comp["capzone__mustBeCapturedByTeam"] : comp["capzone__onlyTeamCanCapture"]
  if (zone?["attackTeam"] != attackTeam)
    changedZoneVals["attackTeam"] <- attackTeam
  let newZone = zone.__merge(changedZoneVals)
  let heroTeam = localPlayerTeam.value
  if ("curTeamCapturingZone" in changedZoneVals){
    notifyOnZoneVisitor(changedZoneVals.curTeamCapturingZone, zone.prevTeamCapturingZone, heroTeam, zone.attackTeam)
    newZone.prevTeamCapturingZone = zone.curTeamCapturingZone
  }
  if (zone.active && !zone.isBombSite && !zone.trainTriggerable && zone.attackTeam < 0 && "capTeam" in changedZoneVals) {
    let {capTeam} = changedZoneVals
    if (capTeam >= FIRST_GAME_TEAM && zone.capTeam < FIRST_GAME_TEAM) {
      let isHeroTeam = capTeam == heroTeam
      let isAllies = isFriendlyTeam(capTeam, heroTeam)
      let isHero = isHeroTeam && is_entity_in_capzone(controlledHeroEid.value, eid)
      let event = {event="zone_capture_start", text=loc("Zone is being captured"), myTeamScores=isHeroTeam}
      let title = comp["capzone__title"]
      if (!isHero && !tryPlayMajorEvent(event, "pointCapturingPlayer") && !tryPlayMajorEvent(event, isAllies ? $"point{title}CapturingAlly" : $"point{title}CapturingEnemy"))
        playMajorEvent(event, isAllies ? "pointCapturingAlly" : "pointCapturingEnemy")
    }
  }
  newZone.isCapturing = newZone.curTeamCapturingZone != TEAM_UNASSIGNED
    && (newZone.progress != 1.0 || newZone.isMultipleTeamsPresent)
    && newZone.active
  if (changedZoneVals?.active)
    newZone.wasActive = true
  capZones.mutate(@(v) v[eid] = newZone)
}


let function onCapzonesDestroy(eid, _comp) {
  if (eid in capZones.value)
    capZones.mutate(@(v) delete v[eid])
}


let function onZonePresenseChange(eid, visitor_eid, leave) {
  let zone = capZones.value?[eid]
  if (!zone)
    return

  let hero_eid = controlledHeroEid.value
  if (visitor_eid == hero_eid)
    capZones.mutate(@(v) v[eid] = zone.__merge({ heroInsideEid = leave ? INVALID_ENTITY_ID : hero_eid }))
}

ecs.register_es("capzones_ui_state_es",
  {
    onChange = onCapZoneChanged,
    onInit = onCapzonesInitialized,
    onDestroy = onCapzonesDestroy,
    [EventCapZoneEnter] = @(evt, eid, _comp) onZonePresenseChange(eid, evt.visitor, false),
    [EventCapZoneLeave] = @(evt, eid, _comp) onZonePresenseChange(eid, evt.visitor, true),
    [EventZoneCaptured] = narratorOnZoneCaptured,
    [EventZoneIsAboutToBeCaptured] = narratorOnZoneCaptured,
    [EventHeroChanged] = onHeroChanged,
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
      ["capzoneTwoChains", ecs.TYPE_TAG, null]
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
      ["capzone__bombSiteEid", ecs.TYPE_EID, INVALID_ENTITY_ID],
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


return {
  capZones
  visibleCurrentCapZonesEids
  visibleZoneGroups
  whichTeamAttack
  curCapZone
  nextTrainCapzoneEid
  trainZoneEid
  trainCapzoneProgress
  isTwoChainsCapzones
}
