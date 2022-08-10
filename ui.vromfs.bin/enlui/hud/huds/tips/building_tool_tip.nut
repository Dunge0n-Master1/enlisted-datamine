from "%enlSqGlob/ui_library.nut" import *

let { isBuildingToolMenuAvailable, selectedBuildingName, selectedDestroyableObjectName, isBuildingAlive,
  buildingRepairText, buildingPreviewId, buildingAllowRecreates, canInteractWithDeadBuilding,
  availableBuildings, selectedBuildingAllowRepair } = require("%ui/hud/state/building_tool_state.nut")
let {isRadioMode} = require("%ui/hud/state/enlisted_hero_state.nut")
let {isMortarMode} = require("%ui/hud/state/mortar.nut")
let {isAlive, isDowned} = require("%ui/hud/state/health_state.nut")
let { inVehicle } = require("%ui/hud/state/vehicle_state.nut")
let { showBuildingToolMenu } = require("%ui/hud/state/building_tool_menu_state.nut")
let {tipCmp} = require("%ui/hud/huds/tips/tipComponent.nut")
let { DEFAULT_TEXT_COLOR, FAIL_TEXT_COLOR } = require("%ui/hud/style.nut")
let {fortificationPreviewCanBeRotated} = require("%ui/hud/state/fortification_preview_can_be_rotated.nut")
let { usefulBoxHintFull, usefulBoxHintEmpty, isUsefulBoxEmpty } = require("%ui/hud/state/useful_box_state.nut")

let function notAbleBuildStructures() {
  let res = { watch = [selectedBuildingName, buildingPreviewId, buildingAllowRecreates, availableBuildings, isBuildingToolMenuAvailable] }
  if (!isBuildingToolMenuAvailable.value || selectedBuildingName.value != null)
    return res
  if ((availableBuildings.value?[buildingPreviewId.value] ?? -1) != 0)
    return res
  let allowRecreate = buildingAllowRecreates.value?[buildingPreviewId.value] ?? false
  return res.__update({
    hplace = ALIGN_LEFT
    vplace = ALIGN_BOTTOM
    flow = FLOW_HORIZONTAL
    children = tipCmp({
      text = allowRecreate ? loc("building_previous_will_be_destroyed", "The previous building of this type will be destroyed automatically.") :
        loc("building_blocked_by_no_available_buildings_by_type", "Cant build anymore")
      textColor = FAIL_TEXT_COLOR
    })
  })
}

let function buildStructure() {
  let res = { watch = [isBuildingToolMenuAvailable, showBuildingToolMenu, fortificationPreviewCanBeRotated] }
  if (!isBuildingToolMenuAvailable.value || showBuildingToolMenu.value)
    return res
  return res.__update({
    hplace = ALIGN_CENTER
    vplace = ALIGN_BOTTOM
    flow = FLOW_HORIZONTAL
    children = [
      tipCmp({
        text = loc("hud/build_building", "Build structure")
        inputId = "Human.Shoot"
        textColor = DEFAULT_TEXT_COLOR
      }),
      tipCmp({
        text = loc("tips/open_building_menu", "Select structure")
        inputId = "HUD.BuildingToolMenu"
        textColor = DEFAULT_TEXT_COLOR
      }),
      fortificationPreviewCanBeRotated.value
        ? tipCmp({
          text = loc("tips/mirror_building", "Mirror structure")
          inputId = "Human.Reload"
          textColor = DEFAULT_TEXT_COLOR
        })
        : null
    ]
  })
}

let function destroyStructure() {
  let res = { watch = [selectedDestroyableObjectName, inVehicle, isAlive, isDowned, isMortarMode, isRadioMode] }
  if (!selectedDestroyableObjectName.value || inVehicle.value || !isAlive.value || isDowned.value || isMortarMode.value || isRadioMode.value)
    return res
  return res.__update({
    children = tipCmp({
      text = "{0} : {1}".subst(loc("hud/destroy_building"), loc(selectedDestroyableObjectName.value))
      inputId = "Human.BuildingAction"
      textColor = DEFAULT_TEXT_COLOR
    })
  })
}

let function resupplyCannonStructure() {
  let res = { watch = [selectedBuildingName, inVehicle, isBuildingAlive, buildingRepairText, canInteractWithDeadBuilding,
    isAlive, isDowned, isMortarMode, isRadioMode, isBuildingToolMenuAvailable, selectedBuildingAllowRepair] }

  let canInteractWithBuilding = (isBuildingAlive.value || canInteractWithDeadBuilding.value)
  if (!isBuildingToolMenuAvailable.value || !selectedBuildingName.value || inVehicle.value || !canInteractWithBuilding
      || !isAlive.value || isDowned.value || isMortarMode.value || isRadioMode.value || !selectedBuildingAllowRepair.value)
    return res
  return res.__update({
    children = tipCmp({
      text = "{0} : {1}".subst(loc(buildingRepairText.value), loc(selectedBuildingName.value))
      inputId = "Human.VehicleMaintenance"
      textColor = DEFAULT_TEXT_COLOR
    })
  })
}

let function useUsefulBox() {
  let res = { watch = [usefulBoxHintFull, usefulBoxHintEmpty, isUsefulBoxEmpty] }
  let text = isUsefulBoxEmpty.value ? usefulBoxHintEmpty : usefulBoxHintFull

  if (!text.value)
    return res

  return res.__update({
    children = tipCmp({
      text = loc(text.value)
      inputId = isUsefulBoxEmpty.value ? "" : "Human.Use"
      textColor = isUsefulBoxEmpty.value ? Color(120, 120, 120, 120) : DEFAULT_TEXT_COLOR
    })
  })
}

return [
  notAbleBuildStructures
  buildStructure
  useUsefulBox
  destroyStructure
  resupplyCannonStructure
]
