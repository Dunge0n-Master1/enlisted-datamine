from "%enlSqGlob/ui_library.nut" import *


let { fontMedium } = require("%enlSqGlob/ui/fontsStyle.nut")
let { bigPadding, defTxtColor, colPart, accentColor, titleTxtColor, smallPadding, midPadding,
  colFull
} = require("%enlSqGlob/ui/designConst.nut")
let JB = require("%ui/control/gui_buttons.nut")
let mkTeamIcon = require("%ui/hud/components/teamIcon.nut")
let { Bordered } = require("%ui/components/txtButton.nut")
let { timeToRespawn, timeToCanRespawn, respEndTime, canRespawnTime, canRespawnWaitNumber,
  respRequested } = require("%ui/hud/state/respawnState.nut")
let armyData = require("%ui/hud/state/armyData.nut")
let armiesPresentation = require("%enlSqGlob/ui/armiesPresentation.nut")
let { localPlayerTeamIcon } = require("%ui/hud/state/teams.nut")
let colorize = require("%ui/components/colorize.nut")
let { mkHintRow } = require("%ui/components/uiHotkeysHint.nut")
let { missionName, missionType } = require("%enlSqGlob/missionParams.nut")


let defTxtStyle = { color = defTxtColor }.__update(fontMedium)
let titleTxtStyle = { color = titleTxtColor }.__update(fontMedium)
let sIconSize = colPart(0.24)
let commonBlockWidth = colFull(4) + bigPadding * 2

let requestRespawn = @() respRequested(true)
let cancelRequestRespawn = @() respRequested(false)


let playerArmyIcon = Computed(function() {
  let { armyId = null } = armyData.value
  let armyIcon = armiesPresentation?[armyId].icon
  if (armyIcon != null)
    return "!ui/skin#{0}".subst(armyIcon)

  return localPlayerTeamIcon.value
})

let teamIcon = mkTeamIcon(playerArmyIcon, colPart(0.6))


let respAnims = [
  { prop=AnimProp.scale, from = [0, 0], to = [1, 1],
    duration=0.25, play = true, easing = InOutCubic }
  { prop=AnimProp.opacity, from = 0, to = 1,
    duration = 0.25, play = true, easing = InOutCubic }
  { prop=AnimProp.scale, from = [1, 1], to = [0,0],
    duration = 0.25, playFadeOut = true, easing = OutCubic }
  { prop=AnimProp.opacity, from = 1, to = 0,
    duration = 0.25, playFadeOut = true, easing = OutCubic }
]


let squadNameBlock = @(squadLoc, titleTxtStyle) {
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_HORIZONTAL
  gap = bigPadding
  valign = ALIGN_CENTER
  children = [
    teamIcon
    {
      size = [flex(), SIZE_TO_CONTENT]
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      text = loc($"squad/{squadLoc}")
      halign = ALIGN_CENTER
    }.__update(titleTxtStyle)
  ]
}


let respawnTimer = @(locId) function() {
  let respawnTime = timeToRespawn.value
  let res = { watch = timeToRespawn }
  if (respawnTime <= 0)
    return res

  return res.__update({
    size = [flex(), SIZE_TO_CONTENT]
    halign = ALIGN_CENTER
    rendObj = ROBJ_TEXTAREA
    behavior = Behaviors.TextArea
    text = loc(locId, { time = colorize(accentColor, respawnTime) })
  }, titleTxtStyle)
}


let spawnButton = @(timeLeft) Bordered(
  "{0}{1}".subst(loc("Go!"), timeLeft ? " ({0})".subst(timeLeft) : ""),
  requestRespawn,
  { hotkeys = [["^J:Y | Space | Enter | @Human.Use"]] })

let cancelSpawnButton = @(timeLeft) Bordered(
  "{0}{1}".subst(loc("pressToCancel"), timeLeft ? " ({0})".subst(timeLeft) : ""),
  cancelRequestRespawn,
  { hotkeys = [[$"^{JB.B} | Esc | @Human.Use"]] })

let forceSpawnButton = @() {
  watch = [timeToCanRespawn, respEndTime, canRespawnTime, canRespawnWaitNumber, respRequested]
  size = [flex(), SIZE_TO_CONTENT]
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = canRespawnWaitNumber.value > 0 ? null
    : respRequested.value ? cancelSpawnButton(timeToCanRespawn.value)
    : respEndTime.value > 0 && respEndTime.value - canRespawnTime.value <= 1 ? null
    : spawnButton(timeToCanRespawn.value)
}


let function mkSquadSpawnDesc(canSpawnSquad, canSpawnSoldier) {
  let desc = !canSpawnSquad ? "respawn/squadNotParticipate"
      : !canSpawnSquad ? "respawn/squadNotReady"
      : !canSpawnSoldier ? "respawn/soldierNotReady"
      : "respawn/squadReady"
  return {
    size = [flex(), SIZE_TO_CONTENT]
    rendObj = ROBJ_TEXTAREA
    behavior = Behaviors.TextArea
    halign = ALIGN_CENTER
    text = loc(desc)
  }.__update(titleTxtStyle)
}

let mkKeyboardHint = @(keyBordKey, postKeyTxt = null){
  size = [flex(), SIZE_TO_CONTENT]
  hplace = ALIGN_CENTER
  halign = ALIGN_CENTER
  flow = FLOW_VERTICAL
  gap = smallPadding
  children = [
    mkHintRow(keyBordKey, { color = accentColor })
    {
      rendObj = ROBJ_TEXT
      text = postKeyTxt
    }.__update(titleTxtStyle)
  ]
}


let backgroundColor = 0x881E2227
let bgConfig = {
  rendObj = ROBJ_SOLID
  color = backgroundColor
  padding = [midPadding, bigPadding]
}

let function missionNameUI() {
  let res = { watch = missionName }
  if (missionName.value == null)
    return res
  return res.__update({
    size = [commonBlockWidth, SIZE_TO_CONTENT]
    hplace = ALIGN_RIGHT
    children = {
      size = [flex(), SIZE_TO_CONTENT]
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      text = loc(missionName.value, {
        mission_type = loc($"missionType/{missionType.value}") })
    }.__update(titleTxtStyle)
  }.__update(bgConfig))
}


let respawnHint = @(text) text == null ? null : {
  size = [commonBlockWidth, SIZE_TO_CONTENT]
  hplace = ALIGN_CENTER
  pos = [0, colPart(1)]
  children = {
    size = [flex(), SIZE_TO_CONTENT]
    rendObj = ROBJ_TEXTAREA
    behavior = Behaviors.TextArea
    halign = ALIGN_CENTER
    text = text
  }.__update(titleTxtStyle)
}.__update(bgConfig)



return {
  squadNameBlock
  respawnTimer
  forceSpawnButton
  mkSquadSpawnDesc
  mkKeyboardHint
  bgConfig
  respAnims
  defTxtStyle
  titleTxtStyle
  sIconSize
  commonBlockWidth
  missionNameUI
  respawnHint
}
