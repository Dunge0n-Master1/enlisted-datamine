import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let { logerr } = require("dagor.debug")

let DB = ecs.g_entity_mgr.getTemplateDB()
let vehicleSpecsDB = mkWatched(persist, "vehicleSpecsDB", {})

let function getVehicleSpecBlkPath(template, name) {
  let path = template.getCompValNullable(name)
  if (path != null)
    return path.slice(0, path.indexof(":") ?? path.len())
  return null
}

let function isVehicleNeedsCalc(specsDB, templateName, curUpgrades) {
  let specsTmpl = specsDB?[templateName]
  if (specsTmpl == null)
    return true

  let { upgrades = {} } = specsTmpl
  if (upgrades.len() != curUpgrades.len())
    return true

  foreach (k, v in curUpgrades)
    if (upgrades?[k] != v)
      return true

  return false
}

let function requireVehicleSpec(templateName, upgrades = {}) {
  if (!isVehicleNeedsCalc(vehicleSpecsDB.value, templateName, upgrades))
    return {}

  let template = DB.getTemplateByName(templateName)
  if (template == null) {
    logerr($"Template '{templateName}' was not found")
    return {}
  }

  local physModificationsBlk = ""
  foreach (name, value in upgrades) {
    let v = value / 100 + 1
    physModificationsBlk = $"{physModificationsBlk}{name}:r={v};";
  }

  let tankSpecBlkPath = getVehicleSpecBlkPath(template, "vehicle_net_phys__blk")
  if (tankSpecBlkPath != null) {
    ecs.g_entity_mgr.createEntity("tank_phys_spec", {
      "tankTemplateName"     : [templateName,         ecs.TYPE_STRING]
      "tank_phys_spec__blk"  : [tankSpecBlkPath,      ecs.TYPE_STRING]
      "physModificationsBlk" : [physModificationsBlk, ecs.TYPE_STRING]
    })

    return {
      upgrades
      maxSpeed = 0.0
    }
  }

  let planeSpecBlkPath = getVehicleSpecBlkPath(template, "plane_net_phys__blk")
  if (planeSpecBlkPath != null) {
    let collresName = template.getCompValNullable("collres__res")
    if (collresName == null) {
      logerr($"Component 'collres__res' was not found for template '{templateName}'")
      return {}
    }

    ecs.g_entity_mgr.createEntity("plane_phys_spec", {
      "planeTemplateName"    : [templateName,         ecs.TYPE_STRING]
      "plane_phys_spec__blk" : [planeSpecBlkPath,     ecs.TYPE_STRING]
      "collresName"          : [collresName,          ecs.TYPE_STRING]
      "physModificationsBlk" : [physModificationsBlk, ecs.TYPE_STRING]
    })

    return {
      upgrades
      maxSpeed = 0.0
      maxClimb = 0.0
      bestTurnTime = 0.0
    }
  }

  return {}
}

ecs.register_es("tank_phys_spec_calculated_es",
  {
    function onChange(_evt, eid, comp) {
      let { tankTemplateName } = comp
      vehicleSpecsDB.mutate(function(v) {
        // to be sure that data table will be changed, thus triggering computed at mkSpecsWatch
        let data = v?[tankTemplateName] ?? {}
        data["maxSpeed"] <- comp["tank_phys_spec_result__maxSpeed"]
        v[tankTemplateName] <- data
      })

      ecs.g_entity_mgr.destroyEntity(eid)
    }
  },
  {
    comps_ro = [
      ["tankTemplateName", ecs.TYPE_STRING],
    ],
    comps_track = [
      ["tank_phys_spec_result__maxSpeed", ecs.TYPE_FLOAT],
    ],
  }
)

ecs.register_es("plane_phys_spec_calculated_es",
  {
    function onChange(_evt, eid, comp) {
      let { planeTemplateName } = comp
      vehicleSpecsDB.mutate(function(v) {
        let data = v?[planeTemplateName] ?? {}
        data["maxSpeed"]     <- comp["plane_phys_spec_result__maxSpeed"]
        data["maxClimb"]     <- comp["plane_phys_spec_result__maxClimb"]
        data["bestTurnTime"] <- comp["plane_phys_spec_result__bestTurnTime"]
        v[planeTemplateName] <- data
      })

      ecs.g_entity_mgr.destroyEntity(eid)
    }
  },
  {
    comps_ro = [
      ["planeTemplateName", ecs.TYPE_STRING],
    ],
    comps_track = [
      ["plane_phys_spec_result__maxSpeed",     ecs.TYPE_FLOAT],
      ["plane_phys_spec_result__maxClimb",     ecs.TYPE_FLOAT],
      ["plane_phys_spec_result__bestTurnTime", ecs.TYPE_FLOAT],
    ],
  }
)

let mkUpgradeWatch = @(upgradesWatch, upgradesId, upgradeIdx)
  Computed(@() upgradesWatch.value?[upgradesId][upgradeIdx] ?? {})

let function mkSpecsWatch(upgradesWatch, item) {
  let { gametemplate = null, itemtype = null } = item
  return itemtype == "vehicle"
    ? Computed(@() requireVehicleSpec(gametemplate, upgradesWatch.value)
        .__update(vehicleSpecsDB.value?[gametemplate] ?? {}))
    : Computed(@() vehicleSpecsDB.value?[gametemplate] ?? {})
}

return {
  vehicleSpecsDB
  requireVehicleSpec
  mkUpgradeWatch
  mkSpecsWatch
}