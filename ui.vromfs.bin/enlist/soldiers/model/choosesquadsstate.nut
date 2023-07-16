from "%enlSqGlob/ui_library.nut" import *

let serverTime = require("%enlSqGlob/userstats/serverTime.nut")
let { jumpToArmyProgress } = require("%enlist/mainMenu/sectionsState.nut")
let { soldiersBySquad, squadsByArmy, chosenSquadsByArmy, vehicleBySquad, limitsByArmy,
  armyLimitsDefault, curArmy, lockedSquadsByArmy
} = require("state.nut")
let { set_squad_order } = require("%enlist/meta/clientApi.nut")
let { squadsCfgById } = require("%enlist/soldiers/model/config/squadsConfig.nut")
let { soldiersStatuses } = require("readySoldiers.nut")
let { READY } = require("%enlSqGlob/readyStatus.nut")
let { allSquadsLevels } = require("%enlist/researches/researchesState.nut")
let { markSeenSquads } = require("unseenSquads.nut")
let msgbox = require("%enlist/components/msgbox.nut")
let { allArmyUnlocks } = require("armyUnlocksState.nut")
let { trimUpgradeSuffix } = require("%enlSqGlob/ui/itemsInfo.nut")
let { curCampaign } = require("%enlist/meta/curCampaign.nut")
let { addPopup } = require("%enlSqGlob/ui/popup/popupsState.nut")
let { sendBigQueryUIEvent } = require("%enlist/bigQueryEvents.nut")
let armiesPresentation = require("%enlSqGlob/ui/armiesPresentation.nut")
let squadsPresentation = require("%enlSqGlob/ui/squadsPresentation.nut")
let { curCampaignAccessItem, isCampaignBought } = require("%enlist/campaigns/campaignConfig.nut")
let JB = require("%ui/control/gui_buttons.nut")


let justGainSquadId = Watched(null)
let selectedSquadId = Watched(null)
let previewSquads = Watched(null)
let squadsArmy = mkWatched(persist, "squadsArmy")
let curChoosenSquads = Computed(@() chosenSquadsByArmy.value?[squadsArmy.value] ?? [])
let curUnlockedSquads = Computed(@() squadsByArmy.value?[squadsArmy.value] ?? [])

let chosenSquads = mkWatched(persist, "chosen", [])
let reserveSquads = mkWatched(persist, "reserve", [])
let displaySquads = Computed(@() previewSquads.value ?? clone chosenSquads.value)

let unlockedSquads = Computed(@() (clone chosenSquads.value).extend(reserveSquads.value))
let slotsCount = Computed(@() chosenSquads.value.len())
let focusedSquads = mkWatched(persist, "focused", {})

focusedSquads.subscribe(@(focused) reserveSquads.mutate(@(v) v
  .reduce(@(list, sq) sq.squadId in focused
    ? list.insert(0, sq)  // warning disable: -unwanted-modification
    : list.append(sq), []) // warning disable: -unwanted-modification
  ))

let close = @() squadsArmy(null)

curCampaign.subscribe(function(_) {
  if (squadsArmy.value == null)
    return
  close()
  addPopup({
    id = "close_squads_manage"
    text = loc("msg/closeSquadManageOnCampaignChange")
  })
})

let curArmyLockedSquadsData = Computed(function() {
  let armyId = curArmy.value
  let unlocks = allArmyUnlocks.value ?? []
  let armyPremIcon = armiesPresentation?[armyId].premIcon
  let campaignSquads = (curCampaignAccessItem.value?.squads ?? [])
    .reduce(@(tbl, s) tbl.rawset(s.id, true), {})
  let squads = (lockedSquadsByArmy.value?[armyId] ?? [])
    .map(function(squad) {
      let { squadId } = squad
      let { battleExpBonus = 0 } = squadsCfgById.value?[armyId][squadId]
      let isPremium = battleExpBonus > 0
      local { premIcon = null } = squadsPresentation?[armyId][squadId]
      if (isPremium)
        premIcon = premIcon ?? armyPremIcon
      let isInCampaign = squadId in campaignSquads
      let unlock = unlocks.findvalue(function(u) {
        if (u?.unlockId == squadId)
          return true
        let { squads = [] } = u
        return squads.findvalue(@(squadInUnlock) squadInUnlock?.id == squadId)
      })
      return {
        squad = squad.__merge({premIcon})
        isPremium
        isInCampaign
        shopItem = unlock
      }
    })
    .filter(@(s) (!s.isInCampaign && s.shopItem != null)
      || (s.isInCampaign && isCampaignBought.value))
    .sort(@(a, b) (b.isInCampaign <=> a.isInCampaign)
      || (b.isPremium <=> a.isPremium)
      || (a.shopItem?.level ?? 0) <=> (b.shopItem?.level ?? 0))
  return squads
})

let squadsArmyLimits = Computed(@() limitsByArmy.value?[squadsArmy.value] ?? armyLimitsDefault)
let maxSquadsInBattle = Computed(@() squadsArmyLimits.value.maxSquadsInBattle)


let prepareSquad = @(squad, cfg, squadsLevel) squad.__merge({
  level = squadsLevel?[squad.squadId] ?? 0
  manageLocId = squad?.manageLocId ?? cfg?.manageLocId
  icon = squad?.icon ?? cfg?.icon
  vehicle = squad?.vehicle
  squadSize = squad?.squadSize ?? soldiersBySquad.value?[squad.guid].len() ?? 0
  battleExpBonus = cfg?.battleExpBonus ?? 0
})

let preparedSquads = Computed(function() {
  let visOrdered = clone curChoosenSquads.value
  foreach (squad in curUnlockedSquads.value)
    if (curChoosenSquads.value.indexof(squad) == null)
      visOrdered.append(squad)
  return visOrdered.map(@(squad) prepareSquad(squad, squadsCfgById.value?[squadsArmy.value][squad.squadId], allSquadsLevels.value))
})

let function updateSquadsList(_ = null) {
  let all = preparedSquads.value
  if (all.len() == 0) {
    chosenSquads.mutate(@(v) v.clear())
    reserveSquads.mutate(@(v) v.clear())
    return
  }
  let byId = {}
  all.each(@(s) byId[s.squadId] <- s)
  local chosen = chosenSquads.value.map(@(s) byId?[s?.squadId])
  let chosenCount = chosen.filter(@(s) s != null).len()
  local reserve = reserveSquads.value.map(@(s) byId?[s.squadId])
    .filter(@(s) s != null)

  if (chosenCount == 0 && reserve.len() == 0) { //new list, or just opened window
    let amount = curChoosenSquads.value.len()
    chosen = all.slice(0, amount)
    reserve = all.slice(amount)

    let gainSquadId = justGainSquadId.value
    if (gainSquadId != null) {
      let gainSquadIdx = chosen.findindex(@(s) s.squadId == gainSquadId)
      if (gainSquadIdx != null)
        reserve = [chosen.remove(gainSquadIdx)].extend(reserve)
    }
  }
  else {
    let left = clone byId
    chosen.each(function(s) { if (s != null) delete left[s.squadId] })
    reserve.each(function(s) { if (s.squadId in left) delete left[s.squadId] })
    foreach (squad in all)
      if (squad.squadId in left)
        reserve.append(squad)
  }

  if (chosen.len() != maxSquadsInBattle.value)
    chosen.resize(maxSquadsInBattle.value)

  chosenSquads(chosen)
  reserveSquads(reserve)
}
updateSquadsList()
foreach (v in [preparedSquads, maxSquadsInBattle]) v.subscribe(updateSquadsList)

preparedSquads.subscribe(function(uSquads) {
  if (uSquads.findvalue(@(s) s.squadId == selectedSquadId.value) != null)
    return
  selectedSquadId(uSquads?[0].squadId)
})

let function moveIndex(list, idxFrom, idxTo) {
  let res = clone list
  let val = res.remove(idxFrom)
  res.insert(idxTo, val)
  return res
}

let squadPlaceReasonData = {
  limit = {
    type = "limit"
    getErrorText = @() loc("msg/cantTakeExpiredSquad")
  }
  squadTypeZero = @(squadType) {
    type = $"{squadType}Zero"
    squadType
    getErrorText = @() loc($"msg/{squadType}IsZero")
  }
  squadTypeFull = @(squadType) {
    type = $"{squadType}Full"
    squadType
    getErrorText = @() loc($"msg/{squadType}Full", { maxSquads = squadsArmyLimits.value[squadType] })
  }
}

let getSquadTypeLimitId = @(squadType) squadType == "bike" ? "maxBikeSquads"
  : squadType != "" ? "maxVehicleSquads"
  : "maxInfantrySquads"

let function isSquadExpired(squad) {
  let { expireTime = 0 } = squad
  return expireTime > 0 && expireTime < serverTime.value
}

let function getCantTakeSquadReasonData(squad, squadsList, idxTo) {
  if (isSquadExpired(squad))
    return squadPlaceReasonData.limit()

  let { vehicleType = 0 } = squad
  let typeKey = getSquadTypeLimitId(vehicleType)
  let maxType = squadsArmyLimits.value[typeKey]
  if (maxType <= 0)
    return squadPlaceReasonData.squadTypeZero(typeKey)

  local curCount = 0
  foreach (idx, s in squadsList) {
    if (s == null || idx == idxTo)
      continue
    let squadVehicleType = s?.vehicleType ?? ""
    if (vehicleType == "bike") {
      if (squadVehicleType == "bike")
        ++curCount
    } else if (vehicleType != "") {
      if (squadVehicleType != "" && squadVehicleType != "bike")
        ++curCount
    } else {
      if (squadVehicleType == "")
        ++curCount
    }
  }
  if (curCount < maxType)
    return null

  return squadPlaceReasonData.squadTypeFull(typeKey)
}

let getCantTakeReason = @(squad, squadsList, idxTo)
  getCantTakeSquadReasonData(squad, squadsList, idxTo)?.getErrorText()

let function sendSquadActionToBQ(eventType, squadGuid, squadId) {
  sendBigQueryUIEvent("squad_management", null, {
    eventType
    squadGuid
    squadId
    army = squadsArmy.value
  })
}

local function changeSquadOrderByUnlockedIdx(idxFrom, idxTo) {
  let watchFrom = idxFrom < maxSquadsInBattle.value ? chosenSquads : reserveSquads
  if (idxFrom >= maxSquadsInBattle.value)
    idxFrom -= maxSquadsInBattle.value
  let { guid = null } = watchFrom.value?[idxFrom]
  let squadIdFrom = watchFrom.value?[idxFrom].squadId
  let watchTo = idxTo < maxSquadsInBattle.value ? chosenSquads : reserveSquads
  if (idxTo >= maxSquadsInBattle.value)
    idxTo -= maxSquadsInBattle.value

  if (watchFrom == watchTo) {
    watchFrom(moveIndex(watchFrom.value, idxFrom, idxTo))
    markSeenSquads(squadsArmy.value, [squadIdFrom])
    sendSquadActionToBQ("change_order", guid, squadIdFrom)
    return
  }
  if (watchFrom == chosenSquads) {
    if (chosenSquads.value[idxFrom] == null)
      return
    reserveSquads.mutate(@(list) list.insert(idxTo, chosenSquads.value[idxFrom]))
    chosenSquads.mutate(function(list) { list[idxFrom] = null })
    markSeenSquads(squadsArmy.value, [squadIdFrom])
    sendSquadActionToBQ("move_to_reserve", guid, squadIdFrom)
    return
  }

  if (idxFrom not in reserveSquads.value)
    return

  let cantChangeReason = getCantTakeReason(reserveSquads.value[idxFrom], chosenSquads.value, idxTo)
  if (cantChangeReason == null) {
    let prevSquad = chosenSquads.value[idxTo]
    chosenSquads.mutate(@(list) list[idxTo] = reserveSquads.value[idxFrom])
    reserveSquads.mutate(function(list) {
      if (prevSquad)
        list[idxFrom] = prevSquad
      else
        list.remove(idxFrom)
    })
    markSeenSquads(squadsArmy.value, [squadIdFrom])
    sendSquadActionToBQ("move_to_squad", guid, squadIdFrom)
    return
  }

  sendSquadActionToBQ("failed_management", guid, squadIdFrom)
  msgbox.show({
    uid = "change_squad_order"
    text = cantChangeReason
  })
}

let function changeList() {
  let squadId = selectedSquadId.value
  if (squadId == null)
    return

  local idx = chosenSquads.value.findindex(@(s) s?.squadId == squadId)
  if (idx != null) {
    markSeenSquads(squadsArmy.value, [squadId])
    reserveSquads.mutate(@(v) v.insert(0, chosenSquads.value[idx]))
    chosenSquads.mutate(function(v) { v[idx] = null })
    return
  }

  idx = reserveSquads.value.findindex(@(s) s.squadId == squadId)
  if (idx == null)
    return

  let newIdx = chosenSquads.value.findindex(@(s) s == null)
  if (newIdx == null) {
    msgbox.show({ text = loc("msg/battleSquadsFull") })
    return
  }
  let cantChangeReason = getCantTakeReason(reserveSquads.value[idx], chosenSquads.value, newIdx)
  if (cantChangeReason != null) {
    msgbox.show({
      uid = "change_squad_order"
      text = cantChangeReason
    })
    return
  }

  markSeenSquads(squadsArmy.value, [squadId])
  chosenSquads.mutate(function(v) { v[newIdx] = reserveSquads.value[idx] })
  reserveSquads.mutate(@(v) v.remove(idx))
}

let function findLastIndexToTakeSquad(squad) {
  let res = chosenSquads.value.findindex(@(s) s == null)
  if (res != null && getCantTakeReason(squad, chosenSquads.value, res) == null)
    return res

  for(local i = chosenSquads.value.len() - 1; i >= 0; i--)
    if (getCantTakeReason(squad, chosenSquads.value, i) == null)
      return i

  return -1
}

let selectedSquad = Computed(@()
  curUnlockedSquads.value.findvalue(@(squad) squad.squadId == selectedSquadId.value))

let selectedSquadSoldiers = Computed(function() {
  let squadGuid = selectedSquad.value?.guid
  if (squadGuid == null)
    return null

  let statuses = soldiersStatuses.value
  return (soldiersBySquad.value?[squadGuid] ?? [])
    .filter(@(soldier) statuses?[soldier?.guid] == READY)
})

let selSquadVehicleGameTpl = Computed(@()
  trimUpgradeSuffix(vehicleBySquad.value?[selectedSquad.value?.guid].gametemplate))

let function applyAndCloseImpl() {
  let armyId = squadsArmy.value
  let guids = unlockedSquads.value.filter(@(s) s != null).map(@(s) s.guid)
  let ids = unlockedSquads.value.filter(@(s) s != null).map(@(s) s.squadId)
  markSeenSquads(armyId, ids)
  set_squad_order(armyId, guids)
  close()
}

let function applyAndClose() {
  let selCount = chosenSquads.value.filter(@(s) s != null).len()
  if (selCount >= curChoosenSquads.value.len())
    applyAndCloseImpl()
  else
    msgbox.show({
      text = loc("msg/notFullSquadsAtApply")
      buttons = [
        { text = loc("Ok"), action = applyAndCloseImpl, isCurrent = true }
        { text = loc("Cancel"), isCancel = true, customStyle = { hotkeys = [[$"^{JB.B} | Esc"]] } }
      ]
    })
}

let function focusSquad(squadId) {
  if (squadId not in focusedSquads.value)
    focusedSquads.mutate(@(v) v.__merge({ [squadId] = true }))
}

let function unfocusSquad(squadId) {
  if (squadId in focusedSquads.value)
    focusedSquads.mutate(@(v) delete v[squadId])
}

let function closeAndOpenCampaign() {
  jumpToArmyProgress()
  close()
}

let function getUnlockedSquadsBySquadIds(squadIdsList) {
  return squadIdsList
    .map(@(squadId) unlockedSquads.value.findvalue(@(squad) squad?.squadId == squadId))
    .filter(@(squad) squad != null)
}

console_register_command(function(squadId) {
  if (squadId in focusedSquads.value)
    unfocusSquad(squadId)
  else
    focusSquad(squadId)
  console_print($"{squadId} toggled to", focusedSquads.value)
}, "meta.toggleFocusSquad")

return {
  openChooseSquadsWnd = function(army, selSquadId, isNew = false) {
    selectedSquadId(selSquadId)
    justGainSquadId(isNew ? selSquadId : null)
    squadsArmy(army)
  }
  closeChooseSquadsWnd = close
  applyAndClose
  closeAndOpenCampaign
  squadsArmy
  squadsArmyLimits
  maxSquadsInBattle
  unlockedSquads
  curArmyLockedSquadsData
  chosenSquads
  reserveSquads
  previewSquads
  displaySquads
  slotsCount
  changeSquadOrderByUnlockedIdx
  moveIndex
  changeList
  getCantTakeReason
  findLastIndexToTakeSquad
  focusedSquads
  focusSquad
  unfocusSquad

  selectedSquadId
  selectedSquad
  selectedSquadSoldiers
  selSquadVehicleGameTpl
  sendSquadActionToBQ
  getUnlockedSquadsBySquadIds
  isSquadExpired
  getCantTakeSquadReasonData
}