from "%enlSqGlob/ui_library.nut" import *

let { register_command } = require("console")
let { setSquadsPreset, squadsPresetWatch } = require("%enlist/squadPresets/squadPresetsState.nut")
let { getRomanNumeral } = require("%sqstd/math.nut")
let { unlockedSquads, reserveSquads, chosenSquads, previewSquads, slotsCount,
  getCantTakeSquadReasonData
} = require("%enlist/soldiers/model/chooseSquadsState.nut")
let { addPopup } = require("%enlSqGlob/ui/popup/popupsState.nut")

let logP = require("%enlSqGlob/library_logs.nut").with_prefix("[Soldiers Presets] ")

let function savePresets(armyId, idx, preset) {
  let newPresetsList = clone squadsPresetWatch.value?[armyId] ?? []

  if (idx > newPresetsList.len()) {
    logP($"Save preset: try to use not existing index {idx}, for", newPresetsList)
    return
  }

  if (preset == null)
    newPresetsList.remove(idx)
  else if (idx < 0)
    newPresetsList.append(preset)
  else
    newPresetsList[idx] = newPresetsList[idx].__merge(preset)


  let squadsPreset = clone squadsPresetWatch.value
  if (newPresetsList.len()) {// Save data with presets
    if (armyId not in squadsPreset)
      squadsPreset[armyId] <- []

    squadsPreset[armyId] = newPresetsList
  }
  else //Try to save empty data. Remove whole block
    delete squadsPreset[armyId]

  setSquadsPreset(squadsPreset)
}

let getPreset = function(armyId, idx) {
  let armyPresets = squadsPresetWatch.value?[armyId] ?? []
  if (idx >= armyPresets.len()) {
    logP($"try to accept not existing preset index {idx}", armyPresets)
    return null
  }

  return armyPresets[idx]
}

let function createSquadsPreset(armyId, squadIds) {
  if (squadIds.len() == 0) {
    logP("Create: empty squad data.")
    return
  }

  savePresets(armyId, -1, {
    name = loc("squads/presets/new",
      { name = getRomanNumeral((squadsPresetWatch.value?[armyId] ?? []).len() + 1) })
    preset = squadIds
  })
}

let function changePresetInfo(armyId, idx, updateInfo) {
  let preset = getPreset(armyId, idx)
  if (!preset)
    return

  savePresets(armyId, idx, preset.__merge(updateInfo))
}

let updateSquadsPreset = @(armyId, idx, preset) changePresetInfo(armyId, idx, { preset })
let renameSquadsPreset = @(armyId, idx, name) changePresetInfo(armyId, idx, { name })
let deleteSquadsPreset = @(armyId, idx) savePresets(armyId, idx, null)


let function applySquadsPreset(armyId, idx) {
  let preset = clone getPreset(armyId, idx)?.preset
  if (!preset)
    return

  let squadPlaceErrors = {}
  let newChosenSquads = []

  //Filter by actual requirements
  previewSquads.value.each(function(squad) {
    if (!squad?.squadId) //Empty Slot
      return

    let reasonData = getCantTakeSquadReasonData(squad, newChosenSquads, newChosenSquads.len())
    if (reasonData != null) {
      if (reasonData.type not in squadPlaceErrors)
        squadPlaceErrors[reasonData.type] <- reasonData.getErrorText()
      return
    }

    newChosenSquads.append(squad)
  })

  if (squadPlaceErrors.len())
    foreach (errorType, errorText in squadPlaceErrors)
      addPopup({
        id = $"{errorType}_squad_preset_error"
        text = errorText
        needPopup = true
        styleName = "error"
      })

  if (newChosenSquads.len() == 0)
    return

  //Resize for current slotbar size
  newChosenSquads.resize(slotsCount.value, null)

  //Collect final squads with squadId for fast filter
  let previewSquadIds = {}
  newChosenSquads.each(function(squad) {
    if (squad?.squadId)
      previewSquadIds[squad.squadId] <- true
  })

  //Filter all squads list, making new reserve list
  let newReserveSquads = unlockedSquads.value.filter(@(squad) squad != null && squad.squadId not in previewSquadIds)

  chosenSquads(newChosenSquads)
  reserveSquads(newReserveSquads)
}

register_command(createSquadsPreset, "debug.preset.squads.create")
register_command(updateSquadsPreset, "debug.preset.squads.update")
register_command(deleteSquadsPreset, "debug.preset.squads.delete")
register_command(renameSquadsPreset, "debug.preset.squads.rename")
register_command(applySquadsPreset, "debug.preset.squads.accept")


return {
  createSquadsPreset
  updateSquadsPreset
  deleteSquadsPreset
  renameSquadsPreset
  applySquadsPreset
}