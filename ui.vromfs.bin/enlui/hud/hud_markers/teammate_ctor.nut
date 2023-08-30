import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let { forcedMinimalHud } = require("%ui/hud/state/hudGameModes.nut")
let {Point2} = require("dagor.math")
let { localPlayerGroupMembers } = require("%ui/hud/state/local_player.nut")
let {selectedBotForOrderEid, isPersonalContextCommandMode, watchedHeroSquadEid} = require("%ui/hud/state/squad_members.nut")
let teammateName = require("%ui/hud/components/teammateName.nut")
let {
  HUD_COLOR_TEAMMATE_INNER, HUD_COLOR_TEAMMATE_OUTER,
  HUD_COLOR_GROUPMATE_BOT_INNER, HUD_COLOR_GROUPMATE_BOT_OUTER,
  HUD_COLOR_SQUADMATE_INNER, HUD_COLOR_SQUADMATE_OUTER,
  HUD_COLOR_MEDIC_HP_LOW, HUD_COLOR_MEDIC_HP_CRITICAL, HUD_COLOR_MEDIC_HP_OUTER
} = require("%enlSqGlob/ui/style/unit_colors.nut")
let { remap_nick } = require("%enlSqGlob/remap_nick.nut")
let { frameNick } = require("%enlSqGlob/ui/decoratorsPresentation.nut")
let engineersInSquad = require("%ui/hud/state/engineers_in_squad.nut")
let { heroSoldierKind } = require("%ui/hud/state/soldier_class_state.nut")
let { MedicHealState } = require("%enlSqGlob/dasenums.nut")
let { heroMedicMedpacks } = require("%ui/hud/state/medic_state.nut")
let { teammatesAvatarsSet, teammatesAvatarsGetWatched } = require("%ui/hud/state/human_teammates.nut")
let { showTeammateName, showTeammateMarkers } = require("%ui/hud/state/hudOptionsState.nut")

let defTransform = {}
let hpIconSize = [hdpxi(27), hdpxi(27)]

let mkIcon = function(colorInner, colorOuter, sizeFactor) {
  let unitIconSize = [fsh(1*sizeFactor), fsh(1.25*sizeFactor)].map(@(v) v.tointeger())

  return {
    key = {}
    rendObj = ROBJ_IMAGE
    color = colorOuter
    image = Picture($"ui/skin#unit_outer.svg:{unitIconSize[0]}:{unitIconSize[1]}:K")
    size = unitIconSize
    minDistance = 0.5

    children = {
      rendObj = ROBJ_IMAGE
      color = colorInner
      image = Picture($"ui/skin#unit_inner.svg:{unitIconSize[0]}:{unitIconSize[1]}:K")
      size = unitIconSize
    }
    markerFlags = MARKER_SHOW_ONLY_IN_VIEWPORT
  }
}
let selectedIcon = mkIcon(HUD_COLOR_SQUADMATE_INNER, HUD_COLOR_SQUADMATE_OUTER, 2.0)
let notSelectedIcon = mkIcon(HUD_COLOR_SQUADMATE_INNER, HUD_COLOR_SQUADMATE_OUTER, 1.0)
let animSquadIcon = freeze([
  {prop = AnimProp.translate, from=[0, hdpx(25)], to=[0, 0], duration=0.5, play=true, loop=true, easing=OutBack}
])

let mkSquadmateIcon = memoize(function(eid) {
  let selectedIco = freeze(selectedIcon.__merge({key = {}, transform = {}, animations = animSquadIcon}))
  let notSelectedIco = freeze(notSelectedIcon.__merge({key = eid}))
  return function() {
    let isSelectedBotForOrders = selectedBotForOrderEid.value == eid && isPersonalContextCommandMode.value
    return {
      watch = [selectedBotForOrderEid, isPersonalContextCommandMode]
      children = isSelectedBotForOrders ? selectedIco : notSelectedIco
    }
  }
})

let healing_outer_ico = Picture($"ui/skin#healing_icon_outer.svg:{hpIconSize[0]}:{hpIconSize[1]}:K")
let healing_ico = Picture($"ui/skin#healing_icon.svg:{hpIconSize[0]}:{hpIconSize[1]}:K")
let innerMedIco = memoize(@(colorInner) freeze({
  rendObj = ROBJ_IMAGE
  color = colorInner
  image = healing_ico
  size = hpIconSize
}))
let outerMedIco = memoize(@(colorOuter) freeze({
  rendObj = ROBJ_IMAGE
  color = colorOuter
  image = healing_outer_ico
  size = hpIconSize
}))

let mkHpIcon = @(eid, colorInner, colorOuter) {
  key = eid
  size = hpIconSize
  minDistance = 0.5
  children = [
    outerMedIco(colorOuter)
    innerMedIco(colorInner)
  ]
}

let ammoBoxIconSize = [hdpxi(65), hdpxi(65)]
let build_ammo_ico = Picture($"ui/skin#building_ammo_box.svg:{ammoBoxIconSize[0]}:{ammoBoxIconSize[1]}:K")
let requestAmmoBoxIcon = freeze({
  rendObj = ROBJ_IMAGE
  color = Color(255, 255, 255, 255)
  image = build_ammo_ico
  size = ammoBoxIconSize
  minDistance = 0.5
})

let rallyPointIconSize = [hdpxi(65), hdpxi(65)]
let pic_rally = Picture($"ui/skin#custom_spawn_point.svg:{rallyPointIconSize[0]}:{rallyPointIconSize[1]}:K")
let requestRallyPointIcon = freeze({
  rendObj = ROBJ_IMAGE
  color = Color(255, 255, 255, 255)
  image = pic_rally
  size = rallyPointIconSize
  minDistance = 0.5
})

let teammateIcon = mkIcon(HUD_COLOR_TEAMMATE_INNER, HUD_COLOR_TEAMMATE_OUTER, 1.0)
let groupmateBotIcon = mkIcon(HUD_COLOR_GROUPMATE_BOT_INNER, HUD_COLOR_GROUPMATE_BOT_OUTER, 1.0)

let displayMarkerOverHeadQuery = ecs.SqQuery("displayMarkerOverHeadQuery", {comps_rq=["vehicleDisplayMarkerOverHead"]})
let maxRange = Point2(10,10) // Big enough to cover whole screen on different aspect ratio
let opRangeX = Point2(0.25, 0.35)
let opRangeY = Point2(0.25, 0.75)
let opRangeX_hardcore = Point2(0.125, 0.135)

let needShowMed = Computed(@() heroSoldierKind.value == "medic" && heroMedicMedpacks.value > 0)
let hasEngineers = Computed(@() engineersInSquad.value >0)

let unit = function(eid, showMed){
  let infoState = teammatesAvatarsGetWatched(eid)
  let watch = [infoState, hasEngineers, showMed ? needShowMed : null, forcedMinimalHud, watchedHeroSquadEid, localPlayerGroupMembers, showTeammateName, showTeammateMarkers]
  return function() {
    let info = infoState.value
    if (!info.isAlive )
      return { watch }
    let vehicle = info?["human_anim__vehicleSelected"] ?? ecs.INVALID_ENTITY_ID
    if (vehicle != ecs.INVALID_ENTITY_ID){
      let vehicleNeedDisplayMarker = displayMarkerOverHeadQuery(vehicle, @(_, __) true ) ?? false
      if (!vehicleNeedDisplayMarker)
        return { watch }
    }

    let isSquadmate = info.squad_member__squad != ecs.INVALID_ENTITY_ID && info.squad_member__squad == watchedHeroSquadEid.value
    let isBot = info.possessedByPlr == ecs.INVALID_ENTITY_ID
    let isGroupmate = !isSquadmate && info.squad_member__playerEid in localPlayerGroupMembers.value

    let minHud = forcedMinimalHud.value
    let showName = info?.name && isGroupmate && !isBot && showTeammateName.value
    let nameComp = showName
      ? teammateName(eid, frameNick(remap_nick(info?.name), info?["decorators__nickFrame"]),
            HUD_COLOR_TEAMMATE_INNER)
      : null

    let icon = isSquadmate ? mkSquadmateIcon(eid)
      : isBot && isGroupmate ? groupmateBotIcon
      : teammateIcon
    let iconHpColor = info.medic__healState == MedicHealState.MHS_NEED_REVIVE ? HUD_COLOR_MEDIC_HP_CRITICAL
      : info.medic__healState == MedicHealState.MHS_NEED_HEAL ? HUD_COLOR_MEDIC_HP_LOW
      : null
    let hasEngineerInPlayerSquad = hasEngineers.value
    let isRequestAmmoBoxMarkerEnabled = hasEngineerInPlayerSquad
      && info["human_quickchat__requestAmmoBoxMarkerShowUpTo"] > 0.0
    let isRequestRallyPointMarkerEnabled = hasEngineerInPlayerSquad
      && info["human_quickchat__requestRallyPointMarkerShowUpTo"] > 0.0

    let maxHealIconDistance = minHud ? 25 : 30
    let maxTeammateIconDistance = minHud ? 100 : 1000

    return {
      data = {
        eid
        opacityForInvisibleAnimchar = 0.4
        minDistance = showMed ? 0 : maxHealIconDistance
        maxDistance = showMed ? maxHealIconDistance : maxTeammateIconDistance
        distScaleFactor = 0.5
        clampToBorder = false
        yOffs = 0.25
        opacityRangeViewDistance = minHud ? 1.0 : 20.0
        opacityRangeX = showName && !minHud
          ? maxRange
          : minHud ? opRangeX_hardcore : opRangeX
        opacityRangeY = showName ? maxRange : opRangeY
      }

      key = {}
      sortOrder = eid
      watch
      transform = defTransform

      halign = ALIGN_CENTER
      valign = ALIGN_BOTTOM
      size = [0,0]

      children = {
        flow = FLOW_VERTICAL
        halign = ALIGN_CENTER

        children = [
          {
            flow = FLOW_HORIZONTAL
            valign = ALIGN_CENTER

            gap = hdpx(2)

            children = [
              isRequestAmmoBoxMarkerEnabled ? requestAmmoBoxIcon : null
              isRequestRallyPointMarkerEnabled ? requestRallyPointIcon : null
            ]
          }
          nameComp
          showTeammateMarkers.value
          ? (showMed && needShowMed.value && iconHpColor
              ? mkHpIcon(eid, iconHpColor, HUD_COLOR_MEDIC_HP_OUTER)
              : icon)
          : { size=[hdpxi(10), hdpxi(13)] }
        ]
      }
    }
  }
}
let mapAvatarsMed = mkMemoizedMapSet(@(eid) unit(eid, true))
let mapAvatars = mkMemoizedMapSet(@(eid) unit(eid, false))

return {
  teammates_markers_ctor = {
    watch = teammatesAvatarsSet
    ctor = function() {
      let v = teammatesAvatarsSet.value
      return mapAvatarsMed(v).values().extend(mapAvatars(v).values())
    }
  }
}