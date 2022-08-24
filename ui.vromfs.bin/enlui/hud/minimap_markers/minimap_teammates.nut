import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let { sub_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let {ceil} = require("math")
let {localPlayerTeam, localPlayerGroupId} = require("%ui/hud/state/local_player.nut")
let { watchedHeroEid } = require("%ui/hud/state/watched_hero.nut")
let {teammatesAvatarsGetWatched, groupmatesAvatarsSet, groupmatesAvatarsGetWatched, teammatesAvatarsNotGroupmatesSet} = require("%ui/hud/state/human_teammates.nut")
let { TEAM_UNASSIGNED } = require("team")
let { INVALID_GROUP_ID } = require("matching.errors")
let {MAP_COLOR_SQUADMATE, MAP_COLOR_GROUPMATE, MAP_COLOR_TEAMMATE} = require("%enlSqGlob/ui/style/unit_colors.nut")
let {hudMarkerEnable} = require("%ui/hud/state/hudOptionsState.nut")
let unitArrowSz = [fsh(0.7), fsh(1.4)]
let teammateArrowSz = [fsh(1.7), fsh(1.7)]

let unit_arrow = Picture("!ui/skin#unit_arrow.svg:{0}:{1}:K".subst(
    ceil(unitArrowSz[0]*1.3).tointeger(), ceil(unitArrowSz[1]*1.3).tointeger()))

let teammate_arrow = Picture("!ui/skin#teammate_arrow.svg:{0}:{1}:K".subst(
    ceil(teammateArrowSz[0]*1.3).tointeger(), ceil(teammateArrowSz[1]*1.3).tointeger()))

let mkIcon = memoize(@(fillColor) freeze({
  rendObj = ROBJ_IMAGE
  color = fillColor
  image = unit_arrow
  pos = [0, -unitArrowSz[1] * 0.25]
  size = unitArrowSz
}))

let mkIconPlayerGroupmate = memoize(@(fillColor) freeze({
  rendObj = ROBJ_IMAGE
  color = fillColor
  image = teammate_arrow
  size = SIZE_TO_CONTENT
  pos = [0, -unitArrowSz[1] * 0.1]
}))

let mkTextPlayerGroupmate = memoize(@(num) freeze({
  rendObj = ROBJ_TEXT
  color = Color(255, 255, 255)
  text = num
  fontSize = hdpx(24) * 0.4
  transform = {
    pivot = [0.5, 0.5]
    rotate = -90
  }
}.__update(sub_txt)))

let mkBlinkAnimation = @(trigger) {
    animations = [{ prop=AnimProp.color, from=Color(200,50,50,250), to=Color(255,200,200), duration=0.5, trigger, loop=true, easing=Blink }]
}

let map_unit_ctor = function(eid, showHero=false) {
  let data = {
    eid
    dirRotate = true
  }
  let markerState = teammatesAvatarsGetWatched(eid)
  let watch = [localPlayerTeam, watchedHeroEid, markerState, localPlayerGroupId, hudMarkerEnable]
  let blinkAnimation = mkBlinkAnimation(eid)
  return function() {
    let {isAlive=true, human_anim__vehicleSelected=INVALID_ENTITY_ID} = markerState.value
    let hideMarker = !isAlive
      || !hudMarkerEnable.value
      || (showHero && watchedHeroEid.value==eid)
      || human_anim__vehicleSelected != INVALID_ENTITY_ID
    if (hideMarker)
      return {watch}

    let heroEid = watchedHeroEid.value ?? INVALID_ENTITY_ID
    let heroTeam = localPlayerTeam.value ?? TEAM_UNASSIGNED
    let groupId = localPlayerGroupId.value ?? INVALID_GROUP_ID
    let squadEid = markerState.value?.squad_member__squad ?? INVALID_ENTITY_ID
    local fillColor = Color(0, 0, 0)
    let isSquadmate = (squadEid!=INVALID_ENTITY_ID && squadEid >= 0 && squadEid == ecs.obsolete_dbg_get_comp_val(heroEid, "squad_member__squad"))
    let isTeammate = (markerState.value?.team ?? -1) == heroTeam
    local isGroupmate = false
    if (!isSquadmate && squadEid != INVALID_ENTITY_ID && groupId != INVALID_GROUP_ID) {
      let ownerPlayer = ecs.obsolete_dbg_get_comp_val(squadEid, "squad__ownerPlayer", INVALID_ENTITY_ID)
      if (ownerPlayer != INVALID_ENTITY_ID)
        isGroupmate = groupId == ecs.obsolete_dbg_get_comp_val(ownerPlayer, "groupId", INVALID_GROUP_ID)
    }

    if (isSquadmate) {
      fillColor = MAP_COLOR_SQUADMATE
    }
    else if (isGroupmate) {
      fillColor = MAP_COLOR_GROUPMATE
    }
    else if (isTeammate) {
      fillColor = MAP_COLOR_TEAMMATE
    }

    return {
      key = eid
      data
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      transform = {}
      children = mkIcon(fillColor).__merge(blinkAnimation)
      watch
    }
  }
}

let groupmate_number_ctor = function(eid) {
  let markerState = groupmatesAvatarsGetWatched(eid)
  let watch = [markerState, hudMarkerEnable]
  let data = { eid, dirRotate = false}
  return function() {
    if (!hudMarkerEnable.value || !markerState.value?.isAlive)
      return {watch}

    return {
      key = eid
      data
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      transform = {}
      children = mkTextPlayerGroupmate((ecs.obsolete_dbg_get_comp_val(markerState.value?.possessedByPlr, "player_group__memberIndex") ?? 0) + 1)
    }
  }
}

let function groupmate_marker_ctor(eid) {
  let markerState = groupmatesAvatarsGetWatched(eid)
  let watch = [markerState, hudMarkerEnable]
  let data = {eid, dirRotate = true}
  let blinkAnimation = mkBlinkAnimation(eid)
  let children = mkIconPlayerGroupmate(MAP_COLOR_TEAMMATE).__merge(blinkAnimation)
  return function() {
    if (!markerState.value?.isAlive || !hudMarkerEnable.value)
      return {watch}

    return {
      watch
      key = eid
      data
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      transform = {}
      children
    }
  }
}

let memoizedMapNumbers = mkMemoizedMapSet(groupmate_number_ctor)
let memoizedMapMarkers = mkMemoizedMapSet(groupmate_marker_ctor)
let memoizedMapShowHero = mkMemoizedMapSet(@(eid) map_unit_ctor(eid, true))
let memoizedMapNoHero = mkMemoizedMapSet(@(eid) map_unit_ctor(eid, false))
return {
  groupmatesNumbers = {
    watch = groupmatesAvatarsSet
    ctor = @(_) memoizedMapNumbers(groupmatesAvatarsSet.value).values()
  }
  groupmatesMarkers = {
    watch = groupmatesAvatarsSet
    ctor = @(_) memoizedMapMarkers(groupmatesAvatarsSet.value).values()
  }
  teammatesMarkers = {
    watch = teammatesAvatarsNotGroupmatesSet
    ctor = @(p) p?.showHero
      ? memoizedMapShowHero(teammatesAvatarsNotGroupmatesSet.value).values()
      : memoizedMapNoHero(teammatesAvatarsNotGroupmatesSet.value).values()
  }
}