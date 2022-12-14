from "%enlSqGlob/ui_library.nut" import *

let eventbus = require("eventbus")
let { profile } = require("servProfile.nut")
let rand = require("%sqstd/rand.nut")()
let { updateAllConfigs } = require("%enlist/meta/configs.nut")
let { serverTimeUpdate } = require("%enlSqGlob/userstats/serverTimeUpdate.nut")
let { get_time_msec } = require("dagor.time")
let { logerr } = require("dagor.debug")
let logApi = require("%enlSqGlob/library_logs.nut").with_prefix("[ClientApi] ")

const MAX_REQUESTS_HISTORY = 20
const LONG_TIME = 100 // threshold for long requests and calls logging
let requestData = persist("requestData", @() { id = rand.rint(), callbacks = {}})
let debugDelay = mkWatched(persist, "debugDelay", 0)
let lastRequests = mkWatched(persist, "lastRequests", [])

let diffTime = @(time) get_time_msec() - time

let function handleMessages(msg) {
  let result = msg.data?.result
  let idStr = msg.id
  let cb = idStr in requestData.callbacks ? delete requestData.callbacks[idStr] : null
  local reqTime = 0
  local method

  lastRequests.mutate(function(v) {
    local data = v.findvalue(@(d) d.id == idStr)
    if (data == null) {
      data = { id = idStr, request = "unknown" }
      if (v.len() >= MAX_REQUESTS_HISTORY)
        v.remove(0)
      v.append(data)
    }
    data.resultKeys <- result?.keys()  //store only keys, because of data can be really big
    reqTime = data?.reqTime ?? 0
    method = data.request?.method ?? idStr
    let diff = diffTime(reqTime)
    if (diff > LONG_TIME)
      logApi($"TOO LONG request '{method}' takes {diff} ms")
  })

  if (!result) {
    let errorStr = msg.data?.error.message ?? "unknown error"
    if (cb)
      cb({ error = errorStr })
    return
  }

  let { timeMs = 0 } = result
  if (reqTime > 0 && timeMs > 0)
    serverTimeUpdate(timeMs, reqTime)

  if (result?.configs != null) {
    let curTime = get_time_msec()
    updateAllConfigs(result)
    delete result.configs
    logApi($"Config update takes {diffTime(curTime)} ms")
  }

  if (result?.full ?? false) {
    let curTime = get_time_msec()
    delete result.full
    if ("removed" in result) {
      logerr($"Not empty removed field on full profile update on '{method}'")
      delete result.removed
    }
    profile(result)
    logApi($"Full profile update on '{method}' takes {diffTime(curTime)} ms")
  }
  else if (typeof result == "table") {
    let found = result.findindex(@(tbl) type(tbl) == "table")
    if (found != null) {
      let curTime = get_time_msec()
      local count = 0
      local removed = 0
      profile.mutate(function(data) {
        foreach (k, v in result)
          if (type(v) == "table" && k != "removed") {
            ++count
            data[k] <- k in data ? data[k].__merge(v) : v
          }

        foreach (tableId, list in (result?.removed ?? {})) {
          if (tableId not in data) {
            logerr($"Trying to remove unknown table '{tableId}' from profile on '{method}'")
            continue
          }
          ++removed
          let tbl = clone data[tableId]
          foreach (fieldId in list)
            if (fieldId in tbl)
              delete tbl[fieldId]
          data[tableId] <- tbl
        }
      })
      logApi($"Profile updated:{count} deleted:{removed} tables of '{method}' takes {diffTime(curTime)} ms")
    }
  }

  if (cb) {
    let curTime = get_time_msec()
    cb(result)
    let diff = diffTime(curTime)
    if (diff > 0)
      logApi($"Handler call on '{method}' takes {diff} ms")
  }
}

eventbus.subscribe("profile_srv.response", handleMessages)

let function requestImpl(data, cb = null) {
  let idStr = (++requestData.id).tostring()
  if (cb)
    requestData.callbacks[idStr] <- cb

  lastRequests.mutate(function(v) {
    if (v.len() >= MAX_REQUESTS_HISTORY)
      v.remove(0)
    v.append({ id = idStr, request = data, reqTime = get_time_msec() })
  })

  eventbus.send("profile_srv.request", {id = idStr, data})
}

local request = requestImpl
let function updateDebugDelay() {
  request = (debugDelay.value <= 0) ? requestImpl
    : @(data, cb = null) gui_scene.setTimeout(debugDelay.value, @() requestImpl(data, cb))
}
updateDebugDelay()
debugDelay.subscribe(@(_) updateDebugDelay())

console_register_command(@(delay) debugDelay(delay), "pserver.delay_requests")
console_register_command(function() {
  logApi("lastRequests: ")
  debugTableData(lastRequests.value, { recursionLevel = 7 })
}, "pserver.debug_last_requests")

return {
  lastRequests

  update_profile  = @(cb = null, token = null) request({
    method = "get"
    token
  }, cb)

  get_all_configs = @(cb = null, token = null) request({
    method = "get_all_configs"
    token
  }, cb)

  check_purchases = @() request({
    method = "check_purchases"
  })

  get_userlogs = @(timestamp = 0, cb = null, token = null) request({
    method = "get_userlogs"
    token = token
    params = { timestamp }}, cb)

  equip_item = @(target, item, slot, index, cb = null) request({
    method = "equip_item"
    params = {
      target = target
      item = item
      slot = slot
      index = index ?? -1
  }}, cb)

  equip_by_list = @(target, equipList, cb = null) request({
    method = "equip_by_list"
    params = { target = target, equipList = equipList }
  }, cb)

  set_soldier_to_squad = @(soldier, ind, squad) request({
    method = "set_soldier_to_squad"
    params = {soldier = soldier, ind=ind, squad=squad}
  })

  swap_soldiers_equipment = @(soldierAGuid, soldierBGuid, cb = null) request({
    method = "swap_soldiers_equipment"
    params = { soldierAGuid, soldierBGuid }
  }, cb)

  set_vehicle_to_squad = @(vehicle, squad)  request({
    method = "set_vehicle_to_squad"
    params = {vehicle = vehicle, squad=squad}
  })

  set_squad_order = @(armyId, orderedGuids, cb = null) request({
    method = "set_squad_order"
    params = {armyId = armyId, orderedGuids = orderedGuids}
  }, cb)

  rent_squad = @(armyId, squadId, rentTime, price, cb = null) request({
    method = "rent_squad"
    params = { armyId, squadId, rentTime, price }
  }, cb)

  set_soldier_order = @(squad, orderedGuids, cb = null)  request({
    method = "set_soldier_order"
    params = {squad = squad, orderedGuids = orderedGuids}
  }, cb)

  set_reserve_order = @(armyId, orderedGuids, cb = null) request({
    method = "set_reserve_order"
    params = {armyId = armyId, orderedGuids = orderedGuids}
  }, cb)

  manage_squad_soldiers = @(armyId, squadGuid, squadSoldiers, reserveSoldiers, cb = null) request({
    method = "manage_squad_soldiers"
    params = {
      armyId = armyId, squadGuid = squadGuid,
      squadSoldiers = squadSoldiers, reserveSoldiers = reserveSoldiers
    }
  }, cb)
  dismiss_reserve_soldier = @(armyId, soldierGuid, cb = null) request({
    method = "dismiss_reserve_soldier"
    params = { armyId = armyId, soldierGuid = soldierGuid }
  }, cb)

  swap_items = @(soldier1, slot1, index1, soldier2, slot2, index2, cb = null) request({
    method = "swap_items"
    params = {
        soldier1 = soldier1,
        slot1 = slot1,
        index1 = index1 ?? -1,
        soldier2 = soldier2,
        slot2 = slot2,
        index2 = index2 ?? -1
    }
  }, cb)

  drop_items = @(armyId, crateId, cb = null) request({
    method = "drop_items"
    params = { armyId, crateId }
  }, cb)

  get_crates_content = @(armyId, crates, cb) request({
    method = "get_crates_content"
    params = { armyId = armyId, crates = crates }
  }, cb)

  add_squad = @(armyId, squadId, cb = null) request({
    method = "add_squad"
    params = { armyId, squadId }
  }, cb)

  remove_squad = @(guid, cb = null) request({
    method = "remove_squad"
    params = { guid }
  }, cb)

  add_all_squads = @(cb = null) request({
    method = "add_all_squads"
  }, cb)

  add_soldier = @(armyId, sClass, tier, cb = null) request({
    method = "add_soldier"
    params = { armyId, sClass, tier }
  }, cb)

  add_items = @(armyId, itemTmpl, count, cb = null) request({
    method = "add_items"
    params = { armyId, itemTmpl, count }
  }, cb)

  remove_item = @(itemGuid, count = 1) request({
    method = "remove_item"
    params = { itemGuid, count }
  })

  add_items_by_type = @(armyId, itemTypes, count, cb = null) request({
    method = "add_items_by_type"
    params = { armyId, itemTypes, count }
  }, cb)

  add_army_exp = @(armyId, exp, cb) request({
    method = "add_army_exp"
    params = { armyId = armyId, exp = exp }
  }, cb)

  buy_army_exp = @(armyId, exp, cost, cb = null) request({
    method = "buy_army_exp"
    params = { armyId = armyId, exp = exp, cost = cost }
  }, cb)

  buy_squad_exp = @(armyId, squadId, exp, cost, cb = null) request({
    method = "buy_squad_exp"
    params = { armyId = armyId, squadId = squadId, exp = exp, cost = cost }
  }, cb)

  use_soldier_levelup_orders = @(guid, barterData, cb = null) request({
    method = "use_soldier_levelup_orders"
    params = { guid, barterData }
  }, cb)

  buy_soldier_exp = @(guid, exp, cost, cb = null) request({
    method = "buy_soldier_exp"
    params = { guid = guid, exp = exp, cost = cost }
  }, cb)

  buy_soldier_max_level = @(guid, cost, cb = null) request({
    method = "buy_soldier_max_level"
    params = { guid = guid, cost = cost }
  }, cb)

  unlock_squad = @(armyId, squadId, cb) request({
    method = "unlock_squad"
    params = { armyId = armyId, squadId = squadId }
  }, cb)

  get_army_level_reward = @(armyId, unlockGuid, cb = null) request({
    method = "get_army_level_reward"
    params = { armyId = armyId, unlockGuid = unlockGuid }
  }, cb)

  barter_shop_items = @(armyId, shopItemGuid, payItems, count, cb = null) request({
    method = "barter_shop_items"
    params = { armyId, shopItemGuid, payItems, count }
  }, cb)

  buy_shop_items = @(armyId, shopItemGuid, currencyId, price, count, cb = null) request({
    method = "buy_shop_items"
    params = { armyId, shopItemGuid, currencyId, price, count }
  }, cb)

  update_offers = @(cb = null) request({
    method = "update_offers"
    params = {}
  }, cb)

  buy_shop_offer = @(armyId, shopItemGuid, currencyId, price, offerGuid = "", cb = null) request({
    method = "buy_shop_offer"
    params = { armyId, shopItemGuid, currencyId, offerGuid, price }
  }, cb)

  get_shop_item = @(shopId, cb = null) request({
    method = "get_shop_item"
    params = { shopId }
  }, cb)

  transfer_item = @(itemGuid, armyId, cb = null) request({
    method = "transfer_item"
    params = { itemGuid, armyId }
  }, cb)

  use_transfer_item_order = @(itemGuid, armyId, orders, cb = null) request({
    method = "use_transfer_item_order"
    params = { itemGuid, armyId, orders }
  }, cb)

  reset_profile = @(cb) request({
    method = "reset_profile"
    params = {}
  }, cb)

  soldiers_regenerate_view = @(cb = null) request({
    method = "soldiers_regenerate_view"
    params = {}
  }, cb)

  reset_mutations_timestamp = @(cb = null) request({
    method = "reset_mutations_timestamp"
    params = {}
  }, cb)

  apply_profile_mutation = @(key, cb = null) request({
    method = "apply_profile_mutation"
    params = { key }
  }, cb)

  soldier_train = @(guid, steps, cb = null) request({
    method = "soldier_train"
    params = { guid, steps }
  }, cb)

  use_soldier_train_order = @(guid, ticket, steps, cb = null) request({
    method = "use_soldier_train_order"
    params = { guid, ticket, steps }
  }, cb)

  add_exp_to_soldiers = @(list, cb) request({
    method = "add_exp_to_soldiers"
    params = { list = list }
  }, cb)

  add_perk_points = @(guid, count, cb = null) request({
    method = "add_perk_points"
    params = { guid, count }
  }, cb)

  get_perks_choice = @(soldierGuid, tierIdx, slotIdx, cb) request({
    method = "get_perks_choice"
    params = { soldierGuid = soldierGuid, tierIdx = tierIdx, slotIdx = slotIdx }
  }, cb)

  choose_perk = @(soldierGuid, tierIdx, slotIdx, perkId, cb) request({
    method = "choose_perk"
    params = { soldierGuid = soldierGuid, tierIdx = tierIdx, slotIdx = slotIdx, perkId = perkId }
  }, cb)

  change_perk_choice = @(soldierGuid, tierIdx, slotIdx, cost, cb) request({
    method = "change_perk_choice"
    params = { soldierGuid = soldierGuid, tierIdx = tierIdx, slotIdx = slotIdx, cost = cost }
  }, cb)

  drop_perk = @(soldierGuid, tierIdx, slotIdx) request({
    method = "drop_perk"
    params = { soldierGuid = soldierGuid, tierIdx = tierIdx, slotIdx = slotIdx }
  }, null)

  add_army_squad_exp_by_id = @(armyId, exp, squadId, cb = null) request({
    method = "add_army_squad_exp_by_id"
    params = { armyId = armyId, exp = exp, squadId = squadId }
  }, cb)

  do_research = @(armyId, researchId, cb = null) request({
    method = "research"
    params = {armyId = armyId, researchId = researchId}
  }, cb)

  change_research = @(armyId, researchFrom, researchTo, payItems, cb = null) request({
    method = "change_research"
    params = { armyId, researchFrom, researchTo, payItems }
  }, cb)

  buy_change_research = @(armyId, researchFrom, researchTo, cost, cb = null) request({
    method = "buy_change_research"
    params = { armyId, researchFrom, researchTo, cost }
  }, cb)

  upgrade_item_order = @(itemGuid, sacrificeItems, cb = null) request({
    method = "upgrade_item_order"
    params = { itemGuid, sacrificeItems }
  }, cb)

  dispose_item = @(guids, cb = null) request({
    method = "dispose_item"
    params = { itemGuids = guids }
  }, cb)

  gen_perks_points_statistics = @(tier, count, genId, cb) request({
    method = "gen_perks_points_statistics"
    params = {tier = tier, count = count, genId = genId }
  }, cb)

  get_profile_data_jwt = @(armies, cb) request({
    method = "get_profile_data_jwt"
    params = { armies }
    timeout_factor = 4.0
  }, cb)

  gen_default_profile = @(target, armies, cb) request({
    method = "gen_default_profile"
    params = {target = target, armies = armies}
    timeout_factor = 4.0
  }, cb)

  gen_tutorial_profiles = @(cb) request({
    method = "gen_tutorial_profiles"
    params = {}
  }, cb)

  get_info_for_matching_jwt = @(cb) request({
    method = "get_info_for_matching_jwt"
    params = {}
  }, cb)

  mark_as_seen = @(itemsGuids, soldiersGuids = [], cb = null) request({
    method = "mark_as_seen"
    params = {itemsGuids = itemsGuids, soldiersGuids = soldiersGuids}
  }, cb)

  reward_single_player_mission = @(missionId, armyId, squads, soldiers, cb = null) request({
    method = "reward_single_player_mission"
    params = {
      missionId = missionId,
      armyId = armyId,
      squads = squads,
      soldiers = soldiers
    }
  }, cb)

  premium_add = @(durationSec, cb = null) request({
    method = "premium_add"
    params = { duration = durationSec }
  }, cb)

  premium_remove = @(durationSec, cb = null) request({
    method = "premium_remove"
    params = { duration = durationSec }
  }, cb)

  use_callname_change_order = @(soldierGuid, callname, ticket, cb = null) request({
    method = "use_callname_change_order"
    params = { guid = soldierGuid, callname, ticket }
  }, cb)

  buy_callname_change = @(soldierGuid, callname, cost, cb = null) request({
      method = "buy_callname_change"
      params = { guid = soldierGuid, callname, cost }
  }, cb)

  appearance_change = @(soldierGuid, cb = null) request({
    method = "appearance_change"
    params = { guid = soldierGuid }
  }, cb)

  use_appearance_change_order = @(soldierGuid, ticket, cb = null) request({
    method = "use_appearance_change_order"
    params = { guid = soldierGuid, ticket }
  }, cb)

  buy_appearance_change = @(soldierGuid, cost, cb = null) request({
      method = "buy_appearance_change"
      params = { guid = soldierGuid, cost }
  }, cb)

  inventory_add_item = @(itemdef) request({
    method = "inventory_add_item"
    params = { itemdef, quantity = 1 }
  })

  gen_testdrive_squad_profile_jwt = @(armyId, squadId, shopItemGuid, cb) request({
    method = "gen_testdrive_squad_profile_jwt"
    params = { armyId, squadId, shopItemGuid }
  }, cb)

  choose_decorator = @(cType, guid, cb = null) request({
    method = "choose_decorator"
    params = { cType, guid }
  }, cb)

  buy_decorator = @(guid, cost, cb = null) request({
    method = "buy_decorator"
    params = { guid, cost }
  }, cb)

  add_decorator = @(guid, lifeTime = 0, cb = null) request({
    method = "add_decorator"
    params = { guid, lifeTime }
  }, cb)

  add_all_decorators = @(cb = null) request({
    method = "add_all_decorators"
    params = {}
  }, cb)

  add_veh_decorators = @(cType, id, cb = null) request({
    method = "add_veh_decorators"
    params = { cType, id }
  }, cb)

  apply_decorator = @(guid, vehGuid, cType, details, slot, cb = null) request({
    method = "apply_decorator"
    params = { guid, vehGuid, cType, details, slot }
  }, cb)

  buy_veh_decorator = @(cType, id, cost, cb = null) request({
    method = "buy_veh_decorator"
    params = { cType, id, cost }
  }, cb)

  buy_apply_veh_decorators = @(decorators, vehGuid, cost, cb = null) request({
    method = "buy_apply_veh_decorators"
    params = { decorators, vehGuid, cost }
  }, cb)

  mark_decorators_as_seen = @(guids, cb = null) request({
    method = "mark_decorators_as_seen"
    params = { guids }
  }, cb)

  mark_veh_decorators_as_seen = @(guids, cb = null) request({
    method = "mark_veh_decorators_as_seen"
    params = { guids }
  }, cb)

  add_medal = @(id, cb = null) request({
    method = "add_medal"
    params = { id }
  }, cb)

  mark_medals_as_seen = @(guids, cb = null) request({
    method = "mark_medals_as_seen"
    params = { guids }
  }, cb)

  mark_wallposters_as_seen = @(guids, cb = null) request({
    method = "mark_wallposters_as_seen"
    params = { guids }
  }, cb)

  debug_apply_booster_in_battle = @(battleBoosters) request({
    method = "debug_apply_booster_in_battle"
    params = { battleBoosters }
  })

  decrease_purchases_count = @(goodsGuid, count) request({
    method = "decrease_purchases_count"
    params = { goodsGuid, count }
  })

  add_wallposter = @(tpl) request({
    method = "add_wallposter"
    params = { tpl }
  })

  update_meta_config = @(data, cb = null) request({
    method = "update_meta_config"
    params = { data }
  }, cb)

  apply_outfit = @(guid, free, premium, cb = null) request({
    method = "apply_outfit"
    params = { guid, free, premium }
  }, cb)

  add_outfit = @(armyId, outfitTmpl, count) request({
    method = "add_outfit"
    params = { armyId, outfitTmpl, count }
  })

  buy_outfit = @(armyId, items, cost, cb = null) request({
    method = "buy_outfit"
    params = { armyId, items, cost }
  }, cb)

  apply_freemium = @(campaignId) request({
    method = "apply_freemium"
    params = { campaignId }
  })

  apply_freemium_soldier = @(guid, level = 0) request({
    method = "apply_freemium_soldier"
    params = { guid, level }
  })

  use_outfit_orders = @(armyId, items, orders, cb = null) request({
    method = "use_outfit_orders"
    params = { armyId, items, orders }
  }, cb)

  usermail_list = @(ts, limit, cb) request({
    method = "usermail_list"
    params = { ts, limit }
  }, cb)

  usermail_take_reward = @(guid, cb) request({
    method = "usermail_take_reward"
    params = { guid }
  }, cb)

}
