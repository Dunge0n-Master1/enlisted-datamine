from "%enlSqGlob/ui_library.nut" import *

let { curSoldierGuid } = require("squadInfoState.nut")
let { genPerksPointsStatistics } = require("playerStatistics.nut")
let { resetProfile, dumpProfile } = require("state.nut")
let { get_all_configs, premium_add, premium_remove, add_exp_to_soldiers, add_perk_points,
  reset_mutations_timestamp, check_purchases, inventory_add_item, appearance_change,
  soldier_train, remove_item, decrease_purchases_count, apply_profile_mutation,
  apply_freemium_soldier
} = require("%enlist/meta/clientApi.nut")
let { selectedSoldierGuid } = require("chooseSoldiersState.nut")
let { soldierReset, soldierResetAll, isSoldierDisarmed, setSoldierDisarmed, setSoldierIdle,
  switchSoldierIdle, setSoldierHead, switchSoldierHead, setSoldierFace, switchSoldierFace,
  isSoldierSlotsSwap, setSoldierSlotsSwap
} = require("%enlist/scene/soldier_overrides.nut")
let userInfo = require("%enlSqGlob/userInfo.nut")

let curSoldier = Computed(@() selectedSoldierGuid.value ?? curSoldierGuid.value)

console_register_command(
  function(exp) {
    let guid = curSoldier.value
    if (exp <= 0)
      log_for_user("Unable to substract exp")
    else if (!guid)
      log_for_user("Select soldier in squad list")
    else
      add_exp_to_soldiers({ [guid] = exp }, log_for_user)
  },
  "meta.addCurSoldierExp")

console_register_command(function(count) {
  let guid = curSoldier.value
  if (!guid)
    log_for_user("Select soldier in squad list")
  else
    add_perk_points(guid, count, log_for_user)
}, "meta.addCurSoldierPerkPoints")

console_register_command(function(steps) {
  let guid = curSoldier.value
  if (guid)
    soldier_train(guid, steps, log_for_user)
  else
    log_for_user("Select soldier in squad list")
}, "meta.trainCurSoldier")

console_register_command(@() appearance_change(curSoldier.value), "meta.changeSoldierAppearance")

console_register_command(@()
  console_print($"{userInfo.value.nameorig}:{userInfo.value.userId}"), "whoami")
console_register_command(@() resetProfile(), "meta.resetProfile")
console_register_command(@() dumpProfile(), "meta.dumpProfile")
console_register_command(@() reset_mutations_timestamp(), "meta.resetMutationsTimestamp")
console_register_command(@(key) apply_profile_mutation(key), "meta.applyMutation")
console_register_command(@() check_purchases(), "meta.check_purchases")

console_register_command(@(sTier, count, genId) genPerksPointsStatistics(sTier, count, genId), "stat.perksPoints")

console_register_command(@() get_all_configs(), "meta.getAllConfigs")

console_register_command(@(durationSec) premium_add(durationSec), "meta.cheatPremiumAdd")

console_register_command(@(durationSec) premium_remove(durationSec), "meta.cheatPremiumRemove")

console_register_command(soldierResetAll, "soldier.resetOverrideAll")
console_register_command(@() soldierReset(curSoldier.value), "soldier.resetOverrideCurrent")

console_register_command(@()
  setSoldierDisarmed(curSoldier.value, !isSoldierDisarmed(curSoldier.value)),
  "soldier.disarmedToggle")

console_register_command(@()
  setSoldierSlotsSwap(curSoldier.value, !isSoldierSlotsSwap(curSoldier.value)),
  "soldier.swapToggle")

console_register_command(@(anim) setSoldierIdle(curSoldier.value, anim), "soldier.idleSet")
console_register_command(@() switchSoldierIdle(curSoldier.value, 1), "soldier.idleNext")
console_register_command(@() switchSoldierIdle(curSoldier.value, -1), "soldier.idlePrev")

console_register_command(@(anim) setSoldierHead(curSoldier.value, anim), "soldier.headSet")
console_register_command(@() switchSoldierHead(curSoldier.value, 1), "soldier.headNext")
console_register_command(@() switchSoldierHead(curSoldier.value, -1), "soldier.headPrev")

console_register_command(@(anim) setSoldierFace(curSoldier.value, anim), "soldier.faceSet")
console_register_command(@() switchSoldierFace(curSoldier.value, 1), "soldier.faceNext")
console_register_command(@() switchSoldierFace(curSoldier.value, -1), "soldier.facePrev")

console_register_command(@(itemdef) inventory_add_item(itemdef), "meta.cheatInvAddItem")


console_register_command(@(itemGuid) remove_item(itemGuid), "meta.removeItem")
console_register_command(remove_item, "meta.removeItemWithCount")
console_register_command(decrease_purchases_count, "meta.cheatDecreasePurchasesCount")

console_register_command(@() apply_freemium_soldier(curSoldier.value), "freemium.applySoldier")
console_register_command(@(level)
  apply_freemium_soldier(curSoldier.value, level), "freemium.applySoldierLevel")
