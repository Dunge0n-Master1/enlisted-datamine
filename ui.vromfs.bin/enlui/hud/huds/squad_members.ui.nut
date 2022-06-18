from "%enlSqGlob/ui_library.nut" import *

let { sub_txt, tiny_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let { fabs } = require("math")
let {
  watchedHeroSquadMembers, selectedBotForOrderEid, isPersonalContextCommandMode
} = require("%ui/hud/state/squad_members.nut")
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
let { ESFN_CLOSEST, ESFN_WIDE } = require("ai")
let { squadBehaviour } = require("%ui/hud/state/squad_behaviour.nut")
let { ESB_PASSIVE } = require("%enlSqGlob/dasenums.nut")

let sIconSize = hdpx(15).tointeger()
let iconSize = hdpx(40).tointeger()
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

let blurBack = {
  size = flex()
  rendObj = ROBJ_WORLD_BLUR
  color = Color(220, 220, 220, 220)
}

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

let function splitOnce(name) {
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
    ? name
    : $"{name.slice(0, found)}\n{name.slice(found + 1)}"
}

let memberName = @(member) {
  size = [SIZE_TO_CONTENT, iconSize]
  valign = ALIGN_CENTER
  clipChildren = true
  children = [
    blurBack
    {
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      text = (member?.callname ?? "") != ""
        ? splitOnce(member.callname)
        : splitOnce(member.name)
      color = SUCCESS_TEXT_COLOR
      indent = gap
      transform = {}
      animations = [
        { prop = AnimProp.translate, from = [-hdpx(100), 0], to = [0, 0], duration = 0.2, easing = OutCubic, play = true }
      ]
    }.__update(tiny_txt)
  ]
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

let killRow = @(member) {
  key = member.eid
  hplace = ALIGN_RIGHT
  flow = FLOW_HORIZONTAL
  gap = smallGap
  children = [
    {
      size = [sIconSize, sIconSize]
      rendObj = ROBJ_IMAGE
      image = Picture("ui/skin#kills_icon.svg:{0}:{0}:K".subst(sIconSize))
    }
    {
      children = [
        blurBack
        {
          minWidth = sIconSize
          halign = ALIGN_CENTER
          rendObj = ROBJ_TEXT
          color = DEFAULT_TEXT_COLOR
          text = member.kills

          animations = [{ prop = AnimProp.color, from = SUCCESS_TEXT_COLOR, to = DEFAULT_TEXT_COLOR,
            duration = 5, easing = InOutCubic, trigger = $"member_kill_{member.eid}" }]
        }.__update(tiny_txt)
      ]
    }
  ]

  transform = {}
  animations = [{ prop = AnimProp.scale, from = [1,1], to = [2,2], duration = 0.5, easing = CosineFull,
      trigger = $"member_kill_{member.eid}" }]
}

let selectedBotArrowSize = [hdpx(40), hdpx(14)]
let selectedBotArrow = {
  size = selectedBotArrowSize
  hplace = ALIGN_CENTER
  rendObj = ROBJ_IMAGE
  image = Picture($"ui/skin#squad_member_selected.svg:{selectedBotArrowSize[0].tointeger()}:{selectedBotArrowSize[1].tointeger()}")
  color = SUCCESS_TEXT_COLOR
}

let selectedBotArrowDummy = {size = selectedBotArrowSize}

let personalOrderMarkerSize = [hdpx(16), hdpx(16)]
let personalOrderMarker = {
  size = personalOrderMarkerSize
  hplace = ALIGN_CENTER
  rendObj = ROBJ_IMAGE
  image = Picture($"ui/skin#white_circle.svg:{personalOrderMarkerSize[0].tointeger()}:{personalOrderMarkerSize[1].tointeger()}")
  color = SUCCESS_TEXT_COLOR
}

let memberUi = @(member) function() {
  let isSelf = member.eid == controlledHeroEid.value
  let isAliveAI = !isSelf && member.isAlive && member.hasAI
  let isSelectedForOrder = (isAliveAI && member.eid == selectedBotForOrderEid.value)
  return {
    flow = FLOW_VERTICAL
    vplace = ALIGN_BOTTOM
    gap = smallGap
    watch = [controlledHeroEid, selectedBotForOrderEid, isPersonalContextCommandMode]

    children = [
      member.isPersonalOrder ? personalOrderMarker : null
      {
        flow = FLOW_HORIZONTAL

        children = [
          {
            size = [iconSize, SIZE_TO_CONTENT]
            flow = FLOW_VERTICAL
            gap = smallGap
            children = [
              statusIcon(member, isSelf)
              killRow(member)
              isAliveAI || isSelf ? equipmentStatusRow(member) : equipmentStatusRowDummy
              !isPersonalContextCommandMode.value ? null
                : isSelectedForOrder ? selectedBotArrow
                : selectedBotArrowDummy
            ]
          }
          isSelf && member.isAlive ? memberName(member) : null
        ]
      }
    ]
  }
}

let squadMembersList = @(squadMembersV) {
  flow = FLOW_HORIZONTAL
  gap = gap
  children = squadMembersV.map(memberUi)
}

let squadStatusIconSize = [hdpx(26), hdpx(26)]
let mkSquadStatusIcon = @(icon) {
  hplace = ALIGN_CENTER
  rendObj = ROBJ_IMAGE
  image = Picture($"{icon}:{squadStatusIconSize[0].tointeger()}:{squadStatusIconSize[1].tointeger()}")
}

let squadFormationIcons = {
  [ESFN_CLOSEST] = mkSquadStatusIcon("ui/skin#squad_formation_closest.svg"),
  [ESFN_WIDE] = mkSquadStatusIcon("ui/skin#squad_formation_wide.svg")
}

let squadBehaviourIcons = {
  [ESB_PASSIVE] = mkSquadStatusIcon("ui/skin#squad_behaviour_passive.svg")
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
  watch = isPersonalContextCommandMode

  children = [
    isPersonalContextCommandMode.value
      ? tipCmp({
          text = loc("squad_orders/switch_bot_for_order"),
          inputId = "Human.SwitchBotForOrders"
        }.__update(sub_txt))
      : null

    cancelContextCommandHint
    contextCommandHint

    {
      flow = FLOW_VERTICAL

      children = [
        tipCmp({
          text = loc("controls/Human.SwitchContextCommandMode"),
          inputId = "Human.SwitchContextCommandMode"
        }.__update(sub_txt))
        tipCmp({
          text = loc("controls/HUD.SquadSoldiersMenu"),
          inputId = "HUD.SquadSoldiersMenu"
        }.__update(sub_txt))
      ]
    }
  ]
}

let function members() {
  let res = {
    watch = [
      watchedHeroSquadMembers, canChangeRespawnParams, inVehicle
    ]
  }
  if (watchedHeroSquadMembers.value.len() <= 1 || canChangeRespawnParams.value || inVehicle.value)
    return res

  return res.__update({
    flow = FLOW_VERTICAL
    gap = gap
    children = [
      squadStatus
      squadMembersList(watchedHeroSquadMembers.value)
      isSpectatorEnabled.value ? null : squadControlHints
    ]
  })
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
