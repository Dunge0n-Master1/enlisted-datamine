from "%enlSqGlob/ui_library.nut" import *

let { HIT_RES_KILLED, HIT_RES_DOWNED, HIT_RES_NORMAL } = require("dm")
let { HEAL_RES_COMMON, HEAL_RES_REVIVE, ATTACK_RES } = require("%ui/hud/state/squad_members.nut")
let { DEFAULT_TEXT_COLOR, DEAD_TEXT_COLOR } = require("%ui/hud/style.nut")
let { mkGrenadeIcon } = require("%ui/hud/huds/player_info/grenadeIcon.nut")
let { mkMineIcon } = require("%ui/hud/huds/player_info/mineIcon.nut")
let { mkMedkitIcon } = require("%ui/hud/huds/player_info/medkitIcon.nut")
let { mkFlaskIcon } = require("%ui/hud/huds/player_info/flaskIcon.nut")
let { kindIcon } = require("%enlSqGlob/ui/soldiersUiComps.nut")
let { controlledHeroEid } = require("%ui/hud/state/controlled_hero.nut")
let {AI_ACTION_UNKNOWN, AI_ACTION_STAND, AI_ACTION_HEAL,
  AI_ACTION_HIDE, AI_ACTION_MOVE, AI_ACTION_ATTACK, AI_ACTION_IN_COVER, AI_ACTION_RELOADING, AI_ACTION_DOWNED} = require("ai")

let calcIconHpColor = @(ratio, defColor) ratio < 0.3 ? Color(200,50,50)
  : ratio < 0.75 ? Color(200,100,100)
  : defColor

let mkGrenadeIconByMember = @(member, size) member.isAlive && member.grenadeType != null
  ? mkGrenadeIcon(member.grenadeType, size)
  : null

let mkMineIconByMember = @(member, size) member.isAlive && member.mineType != null
  ? mkMineIcon(member.mineType, size)
  : null

let mkMemberHealsBlock = @(member, size) member.isAlive && member.targetHealCount > 0
  ? mkMedkitIcon(size)
  : null

let mkMemberFlaskBlock = @(member, size) member.isAlive && member.hasFlask
  ? mkFlaskIcon(size)
  : null

let animByTrigger = @(color, time, trigger) trigger
  ? { prop=AnimProp.color, from=color, easing=OutCubic, duration=time, trigger=trigger }
  : null

let aiActionIcons = {
  [AI_ACTION_UNKNOWN] = null,
  [AI_ACTION_STAND]   = "stand_icon.svg",
  [AI_ACTION_HEAL]    = "healing_icon.svg",
  [AI_ACTION_HIDE]    = "hide_tree_icon.svg",
  [AI_ACTION_MOVE]    = "move_icon.svg",
  [AI_ACTION_ATTACK]  = "attack_icon.svg",
  [AI_ACTION_IN_COVER]  = "stand_icon.svg",
  [AI_ACTION_RELOADING]  = "semiauto_rifle.svg",
  [AI_ACTION_DOWNED]  = "heartbeat.svg",
}

let mkAiImage = memoize(function(image, size) {
  return Picture($"ui/skin#{image}:{size}:{size}:K")
})

let function mkAiActionIcon(member, size) {
  let image = aiActionIcons?[member.currentAiAction]
  if (member.eid == controlledHeroEid.value || !member.isAlive || !member.hasAI || !image)
    return null

  return {
    hplace = ALIGN_RIGHT
    vplace = ALIGN_BOTTOM
    size = [size, size]
    rendObj = ROBJ_IMAGE
    image = mkAiImage(image, size)
    color = member.maxHp > 0 ? calcIconHpColor(member.hp / member.maxHp, 0xFFFFFFFF) : 0xFFFFFFFF
    animations = [
      animByTrigger(Color(200, 0, 0, 200), 1.0, member.hitTriggers[HIT_RES_NORMAL])
      animByTrigger(Color(200, 0, 0, 200), 1.0, member.hitTriggers[ATTACK_RES])
    ]
  }
}
let deaths = freeze({
        rendObj = ROBJ_IMAGE
        size = flex()
        vplace = ALIGN_CENTER
        image = Picture("ui/skin#lb_deaths.avif")
        tint = DEAD_TEXT_COLOR
      })

let mkStatusIcon = @(member, size, color=DEFAULT_TEXT_COLOR) {
  size = flex()
  animations = [
    animByTrigger(Color(200, 0, 0, 200), 1.0, member?.hitTriggers[HIT_RES_NORMAL])
    animByTrigger(Color(200, 100, 0, 200), 3.0, member?.hitTriggers[HIT_RES_DOWNED])
    animByTrigger(Color(200, 0, 0, 200), 3.0, member?.hitTriggers[HIT_RES_KILLED])
    animByTrigger(Color(0, 200, 100, 200), 1.0, member?.hitTriggers[HEAL_RES_COMMON])
    animByTrigger(Color(0, 100, 200, 200), 3.0, member?.hitTriggers[HEAL_RES_REVIVE])
  ]
  children = member.isAlive
    ? kindIcon(member?.sKind, size, member?.sClassRare).__update({color, vplace = ALIGN_CENTER})
    : deaths
}

return {
  mkGrenadeIcon = mkGrenadeIconByMember
  mkMineIcon = mkMineIconByMember
  mkMemberHealsBlock
  mkStatusIcon
  mkAiActionIcon
  mkMemberFlaskBlock
}