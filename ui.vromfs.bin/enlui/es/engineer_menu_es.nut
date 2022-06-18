import "%dngscripts/ecs.nut" as ecs
let { showBuildingToolMenu } = require("%ui/hud/state/building_tool_menu_state.nut")

let setEngineerMenuOpenQuery = ecs.SqQuery("setEngineerMenuOpenQuery", {
  comps_rw = [["engineer__isMenuOpen", ecs.TYPE_BOOL]],
  comps_rq = ["hero"]
})

showBuildingToolMenu.subscribe(@(v)
  setEngineerMenuOpenQuery(@(_eid, comp) comp["engineer__isMenuOpen"] = v )
)