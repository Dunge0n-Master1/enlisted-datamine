import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let { forcedMinimalHud } = require("%ui/hud/state/hudGameModes.nut")
let {Point2} = require("dagor.math")
let { watchedHeroEid } = require("%ui/hud/state/watched_hero.nut")
let { localPlayerEid } = require("%ui/hud/state/local_player.nut")
let {selectedBotForOrderEid, isPersonalContextCommandMode} = require("%ui/hud/state/squad_members.nut")
let teammateName = require("%ui/hud/components/teammateName.nut")
let { INVALID_GROUP_ID } = require("matching.errors")
let {
  HUD_COLOR_TEAMMATE_INNER, HUD_COLOR_TEAMMATE_OUTER,
  HUD_COLOR_GROUPMATE_BOT_INNER, HUD_COLOR_GROUPMATE_BOT_OUTER,
  HUD_COLOR_SQUADMATE_INNER, HUD_COLOR_SQUADMATE_OUTER,
  HUD_COLOR_MEDIC_HP_LOW, HUD_COLOR_MEDIC_HP_CRITICAL, HUD_COLOR_MEDIC_HP_OUTER
} = require("%enlSqGlob/ui/style/unit_colors.nut")
let remap_nick = require("%enlSqGlob/remap_nick.nut")
let { frameNick } = require("%enlSqGlob/ui/decoratorsPresentation.nut")
let engineersInSquad = require("%ui/hud/state/engineers_in_squad.nut")
let { heroSoldierKind } = require("%ui/hud/state/soldier_class_state.nut")
let { MHS_NEED_HEAL, MHS_NEED_REVIVE } = require("%enlSqGlob/dasenums.nut")
let { heroMedicMedpacks } = require("%ui/hud/state/medic_state.nut")

let defTransform = {}
let hpIconSize = [fsh(2.5), fsh(2.5)]

let mkIcon = function(colorInner, colorOuter, sizeFactor) {
  let unitIconSize = [fsh(1*sizeFactor), fsh(1.25*sizeFactor)].map(@(v) v.tointeger())

  return {
    key = $"icon_{colorInner}_{colorOuter}"
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

let mkSquadmateIcon = @(eid) function() {
  let isSelectedBotForOrders = selectedBotForOrderEid.value == eid && isPersonalContextCommandMode.value
  let sizeFactor = isSelectedBotForOrders ? 2.0 : 1.0
  let icon = mkIcon(HUD_COLOR_SQUADMATE_INNER, HUD_COLOR_SQUADMATE_OUTER, sizeFactor)
  return {
    watch = [selectedBotForOrderEid, isPersonalContextCommandMode]
    children = icon.__update(isSelectedBotForOrders
      ? {
          key = $"{eid}_selected"
          transform = {}
          animations = [
            {prop = AnimProp.translate, from=[0, hdpx(25)], to=[0, 0], duration=0.5, play=true, loop=true, easing=OutBack}
          ]
        }
      : { key = eid })
  }
}

let mkHpIcon = @(eid, colorInner, colorOuter) {
  key = eid
  rendObj = ROBJ_IMAGE
  color = colorOuter
  image = Picture($"ui/skin#healing_icon_outer.svg:{hpIconSize[0]}:{hpIconSize[1]}:K")
  size = hpIconSize
  minDistance = 0.5

  children = {
    rendObj = ROBJ_IMAGE
    color = colorInner
    image = Picture($"ui/skin#healing_icon.svg:{hpIconSize[0]}:{hpIconSize[1]}:K")
    size = hpIconSize
  }
}

let ammoBoxIconSize = [fsh(6.0), fsh(6.0)]
let requestAmmoBoxIcon = {
  rendObj = ROBJ_IMAGE
  color = Color(255, 255, 255, 255)
  image = Picture($"ui/skin#building_ammo_box.svg:{ammoBoxIconSize[0]}:{ammoBoxIconSize[1]}:K")
  size = ammoBoxIconSize
  minDistance = 0.5
}

let rallyPointIconSize = [fsh(6.0), fsh(6.0)]
let requestRallyPointIcon = {
  rendObj = ROBJ_IMAGE
  color = Color(255, 255, 255, 255)
  image = Picture($"ui/skin#custom_spawn_point.svg:{rallyPointIconSize[0]}:{rallyPointIconSize[1]}:K")
  size = rallyPointIconSize
  minDistance = 0.5
}

let teammateIcon = mkIcon(HUD_COLOR_TEAMMATE_INNER, HUD_COLOR_TEAMMATE_OUTER, 1.0)
let groupmateBotIcon = mkIcon(HUD_COLOR_GROUPMATE_BOT_INNER, HUD_COLOR_GROUPMATE_BOT_OUTER, 1.0)

let displayMarkerOverHeadQuery = ecs.SqQuery("displayMarkerOverHeadQuery", {comps_rq=["vehicleDisplayMarkerOverHead"]})
let zeroPoint = Point2(0,0)
let opRangeX = Point2(0.25, 0.35)
let opRangeY = Point2(0.25, 0.75)
let opRangeX_hardcore = Point2(0.125, 0.135)

let function unit(eid, info){
  if (!info.isAlive)
    return null
  let squadEid = ecs.obsolete_dbg_get_comp_val(eid, "squad_member__squad") ?? INVALID_ENTITY_ID
  let groupId = ecs.obsolete_dbg_get_comp_val(localPlayerEid.value, "groupId") ?? INVALID_GROUP_ID
  let isSquadmate = (squadEid!=INVALID_ENTITY_ID && squadEid >= 0 && squadEid == ecs.obsolete_dbg_get_comp_val(watchedHeroEid.value, "squad_member__squad"))
  let isBot = (ecs.obsolete_dbg_get_comp_val(eid, "possessedByPlr") ?? INVALID_ENTITY_ID) == INVALID_ENTITY_ID
  local isGroupmate = false
  if (!isSquadmate && squadEid != INVALID_ENTITY_ID && groupId != INVALID_ENTITY_ID) {
    let ownerPlayer = ecs.obsolete_dbg_get_comp_val(squadEid, "squad__ownerPlayer") ?? INVALID_ENTITY_ID
    isGroupmate = groupId == ecs.obsolete_dbg_get_comp_val(ownerPlayer, "groupId")
  }

  let vehicle = info?["human_anim__vehicleSelected"] ?? INVALID_ENTITY_ID
  let vehicleNeedDisplayMarker = displayMarkerOverHeadQuery(vehicle, @(_, __) true ) ?? false

  if (vehicle != INVALID_ENTITY_ID && !vehicleNeedDisplayMarker)
    return null

  let minHud = forcedMinimalHud.value
  let showName = info?.name && isGroupmate && !isBot
  let nameComp = showName
    ? teammateName(eid, frameNick(remap_nick(info?.name), info?["decorators__nickFrame"]),
          HUD_COLOR_TEAMMATE_INNER)
    : null

  let icon = isSquadmate ? mkSquadmateIcon(eid)
    : isBot && isGroupmate ? groupmateBotIcon
    : teammateIcon
  let iconHpColor = info.medic__healState == MHS_NEED_REVIVE ? HUD_COLOR_MEDIC_HP_CRITICAL
    : info.medic__healState == MHS_NEED_HEAL ? HUD_COLOR_MEDIC_HP_LOW
    : null
  let hasEngineerInPlayerSquad = engineersInSquad.value > 0
  let isRequestAmmoBoxMarkerEnabled = hasEngineerInPlayerSquad
    && info["human_quickchat__requestAmmoBoxMarkerShowUpTo"] > 0.0
  let isRequestRallyPointMarkerEnabled = hasEngineerInPlayerSquad
    && info["human_quickchat__requestRallyPointMarkerShowUpTo"] > 0.0

  let maxHealIconDistance = minHud ? 25 : 30
  let maxTeammateIconDistance = minHud ? 100 : 1000

  let iconCtor = function(minDistance, maxDistance, mainIcon) {
    if (watchedHeroEid.value==eid)
      return {watch = watchedHeroEid}

    return {
      data = {
        eid
        minDistance
        maxDistance
        distScaleFactor = 0.5
        clampToBorder = false
        yOffs = 0.25
        opacityRangeViewDistance = minHud ? 1.0 : 20.0
        opacityRangeX = showName && !minHud
          ? zeroPoint
          : minHud ? opRangeX_hardcore : opRangeX
        opacityRangeY = showName ? zeroPoint : opRangeY
      }

      key = $"unit_marker_{eid}"
      sortOrder = eid
      watch = [watchedHeroEid, heroMedicMedpacks, engineersInSquad, heroSoldierKind]
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
          mainIcon
        ]
      }
    }
  }

  return [
    @() iconCtor(0, maxHealIconDistance,
      heroSoldierKind.value == "medic" && iconHpColor && heroMedicMedpacks.value > 0
        ? mkHpIcon(eid, iconHpColor, HUD_COLOR_MEDIC_HP_OUTER)
        : icon)
    @() iconCtor(maxHealIconDistance, maxTeammateIconDistance, icon)
  ]
}

return {
  teammate_ctor = unit
}