from "%enlSqGlob/ui_library.nut" import *

let msgbox = require("%ui/components/msgbox.nut")
let mkVehicleSeats = require("%enlSqGlob/squad_vehicle_seats.nut")
let {
  getLinksByType, getObjectsByLink, getLinkedArmyName
} = require("%enlSqGlob/ui/metalink.nut")
let { itemsByArmies, armies, vehDecorators } = require("%enlist/meta/profile.nut")
let {
  squadsByArmy, setVehicleToSquad, objInfoByGuid, curVehicle
} = require("%enlist/soldiers/model/state.nut")
let {
  prepareItems, addShopItems, findItemByGuid, putToStackTop
} = require("%enlist/soldiers/model/items_list_lib.nut")
let allowedVehicles = require("allowedVehicles.nut")
let { squadsCfgById } = require("%enlist/soldiers/model/config/squadsConfig.nut")
let { armiesRewards } = require("%enlist/campaigns/armiesConfig.nut")
let { trimUpgradeSuffix } = require("%enlSqGlob/ui/itemsInfo.nut")
let { curSection } = require("%enlist/mainMenu/sectionsState.nut")
let { transfer_item } = require("%enlist/meta/clientApi.nut")


let AVAILABLE_AT_CAMPAIGN      = 0x01
let CAN_RECEIVE_BY_ARMY_LEVEL  = 0x02
let CAN_PURCHASE               = 0x04
let NEED_LEVEL_TO_PURCHASE     = 0x08
let LOCKED                     = 0x10
let CANT_USE                   = 0x20 //never can use for this squad
let CAN_USE                    = 0

let viewVehicle = mkWatched(persist, "viewVehicle")
let selectVehParams = mkWatched(persist, "selectVehParams", {})

let vehicleClear = @() selectVehParams.mutate(@(v) v.clear())

curSection.subscribe(@(_) vehicleClear())

let curSquad = Computed(function() {
  let { armyId = null, squadId = null } = selectVehParams.value
  if (armyId == null || squadId == null)
    return null

  return (squadsByArmy.value?[armyId] ?? []).findvalue(@(s) s.squadId == squadId)
})

let curSquadArmy = Computed(@() curSquad.value == null ? null : getLinkedArmyName(curSquad.value))
let curSquadArmyLevel = Computed(@() armies.value?[curSquadArmy.value].level ?? 0)

let curVehicleType = Computed(function() {
  let { armyId = null, squadId = null } = selectVehParams.value
  if (armyId == null || squadId == null)
    return null

  return squadsCfgById.value?[armyId][squadId].vehicleType
})

let getVehicleSquad = @(vehicle) getLinksByType(vehicle, "curVehicle")?[0]
let findSelVehicle = @(vehicleList, squadGuid) getObjectsByLink(vehicleList, squadGuid, "curVehicle")?[0].guid

let function calcVehicleStatus(vehicle, curSquadAllowedVehicles, armyRewards, armyLevel) {
  let { basetpl, unlocklevel = -1 } = vehicle
  let trimmed = trimUpgradeSuffix(vehicle.basetpl)
  let isAllowed = trimmed in curSquadAllowedVehicles
  let rewards = armyRewards?[basetpl] ?? []
  let levelLimit = rewards.findvalue(@(level) level > armyLevel) ?? -1
  let levelCampaign = rewards?[0] ?? -1

  local flags = CAN_USE
  if (!isAllowed)
    flags = flags | CANT_USE
  if (vehicle?.isShopItem) {
    flags = flags | LOCKED
    if (levelCampaign > 0)
      flags = flags | AVAILABLE_AT_CAMPAIGN
    if (levelLimit > 0)
      flags = flags | CAN_RECEIVE_BY_ARMY_LEVEL
    if (unlocklevel >= 0)
      flags = flags | (armyLevel >= unlocklevel ? CAN_PURCHASE : NEED_LEVEL_TO_PURCHASE)
  }

  let res = { flags }
  if (flags & CANT_USE)
    res.statusText <- loc("hint/notAllowedForCurSquad")
  else if (flags & CAN_PURCHASE)
    res.statusText <- loc("itemDemandsHeader/canObtainInShop_yes")
  else if (flags & NEED_LEVEL_TO_PURCHASE)
    res.__update({
      levelLimit = unlocklevel
      statusText = loc("vehicleObtainInShopAtLevel", { level = unlocklevel })
      statusTextShort = loc("itemDemandsHeader/canObtainInShop_yes")
    })
  else if (flags & CAN_RECEIVE_BY_ARMY_LEVEL)
    res.__update({
      levelLimit
      statusText = loc("hint/receiveVehicleByCampaignRewards", { level = levelLimit })
      statusTextShort = loc($"itemDemandsHeader/levelLimit", { levelLimit })
    })
  else if (flags & AVAILABLE_AT_CAMPAIGN)
    res.__update({
      levelLimit = levelCampaign
      statusText = loc("hint/receiveVehicleByCampaignRewards", { level = levelCampaign })
      statusTextShort = loc($"itemDemandsHeader/canObtainInCampaign")
    })
  else if (flags & LOCKED)
    res.statusText <- loc("hint/unknowVehicleReceive")
  return res
}

let vehicleSort = @(vehicles, curVehicle)
  vehicles.sort(@(a, b) (b == curVehicle) <=> (a == curVehicle)
    || (a?.status.flags ?? 0) <=> (b?.status.flags ?? 0)
    || (a?.tier ?? 0) <=> (b?.tier ?? 0)
    || a.basetpl <=> b.basetpl)

let vehicles = Computed(function() {
  local res = []
  let squadGuid = curSquad.value?.guid
  let vehicleType = curVehicleType.value
  if (squadGuid == null || vehicleType == null)
    return res

  let armyId = getLinkedArmyName(curSquad.value)
  let items = itemsByArmies.value?[armyId] ?? {}
  foreach (item in items) {
    if (item?.itemtype != "vehicle"
        || item?.itemsubtype != vehicleType
        || armyId != getLinkedArmyName(item))
      continue
    let ownerGuid = getVehicleSquad(item)
    if (!ownerGuid || ownerGuid == squadGuid)
      res.append(item)
  }

  let selectedGuid = findSelVehicle(res, squadGuid)
  res = prepareItems(res, objInfoByGuid.value)
  let haveTmpls = res.reduce(@(tbl, v)
    tbl.__merge({ [trimUpgradeSuffix(v.basetpl)] = true }), {})
  if (selectedGuid != null)
    putToStackTop(res, items?[selectedGuid])
  addShopItems(res, armyId, @(tplId, tpl) tpl?.itemtype == "vehicle"
    && tpl?.itemsubtype == vehicleType
    && (tpl?.upgradeIdx ?? 0) == 0
    && trimUpgradeSuffix(tplId) not in haveTmpls)

  let curSquadAllowedVehicles = allowedVehicles.value?[armyId][curSquad.value?.squadId] ?? {}
  let armyRewards = armiesRewards.value?[armyId]
  let armyLevel = curSquadArmyLevel.value
  res = res.map(@(vehicle) vehicle.__merge({
    status = calcVehicleStatus(vehicle, curSquadAllowedVehicles, armyRewards, armyLevel)
  }))
  vehicleSort(res, res.findvalue(@(v) v.guid == selectedGuid))
  return res
})

let selectedVehicle = Computed(function() {
  let vList = vehicles.value
  let squadGuid = curSquad.value?.guid
  if (!squadGuid || vList.len() == 0)
    return null

  let guid = findSelVehicle(vList.filter(@(v) v?.isShopItem != true), squadGuid)
  return guid ? findItemByGuid(vList, guid) : null
})

if (viewVehicle.value != null) {
  let cur = viewVehicle.value
  let new = cur?.isShopItem ? vehicles.value.findvalue(@(item) item?.basetpl == cur.basetpl)
    : cur?.guid ? findItemByGuid(vehicles.value, cur.guid)
    : cur ? vehicles.value[0]
    : null
  viewVehicle(new ?? selectedVehicle.value)
}
selectedVehicle.subscribe(@(v) viewVehicle(v))

let function selectVehicle(vehicle) {
  let { statusText = null } = vehicle?.status
  if ((statusText ?? "") != "")
    return msgbox.show({ text = statusText })

  let squad = curSquad.value
  if (squad)
    setVehicleToSquad(squad.guid, vehicle?.guid)
  vehicleClear()
}

let hasSquadVehicle = @(squadCfg) (squadCfg?.vehicleType ?? "") != ""

let squadsWithVehicles = Computed(function() {
  let armyId = selectVehParams.value?.armyId
  if (!armyId)
    return null

  let armyConfig = squadsCfgById.value?[armyId]
  return (squadsByArmy.value?[armyId] ?? [])
    .filter(@(squad) hasSquadVehicle(armyConfig?[squad.squadId]))
})

let curSquadId = Computed(@()
  selectVehParams.value?.squadId ?? squadsWithVehicles.value?[0].squadId)

let function setCurSquadId(id) {
  if (selectVehParams.value != null && selectVehParams.value.squadId != id)
    selectVehParams.mutate(@(params) params.__update({ squadId = id }))
}


let curVehicleBadgeData = Computed(function() {
  let vehGuid = curVehicle.value
  if (vehGuid == null)
    return null

  let skin = (vehDecorators.value ?? {})
    .findvalue(@(d) d.cType == "vehCamouflage" && d.vehGuid == vehGuid)

  let vehicle = objInfoByGuid.value?[vehGuid]
  return vehicle == null ? null : vehicle.__merge(skin == null ? {} : { skin })
})

let curVehicleSeats = mkVehicleSeats(curVehicleBadgeData)


console_register_command(function(armyId) {
  let { guid = "" } = viewVehicle.value
  if (guid == "")
    return log("Vehicle is not selected")
  transfer_item(guid, armyId)
  log("Move vehicle request sent")
}, "meta.moveVehicle")

return {
  viewVehicle
  selectedVehicle
  selectVehParams
  vehicles
  squadsWithVehicles
  curSquad
  curSquadId
  setCurSquadId
  curSquadArmy

  vehicleClear
  selectVehicle
  hasSquadVehicle

  curVehicleBadgeData
  curVehicleSeats

  AVAILABLE_AT_CAMPAIGN
  CAN_RECEIVE_BY_ARMY_LEVEL
  CAN_PURCHASE
  NEED_LEVEL_TO_PURCHASE
  LOCKED
  CANT_USE
  CAN_USE
}