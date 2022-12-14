from "%darg/ui_imports.nut" import *

let { get_setting_by_blk_path } = require("settings")
let vehicleGroupLimit = mkWatched(persist, "vehicleGroupLimit", get_setting_by_blk_path("gameplay/limit_vehicle_by_group") ?? false)

return vehicleGroupLimit
