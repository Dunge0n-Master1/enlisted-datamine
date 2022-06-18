import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let { sub_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let {ceil} = require("math")
let {localPlayerTeam, localPlayerGroupId} = require("%ui/hud/state/local_player.nut")
let { watchedHeroEid } = require("%ui/hud/state/watched_hero.nut")
let {teammatesAvatars, groupmatesAvatars} = require("%ui/hud/state/human_teammates.nut")
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

let mkIcon = memoize(@(fillColor) {
  rendObj = ROBJ_IMAGE
  color = fillColor
  image = unit_arrow
  pos = [0, -unitArrowSz[1] * 0.25]
  size = unitArrowSz
})

let mkIconPlayerGroupmate = memoize(@(fillColor) {
  rendObj = ROBJ_IMAGE
  color = fillColor
  image = teammate_arrow
  size = SIZE_TO_CONTENT
  pos = [0, -unitArrowSz[1] * 0.1]
})

let mkTextPlayerGroupmate = @(num) {
  rendObj = ROBJ_TEXT
  color = Color(255, 255, 255)
  text = num
  fontSize = hdpx(24) * 0.4
  transform = {
    pivot = [0.5, 0.5]
    rotate = -90
  }
}.__update(sub_txt)

let mkBlinkAnimation = @(trigger) {
    animations = [{ prop=AnimProp.color, from=Color(200,50,50,250), to=Color(255,200,200), duration=0.5, trigger=trigger, loop=true, easing=Blink }]
}

let map_unit_ctor = @(eid, marker, options={}) function() {
  let res = { watch = [localPlayerTeam, watchedHeroEid, hudMarkerEnable, groupmatesAvatars, localPlayerGroupId] }
  if (!hudMarkerEnable.value
     || !marker.isAlive
     || (!options?.showHero && watchedHeroEid.value==eid)
     || (eid in groupmatesAvatars.value)
     || marker["human_anim__vehicleSelected"] != INVALID_ENTITY_ID)
        return res

  let heroEid = watchedHeroEid.value ?? INVALID_ENTITY_ID
  let heroTeam = localPlayerTeam.value ?? TEAM_UNASSIGNED
  let groupId = localPlayerGroupId.value ?? INVALID_GROUP_ID
  let squadEid = marker?["squad_member__squad"] ?? INVALID_ENTITY_ID
  local fillColor = Color(0, 0, 0)
  let isSquadmate = (squadEid!=INVALID_ENTITY_ID && squadEid >= 0 && squadEid == ecs.obsolete_dbg_get_comp_val(heroEid, "squad_member__squad"))
  let isTeammate = marker?.team == heroTeam
  local isGroupmate = false
  if (!isSquadmate && squadEid != INVALID_ENTITY_ID && groupId != INVALID_GROUP_ID) {
    let ownerPlayer = ecs.obsolete_dbg_get_comp_val(squadEid, "squad__ownerPlayer", INVALID_ENTITY_ID)
    if (ownerPlayer != INVALID_ENTITY_ID)
      isGroupmate = groupId == ecs.obsolete_dbg_get_comp_val(ownerPlayer, "groupId", INVALID_GROUP_ID)
  }

  if (isSquadmate) {
    fillColor = MAP_COLOR_SQUADMATE
  } else if (isGroupmate) {
    fillColor = MAP_COLOR_GROUPMATE
  } else if (isTeammate) {
    fillColor = MAP_COLOR_TEAMMATE
  }

  let blinkAnimation = mkBlinkAnimation($"blink_marker_start_{eid}")
  return {
    key = eid
    data = {
      eid = eid
      dirRotate = true
    }
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    transform = {}
    children = mkIcon(fillColor).__merge(blinkAnimation)
  }.__merge(res)
}

let map_groupmate_number_ctor = @(eid, marker, _options={}) function() {
  let res = {watch = hudMarkerEnable}
  if (!hudMarkerEnable.value || !marker.isAlive)
    return res

  return res.__update({
    key = eid
    data = {
      eid = eid
      dirRotate = false
    }
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    transform = {}
    children = mkTextPlayerGroupmate((ecs.obsolete_dbg_get_comp_val(marker.possessedByPlr, "player_group__memberIndex") ?? 0) + 1)
  })
}

let map_groupmate_marker_ctor = @(eid, marker, _options={}) function() {
  let res = {watch = hudMarkerEnable}
  if (!hudMarkerEnable.value || !marker.isAlive)
    return res

  let blinkAnimation = mkBlinkAnimation($"blink_marker_start_{eid}")
  return res.__update({
    key = eid
    data = {
      eid = eid
      dirRotate = true
    }
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    transform = {}
    children = [
      mkIconPlayerGroupmate(MAP_COLOR_TEAMMATE).__merge(blinkAnimation)
    ]
  })
}

return{
  map_unit_ctor
  groupmatesNumbers = {
    watch = groupmatesAvatars
    ctor = @(p) groupmatesAvatars.value.reduce(@(res, info, eid) res.append(map_groupmate_number_ctor(eid, info, p)), [])
  }
  groupmatesMarkers = {
    watch = groupmatesAvatars
    ctor = @(p) groupmatesAvatars.value.reduce(@(res, info, eid) res.append(map_groupmate_marker_ctor(eid, info, p)), [])
  }
  teammatesMarkers = {
    watch = teammatesAvatars
    ctor = @(p) teammatesAvatars.value.reduce(@(res, info, eid) res.append(map_unit_ctor(eid, info, p)), [])
  }
}