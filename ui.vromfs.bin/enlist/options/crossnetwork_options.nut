from "%enlSqGlob/ui_library.nut" import *

let saveCrossnetworkPlayValue = require("crossnetwork_save.nut")
let saveCrossnetworkChatValue = require("crossnetwork_chat_save.nut")
let { optionSpinner, defCmp, optionCtor, optionCheckBox, getOnlineSaveData, mkDisableableCtor
} = require("%ui/hud/menus/options/options_lib.nut")
let { crossnetworkPlay, savedCrossnetworkPlayId,
  savedCrossnetworkStateUpdate, CrossplayState, savedCrossnetworkChatId,
  savedCrossnetworkChatStateUpdate, availableCrossplayOptions,
  isCrossplayOptionNeeded, isCrossnetworkChatOptionNeeded
} = require("%enlSqGlob/crossnetwork_state.nut")
let { isInQueue } = require("%enlist/state/queueState.nut")
let { onlineSettingUpdated, settings} = require("%enlist/options/onlineSettings.nut")

let { get_setting_by_blk_path } = require("settings")
let { selfMemberState, isSquadLeader } = require("%enlist/squad/squadState.nut")


let settingsCrossnetworkPlay = Computed(function() {
  local val = null
  if (onlineSettingUpdated.value)
    val = settings.value?[savedCrossnetworkPlayId]

  if (val == null)
    val = get_setting_by_blk_path(savedCrossnetworkPlayId)

  return val
})

let settingsCrossnetworkChat = Computed(function() {
  local val = null
  if (onlineSettingUpdated.value)
    val = settings.value?[savedCrossnetworkChatId]

  return val
})

let function setValBySettings(val) {
  if (!onlineSettingUpdated.value)
    return
  savedCrossnetworkStateUpdate(val)
}

settingsCrossnetworkPlay.subscribe(setValBySettings)
setValBySettings(settingsCrossnetworkPlay.value)
onlineSettingUpdated.subscribe(@(val) val ? setValBySettings(settingsCrossnetworkPlay.value) : null)


let function setValChatBySettings(val) {
  if (!onlineSettingUpdated.value)
    return
  savedCrossnetworkChatStateUpdate(val)
}

settingsCrossnetworkChat.subscribe(setValChatBySettings)
setValChatBySettings(settingsCrossnetworkChat.value)

let isOptionActive = Computed(@() !isInQueue.value
  && (isSquadLeader.value || !selfMemberState.value?.ready))

let mkOptionCrossplayOption = @() {
  name = loc("gameplay/crossnetwork_play"),
  tab = "Game",
  widgetCtor = mkDisableableCtor(
    Computed(@() isOptionActive.value ? null : loc("options/blocked_in_queue")),
    optionSpinner)
  originalVal = CrossplayState.ALL,
  var = crossnetworkPlay,
  available = availableCrossplayOptions,
  isEqual = defCmp,
  setValue = saveCrossnetworkPlayValue,
  valToString = @(v) loc($"option/crossplay/{v}")
  isAvailableWatched = isCrossplayOptionNeeded
}

let function mkOptionCrosschatOption() {
  let { watch, setValue } = getOnlineSaveData(savedCrossnetworkChatId,
    @() get_setting_by_blk_path(savedCrossnetworkChatId) ?? true)
  return optionCtor({
    name = loc("gameplay/crossnetwork_chat")
    tab = "Game"
    widgetCtor = optionCheckBox
    var = watch
    setValue = @(val) saveCrossnetworkChatValue(val, setValue)
    blkPath = savedCrossnetworkChatId
    isAvailableWatched = Computed(@() isCrossplayOptionNeeded.value && isCrossnetworkChatOptionNeeded)
  })
}

return { crossnetworkOptions = [
  mkOptionCrossplayOption()
  isCrossnetworkChatOptionNeeded ? mkOptionCrosschatOption() : null
]}