from "%enlSqGlob/ui_library.nut" import *
import "%dngscripts/ecs.nut" as ecs
let { round, abs, sin, atan, PI } = require("math")
let regexp2 = require("regexp2")
let DataBlock = require("DataBlock")
let colorize = require("%ui/components/colorize.nut")
let { doesLocTextExist } = require("dagor.localize")
let { activeTxtColor } = require("%enlSqGlob/ui/viewConst.nut")
let { floatToStringRounded, isStringInteger, utf8ToLower } = require("%sqstd/string.nut")

let rePartNameEnding = regexp2(@"(_l|_r)?(_\d+)?$")

let xrayPartsLocNameRemap = {
  optic = [ "optic_body", "optic_body_mg", "optic_turret" ]
  ammo = [ "ammo_body", "ammo_turret" ]
  composite_armor = [ "composite_armor_hull", "composite_armor_turret" ]
  ex_era = [ "ex_era_hull", "ex_era_turret" ]
}

let getSignStr = @(num) num == 0 ? "" : num >= 0 ? "+" : "\u2212"

let function getBlk(path) {
  let blk = DataBlock()
  if (path != "")
    blk.load(path)
  return blk
}

let function getPartIdx(partName) {
  let s = partName.split("_").pop()
  return isStringInteger(s) ? s.tointeger() : 0
}

let getWeaponByPartName = @(vehicleArmament, partName) vehicleArmament.findvalue(
  @(gun) (gun?.name ?? "") == partName,
  vehicleArmament?[getPartIdx(partName)])

let function getCrewMemberLocName(vehicle, partName) {
  let template = ecs.g_entity_mgr.getTemplateDB().getTemplateByName(vehicle.gametemplate)
  let seats = template?.getCompValNullable("vehicle_seats__seats").getAll()
  let seat = seats?.findvalue(@(s) s?.attachNode == partName)
  return loc(seat?.locName ?? "armor_class/steel_tankman")
}

let function getEngineModelName(engineBlk) {
  return " ".join([
    engineBlk?.manufacturer ? loc($"engine_manufacturer/{engineBlk.manufacturer}") : ""
    engineBlk?.model ? loc($"engine_model/{engineBlk.model}") : ""
  ], true)
}

let function getTankEngineDesc(vehicleUpgradedData, dmBlkPath) {
  let desc = []
  let unitBlk = getBlk(dmBlkPath)
  let engineBlk = unitBlk?.VehiclePhys.engine
  let engineModelName = getEngineModelName(engineBlk)
  desc.append(engineModelName)
  let engineType = engineBlk?.type ?? (engineModelName != "" ? "diesel" : "")
  if (engineType != "")
    desc.append("".concat(loc("xray/part_type"), loc("ui/colon"), loc($"xray/engine_type/{engineType}")))
  let horsePowers = round(vehicleUpgradedData?["engine__horsePowers"] ?? 0)
  let maxRPM = round(vehicleUpgradedData?["engine__maxRPM"] ?? 0)
  if (horsePowers > 0 && maxRPM > 0)
    desc.append(loc("itemDetails/enginePowerValues", { val = horsePowers, rpm = maxRPM }))
  return desc
}

let function getTransmissionParams(maxSpeed, gearRatiosBlk) {
  if (maxSpeed == 0 || gearRatiosBlk == null)
    return null
  local gearsF = 0
  local gearsB = 0
  local ratioF = 0
  local ratioB = 0
  foreach (gear in (gearRatiosBlk % "ratio")) {
    if (gear > 0) {
      gearsF++
      ratioF = ratioF ? min(ratioF, gear) : gear
    }
    else if (gear < 0) {
      gearsB++
      ratioB = ratioB ? min(ratioB, -gear) : -gear
    }
  }
  return {
    gearsF
    gearsB
    maxSpeedF = maxSpeed
    maxSpeedB = ratioB ? (maxSpeed * ratioF / ratioB) : 0
  }
}

let function getTransmissionDesc(vehicleUpgradedData, dmBlkPath) {
  let desc = []
  let unitBlk = getBlk(dmBlkPath)
  let info = unitBlk?.VehiclePhys.mechanics
  if (info == null)
    return desc

  let manufacturer = info?.manufacturer
    ? loc($"transmission_manufacturer/{info.manufacturer}", loc($"engine_manufacturer/{info.manufacturer}", ""))
    : ""
  let model = info?.model ? loc($"transmission_model/{info.model}", "") : ""
  let props = info?.type  ? utf8ToLower(loc($"xray/transmission_type/{info.type}", "")) : ""
  desc.append("".concat(" ".join([ manufacturer, model ], true),
    (props == "" ? "" : loc("ui/parentheses/space", { text = props }))))

  let tp = getTransmissionParams(vehicleUpgradedData?.maxSpeed ?? 0, info?.gearRatios)
  if (tp) {
    if (tp.maxSpeedF && tp.gearsF)
      desc.append("".concat(loc("xray/transmission/maxSpeed/forward"), loc("ui/colon"),
        loc($"vehicleDetails/km/h", { val = floatToStringRounded(tp.maxSpeedF, 0.01) }), loc("ui/comma"),
          loc("xray/transmission/gears"), loc("ui/colon"), tp.gearsF))
    if (tp.maxSpeedB && tp.gearsB)
      desc.append("".concat(loc("xray/transmission/maxSpeed/backward"), loc("ui/colon"),
        loc($"vehicleDetails/km/h", { val = floatToStringRounded(tp.maxSpeedB, 0.01) }), loc("ui/comma"),
          loc("xray/transmission/gears"), loc("ui/colon"), tp.gearsB))
  }

  return desc
}

let function getOpticsParams(zoomOutFov, zoomInFov) {
  let fovToDeg = @(f) atan(1.0 / f) / (PI / 180.0 * 0.5)
  let fovDeg = [ zoomOutFov, zoomInFov ].map(@(f) fovToDeg(f))
  let fovToZoom = @(fov) sin(80/2*PI/180) / sin(fov/2*PI/180)
  let fovOutIn = fovDeg.filter(@(fov) fov > 0)
  let zooms = fovOutIn.map(@(fov) fovToZoom(fov))
  if (zooms.len() == 2 && abs(zooms[0] - zooms[1]) < 0.1) {
    zooms.remove(0)
    fovOutIn.remove(0)
  }
  let zoomTexts = zooms.map(@(zoom) "".concat(floatToStringRounded(zoom, 0.1), "x"))
  let fovTexts = fovOutIn.map(@(fov) "".concat(loc("vehicleDetails/°", { val = round(fov) })))
  let mdashTxt = loc("ui/mdash")
  return {
    zoom = mdashTxt.join(zoomTexts)
    fov  = mdashTxt.join(fovTexts)
  }
}

let function getOpticsDesc(vehicle) {
  let desc = []
  let template = ecs.g_entity_mgr.getTemplateDB().getTemplateByName(vehicle.gametemplate)
  let sightName = template?.getCompValNullable("cockpit__sightName")
  if (sightName == null)
    return desc

  let sightNameLocId = $"sight_model/{sightName}"
  if (doesLocTextExist(sightNameLocId))
    desc.append(loc(sightNameLocId))
  let zoomOutFov = template?.getCompValNullable("cockpit__zoomOutFov") ?? 0
  let zoomInFov = template?.getCompValNullable("cockpit__zoomInFov") ?? 0
  let optics = getOpticsParams(zoomOutFov, zoomInFov)
  if (optics.zoom != "")
    desc.append("".concat(loc("controls/Vehicle.Zoom"), loc("ui/colon"), optics.zoom))
  if (optics.fov != "")
    desc.append("".concat(loc("xray/optic/fov"), loc("ui/colon"), optics.fov))
  return desc
}

let function getWeaponStatus(weapon) {
  let gunTemplateName = weapon?.gun__template ?? ""
  let nameParts = gunTemplateName.split("+")
  let templateId = nameParts[0]
  let isPrimary = nameParts.contains("main_turret")
  let isMachinegun = !isPrimary && (weapon?.gun__reloadTime ?? 0) != 0
  let isSecondary = !isPrimary && !isMachinegun && weapon != null
  return {
    templateId
    isPrimary
    isSecondary
    isMachinegun
  }
}

let getGunBarrelLocName = @(status) loc(
  status.isPrimary ? "xray/weapon/role/primary"
  : status.isSecondary ? "xray/weapon/role/secondary"
  : status.isMachinegun ? "xray/part/mg"
  : "xray/part/gun_barrel")

let function getWeaponDriveTurretDesc(weapon, needAxisX, needAxisY) {
  let desc = []
  let status = getWeaponStatus(weapon)
  let weaponTpl = ecs.g_entity_mgr.getTemplateDB().getTemplateByName(status.templateId)
  let angles = weaponTpl?.getCompValNullable("turret__limit")

  foreach (a in [
    { need = needAxisX, x = angles?.x ?? 0, y = angles?.y ?? 0, label = "xray/turret/guidance_angle/hor" }
    { need = needAxisY, x = angles?.z ?? 0, y = angles?.w ?? 0, label = "xray/turret/guidance_angle/ver" }
  ]) {
    if (!a.need || (!a.x && !a.y))
      continue
    let anglesTxt = (a.x + a.y == 0)
      ? loc("vehicleDetails/°", { val = $"±{abs(a.y)}" })
      : "/".concat(loc("vehicleDetails/°", { val = "".concat(getSignStr(a.x), abs(a.x)) }),
                   loc("vehicleDetails/°", { val = "".concat(getSignStr(a.y), abs(a.y)) }))
    desc.append("".concat(loc(a.label), loc("ui/colon"), anglesTxt))
  }

  foreach (s in [
    { need = needAxisX, key = "turret__yawSpeed",   label = "itemDetails/upgrade/turret_hor_speed" },
    { need = needAxisY, key = "turret__pitchSpeed", label = "itemDetails/upgrade/turret_ver_speed" },
  ]) {
    if (!s.need)
      continue
    let speed = weapon?[s.key] ?? 0
    if (speed > 0) {
      let turnSpeedTxt = floatToStringRounded(speed, speed < 10 ? 0.1 : 1)
      desc.append("".concat(loc(s.label), loc("ui/colon"), loc("vehicleDetails/°/С", { val = turnSpeedTxt })))
    }
  }

  return desc
}

let function getWeaponDesc(weapon, status) {
  let desc = []
  if ((weapon?.gun__locName ?? "") != "")
    desc.append(loc($"guns/{weapon.gun__locName}"))
  if ((weapon?.gun__maxAmmo ?? 0) != 0)
    desc.append(loc("vehicleDetails/ammunition/alt", { val = weapon.gun__maxAmmo }))
  if (status.isPrimary || status.isSecondary) {
    let shotFreq = weapon?.gun__shotFreq ?? 0.0
    local reloadTime = weapon?.gun__reloadTime ?? 0.0
    if (reloadTime == 0 && shotFreq != 0)
      reloadTime = 1.0 / shotFreq
    if (shotFreq != 0) {
      let shotFreqRPM = shotFreq * 60
      let shotFreqTxt = floatToStringRounded(shotFreqRPM, shotFreqRPM < 10 ? 0.1 : 1)
      desc.append("".concat(loc("itemDetails/upgrade/gun__shotFreq"), loc("ui/colon"),
        shotFreqTxt, loc("itemDetails/shots/min", { val = shotFreqRPM })))
    }
    if (reloadTime != 0) {
      let reloadTimeTxt = floatToStringRounded(reloadTime, reloadTime < 10 ? 0.1 : 1)
      desc.append("".concat(loc("itemDetails/gun__reloadTime"), loc("ui/colon"),
        loc("vehicleDetails/seconds", { val = reloadTimeTxt })))
    }
    desc.extend(getWeaponDriveTurretDesc(weapon, true, true))
  }
  return desc
}

let function getXrayPartDesc(vehicle, vehicleUpgradedData, dmBlkPath, partName, partDebug) {
  let partType = rePartNameEnding.replace("", partName)
  local title = null
  local desc = []

  switch (partType) {
    case "driver":
    case "machine_gunner":
    case "loader":
    case "commander":
    case "gunner":
      title = getCrewMemberLocName(vehicle, partName)
      break
    case "engine":
      desc = getTankEngineDesc(vehicleUpgradedData, dmBlkPath)
      break
    case "transmission":
      desc = getTransmissionDesc(vehicleUpgradedData, dmBlkPath)
      break
    case "drive_turret_h":
    case "drive_turret_v":
      let isHorizontal = partType == "drive_turret_h"
      let weapon = getWeaponByPartName(vehicleUpgradedData.armament, partName)
      desc = getWeaponDriveTurretDesc(weapon, isHorizontal, !isHorizontal)
      break
    case "gun_barrel":
    case "cannon_breech":
      let weapon = getWeaponByPartName(vehicleUpgradedData.armament, partName)
      let status = getWeaponStatus(weapon)
      if (partType == "gun_barrel")
        title = getGunBarrelLocName(status)
      desc = getWeaponDesc(weapon, status)
      break
    case "optic_gun":
      desc = getOpticsDesc(vehicle)
      break
  }

  if (title == null) {
    let nameLocId = xrayPartsLocNameRemap.findindex(@(v) v.contains(partType)) ?? partType
    title = loc($"xray/part/{nameLocId}")
  }

  return "\n".join([
    colorize(activeTxtColor, title),
    "\n".join(desc, true),
    partDebug,
  ], true)
}

return {
  getXrayPartDesc
}
