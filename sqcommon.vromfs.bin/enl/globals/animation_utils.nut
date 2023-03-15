from "%enlSqGlob/ui_library.nut" import *

let remapWeaponToAnimState = require("menu_poses_for_weapons.nut")
let { rnd } = require("dagor.random")
let { split_by_chars } = require("string")

const SITTING_ORDER = 7

let function getWeapTemplate(template){
  assert(type(template)=="string")
  return split_by_chars(template, "+")?[0] ?? template
}

let SLOTS_ORDER = ["primary", "secondary", "tertiary"]
let firstAvailableWeapon = @(tmpls)
  tmpls?[SLOTS_ORDER.findvalue(@(key) (tmpls?[key] ?? "") != "")] ?? ""

let function getAnimationBlacklist(itemTemplates) {
  let animationBlacklist = {}
  foreach (itemTemplate in itemTemplates) {
    let itemAnimationBlacklist = itemTemplate.getCompValNullable("animationBlacklistForMenu")
    if (itemAnimationBlacklist == null)
      continue
    foreach (anim in itemAnimationBlacklist) {
      animationBlacklist[anim] <- true
    }
  }
  return animationBlacklist
}

local function getIdleAnimState(weapTemplates, itemTemplates = null, overridedIdleAnims = null, seed = null, order = null) {
  seed = seed ?? rnd()
  if (seed < 0)
    seed = -seed

  local idle = overridedIdleAnims?.defaultPoses ?? remapWeaponToAnimState.defaultPoses
  let weaponTemplate = getWeapTemplate(firstAvailableWeapon(weapTemplates))
  if (weaponTemplate == "")
    idle = overridedIdleAnims?.unarmedPoses.getAll() ?? remapWeaponToAnimState?.unarmedPoses ?? idle
  else if (order == null || order < SITTING_ORDER)
    idle = overridedIdleAnims?[weaponTemplate].getAll() ?? remapWeaponToAnimState?[weaponTemplate] ?? idle
  else
    idle = overridedIdleAnims?.sittingPoses.getAll() ?? remapWeaponToAnimState?.sittingPoses ?? idle

  if (itemTemplates != null) {
    idle = clone idle
    let animationBlacklist = getAnimationBlacklist(itemTemplates)
    for (local i = idle.len() - 1; i >= 0; --i)
      if (idle[i] in animationBlacklist)
        idle.remove(i)
  }

  return idle.len() > 0 ? idle[seed % idle.len()] : remapWeaponToAnimState.defaultPoses.top()
}

return {
  getWeapTemplate
  getIdleAnimState = kwarg(getIdleAnimState)
}
