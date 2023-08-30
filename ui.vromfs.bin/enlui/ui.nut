import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

#default:forbid-root-table

require("%enlSqGlob/sqevents.nut")
let {DBGLEVEL} = require("dagor.system")
let {logerr, clear_logerr_interceptors} = require("dagor.debug")
let {scan_folder} = require("dagor.fs")
require("%sqstd/regScriptDebugger.nut")(debugTableData)
let registerScriptProfiler = require("%sqstd/regScriptProfiler.nut")
require("%ui/sound_console.nut")

set_nested_observable_debug(VAR_TRACE_ENABLED)

clear_logerr_interceptors()
ecs.clear_vm_entity_systems()

let { safeAreaAmount } = require("%enlSqGlob/safeArea.nut")
screenScaleUpdate(safeAreaAmount.value)

let {inspectorToggle} = require("%darg/helpers/inspector.nut")

console_register_command(@() inspectorToggle(), "ui.inspector_battle")
console_register_command(@() dump_observables(), "script.dump_observables")
registerScriptProfiler("hud")


require("daRg.debug").requireFontSizeSlot(DBGLEVEL>0 && VAR_TRACE_ENABLED) //warning disable: -const-in-bool-expr
let use_realfs = (DBGLEVEL > 0) ? true : false
let files = scan_folder({root=$"%ui/es", vromfs = true, realfs = use_realfs, recursive = true, files_suffix=".nut"})
foreach (i in files) {
  try {
    require(i)
  } catch (e) {
    logerr($"UI module {i} was not loaded - see log for details")
  }
}

try{
  require("%ui/hud/onHudScriptLoad.nut")
}
catch(e){
  log(e)
  logerr("onHudScriptLoad was not loaded - see log for details")
}

return require("root.nut")

