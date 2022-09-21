import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let {get_setting_by_blk_path, set_setting_by_blk_path} = require("settings")
let {violenceState, violenceStateUpdate, forcedViolenceState} = require("%enlSqGlob/violenceState.nut")
let {getOnlineSaveData, optionCheckBox, optionCtor} = require("%ui/hud/menus/options/options_lib.nut")
let { ps4RegionName, SCE_REGION } = require("%dngscripts/platform.nut")

let optionViolenceCtor = @(actionCb) function (opt, group, xmbNode) {
  let optSetValue = opt.setValue
  let function setValue(val) {
    optSetValue(val)
    actionCb(val)
  }
  opt = opt.__merge({ setValue })
  return optionCheckBox(opt, group, xmbNode)
}

let function mkOption(title, field, actionCb) {
  let blkPath = $"gameplay/{field}"
  let { watch, setValue } = getOnlineSaveData(blkPath,
    @() get_setting_by_blk_path(blkPath) ?? true)
  return optionCtor({
    name = title
    tab = "Game"
    widgetCtor = optionViolenceCtor(actionCb)
    var = watch
    setValue = setValue
    blkPath = blkPath
  })
}

let isOptionsAvailable = @() ecs.g_entity_mgr.getTemplateDB().getTemplateByName("violence_settings") != null

let violenceOptions = []
if (isOptionsAvailable()) {
  if (forcedViolenceState.isBloodEnabled == null)
    violenceOptions.append(mkOption(loc("gameplay/violence_blood"), "violence_blood", @(enabled) violenceStateUpdate(violenceState.value.__merge({isBloodEnabled = enabled}))))

  if (forcedViolenceState.isGoreEnabled == null)
    // Don't show in option for sony japan and force turn off in case if it was on
    if (ps4RegionName != SCE_REGION.SCEJ)
      violenceOptions.append(mkOption(loc("gameplay/violence_gore"),  "violence_gore",  @(enabled) violenceStateUpdate(violenceState.value.__merge({isGoreEnabled = enabled}))))
    else {
      violenceStateUpdate(violenceState.value.__merge({isGoreEnabled = false}))
      set_setting_by_blk_path("gameplay/violence_gore", false)
    }
}

return { violenceOptions }