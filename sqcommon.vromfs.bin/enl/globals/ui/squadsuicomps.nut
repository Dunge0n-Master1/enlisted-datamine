from "%enlSqGlob/ui_library.nut" import *

let { sub_txt, fontawesome } = require("%enlSqGlob/ui/fonts_style.nut")
let fa = require("%ui/components/fontawesome.map.nut")
let {
  smallPadding, activeBgColor, hoverBgColor, defBgColor, selectedTxtColor,
  defTxtColor, spawnNotReadyColor, multySquadPanelSize, blinkingSignalsGreenDark
} = require("%enlSqGlob/ui/viewConst.nut")
let { mkHintRow } = require("%ui/components/uiHotkeysHint.nut")
let { txt } = require("%enlSqGlob/ui/defcomps.nut")
let { soldierKinds } = require("%enlSqGlob/ui/soldierClasses.nut")

let txtColor = @(flags, selected = false)
  selected || (flags & S_HOVER) ? selectedTxtColor : defTxtColor

const ICON_SCALE = 0.85
const defaultSquadIcon = "!ui/uiskin/squad_default.svg"

let squadTypeIconSize = hdpxi(30)
let premIconSize = hdpxi(26)

let squadTypeSvg = soldierKinds.map(@(c) c.icon)
  .__update({
      tank = "tank_icon.svg"
      aircraft = "aircraft_icon.svg"
      bike = "bike_icon.svg"
    })
  .map(@(key) $"ui/skin#{key}")

let getSquadTypeIcon = @(squadType) squadTypeSvg?[squadType] ?? "ui/skin#rifle.svg"

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

let mkKeyboardHint = @(keyBordKey, postKeyTxt = null){
  size = [flex(), SIZE_TO_CONTENT]
  hplace = ALIGN_CENTER
  halign = ALIGN_CENTER
  flow = FLOW_HORIZONTAL
  gap = hdpx(2)
  children = [
    mkHintRow(keyBordKey)
    {
      rendObj = ROBJ_TEXT
      text = postKeyTxt
    }
  ]
}

let function mkSquadSpawnDesc(canSpawnSquad, readiness, canSpawnSoldier = true) {
  if (canSpawnSquad == null || readiness == null)
    return mkTextArea(loc("respawn/squadNotChoosen"))

  let descKeyId = !canSpawnSquad && readiness == 100 ? "respawn/squadNotParticipate"
    : !canSpawnSquad ? "respawn/squadNotReady"
    : !canSpawnSoldier ? "respawn/soldierNotReady"
    : readiness == 100 ? "respawn/squadReady"
    : "respawn/squadPartiallyReady"
  return mkTextArea(loc(descKeyId, { number = readiness }))
}

let mkSquadSpawnIcon = @(size = hdpxi(20))
  {
    rendObj = ROBJ_IMAGE
    margin = smallPadding
    hplace = ALIGN_RIGHT
    size = [size, size]
    keepAspect = true
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
    keepAspect = true
    image = Picture(img)
  }.__update(override)
}

let squadBgColor = @(flags, selected, hasAlertStyle = false)
  selected ? activeBgColor
    : flags & S_HOVER ? hoverBgColor
    : hasAlertStyle ? Color(30,0,0,150) : defBgColor


let blockActiveBgColor = mul_color(activeBgColor, 0.5)
let blockHoverBgColor = mul_color(hoverBgColor, 0.5)
let squadBlockBgColor = @(flags, isSelected)
  isSelected ? blockActiveBgColor
    : flags & S_HOVER ? blockHoverBgColor
    : defBgColor

let mkCardText = @(t, sf, selected) txt({
  text = t
  color = txtColor(sf, selected)
})

let mkSquadTypeIcon = @(squadType, sf, selected, iconSize = squadTypeIconSize) {
  padding = [0, smallPadding]
  children = {
    size = [iconSize, iconSize]
    rendObj = ROBJ_IMAGE
    image = Picture("{0}:{1}:{1}:K".subst(getSquadTypeIcon(squadType), iconSize))
    keepAspect = true
    color = txtColor(sf, selected)
  }
}

let mkActiveBlock = @(sf, selected, content) {
  rendObj = ROBJ_SOLID
  size = SIZE_TO_CONTENT
  flow = FLOW_HORIZONTAL
  color = squadBlockBgColor(sf, selected)
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
        mkCardText(amount, sf, selected)
        mkCardText(fa["user-o"], sf, selected).__update({
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
      mkCardText(loc("level/short", { level = level + 1 }), sf, selected)
        .__update({ margin = smallPadding }))

let mkSquadPremIcon = @(premIcon, override = null) premIcon == null ? null : {
  rendObj = ROBJ_IMAGE
  size = [premIconSize, premIconSize]
  keepAspect = true
  image = Picture($"{premIcon}:{premIconSize}:{premIconSize}:K")
}.__update(override ?? {})


let timerIcon = "ui/skin#/battlepass/boost_time.svg"
let timerSize = hdpxi(18)

let squadTimer = {
  rendObj = ROBJ_IMAGE
  size = [timerSize, timerSize]
  margin = smallPadding
  image = Picture($"{timerIcon}:{timerSize}:{timerSize}:K")
  color = blinkingSignalsGreenDark
}

let mkSquadCard = kwarg(function (idx, isSelected, addChild = null, icon = "",
  squadType = null, squadSize = null, level = null, isFaded = false,
  premIcon = null, onClick = null, addedRightObj = null, mkChild = null,
  expireTime = 0
) {
  let stateFlags = Watched(0)
  let selected = isSelected.value
  icon = (icon ?? "").len() > 0 ? icon : defaultSquadIcon

  return function() {
    let sf = stateFlags.value
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
      rendObj = ROBJ_SOLID
      size = multySquadPanelSize
      color = squadBgColor(sf, selected)
      key = $"squad{idx}"
      behavior = Behaviors.Button
      xmbNode = XmbNode()
      opacity = isFaded ? 0.7 : 1.0
      onElemState = @(nsf) stateFlags(nsf)
      onClick = onClick
      watch = stateFlags
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
      ].append(topRightChilds)
    }
  }
})


return {
  txtColor
  mkSquadCard
  mkKeyboardHint
  mkSquadIcon
  mkSquadTypeIcon
  mkSquadPremIcon
  squadBgColor
  mkCardText
  mkActiveBlock
  mkSquadSpawnIcon
  mkSquadSpawnDesc
}
