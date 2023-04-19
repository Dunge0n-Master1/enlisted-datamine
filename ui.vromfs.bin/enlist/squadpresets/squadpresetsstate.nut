from "%enlSqGlob/ui_library.nut" import *

let { mkOnlineSaveData } = require("%enlSqGlob/mkOnlineSaveData.nut")
let { onlineSettingUpdated } = require("%enlist/options/onlineSettings.nut")
let { hasPremium } = require("%enlist/currency/premium.nut")

let FREE_SLOTS_COUNT = 2
let PREMIUM_SLOTS_COUNT = 1
let MAX_PRESETS_COUNT = FREE_SLOTS_COUNT + PREMIUM_SLOTS_COUNT
let availablePresetsCount = Computed(@() hasPremium.value ? MAX_PRESETS_COUNT : FREE_SLOTS_COUNT)

let squadsPresetsStorage = mkOnlineSaveData("presetSquads", @() {})
let setSquadsPreset = squadsPresetsStorage.setValue
let squadsPresetWatch = squadsPresetsStorage.watch

let function checkOversizePresets() {
  if (!onlineSettingUpdated.value)
    return

  let presetsUpd = {}
  foreach (armyId, presets in squadsPresetWatch.value)
    if (presets.len() > MAX_PRESETS_COUNT) {
      log($"[Squads Presets] resize presets for {armyId}, {presets.len()} > {MAX_PRESETS_COUNT}")
      presets.resize(MAX_PRESETS_COUNT)
      presetsUpd[armyId] <- presets
    }
  if (presetsUpd.len())
    setSquadsPreset(presetsUpd)
}

onlineSettingUpdated.subscribe(@(_) checkOversizePresets())

return {
  setSquadsPreset
  squadsPresetWatch
  availablePresetsCount
  MAX_PRESETS_COUNT
}