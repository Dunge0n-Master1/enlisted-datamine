from "%enlSqGlob/ui_library.nut" import *

let { fontSub } = require("%enlSqGlob/ui/fontsStyle.nut")
let { fabs } = require("math")
let {
  watchedHeroSquadMembers, selectedBotForOrderEid, isPersonalContextCommandMode,
  watchedHeroSquadMembersGetWatched, watchedHeroSquadMembersOrderedSet
} = require("%ui/hud/state/squad_members.nut")
let { isSquadSoldiersMenuAvailable } = require("%ui/hud/state/squad_soldiers_menu_state.nut")
let { controlledHeroEid } = require("%ui/hud/state/controlled_hero.nut")
let { inVehicle } = require("%ui/hud/state/vehicle_state.nut")
let { SUCCESS_TEXT_COLOR, DEFAULT_TEXT_COLOR } = require("%ui/hud/style.nut")
let {
  canChangeRespawnParams, isSpectatorEnabled
} = require("%ui/hud/state/respawnState.nut")
let {
  mkGrenadeIcon, mkMineIcon, mkMemberHealsBlock, mkStatusIcon, mkAiActionIcon
} = require("%ui/hud/components/squad_member.nut")
let {tipCmp} = require("%ui/hud/huds/tips/tipComponent.nut")
let contextCommandHint = require("%ui/hud/huds/context_command_hint.ui.nut")
let cancelContextCommandHint = require("%ui/hud/huds/cancel_context_command_hint.ui.nut")
let { squadFormation } = require("%ui/hud/state/squad_formation.nut")
let { squadBehaviour } = require("%ui/hud/state/squad_behaviour.nut")
let { SquadBehaviour, SquadFormationSpread } = require("%enlSqGlob/dasenums.nut")
let { showTips } = require("%ui/hud/state/hudOptionsState.nut")

let sIconSize = hdpxi(15)
let iconSize = hdpxi(40)
let gap = hdpx(5)
let smallGap = hdpx(2)


local wasKills = {}
let function updateKillsAnim() {
  let kills = {}
  foreach (m in watchedHeroSquadMembers.value) {
    kills[m.eid] <- m.kills
    if (m.kills > (wasKills?[m.eid] ?? 0))
      anim_start($"member_kill_{m.eid}")
  }
  wasKills = kills
}
updateKillsAnim()
watchedHeroSquadMembers.subscribe(@(_) updateKillsAnim())

let blurBack = freeze({
  size = flex()
  rendObj = ROBJ_WORLD_BLUR
  color = Color(220, 220, 220, 220)
})

let function statusIcon(member, isSelf) {
  return {
    size = [iconSize, iconSize]
    children = [
      blurBack
      mkStatusIcon(member, iconSize, isSelf ? SUCCESS_TEXT_COLOR : DEFAULT_TEXT_COLOR)
      mkAiActionIcon(member, sIconSize)
    ]
  }
}

let splitOnce = memoize(function(name) {
  local idx = name.indexof(" ")
  local found = null
  local minDist = name.len()
  let middle = minDist / 2
  while (idx != null) {
    let dist = fabs(middle - idx)
    if (dist < minDist) {
      found = idx
      minDist = dist
    }
    idx = name.indexof(" ", idx + 1)
  }
  return found == null
    ? [name]
    : [name.slice(0, found), name.slice(found + 1)]
})

let memberNameAnimations = freeze([
  { prop = AnimProp.translate, from = [-hdpx(100), 0], to = [0, 0], duration = 0.2, easing = OutCubic, play = true }
])

let mkNamePart = @(text) {
  rendObj = ROBJ_TEXT
  text
  color = SUCCESS_TEXT_COLOR
  indent = gap
  transform = {}
  animations = memberNameAnimations
}.__update(fontSub)

let memberName = function(name) {
  let nameC = @() {
    watch = name
    flow = FLOW_VERTICAL
    children = splitOnce(name.value).map(mkNamePart)
  }

  return {
    size = [SIZE_TO_CONTENT, iconSize]
    valign = ALIGN_CENTER
    clipChildren = true
    children = [
      blurBack
      nameC
    ]
  }
}
let equipmentStatusRow = @(member) {
  hplace = ALIGN_RIGHT
  flow = FLOW_HORIZONTAL
  size = [SIZE_TO_CONTENT, sIconSize]
  gap = smallGap
  children = [
    mkMemberHealsBlock(member, sIconSize)
    mkGrenadeIcon(member, sIconSize) ?? mkMineIcon(member, sIconSize)
  ]
}

let equipmentStatusRowDummy = { size = [sIconSize, sIconSize] }
let killsIco = freeze({
  size = [sIconSize, sIconSize]
  rendObj = ROBJ_IMAGE
  image = Picture("ui/skin#kills_icon.svg:{0}:{0}:K".subst(sIconSize))
})

let killRow = @(eid, kills) {
  key = eid
  hplace = ALIGN_RIGHT
  flow = FLOW_HORIZONTAL
  gap = smallGap
  children = [
    killsIco
    {
      children = [
        blurBack
        {
          minWidth = sIconSize
          halign = ALIGN_CENTER
          rendObj = ROBJ_TEXT
          color = DEFAULT_TEXT_COLOR
          text = kills

          animations = [{ prop = AnimProp.color, from = SUCCESS_TEXT_COLOR, to = DEFAULT_TEXT_COLOR,
            duration = 5, easing = InOutCubic, trigger = $"member_kill_{eid}" }]
        }.__update(fontSub)
      ]
    }
  ]

  transform = {}
  animations = [{ prop = AnimProp.scale, from = [1,1], to = [2,2], duration = 0.5, easing = CosineFull, trigger = $"member_kill_{eid}" }]
}

let selectedBotArrowSize = [hdpxi(40), hdpxi(14)]
let selectedBotArrow = {
  size = selectedBotArrowSize
  hplace = ALIGN_CENTER
  rendObj = ROBJ_IMAGE
  image = Picture($"ui/skin#squad_member_selected.svg:{selectedBotArrowSize[0]}:{selectedBotArrowSize[1]}")
  color = SUCCESS_TEXT_COLOR
}

let selectedBotArrowDummy = {size = selectedBotArrowSize}

let personalOrderMarkerSize = [hdpxi(16), hdpxi(16)]
let personalOrderMarker = {
  size = personalOrderMarkerSize
  hplace = ALIGN_CENTER
  rendObj = ROBJ_IMAGE
  image = Picture($"ui/skin#white_circle.svg:{personalOrderMarkerSize[0]}:{personalOrderMarkerSize[1]}")
  color = SUCCESS_TEXT_COLOR
}

let memberUi = memoize(function(eid) {
  let state = watchedHeroSquadMembersGetWatched(eid)
  let isAliveState = Computed(@() state.value?.isAlive)
  let name = Computed(@() state.value?.callname ?? state.value?.name ?? "")
  let nameC = memberName(name)
  let isPersonalOrder = Computed(@() state.value?.isPersonalOrder)

  let dynamicInf = function(){
    let member = state.value
    if (member == null)
      return {watch = state}
    let {isAlive, hasAI, kills} = member
    let isSelf = eid == controlledHeroEid.value
    let isAliveAI = !isSelf && isAlive && hasAI
    let isSelectedForOrder = (isAliveAI && eid == selectedBotForOrderEid.value)
    return {
      watch = [selectedBotForOrderEid, isPersonalContextCommandMode, state]
      size = [iconSize, SIZE_TO_CONTENT]
      flow = FLOW_VERTICAL
      gap = smallGap
      children = [
        statusIcon(member, isSelf)
        killRow(eid, kills)
        isAliveAI || isSelf ? equipmentStatusRow(member) : equipmentStatusRowDummy
        !isPersonalContextCommandMode.value
          ? null
          : isSelectedForOrder
            ? selectedBotArrow
            : selectedBotArrowDummy
      ]
    }
  }
  let child = function(){
    return {
      flow = FLOW_HORIZONTAL
      watch = [controlledHeroEid, isAliveState]
      children = [
        dynamicInf
        eid==controlledHeroEid.value && isAliveState.value ? nameC : null
      ]
    }
  }
  return freeze({
    flow = FLOW_VERTICAL
    vplace = ALIGN_BOTTOM
    gap = smallGap
    children = [
      @() {watch = isPersonalOrder children = isPersonalOrder.value ? personalOrderMarker : null}
      child
    ]
  })
})

let squadMembersList = @() {
  watch = watchedHeroSquadMembersOrderedSet
  flow = FLOW_HORIZONTAL
  gap
  children = watchedHeroSquadMembersOrderedSet.value.map(memberUi)
}

let squadStatusIconSize = [hdpxi(26), hdpxi(26)]
let mkSquadStatusIcon = memoize(@(icon) {
  hplace = ALIGN_CENTER
  rendObj = ROBJ_IMAGE
  size = squadStatusIconSize
  image = Picture($"{icon}:{squadStatusIconSize[0]}:{squadStatusIconSize[1]}")
})

let squadFormationIcons = {
  [SquadFormationSpread.ESFN_CLOSEST] = mkSquadStatusIcon("ui/skin#squad_formation_closest.svg"),
  [SquadFormationSpread.ESFN_WIDE] = mkSquadStatusIcon("ui/skin#squad_formation_wide.svg")
}

let squadBehaviourIcons = {
  [SquadBehaviour.ESB_PASSIVE] = mkSquadStatusIcon("ui/skin#squad_behaviour_passive.svg")
}

let squadStatus = @() {
  flow = FLOW_HORIZONTAL
  gap = gap
  watch = [squadFormation, squadBehaviour]
  children = [
    squadFormationIcons?[squadFormation.value]
    squadBehaviourIcons?[squadBehaviour.value]
  ]
}


let squadControlHints = @() {
  minHeight = hdpx(20)
  hplace = ALIGN_CENTER
  flow = FLOW_VERTICAL
  watch = [isPersonalContextCommandMode, isSquadSoldiersMenuAvailable]

  children = [
    isPersonalContextCommandMode.value
      ? tipCmp({
          text = loc("squad_orders/switch_bot_for_order"),
          inputId = "Human.SwitchBotForOrders"
        }.__update(fontSub))
      : null

    cancelContextCommandHint
    contextCommandHint

    {
      flow = FLOW_VERTICAL

      children = [
        tipCmp({
          text = loc("controls/Human.SwitchContextCommandMode"),
          inputId = "Human.SwitchContextCommandMode"
        }.__update(fontSub))
        isSquadSoldiersMenuAvailable.value ? tipCmp({
          text = loc("controls/HUD.SquadSoldiersMenu"),
          inputId = "HUD.SquadSoldiersMenu"
        }.__update(fontSub)) : null
      ]
    }
  ]
}
let doNotShowMembers = Computed(@() watchedHeroSquadMembers.value.len() <= 1 || canChangeRespawnParams.value || inVehicle.value)

let function members() {
  if (doNotShowMembers.value)
    return {watch = doNotShowMembers}

  return {
    flow = FLOW_VERTICAL
    gap
    watch = [doNotShowMembers, isSpectatorEnabled, showTips]
    children = [
      squadStatus
      squadMembersList
      !showTips.value || isSpectatorEnabled.value ? null : squadControlHints
    ]
  }
}

console_register_command(function(hitr) {
  let trigger = watchedHeroSquadMembers.value?.top().hitTriggers[hitr]
  if (trigger != null)
    anim_start(trigger)
}, "hud.debugHitMember")

console_register_command(
  function() {
    let member = watchedHeroSquadMembers.value?.top()
    if (member != null)
      anim_start($"member_kill_{member.eid}")
  }
  "hud.debugMemberKills")

return members
