from "%enlSqGlob/ui_library.nut" import *

let colorize = require("%ui/components/colorize.nut")
let { fontSub } = require("%enlSqGlob/ui/fontsStyle.nut")
let JB = require("%ui/control/gui_buttons.nut")
let cursors = require("%ui/style/cursors.nut")
let { textarea } = require("%ui/components/textarea.nut")
let mkTeamIcon = require("%ui/hud/components/teamIcon.nut")
let { Accented } = require("%ui/components/txtButton.nut")
let { Transp } = require("%ui/components/textButton.nut")
let { timeToRespawn, timeToCanRespawn, respEndTime, canRespawnTime, canRespawnWaitNumber,
  respRequested, paratroopersPointSelectorOn } = require("%ui/hud/state/respawnState.nut")
let armyData = require("%ui/hud/state/armyData.nut")
let armiesPresentation = require("%enlSqGlob/ui/armiesPresentation.nut")
let { localPlayerTeamIcon } = require("%ui/hud/state/teams.nut")
let { midPadding, attentionTxtColor, darkPanelBgColor } = require("%enlSqGlob/ui/designConst.nut")


let playerArmyIcon = Computed(function() {
  let { armyId = null } = armyData.value
  let armyIcon = armiesPresentation?[armyId].icon
  if (armyIcon != null)
    return "!ui/skin#{0}".subst(armyIcon)

  return localPlayerTeamIcon.value
})

let iconSize = hdpxi(32)
let teamIcon = mkTeamIcon(playerArmyIcon, iconSize)

let wndPadding = fsh(1)

let respAnims = [
  { prop=AnimProp.scale, from=[0,0], to=[1,1], duration=0.25, play=true, easing=InOutCubic }
  { prop=AnimProp.opacity, from=0, to=1, duration=0.25, play=true, easing=InOutCubic }
  { prop=AnimProp.scale, from=[1,1], to=[0,0], duration=0.25, playFadeOut=true, easing=OutCubic }
  { prop=AnimProp.opacity, from=1, to=0, duration=0.25, playFadeOut=true, easing=OutCubic }
]

let panel = @(content, menuOverride = {}) {
  halign = ALIGN_LEFT
  valign = ALIGN_CENTER
  size = flex()
  cursor = cursors.normal
  children = {
    key = "RespawnBlock"
    size = [fsh(30), SIZE_TO_CONTENT]
    rendObj = ROBJ_WORLD_BLUR
    color = Color(110,110,110)
    margin = [fsh(3), fsh(4)]
    padding = wndPadding
    gap = wndPadding
    flow = FLOW_VERTICAL
    halign = ALIGN_CENTER
    children = content
    transform = {}
    animations = respAnims
  }.__update(menuOverride)
}

let headerBlock = @(text) {
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_HORIZONTAL
  gap = wndPadding
  padding = midPadding
  valign = ALIGN_CENTER
  rendObj = ROBJ_SOLID
  color = darkPanelBgColor
  children = [
    teamIcon
    textarea(text, { size = [flex(), SIZE_TO_CONTENT] }.__update(fontSub))
  ]
}

let squadBlock = @(squadName) textarea(squadName,
  {
    size = [flex(), SIZE_TO_CONTENT]
    padding = wndPadding
    halign = ALIGN_CENTER
  }.__update(fontSub))

let respawnTimer = @(text, params = {}) @() textarea(
  timeToRespawn.value ? $"{text}{colorize(attentionTxtColor, timeToRespawn.value)}" : null,
  {
    watch = timeToRespawn
    size = [flex(), SIZE_TO_CONTENT]
    halign = ALIGN_CENTER
  }.__update(params))

let requestRespawn = @() respRequested(true)
let cancelRequestRespawn = @() respRequested(false)
let forceSpawnStateFlags = Watched(0)


let mtTxtWithTime = @(locId, tLeft) "{0}{1}".subst(loc(locId), tLeft ? $" ({tLeft})" : "")

let spawnButton = @(tLeft) Accented(mtTxtWithTime("Go!", tLeft),
  requestRespawn, {
    hotkeys = [["^J:Y | Space | Enter | @Human.Use"]]
    margin = 0
    minWidth = fsh(25)
    stateFlags = forceSpawnStateFlags
    key = "forceSpawnButton"
  })

let cancelSpawnButton = @(tLeft) Transp(mtTxtWithTime("pressToCancel", tLeft),
  cancelRequestRespawn, {
    hotkeys = [[$"^{JB.B} | Esc | @Human.Use"]]
    margin = 0
    textMargin = fsh(1)
    stateFlags = forceSpawnStateFlags
    key = "cancelSpawnButton"
  })

let forceSpawnButton = @(override = {}) @() {
  watch = [timeToCanRespawn, respEndTime, canRespawnTime, canRespawnWaitNumber, respRequested]
  size = [flex(), SIZE_TO_CONTENT]
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = canRespawnWaitNumber.value > 0 ? null
    : respRequested.value ? cancelSpawnButton(timeToCanRespawn.value)
    : (respEndTime.value > 0 && respEndTime.value - canRespawnTime.value <= 1) && !paratroopersPointSelectorOn.value ? null
    : spawnButton(timeToCanRespawn.value)
}.__update(override)

return {
  panel
  headerBlock
  squadBlock
  respawnTimer
  forceSpawnButton
}
