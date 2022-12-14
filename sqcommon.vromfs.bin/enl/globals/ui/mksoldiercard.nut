from "%enlSqGlob/ui_library.nut" import *

let { tiny_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let { gap, activeBgColor, hoverBgColor, defBgColor, slotBaseSize, disabledTxtColor,
  blockedTxtColor, deadTxtColor, listCtors
} = require("%enlSqGlob/ui/viewConst.nut")
let { statusIconWarning } = require("%enlSqGlob/ui/itemPkg.nut")
let { autoscrollText } = require("%enlSqGlob/ui/defcomps.nut")
let { withTooltip } = require("%ui/style/cursors.nut")
let { kindIcon, classIcon, levelBlock, tierText, classTooltip, rankingTooltip,
  calcExperienceData, experienceTooltip, mkSoldierMedalIcon
} = require("%enlSqGlob/ui/soldiersUiComps.nut")
let { getItemName, getObjectName } = require("%enlSqGlob/ui/itemsInfo.nut")
let { mkSoldierPhoto } = require("%enlSqGlob/ui/soldierPhoto.nut")

let DISABLED_ITEM = { tint = Color(40, 40, 40, 120), picSaturate = 0.0 }

let iconDead = Picture("ui/skin#lb_deaths.png")

let function listSquadColor(flags, selected, isFaded, hasAlertStyle, isDead) {
  if (isDead)
    return Color(40,10,10,180)

  let add = hasAlertStyle ? Color(30,0,0,0)
    : isFaded ? Color(30,30,30,30)
    : 0
  return selected ? activeBgColor
    : flags & S_HOVER
      ? hoverBgColor
      : add + defBgColor
}

let sClassIconSize = hdpxi(22)
let makeClassIcon = @(soldier, color, isDead = false) isDead
  ? {
      rendObj = ROBJ_IMAGE
      size = [sClassIconSize, sClassIconSize]
      vplace = ALIGN_CENTER
      image = iconDead
      tint = color
    }
  : withTooltip(
      {
        vplace = ALIGN_CENTER
        halign = ALIGN_CENTER
        gap = gap
        flow = FLOW_VERTICAL
        children = [
          kindIcon(soldier?.sKind, sClassIconSize, soldier?.sClassRare)
            .__update({ color = color, vplace = ALIGN_CENTER })
          classIcon(soldier?.armyId, soldier?.sClass, sClassIconSize)
        ]
      },
      @() classTooltip(soldier?.armyId, soldier?.sClass, soldier?.sKind)
    )

let mkDropSoldierInfoBlock = @(soldierInfo, squadInfo, nameColor, textColor, group) { //!!FIX ME: Why it here?
  size = flex()
  flow = FLOW_VERTICAL
  valign = ALIGN_CENTER
  children = [
    {
      size = [flex(), SIZE_TO_CONTENT]
      flow = FLOW_HORIZONTAL
      children = {
        size = [flex(), SIZE_TO_CONTENT]
        rendObj = ROBJ_TEXTAREA
        behavior = Behaviors.TextArea
        text = loc(squadInfo.titleLocId)
        color = textColor
      }.__update(tiny_txt)
    }
    autoscrollText({
      text = getObjectName(soldierInfo)
      color = nameColor
      group = group
    })
  ]
}

let function mkWeaponRow(soldierInfo, weaponColor, group, override = {}) {
  let { primaryWeapon = null, weapons = [] } = soldierInfo
  let template = primaryWeapon
    ?? weapons.findvalue(@(v, idx) idx < 3 && (v?.templateName ?? "") != "")?.templateName
  let weaponLocId = template != null
    ? getItemName(template)
    : "delivery/withoutWeapon"
  return autoscrollText({
    text = loc(weaponLocId)
    color = weaponColor
    vplace = ALIGN_BOTTOM
    group = group
  }.__update(override))
}

let mkWeaponRowWithWarning = @(soldierInfo, weaponColor, group, override = {}) {
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_HORIZONTAL
  gap = hdpx(2)
  children = [
    statusIconWarning
    mkWeaponRow(soldierInfo, weaponColor, group, override)
  ]
}

let function soldierName(soldierInfo, nameColor, group) {
  let { guid = "", callname = "" } = soldierInfo
  return guid == "" ? null : {
    size = [flex(), SIZE_TO_CONTENT]
    valign = ALIGN_CENTER
    flow = FLOW_HORIZONTAL
    gap = gap
    children = [
      mkSoldierMedalIcon(soldierInfo, hdpx(16))
      autoscrollText({
        group = group
        text = callname != "" ? callname : getObjectName(soldierInfo)
        color = nameColor
      })
    ]
  }
}

let mkSoldierInfoBlock = function(soldierInfo, nameColor, weaponRow, group, isFreemiumMode, thresholdColor, expToLevel) {
  let {
    guid = "", perksCount = 0, level = 1, maxLevel = 1, tier = 1
  } = soldierInfo
  let perksLevel = min(level, maxLevel)
  return {
    size = flex()
    flow = FLOW_VERTICAL
    valign = ALIGN_CENTER
    children = [
      soldierName(soldierInfo, nameColor, group)
      weaponRow
      withTooltip(@()
        levelBlock({
          curLevel = perksCount
          leftLevel = max(perksLevel - perksCount, 0)
          lockedLevel = max(maxLevel - perksLevel, 0)
          fontSize = hdpx(8)
          hasLeftLevelBlink = true
          guid = guid
          isFreemiumMode = isFreemiumMode
          thresholdColor
          tier = tier
        }).__update({ margin = [gap, 0] }),
        @() experienceTooltip(calcExperienceData(soldierInfo, expToLevel)))
    ]
  }
}

let function soldierCard(soldierInfo, group = null, sf = 0, isSelected = false,
  isFaded = false, isDead = false, size = slotBaseSize, isClassRestricted = false,
  hasAlertStyle = false, hasWeaponWarning = false, addChild = null, squadInfo = null, updStyle = {},
  isDisarmed = false, isFreemiumMode = false, thresholdColor = 0, expToLevel = []
) {
  let canSpawn = soldierInfo?.canSpawn ?? true
  let isBlocked = isDead || !canSpawn

  let textColor = isBlocked
    ? @(...) deadTxtColor
    : isFaded
      ? listCtors.txtDisabledColor
      : listCtors.weaponColor

  let nameColor = isBlocked
    ? @(...) deadTxtColor
    : isFaded
      ? listCtors.weaponColor
      : listCtors.nameColor

  let weaponRow = isDisarmed
    ? mkWeaponRow(soldierInfo, disabledTxtColor, group, { text = loc("delivery/withoutWeapon") })
    : (hasWeaponWarning
        ? mkWeaponRowWithWarning
        : mkWeaponRow)(soldierInfo, textColor(sf, isSelected), group)
  let tier = soldierInfo?.tier ?? 1

  return {
    key = $"{soldierInfo.guid}"
    size = size
    rendObj = ROBJ_SOLID
    color = listSquadColor(sf, isSelected, isFaded, hasAlertStyle, isBlocked)
    clipChildren = true
    group = group
    flow = FLOW_HORIZONTAL
    gap = gap
    padding = [0, 0, 0, gap]

    children = [
      makeClassIcon(soldierInfo,
        isClassRestricted
          ? blockedTxtColor
          : textColor(sf, isSelected),
        isDead)
      withTooltip({
          children = [
            mkSoldierPhoto(soldierInfo?.photo,
              [(0.7 * size[1]).tointeger(), size[1]], [],
              isFaded || isBlocked ? DISABLED_ITEM : {})
            tierText(tier).__update({ margin = [0, hdpx(2)] })
          ]
        },
        @() rankingTooltip(tier))
      {
        size = flex()
        children = [
          squadInfo == null
            ? mkSoldierInfoBlock(
                soldierInfo,
                nameColor(sf, isSelected),
                weaponRow,
                group,
                isFreemiumMode,
                thresholdColor,
                expToLevel
              )
            : mkDropSoldierInfoBlock(
                soldierInfo,
                squadInfo,
                nameColor(sf, isSelected),
                textColor(sf, isSelected),
                group
              )
          addChild == null ? null : {
            size = flex()
            padding = hdpx(2)
            children = addChild(soldierInfo, isSelected)
          }
        ]
      }
    ]
  }.__update(updStyle)
}

return kwarg(soldierCard)