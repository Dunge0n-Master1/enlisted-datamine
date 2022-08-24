import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let {isAlive, isDowned} = require("%ui/hud/state/health_state.nut")
let {inVehicle} = require("%ui/hud/state/vehicle_state.nut")
let isMachinegunner = require("%ui/hud/state/machinegunner_state.nut")
let {get_controlled_hero} = require("%dngscripts/common_queries.nut")
let { localPlayerEid } = require("%ui/hud/state/local_player.nut")
let buildingTemplates = Watched([])
let buildingUnlocks = Watched([])
let availableBuildings = Watched([])
let availableStock = Watched(0.0)
let requirePrice = Watched([])
let buildingLimits = Watched([])
let selectedBuildingAllowRepair = Watched(false)
let buildingRepairText = Watched("hud/resupply_cannon")
let buildingAllowRecreates = Watched([])
let isBuildingToolEquipped = Watched(false)
let isBuildingAlive = Watched(true)
let canInteractWithDeadBuilding = Watched(false)
let isBuildingToolAvailable = Watched(true)
let isBuildingToolMenuAvailable = Computed(@() isBuildingToolAvailable.value && isBuildingToolEquipped.value && isAlive.value &&
  !isDowned.value && !inVehicle.value && !isMachinegunner.value)
let selectedBuildingName = Watched()
let selectedBuildingEid = Watched()
let selectedDestroyableObjectName = Watched()
let buildingPreviewId = Watched()

let selectedBuildingQuery = ecs.SqQuery("selectedBuildingQuery", {
  comps_ro = [
    ["building_menu__text", ecs.TYPE_STRING],
    ["fortification_repair__costPercent", ecs.TYPE_FLOAT, null],
    ["fortification_repair__text", ecs.TYPE_STRING, "hud/resupply_cannon"],
    ["isAlive", ecs.TYPE_BOOL, true],
    ["undestroyableBuilding", ecs.TYPE_TAG, null],
    ["builder_preview", ecs.TYPE_TAG, null],
    ["building_destroy__timeToDestroy", ecs.TYPE_FLOAT, null],
    ["fortification__canRepairDead", ecs.TYPE_TAG, null],
    ["additiveBuildNeedRepair", ecs.TYPE_BOOL, true],
  ]
})

let function updateBuildingsPriceRequirements(previewTemplates){
  let previewCostRequirements = []
  let previewAllowRecreates = []
  foreach (templateName in previewTemplates) {
    let template = ecs.g_entity_mgr.getTemplateDB().getTemplateByName(templateName)
    if (template == null)
      previewCostRequirements.append(0.0)
    let price = template.getCompValNullable("buildingCost")
    let destroySimilarBuilding = template.getCompValNullable("destroySimilarBuilding") != null
    previewCostRequirements.append(price ?? 0.0)
    previewAllowRecreates.append(destroySimilarBuilding)
  }
  requirePrice(previewCostRequirements)
  buildingAllowRecreates(previewAllowRecreates)
}

ecs.register_es("ui_building_tool_change_preview_es",
  {
    [["onChange", "onInit"]] = function (_eid, comp) {
      if (comp["gun__owner"] == get_controlled_hero())
        buildingPreviewId(comp["currentPreviewId"])
    },
  },
  {
    comps_track = [["previewEid", ecs.TYPE_EID]],
    comps_ro = [["gun__owner", ecs.TYPE_EID], ["currentPreviewId", ecs.TYPE_INT]]
  }
)

ecs.register_es("ui_building_selected_object_es",
  {
    [["onChange", "onInit"]] = function (_eid, comp) {
      let selectedObject = comp["human_use_object__selectedBuilding"]
      local name = null
      local allowRepair = false
      local alive = true
      local canBeDestroyed = false
      local fortificationRepairText = "hud/resupply_cannon"
      local canRepairDead = false
      selectedBuildingQuery(selectedObject, function(_eid, comp) {
        name = comp["building_menu__text"]
        allowRepair = comp["additiveBuildNeedRepair"] && (comp["fortification_repair__costPercent"] != null)
        alive = comp["isAlive"]
        canRepairDead = comp["fortification__canRepairDead"] != null
        fortificationRepairText = comp["fortification_repair__text"]
        canBeDestroyed = (comp["builder_preview"] != null || comp["building_destroy__timeToDestroy"] != null) && comp["undestroyableBuilding"] == null
      })
      selectedBuildingName(name)
      selectedDestroyableObjectName(canBeDestroyed ? name : null)
      selectedBuildingAllowRepair(allowRepair)
      isBuildingAlive(alive)
      canInteractWithDeadBuilding(canRepairDead)
      buildingRepairText(fortificationRepairText)
      selectedBuildingEid(selectedObject)
    },
  },
  {
    comps_track = [["human_use_object__selectedBuilding", ecs.TYPE_EID]],
    comps_ro = [["human_weap__currentGunEid", ecs.TYPE_EID]],
    comps_rq = ["hero"]
  }
)

ecs.register_es("ui_additive_build_need_repair_additive_es",
  {
    [["onChange", "onInit"]] = function (eid, comp) {
      if (selectedBuildingEid.value == eid) {
        selectedBuildingAllowRepair(comp["additiveBuildNeedRepair"])
      }
    }
  },
  {
    comps_track = [["additiveBuildNeedRepair", ecs.TYPE_BOOL]],
  }
)

ecs.register_es("ui_building_tool_avalible_es", {
    [["onChange", "onInit"]] = function (_eid, comp) {
      if (comp["is_local"])
        isBuildingToolAvailable(comp["engieer__buildingToolAvailable"])
    }
  },
  {
    comps_track = [["engieer__buildingToolAvailable", ecs.TYPE_BOOL]],
    comps_ro = [["is_local", ecs.TYPE_BOOL]],
  }
)

ecs.register_es("ui_available_buildings_es",
  {
    [["onChange", "onInit"]] = function(_eid, comp) {
      if (comp.is_local)
        availableBuildings(comp.availableBuildings.getAll() ?? [])
    }
  },
  {
    comps_track = [["is_local", ecs.TYPE_BOOL], ["availableBuildings", ecs.TYPE_INT_LIST]],
    comps_rq = ["player"]
  }
)

ecs.register_es("ui_hero_Resources_buildings_es",
  {
    [["onChange", "onInit", "onDestroy"]] = function(_eid, comp) {
      availableStock(comp.stockOfBuilderCapabilities)
    }
  },
  {
    comps_track = [["stockOfBuilderCapabilities", ecs.TYPE_FLOAT]],
    comps_rq = ["hero"]
  }
)

let buildingGunQuery = ecs.SqQuery("buildingGunQuery", {
  comps_ro=[["previewTemplate", ecs.TYPE_STRING_LIST], ["buildingLimits", ecs.TYPE_INT_LIST]]
})

ecs.register_es("building_tool_equipped_es",
  {
    [["onChange", "onInit"]] = function(_eid, comp) {
      let currentGunEid = comp["human_weap__currentGunEid"]
      let buildingToolInCurrentGun = ecs.obsolete_dbg_get_comp_val(currentGunEid, "item__weapType", "") == "building_tool"
      isBuildingToolEquipped(buildingToolInCurrentGun)
      if (buildingToolInCurrentGun){
        local templates = []
        local limits = []
        buildingGunQuery(currentGunEid, function(_, comp) {
          templates = comp["previewTemplate"].getAll()
          limits = comp["buildingLimits"].getAll()
        })
        buildingTemplates(templates)
        updateBuildingsPriceRequirements(templates)
        buildingLimits(limits)
      }
    }
    function onDestroy(_eid, _comp){
      isBuildingToolEquipped(false)
    }
  },
  {
    comps_track = [["human_weap__currentGunEid", ecs.TYPE_EID],
                   ["squad_member__squad", ecs.TYPE_EID]],
    comps_rq = ["hero"]
  }
)

ecs.register_es("building_unlocks_ui_es",
  {
    [["onChange", "onInit"]] = function(_eid, comp) {
      if (comp["squad__ownerPlayer"] == localPlayerEid.value)
        buildingUnlocks(comp["buildings__unlockIds"].getAll())
    }
  },
  {
    comps_track = [["buildings__unlockIds", ecs.TYPE_INT_LIST]],
    comps_ro = [["squad__ownerPlayer", ecs.TYPE_EID]]
  }
)

return {
  buildingTemplates
  buildingUnlocks
  requirePrice
  availableStock
  isBuildingToolEquipped
  isBuildingToolMenuAvailable
  selectedBuildingName
  selectedDestroyableObjectName
  selectedBuildingAllowRepair
  buildingPreviewId
  buildingAllowRecreates
  availableBuildings
  buildingLimits
  isBuildingAlive
  buildingRepairText
  canInteractWithDeadBuilding
}
