import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let {get_setting_by_blk_path} = require("settings")
let {sendNetEvent, CmdLimitVehicleByGroup} = require("dasevents")
let {getOnlineSaveData, optionCheckBox, optionCtor} = require("%ui/hud/menus/options/options_lib.nut")
let vehicleGroupLimit = require("%enlSqGlob/vehicleGroupLimitState.nut")

let localPlayerQuery = ecs.SqQuery("localPlayerQuery", {comps_rq = ["localPlayer"]})

vehicleGroupLimit.subscribe(function(v) {
  localPlayerQuery.perform(@(eid, _comp) sendNetEvent(eid, CmdLimitVehicleByGroup({isLimited=v})))
})

let optionLimitVehicleByGroupCtor = @(actionCb) function (opt, group, xmbNode) {
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
    @() get_setting_by_blk_path(blkPath) ?? false)
  return optionCtor({
    name = title
    tab = "Game"
    widgetCtor = optionLimitVehicleByGroupCtor(actionCb)
    var = watch
    setValue = setValue
    blkPath = blkPath
  })
}

return [
  mkOption(loc("gameplay/limit_vehicle_by_group"), "limit_vehicle_by_group", @(enabled) vehicleGroupLimit(enabled))
]
