from "%enlSqGlob/ui_library.nut" import *

let { tiny_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let {
  gap, bigPadding, slotBaseSize, disabledTxtColor, blockedTxtColor,
  deadTxtColor, defTxtColor, listCtors
} = require("%enlSqGlob/ui/viewConst.nut")
let { statusIconWarning } = require("%enlSqGlob/ui/itemPkg.nut")
let { autoscrollText } = require("%enlSqGlob/ui/defcomps.nut")
let { withTooltip } = require("%ui/style/cursors.nut")
let { kindIcon, classIcon, levelBlock, tierText, classTooltip, rankingTooltip,
  calcExperienceData, experienceTooltip, mkSoldierMedalIcon
} = require("%enlSqGlob/ui/soldiersUiComps.nut")
let { getItemName, getObjectName } = require("%enlSqGlob/ui/itemsInfo.nut")
let { mkSoldierPhoto } = require("%enlSqGlob/ui/soldierPhoto.nut")
let { getClassCfg } = require("%enlSqGlob/ui/soldierClasses.nut")
let {
  panelBgColor, squadSlotBgIdleColor, squadSlotBgHoverColor,
  squadSlotBgActiveColor, squadSlotBgAlertColor
}  = require("%enlSqGlob/ui/designConst.nut")


let DISABLED_ITEM = { tint = Color(40, 40, 40, 120), picSaturate = 0.0 }
let borderThickness = hdpxi(3)
let iconDead = Picture("ui/skin#lb_deaths.avif")
let panelBgDeadColor = Color(40,10,10,180)

let listSquadColor = @(flags, selected, hasAlertStyle, isDead)
  isDead ? panelBgDeadColor
    : flags & S_HOVER ? squadSlotBgHoverColor
    : selected ? squadSlotBgActiveColor
    : hasAlertStyle ? squadSlotBgAlertColor
    : squadSlotBgIdleColor


let iconSize = hdpxi(26)
let deadIcon = {
  rendObj = ROBJ_IMAGE
  size = [iconSize, iconSize]
  padding = [0, gap]
  vplace = ALIGN_CENTER
  image = iconDead
  tint = 0xCC990000
}

let mkPhotoSize = @(h) [h * 2 / 3, h]

let function mkClassBlock(soldier, isClassRestricted, isPremium, isDead) {
  let { sKind = null, sClass = null, sClassRare = null, armyId = null } = soldier
  let color = isClassRestricted ? blockedTxtColor : defTxtColor

  return {
    size = [hdpxi(36), flex()]
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    rendObj = ROBJ_SOLID
    color = panelBgColor
    children = isDead ? deadIcon
      : withTooltip({
          flow = FLOW_VERTICAL
          gap
          children = [
            kindIcon(sKind, iconSize, sClassRare).__update({ color, vplace = ALIGN_CENTER })
            isPremium ? null : classIcon(armyId, sClass, iconSize)
          ]
        }, @() classTooltip(armyId, sClass, sKind))
  }
}


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
          fontSize = hdpx(14)
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
  hasAlertStyle = false, hasWeaponWarning = false, addChild = null, squadInfo = null,
  isDisarmed = false, isFreemiumMode = false, thresholdColor = 0, expToLevel = []
) {
  let {
    guid, photo = null, sClass = null, armyId = null, canSpawn = true, tier = 1
  } = soldierInfo

  let isBlocked = isDead || !canSpawn
  let isPremium = getClassCfg(sClass)?.isPremium ?? false
  let photoStyle = isFaded || isBlocked ? DISABLED_ITEM : {}
  let noWeaponTxt = loc("delivery/withoutWeapon")

  let textColor = isBlocked ? @(...) deadTxtColor
    : isFaded ? listCtors.txtDisabledColor
    : listCtors.weaponColor

  let nameColor = isBlocked ? @(...) deadTxtColor
    : isFaded ? listCtors.weaponColor
    : listCtors.nameColor

  let weaponRow = isDisarmed ? mkWeaponRow(soldierInfo, disabledTxtColor,
        group, { text = noWeaponTxt })
    : (hasWeaponWarning ? mkWeaponRowWithWarning : mkWeaponRow)(soldierInfo,
        textColor(sf, isSelected), group)

  return {
    key = guid
    size
    children = [
      {
        size = flex()
        flow = FLOW_HORIZONTAL
        clipChildren = true
        children = [
          {
            size = flex()
            flow = FLOW_HORIZONTAL
            gap = bigPadding
            rendObj = ROBJ_SOLID
            color = listSquadColor(sf, isSelected, hasAlertStyle, isBlocked)
            children = [
              withTooltip({
                halign = ALIGN_RIGHT
                children = [
                  mkSoldierPhoto(photo, mkPhotoSize(size[1]), null, photoStyle)
                  tierText(tier).__update({ margin = [0, hdpx(2)] })
                ]}, @() rankingTooltip(tier))
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
                    flow = FLOW_HORIZONTAL
                    vplace = ALIGN_BOTTOM
                    hplace = ALIGN_RIGHT
                    margin = hdpx(2)
                    children = addChild(soldierInfo, isSelected)
                  }
                ]
              }
            ]
          }
          mkClassBlock(soldierInfo, isClassRestricted, isPremium, isDead)
        ]
      }
      isPremium ? classIcon(armyId, sClass, iconSize) : null
      {
        size = flex()
        borderWidth = isSelected ? [0,0,borderThickness,0] : 0
        rendObj = ROBJ_BOX
        fillColor = 0
      }
    ]
  }
}

return kwarg(soldierCard)
