from "%enlSqGlob/ui_library.nut" import *

let json = require("%sqstd/json.nut")
let userInfo = require("%enlSqGlob/userInfo.nut")
let { profile } = require("%enlist/meta/servProfile.nut")
let { endswith } = require("string")
let { gameProfile, allArmiesInfo } = require("config/gameProfile.nut")
let { unlockedCampaigns } = require("%enlist/meta/campaigns.nut")
let { curCampaign, setCurCampaign } = require("%enlist/meta/curCampaign.nut")
let { hasPremium } = require("%enlist/currency/premium.nut")
let { squadsCfgById } = require("config/squadsConfig.nut")
let armyEffects = require("armyEffects.nut")
let { add_army_exp, reset_profile, update_profile, set_vehicle_to_squad, drop_items,
  soldiers_regenerate_view, add_squad, add_all_squads, add_soldier, add_items, add_items_by_type,
  check_purchases, get_shop_item, remove_squad, add_outfit
} = require("%enlist/meta/clientApi.nut")
let { armies, curArmiesList, itemsByArmies, curArmiesListExt,
  curCampItems, soldiersByArmies, curCampSoldiers, squadsByArmies, curCampSquads, campItemsByLink
} = require("%enlist/meta/profile.nut")
let { getObjectsByLinkSorted, getObjectsTableByLinkType, getLinkedSquadGuid, getItemIndex
} = require("%enlSqGlob/ui/metalink.nut")
let squadsParams = require("squadsParams.nut")
let { mkOnlineSaveData } = require("%enlSqGlob/mkOnlineSaveData.nut")
let { onlineSettingUpdated } = require("%enlist/options/onlineSettings.nut")
let armiesPresentation = require("%enlSqGlob/ui/armiesPresentation.nut")
let squadsPresentation = require("%enlSqGlob/ui/squadsPresentation.nut")
let { expiredRentedSquads } = require("rentedSquads.nut")


let curArmiesStorage = mkOnlineSaveData("curArmies", @() {})
let setCurArmies = curArmiesStorage.setValue
let curArmies = curArmiesStorage.watch
let playerSelectedSquadsStorage = mkOnlineSaveData("playerSelectedSquads", @() {})
let setPlayerSelectedSquads = playerSelectedSquadsStorage.setValue
let playerSelectedSquads = playerSelectedSquadsStorage.watch
let roomArmy = mkWatched(persist, "roomArmy", null)


let allAvailableArmies = Computed(function() {
  let res = {}
  foreach (campaign in unlockedCampaigns.value)
    res[campaign] <- (gameProfile.value?.campaigns[campaign].armies ?? []).map(@(a) a.id)
  return res
})

let curArmy = Computed(function() {
  local armyId = roomArmy.value ?? curArmies.value?[curCampaign.value]
  if (curArmiesList.value.indexof(armyId) == null)
    armyId = curArmiesList.value?[0]
  return armyId
})

let function selectArmy(army) {
  let campaign = gameProfile.value?.campaignByArmyId[army]
  if (campaign && curArmies.value?[campaign] != army)
    setCurArmies(curArmies.value.__merge({ [campaign] = army }))
}

let curArmyData = Computed(@() armies.value?[curArmy.value])

let mteam = Computed(@() endswith(curArmy.value ?? "", "axis") ? 1 : 0)

let armyLimitsDefault = {
  maxSquadsInBattle = 1
  maxInfantrySquads = 1
  maxBikeSquads = 0
  maxVehicleSquads = 0
  soldiersReserve = 0
}

let limitsByArmy = Computed(function() {
  let res = {}
  let armiesInfo = allArmiesInfo.value
  let premiumBonuses = gameProfile.value?.premiumBonuses
  let effects = armyEffects.value

  foreach (armyId in curArmiesList.value)
    res[armyId] <- armyLimitsDefault.map(function(val, key) {
      local keyValue = (armiesInfo?[armyId][key] ?? val)
        + (effects?[armyId][key] ?? 0)

      if (hasPremium.value)
        keyValue += premiumBonuses?[key] ?? 0
      return keyValue
    })

  return res
})

let curArmyLimits = Computed(@()
  limitsByArmy.value?[curArmy.value] ?? armyLimitsDefault)

let sortByIndex = @(a,b) getItemIndex(a) <=> getItemIndex(b)
let objInfoByGuid = Computed(@() curCampSoldiers.value.__merge(curCampItems.value))

let soldiersBySquad = Computed(@()
  getObjectsTableByLinkType(curCampSoldiers.value, "squad")
    .map(@(list) list.sort(sortByIndex)))

let getItemOwnerGuid = @(item) (item?.links ?? {})
  .keys()
  .findvalue(@(guid) guid in curCampSoldiers.value || guid in curCampItems.value)

let function getItemOwnerSoldier(itemGuid) {
  foreach (guid, _ in curCampItems.value?[itemGuid].links ?? {})
    if (guid in curCampSoldiers.value)
      return curCampSoldiers.value[guid]
  return null
}

let vehicleBySquad = Computed(@()
  getObjectsTableByLinkType(curCampItems.value, "curVehicle")
    .map(@(list) list[0]))

let getSquadConfig = @(squadId, armyId = null)
  squadsCfgById.value?[armyId ?? curArmy.value][squadId]

// config is profile server side; presentation is client side
let function mixSquadData(config, presentation) {
  let titleLocId = presentation?.titleLocId ?? "squad/defaultTitle"
  return {
    size = config?.size ?? 1 //base squad size
    capacity = config?.size ?? 0
    squadType = config?.squadType ?? "unknown"
    vehicleType = config?.vehicleType ?? ""
    icon = presentation?.icon ?? ""
    image = presentation?.image ?? ""
    nameLocId = presentation?.nameLocId ?? "squad/defaultName"
    titleLocId
    manageLocId = presentation?.manageLocId ?? titleLocId
    premIcon = presentation?.premIcon
  }
}

let squadsByArmy = Computed(function() {
  let res = {}
  foreach (armyId in curArmiesList.value) {
    let configs = squadsCfgById.value?[armyId]
    let presentations = squadsPresentation?[armyId]
    let squadsList = (squadsByArmies.value?[armyId] ?? {})
      .values()
      .map(function(squad) {
        let squadGuid = squad.guid
        let squadId = squad.squadId
        let config = configs?[squadId]
        let curVehicle = vehicleBySquad.value?[squadGuid]
        squad = squad.__merge(mixSquadData(config, presentations?[squadId]))
        if ((config?.battleExpBonus ?? 0) > 0) {
          squad.premIcon <- armiesPresentation?[armyId].premIcon
          squad.battleExpBonus <- config.battleExpBonus
        }
        squad.vehicle <- objInfoByGuid.value?[curVehicle?.guid]
        squad.squadSize <- soldiersBySquad.value?[squadGuid].len() ?? 0
        return squad
      })
      .sort(sortByIndex)
    res[armyId] <- squadsList
  }
  return res
})

let lockedSquadsByArmy = Computed(function() {
  let res = {}
  foreach (armyId in curArmiesList.value) {
    let presentations = squadsPresentation?[armyId]
    let unlockedSquads = squadsByArmies.value?[armyId] ?? {}
    let squadsList = (squadsCfgById.value?[armyId] ?? {})
      .filter(@(_, key) unlockedSquads.findvalue(@(s) key == s.squadId) == null)
      .map(function(config, squadId) {
        let squad = mixSquadData(config, presentations?[squadId])
        squad.squadId <- squadId
        squad.size <- config.size
        return squad
      })
      .values()
    res[armyId] <- squadsList
  }
  return res
})

let armySquadsById = Computed(@() squadsByArmy.value.map(@(squads)
  squads.reduce(@(res, s) res.rawset(s.squadId, s), {})))

let curUnlockedSquads = Computed(@() squadsByArmy.value?[curArmy.value] ?? [])

let lockedArmySquadsById = Computed(@() lockedSquadsByArmy.value.map(@(squads)
  squads.reduce(@(res, s) res.rawset(s.squadId, s), {})))

let allUnlockedSquadsSoldiers = Computed(function() {
  let res = {}
  foreach (armyId in curArmiesList.value)
    res[armyId] <- (soldiersByArmies.value?[armyId] ?? {})
      .filter(@(soldier) curCampSquads.value?[getLinkedSquadGuid(soldier)] != null)
      .values()
  return res
})

let curUnlockedSquadsSoldiers = Computed(@()
  allUnlockedSquadsSoldiers.value?[curArmy.value] ?? [])

let chosenSquadsByArmy = Computed(function() {
  let res = {}
  let expired = expiredRentedSquads.value
  foreach (armyId in curArmiesList.value) {
    let squadsLimits = limitsByArmy.value?[armyId] ?? armyLimitsDefault
    local { maxSquadsInBattle, maxInfantrySquads, maxBikeSquads, maxVehicleSquads } = squadsLimits
    let squadsList = []
    foreach (squad in squadsByArmy.value?[armyId] ?? []) {
      let { guid, vehicleType = "" } = squad
      if (guid in expired)
        continue

      if (vehicleType == "bike") {
        if (maxBikeSquads <= 0)
          continue
        maxBikeSquads--
      }
      else if (vehicleType != "") {
        if (maxVehicleSquads <= 0)
          continue
        maxVehicleSquads--
      }
      else {
        if (maxInfantrySquads <= 0)
          continue
        maxInfantrySquads--
      }

      squadsList.append(squad)
      maxSquadsInBattle--
      if (maxSquadsInBattle <= 0)
        break
    }
    res[armyId] <- squadsList
  }
  return res
})

let curChoosenSquads = Computed(@() chosenSquadsByArmy.value?[curArmy.value] ?? [])

let curSquadId = Computed(function() {
  local squadId = null
  let choosenSquads = curChoosenSquads.value ?? []
  if (choosenSquads.len() > 0) {
    squadId = playerSelectedSquads.value?[curArmy.value]
    if (!squadId || choosenSquads.findindex(@(s) s.squadId == squadId) == null)
      squadId = choosenSquads[0].squadId
  }
  return squadId
})

let function setCurSquadId(squadId) {
  if (!onlineSettingUpdated.value)
    return
  let armyId = curArmy.value
  if (armyId && squadId != playerSelectedSquads.value?[armyId])
    setPlayerSelectedSquads(playerSelectedSquads.value.__merge({ [armyId] = squadId }))
}

let function getModSlots(item /*full item info recived via objInfoByGuid*/) {
  let res = []
  foreach (slotType, scheme in item?.equipScheme ?? {})
    if ((scheme?.listSize ?? 0) <= 0) //do not support modes list as item mods yet.
      res.append({
        slotType = slotType
        scheme = scheme
        equipped = campItemsByLink.value?[item.guid][slotType][0].guid
      })
  return res
}

let getScheme = @(item, slotType) item?.equipScheme[slotType]

let curSquad = Computed(@()
  curUnlockedSquads.value.findvalue(@(s) s.squadId == curSquadId.value))

let curSquadParams = Computed(@()
  squadsParams.value?[curArmy.value][curSquadId.value])

let curSquadSoldiersInfo = Computed(function() {
  let squad = curSquad.value
  return squad != null
    ? getObjectsByLinkSorted(curCampSoldiers.value, squad.guid, "squad")
    : []
})

let armoryByArmy = Computed(@() itemsByArmies.value
  .map(@(list) list.filter(@(item) item.links.len() == 1)
    .values()))

let curArmory = Computed(@() armoryByArmy.value?[curArmy.value] ?? [])

let itemCountByArmy = Computed(function() {
  let res = {}
  foreach (armyId in curArmiesListExt.value) {
    let armyCount = {}
    foreach (item in itemsByArmies.value?[armyId] ?? []) {
      let { basetpl } = item
      armyCount[basetpl] <- (armyCount?[basetpl] ?? 0) + item.count
    }
    res[armyId] <- armyCount
  }
  return res
})

let armyItemCountByTpl = Computed(function() {
  let curArmyId = curArmy.value
  let commonArmyId = gameProfile.value?.commonArmy
  let res = {}
  foreach (armyId, armyData in itemCountByArmy.value) {
    if (armyId != curArmyId && armyId != commonArmyId)
      continue
    foreach (tpl, count in armyData)
      res[tpl] <- (res?[tpl] ?? 0) + count
  }

  return res
})


let curCampItemsCount = Computed(function() {
  local res = {}
  foreach (armyCount in itemCountByArmy.value) {
    if (res.len() == 0) {
      res = clone armyCount
      continue
    }
    foreach (basetpl, count in armyCount)
      res[basetpl] <- (res?[basetpl] ?? 0) + count
  }
  return res
})

let curVehicle = Computed(@() vehicleBySquad.value?[curSquad.value?.guid].guid)

let getEquippedItemGuid = @(itemsByLink, soldierGuid, slotType, slotId)
  itemsByLink?[soldierGuid][slotType].findvalue(@(item) ((slotId ?? -1) == -1 || slotId == getItemIndex(item))).guid

let getSoldierByGuid = @(guid)
  curCampSoldiers.value?[guid]

let function addArmyExp(armyId, exp, cb = null) {
  add_army_exp(armyId, exp, cb)
}

let function setVehicleToSquad(squadGuid, vehicleGuid) {
  if (vehicleBySquad.value?[squadGuid] == vehicleGuid)
    return

  set_vehicle_to_squad(vehicleGuid, squadGuid)
}

let function resetProfile() {
  reset_profile(function(res) {
    debugTableData(res)
    check_purchases()
  })
}

let function dumpProfile() {
  let { userId = -1 } = userInfo.value
  if (userId < 0)
    return

  let path = $"enlisted_profile_{userId}.json"
  json.save(path, profile.value, { logger = log_for_user })
  console_print($"Current user profile saved to {path}")
}

let function getSoldierItemSlots(guid, itemsByLink) {
  //todo: here better same format with campItemsByLink
  let res = []
  foreach (slotType, itemsList in itemsByLink?[guid] ?? {})
    foreach (item in itemsList)
      res.append({ item, slotType, slotId = getItemIndex(item) })
  return res
}

let getSoldierItem = @(guid, slot, campItems) campItems?[guid][slot][0]

let function getDemandingSlots(ownerGuid, slotType, objInfo, itemsByLink) {
  let { equipScheme = {} } = objInfo
  let equipGroup = equipScheme?[slotType].atLeastOne ?? ""
  return equipGroup != ""
    ? equipScheme
        .filter(@(s) s?.atLeastOne == equipGroup)
        .map(@(_, slotType) getEquippedItemGuid(itemsByLink, ownerGuid, slotType, null)) //lists with atLeastOne does not supported yet
    : {}
}

let function getDemandingSlotsInfo(ownerGuid, slotType) {
  let equipGroup = objInfoByGuid.value?[ownerGuid].equipScheme[slotType].atLeastOne ?? ""
  return equipGroup != "" ? loc($"equipDemand/{equipGroup}") : ""
}

let maxCampaignLevel = Computed(@() armies.value.reduce(@(v,camp) max(v, camp?.level ?? 0), 0))

console_register_command(function() {
  setCurCampaign(null)
  setCurArmies(null)
}, "meta.resetCurCampaign")

console_register_command(@(crateId) drop_items(curArmy.value, crateId), "meta.dropCrate")
console_register_command(@() update_profile(), "meta.updateProfile")
console_register_command(@() soldiers_regenerate_view(), "meta.soldiersRegenerateView")
console_register_command(function() {
  let tmpArmies = clone curArmies.value
  if (curCampaign.value in tmpArmies)
    delete tmpArmies[curCampaign.value]
  setCurArmies(tmpArmies)
}, "meta.selectArmyScene")
console_register_command(@(exp) addArmyExp(curArmy.value, exp), "meta.addCurArmyExp")
console_register_command(@(squadId) add_squad(curArmy.value, squadId), "meta.addSquad")
console_register_command(@(guid) remove_squad(guid), "meta.removeSquad")
console_register_command(@() add_all_squads(), "meta.addAllSquads")
console_register_command(@(shopId) get_shop_item(shopId), "meta.getFromShop")
console_register_command(@(sClass, tier) add_soldier(curArmy.value, sClass, tier), "meta.addSoldier")
console_register_command(@(itemTmpl) add_items(curArmy.value, itemTmpl, 1), "meta.addItem")
console_register_command(@(itemTmpl, count) add_items(curArmy.value, itemTmpl, count), "meta.addItems")
console_register_command(@(itemTmpl, count) add_items("common_army", itemTmpl, count), "meta.addCommonItems")
console_register_command(@(itemTmpl) add_outfit(curArmy.value, itemTmpl, 1), "meta.addOutfit")

let DROP_COMMANDS = {
  addAllVehicles          = ["vehicle"]
  addAllSemiautos         = ["semiauto", "carbine_tanker"]
  addAllShotguns          = ["shotgun"]
  addAllSniperBoltactions = ["boltaction"]
  addAllSniperSemiautos   = ["semiauto_sniper"]
  addAllBoltactions       = ["boltaction_noscope"]
  addAllGrenadeRifles     = ["rifle_grenade_launcher"]
  addAllAntitankRifles    = ["antitank_rifle"]
  addAllGrenadeLaunchers  = ["grenade_launcher"]
  addAllInfantryLaunchers = ["infantry_launcher"]
  addAllRocketLaunchers   = ["launcher"]
  addAllMachineguns       = ["mgun"]
  addAllSubmachineguns    = ["submgun", "carbine_pistol"]
  addAllAssaultrifles     = ["assault_rifle"]
  addAllFlareguns         = ["flaregun"]
  addAllMortars           = ["mortar"]
  addAllFlamethrowers     = ["flamethrower"]
  addAllScopes            = ["scope"]
  addAllPistols           = ["sideweapon"]
  addAllMedkits           = ["medkits", "medic_medkits"]
  addAllGrenades          = ["grenade", "explosion_pack", "molotov", "tnt_block_exploder",
                             "impact_grenade", "smoke_grenade", "incendiary_grenade"]
  addAllMines             = ["antipersonnel_mine", "antitank_mine", "lunge_mine"]
  addAllRepairKits        = ["repair_kit"]
  addAllMelee             = ["melee"]
  addAllBayonet           = ["bayonet"]
  addAllBackpacks         = ["backpack"]
  addAllBinoculars        = ["binoculars_usable"]
  addAllFlasks            = ["flask_usable"]
}
let COMMON_ARMY_DROP_COMMANDS = {
  addAllTickets           = ["ticket"]
  addAllBoosters          = ["booster"]
}
let COUNT_OVERRIDES = {
  addAllTickets = 10
}
foreach (cmd, drop in DROP_COMMANDS) {
  let types = drop
  let count = COUNT_OVERRIDES?[cmd] ?? 1
  console_register_command(@() add_items_by_type(curArmy.value, types, count), $"meta.{cmd}")
}
foreach (cmd, drop in COMMON_ARMY_DROP_COMMANDS) {
  let types = drop
  let count = COUNT_OVERRIDES?[cmd] ?? 1
  console_register_command(@() add_items_by_type("common_army", types, count), $"meta.{cmd}")
}

console_register_command(function() {
  let dropTable = {
    [curArmy.value] = DROP_COMMANDS,
    common_army = COMMON_ARMY_DROP_COMMANDS
  }
  foreach (armyId, typeList in dropTable)
    foreach (cmd, types in typeList)
      add_items_by_type(armyId, types, COUNT_OVERRIDES?[cmd] ?? 1)
}, "meta.addAll")

let vehicleInfo = Computed(@() objInfoByGuid.value?[curVehicle.value])

return {
  resetProfile
  dumpProfile
  armies
  curCampSquads
  curCampItems
  curCampSoldiers
  curSquadId
  setCurSquadId
  curUnlockedSquads
  allUnlockedSquadsSoldiers
  curUnlockedSquadsSoldiers
  chosenSquadsByArmy
  curChoosenSquads
  limitsByArmy
  armyLimitsDefault
  curArmyLimits
  curSquad
  curSquadParams
  curSquadSoldiersInfo
  curCampaign
  curCampItemsCount
  itemCountByArmy
  armyItemCountByTpl
  playerSelectedSquads
  objInfoByGuid
  getModSlots
  getScheme
  getSoldierByGuid
  getSoldierItemSlots
  getSoldierItem
  getDemandingSlots
  getDemandingSlotsInfo
  maxCampaignLevel

  setCurArmies
  curArmies
  squadsByArmy
  lockedSquadsByArmy
  armySquadsById
  lockedArmySquadsById

  curArmy
  selectArmy
  setRoomArmy = @(armyId) roomArmy(armyId)
  curArmyData
  curArmiesList
  armoryByArmy
  curArmory
  curVehicle
  vehicleInfo
  getSquadConfig
  mteam
  allAvailableArmies

  getItemIndex
  vehicleBySquad
  getSoldiersByArmy = @(armyId) soldiersByArmies.value?[armyId] ?? {}
  soldiersBySquad
  getItemOwnerGuid
  getItemOwnerSoldier

  addArmyExp
  setVehicleToSquad
  getEquippedItemGuid
}