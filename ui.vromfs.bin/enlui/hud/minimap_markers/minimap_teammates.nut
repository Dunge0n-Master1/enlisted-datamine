import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let { fontSub } = require("%enlSqGlob/ui/fontsStyle.nut")
let {ceil} = require("math")
let {localPlayerTeam, localPlayerGroupMembers} = require("%ui/hud/state/local_player.nut")
let { watchedHeroEid } = require("%ui/hud/state/watched_hero.nut")
let {watchedHeroSquadEid} = require("%ui/hud/state/squad_members.nut")
let {teammatesAvatarsGetWatched, groupmatesAvatarsSet, groupmatesAvatarsGetWatched, teammatesAvatarsNotGroupmatesSet} = require("%ui/hud/state/human_teammates.nut")
let { TEAM_UNASSIGNED } = require("team")
let {MAP_COLOR_SQUADMATE, MAP_COLOR_GROUPMATE, MAP_COLOR_TEAMMATE} = require("%enlSqGlob/ui/style/unit_colors.nut")
let {hudMarkerEnable} = require("%ui/hud/state/hudOptionsState.nut")
let { isReplay } = require("%ui/hud/state/replay_state.nut")


let unitArrowSz = [hdpxi(7), hdpxi(15)]
let teammateArrowSz = [hdpxi(18), hdpxi(18)]

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
  pos = [0, -unitArrowSz[1] * 0.1]
  size = teammateArrowSz
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
}.__update(fontSub)))

let mkBlinkAnimation = @(trigger) {
    animations = [{ prop=AnimProp.color, from=Color(200,50,50,250), to=Color(255,200,200), duration=0.5, trigger, loop=true, easing=Blink }]
}

let map_unit_ctor = function(eid, showHero=false) {
  let data = {
    eid
    dirRotate = true
  }
  let markerState = teammatesAvatarsGetWatched(eid)
  let blinkAnimation = mkBlinkAnimation(eid)
  let hideMarker = Computed(function(){
    let {isAlive=true, human_anim__vehicleSelected = ecs.INVALID_ENTITY_ID} = markerState.value
    return !isAlive
      || !hudMarkerEnable.value
      || (showHero && watchedHeroEid.value==eid)
      || human_anim__vehicleSelected != ecs.INVALID_ENTITY_ID
  })
  let fillColorState = Computed(function(){
    let {squad_member__squad = ecs.INVALID_ENTITY_ID, team = TEAM_UNASSIGNED, squad_member__playerEid=ecs.INVALID_ENTITY_ID} = markerState.value
    let isSquadmate = squad_member__squad != ecs.INVALID_ENTITY_ID && squad_member__squad == watchedHeroSquadEid.value
    if (isSquadmate) {
      return MAP_COLOR_SQUADMATE
    }
    else if (!isSquadmate && squad_member__playerEid in localPlayerGroupMembers.value) {
      return MAP_COLOR_GROUPMATE
    }
    else if (team == localPlayerTeam.value) {
      return MAP_COLOR_TEAMMATE
    }
    else if (isReplay.value)
      return null /* FIX ME: It is made to hide ENEMIES on the map in replays */
    return Color(0, 0, 0)
  })

  let watch = [hideMarker, fillColorState]
  return function() {
    if (hideMarker.value)
      return {watch}

    return {
      watch
      key = {}
      data
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      transform = {}
      children = fillColorState.value == null ? null
        : mkIcon(fillColorState.value).__merge(blinkAnimation)
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
      children = mkTextPlayerGroupmate((markerState.value?.player_group__memberIndex ?? 0) + 1)
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