from "%enlSqGlob/ui_library.nut" import *

let faComp = require("%ui/components/faComp.nut")
let { fontSub } = require("%enlSqGlob/ui/fontsStyle.nut")
let { spawnNotReadyColor, multySquadPanelSize } = require("%enlSqGlob/ui/viewConst.nut")
let {
  miniPadding, smallPadding, midPadding, darkTxtColor, defTxtColor,
  squadSlotBgIdleColor, squadSlotBgHoverColor, squadSlotBgActiveColor,
  squadSlotBgAlertColor, levelNestGradient
} = require("%enlSqGlob/ui/designConst.nut")
let { txt } = require("%enlSqGlob/ui/defcomps.nut")
let { soldierKinds } = require("%enlSqGlob/ui/soldierClasses.nut")
let { getLinkedArmyName } = require("%enlSqGlob/ui/metalink.nut")
let armiesPresentation = require("%enlSqGlob/ui/armiesPresentation.nut")
let squadsPresentation = require("%enlSqGlob/ui/squadsPresentation.nut")


let txtColor = @(flags, _selected=false)
  flags & S_HOVER ? darkTxtColor : defTxtColor

const ICON_SCALE = 0.65
const defaultSquadIcon = "!ui/uiskin/squad_default.svg"

let squadTypeIconSize = hdpxi(24)
let premIconSize = hdpxi(26)

let isSquadPremium = @(squad) squad?.premIcon != null
  || (squad?.premSquadExpBonus ?? 0) > 0
  || (squad?.battleExpBonus ?? 0) > 0

let squadTypeSvg = soldierKinds.map(@(c) c.icon)
  .__update({
      tank = "tank_icon.svg"
      aircraft = "aircraft_icon.svg"
      assault_aircraft = "assault_aircraft_icon.svg"
      bike = "bike_icon.svg"
      mech = "mech_icon.svg"
    })
  .map(@(key) $"ui/skin#{key}")

let getSquadTypeIcon = @(squadType) squadTypeSvg?[squadType] ?? squadTypeSvg.unknown

let mkText = @(text) {
  rendObj = ROBJ_TEXT
  text
  color = defTxtColor
}.__update(fontSub)

let mkTextArea = @(text) mkText(text).__update({
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  size = SIZE_TO_CONTENT
  maxWidth = pw(80)
})


let function mkSquadSpawnDesc(canSpawnSquad, readiness, canSpawnSoldier, isAffordable, price, score) {
  if (canSpawnSquad == null || readiness == null)
    return mkTextArea(loc("respawn/squadNotChoosen"))

  let descKeyId = !canSpawnSquad && readiness == 100 && price <= 0 ? "respawn/squadNotParticipate"
    : price > 0 && !isAffordable ? "respawn/notAffordableSubtext"
    : !canSpawnSquad ? "respawn/squadNotReady"
    : !canSpawnSoldier ? "respawn/soldierNotReady"
    : readiness < 100 ? "respawn/squadPartiallyReady"
    : price > 0 ? "respawn/squadReadyWithCost"
    : null
  return descKeyId == null ? null : mkTextArea(loc(descKeyId, { number = readiness, price, score }))
}

let mkSquadSpawnIcon = @(size = hdpxi(20))
  {
    rendObj = ROBJ_IMAGE
    margin = smallPadding
    hplace = ALIGN_RIGHT
    size = [size, size]
    keepAspect = KEEP_ASPECT_FIT
    image = Picture($"ui/skin#ban_icon.svg:{size}:{size}:K")
    color = spawnNotReadyColor
  }

local function mkSquadIcon(img, override = {}) {
  if ((img ?? "") == "")
    return {
      rendObj = ROBJ_BOX
      borderWidth = hdpx(1)
      size = flex()
    }
  if (img.endswith(".svg") && "size" in override) {
    let size = override.size
    if (typeof size == "array")
      img = $"{img}:{size[0].tointeger()}:{size[1].tointeger()}:K"
  }
  return {
    rendObj = ROBJ_IMAGE
    size = flex()
    keepAspect = KEEP_ASPECT_FIT
    image = Picture(img)
  }.__update(override)
}

let squadBgColor = @(sf, selected, hasAlertStyle = false)
  sf & S_HOVER ? squadSlotBgHoverColor
    : selected ? squadSlotBgActiveColor
    : hasAlertStyle ? squadSlotBgAlertColor
    : squadSlotBgIdleColor


let mkCardText = @(t, sf, _selected=false) txt({
  text = t
  color = txtColor(sf)
})

let squadTypeIcon = @(squadType, iconSize = squadTypeIconSize, override = {}) {
  size = [iconSize, iconSize]
  rendObj = ROBJ_IMAGE
  image = Picture("{0}:{1}:{1}:K".subst(getSquadTypeIcon(squadType), iconSize))
  keepAspect = KEEP_ASPECT_FIT
}.__update(override)

let mkSquadTypeIcon = @(squadType, sf, _selected, iconSize = squadTypeIconSize) {
  padding = [0, smallPadding]
  children = squadTypeIcon(squadType, iconSize, { color = txtColor(sf) })
}


let typeCircleSize = hdpx(34)
let mkSquadType = @(squadType) {
  size = [typeCircleSize, typeCircleSize]
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  rendObj = ROBJ_VECTOR_CANVAS
  commands = [[ VECTOR_ELLIPSE, 50, 50, 50, 50 ]]
  fillColor = 0xFF000000
  color = 0xFF000000
  children = mkSquadTypeIcon(squadType, 0, false)
}


let mkSquadUnits = @(amount, sf) (amount ?? 0) == 0 ? null : {
  size = SIZE_TO_CONTENT
  flow = FLOW_HORIZONTAL
  gap = miniPadding
  margin = miniPadding
  valign = ALIGN_CENTER
  children = [
    txt({ text = amount, color = txtColor(sf) })
    faComp("user", { fontSize = hdpx(12), color = txtColor(sf) })
  ]
}

let mkUnlockLevel = @(unlockLevel, sf) (unlockLevel ?? 0) == 0 ? null
  : {
      flow = FLOW_HORIZONTAL
      gap = miniPadding
      children = [
        faComp("lock", { fontSize = fontSub.fontSize, color = txtColor(sf) })
        txt({ text = loc("level/short", { level = unlockLevel }), color = txtColor(sf) })
      ]
    }


let timerIcon = "ui/skin#/battlepass/boost_time.svg"
let timerSize = hdpxi(18)

let mkSquadTimer = @(sf) {
  rendObj = ROBJ_IMAGE
  size = [timerSize, timerSize]
  margin = smallPadding
  image = Picture($"{timerIcon}:{timerSize}:{timerSize}:K")
  color = txtColor(sf)
}

let borderThickness = hdpxi(3)
let mkSquadLevel = @(level, expireTime, sf, addChild) {
  size = [flex(), SIZE_TO_CONTENT]
  valign = ALIGN_CENTER
  margin = [0,0,borderThickness,0]
  children = [
    {
      padding = [miniPadding, midPadding]
      children = addChild
    }
    level == null && expireTime == 0 ? null
      : {
          size = [flex(), SIZE_TO_CONTENT]
          flow = FLOW_HORIZONTAL
          gap = miniPadding
          padding = [miniPadding, midPadding]
          vplace = ALIGN_BOTTOM
          valign = ALIGN_CENTER
          halign = ALIGN_RIGHT
          rendObj = ROBJ_IMAGE
          image = levelNestGradient
          children = [
            expireTime == 0 ? null : mkSquadTimer(sf)
            level == null ? null
              : mkCardText(loc("level/short", { level = level + 1 }), sf).__update({
                  hplace = ALIGN_RIGHT
                })
          ]
        }
  ]
}


let function mkSquadPremIcon(premIcon, override = null) {
  if (premIcon == null)
    return null

  let [ iconW = premIconSize, iconH = premIconSize ] = override?.size
  return (override ?? {}).__merge({
    rendObj = ROBJ_IMAGE
    size = [iconW, iconH]
    keepAspect = KEEP_ASPECT_FIT
    image = Picture($"{premIcon}:{iconW}:{iconH}:K")
  })
}

let function mkSquadSpecIconFields(armyId, squad, isPremium = false, override = null) {
  local { squadId = null, premIcon = null } = squad
  if (isPremium && premIcon == null)
    premIcon = squadsPresentation?[armyId][squadId] ?? armiesPresentation?[armyId].premIcon
  if (premIcon == null)
    return null

  return mkSquadPremIcon(premIcon, override)
}

let function mkSquadSpecIcon(squad, override = null) {
  let armyId = getLinkedArmyName(squad)
  let isPremium = isSquadPremium(squad)
  return mkSquadSpecIconFields(armyId, squad, isPremium, override)
}


let mkSquadCard = kwarg(function (idx, isSelected, addChild = null, icon = "",
  squadType = null, squadSize = null, level = null, isFaded = false,
  premIcon = null, onClick = null, addedRightObj = null, mkChild = null,
  expireTime = 0, onDoubleClick = null, onHover = null, squadCardSize = null,
  unlockLevel = null
) {
  let stateFlags = Watched(0)
  icon = (icon ?? "").len() > 0 ? icon : defaultSquadIcon
  let size = squadCardSize ?? multySquadPanelSize

  return function() {
    let sf = stateFlags.value
    let selected = isSelected.value

    return {
      watch = [stateFlags, isSelected]
      key = idx
      size
      borderWidth = selected ? [0,0,borderThickness,0] : 0
      rendObj = ROBJ_BOX
      fillColor = squadBgColor(sf, selected)
      behavior = onClick == null ? null : Behaviors.Button
      sound = {
        hover = "ui/enlist/button_highlight"
        click = "ui/enlist/button_click"
        active = "ui/enlist/button_action"
      }
      xmbNode = XmbNode()
      opacity = isFaded ? 0.7 : 1.0
      onElemState = @(nsf) stateFlags(nsf)
      onHover
      onClick
      onDoubleClick
      children = [
        mkSquadIcon(icon, {
          size = array(2, size[1] * ICON_SCALE)
          margin = [0, midPadding]
          vplace = ALIGN_CENTER
        })
        {
          size = [flex(), SIZE_TO_CONTENT]
          vplace = ALIGN_BOTTOM
          children = mkSquadLevel(premIcon == null ? level : null, expireTime, sf, addChild)
        }
        premIcon == null ? null : mkSquadPremIcon(premIcon)
        {
          flow = FLOW_VERTICAL
          gap = smallPadding
          margin = [smallPadding, midPadding]
          hplace = ALIGN_RIGHT
          halign = ALIGN_RIGHT
          children = [
            mkSquadType(squadType)
            addedRightObj
              ?? mkChild?(sf, selected)
              ?? mkSquadUnits(squadSize, sf)
              ?? mkUnlockLevel(unlockLevel, sf)
          ]
        }
      ]
    }
  }
})


return {
  txtColor
  isSquadPremium
  mkSquadCard
  mkSquadIcon
  squadTypeIcon
  mkSquadTypeIcon
  mkSquadPremIcon
  mkSquadSpecIconFields
  mkSquadSpecIcon
  squadBgColor
  mkCardText
  mkSquadSpawnIcon
  mkSquadSpawnDesc
}
