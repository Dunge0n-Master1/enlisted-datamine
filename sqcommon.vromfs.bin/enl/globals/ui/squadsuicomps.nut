from "%enlSqGlob/ui_library.nut" import *

let { sub_txt, fontawesome } = require("%enlSqGlob/ui/fonts_style.nut")
let fa = require("%ui/components/fontawesome.map.nut")
let {
  spawnNotReadyColor, multySquadPanelSize, blinkingSignalsGreenDark
} = require("%enlSqGlob/ui/viewConst.nut")
let { smallPadding, darkTxtColor, defTxtColor, hoverSlotBgColor, panelBgColor, accentColor } = require("%enlSqGlob/ui/designConst.nut")
let { txt } = require("%enlSqGlob/ui/defcomps.nut")
let { soldierKinds } = require("%enlSqGlob/ui/soldierClasses.nut")
let { getLinkedArmyName } = require("%enlSqGlob/ui/metalink.nut")
let armiesPresentation = require("%enlSqGlob/ui/armiesPresentation.nut")
let squadsPresentation = require("%enlSqGlob/ui/squadsPresentation.nut")


let txtColor = @(flags, _selected=false)
  (flags & S_HOVER) ? darkTxtColor : defTxtColor

const ICON_SCALE = 0.67
const defaultSquadIcon = "!ui/uiskin/squad_default.svg"

let squadTypeIconSize = hdpxi(30)
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
}.__update(sub_txt)

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

let selectedColor = mul_color(panelBgColor, 1.5)
let squadBgColor = @(sf, selected, hasAlertStyle = false)
  sf & S_HOVER
    ? hoverSlotBgColor
    : selected
      ? selectedColor
      : hasAlertStyle ? Color(30,0,0,150) : panelBgColor


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

let mkActiveBlock = @(_sf, _selected, content) {
//  rendObj = ROBJ_SOLID
  size = SIZE_TO_CONTENT
  flow = FLOW_HORIZONTAL
//  color = squadBlockBgColor(sf, selected)
  children = content
}

let mkSquadUnits = @(amount, squadType, sf, selected, addedRightObj, mkChild = null) {
  size = flex()
  children = [
    addedRightObj
    mkChild?(sf, selected)
    mkActiveBlock(sf, selected, mkSquadTypeIcon(squadType, sf, selected))
      .__update({
        hplace = ALIGN_LEFT
        vplace = ALIGN_BOTTOM
      })
    mkActiveBlock(sf, selected,
      [
        mkCardText(amount, sf)
        mkCardText(fa["user-o"], sf).__update({
          rendObj = ROBJ_INSCRIPTION
          font = fontawesome.font
          fontSize = hdpx(12)
        })
      ]).__update({
        padding = smallPadding
        gap = hdpx(3)
        hplace = ALIGN_RIGHT
        vplace = ALIGN_BOTTOM
        valign = ALIGN_CENTER
      })
  ]
}

let mkSquadLevel = @(level, sf, selected) level == null ? null
  : mkActiveBlock(sf, selected,
      mkCardText(loc("level/short", { level = level + 1 }), sf)
        .__update({ margin = smallPadding }))

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

let timerIcon = "ui/skin#/battlepass/boost_time.svg"
let timerSize = hdpxi(18)

let squadTimer = {
  rendObj = ROBJ_IMAGE
  size = [timerSize, timerSize]
  margin = smallPadding
  image = Picture($"{timerIcon}:{timerSize}:{timerSize}:K")
  color = blinkingSignalsGreenDark
}

let selMarker = freeze({size = [flex(),hdpx(2)], rendObj = ROBJ_SOLID, color = accentColor, vplace = ALIGN_BOTTOM, pos = [0, hdpx(2)]})

let mkSquadCard = kwarg(function (idx, isSelected, addChild = null, icon = "",
  squadType = null, squadSize = null, level = null, isFaded = false,
  premIcon = null, onClick = null, addedRightObj = null, mkChild = null,
  expireTime = 0, onDoubleClick = null, onHover=null
) {
  let stateFlags = Watched(0)
  icon = (icon ?? "").len() > 0 ? icon : defaultSquadIcon
  return function() {
    let sf = stateFlags.value
    let selected = isSelected.value
    let topRightChilds = expireTime == 0 ? addChild
      : {
          flow = FLOW_HORIZONTAL
          hplace = ALIGN_RIGHT
          children = [
            addChild
            squadTimer
          ]
        }

    return {
      rendObj = ROBJ_BOX
      size = multySquadPanelSize
      fillColor = squadBgColor(sf, selected)
      borderWidth = selected ? hdpx(2) : 0
      borderColor = accentColor
      key = idx
      behavior = Behaviors.Button
      sound = {
        hover = "ui/enlist/button_highlight"
        click = "ui/enlist/button_click"
        active = "ui/enlist/button_action"
      }
      onHover
      xmbNode = XmbNode()
      opacity = isFaded ? 0.7 : 1.0
      onElemState = @(nsf) stateFlags(nsf)
      onClick
      onDoubleClick
      watch = [stateFlags, isSelected]
      children = [
        mkSquadIcon(icon, {
          size = multySquadPanelSize.map(@(val) val * ICON_SCALE)
          hplace = ALIGN_CENTER
          vplace = ALIGN_CENTER
        })
        mkSquadUnits(squadSize, squadType, sf, selected, addedRightObj, mkChild)
        premIcon != null
          ? mkSquadPremIcon(premIcon, { margin = [0, hdpx(6)] })
          : mkSquadLevel(level, sf, selected)
      ].append(topRightChilds, selected ? selMarker : null)
    }
  }
})


return {
  txtColor
  isSquadPremium
  mkSquadCard
  mkSquadIcon
  mkSquadTypeIcon
  mkSquadPremIcon
  mkSquadSpecIconFields
  mkSquadSpecIcon
  squadBgColor
  mkCardText
  mkActiveBlock
  mkSquadSpawnIcon
  mkSquadSpawnDesc
}
