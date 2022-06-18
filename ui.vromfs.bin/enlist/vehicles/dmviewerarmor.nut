from "%enlSqGlob/ui_library.nut" import *
let { round, cos, PI } = require("math")
let DataBlock = require("DataBlock")
let colorize = require("%ui/components/colorize.nut")
let { activeTxtColor } = require("%enlSqGlob/ui/viewConst.nut")

const ABSOLUTE_ARMOR_THRESHOLD = 500.0
const RELATIVE_ARMOR_THRESHOLD = 5.0

let armorClassRemap = {
  CHA_tank_modern = "CHA_tank"
  RHA_tank_modern = "RHA_tank"
  RHAHH_tank_modern = "RHAHH_tank"
  ship_wood = "wood"
}

let function getArmorClassLocName(dmBlkPath, partName) {
  if (dmBlkPath == "")
    return ""
  let blk = DataBlock()
  blk.load(dmBlkPath)
  local armorClass = blk?.DamageParts[partName].armorClass
  armorClass = armorClassRemap?[armorClass] ?? armorClass
  return armorClass ? loc($"armor_class/{armorClass}") : ""
}

let function getEffectiveThicknessStr(thickness, viewingAngle) {
  let divider = cos(viewingAngle * PI / 180.0)
  let effThickness = round(divider != 0 ? (thickness / divider) : (ABSOLUTE_ARMOR_THRESHOLD + 1))
  let effThicknessMax = round(min(ABSOLUTE_ARMOR_THRESHOLD, RELATIVE_ARMOR_THRESHOLD * thickness))
  return "".concat(effThickness <= effThicknessMax ? "" : ">", min(effThickness, effThicknessMax))
}

let function getArmorPartDesc(armorClassLoc, armorParams, partDebug) {
  let { thickness, normalAngle, viewingAngle } = armorParams
  let effectiveThickness = getEffectiveThicknessStr(thickness, viewingAngle)
  return "\n".join([
    colorize(activeTxtColor, armorClassLoc),
    " ".concat(loc("vehicle/armor/thickness"), loc("vehicleDetails/millimeter", { val = colorize(activeTxtColor, thickness) })),
    " ".concat(loc("vehicle/armor/normal_angle"), loc("vehicleDetails/°", { val = round(normalAngle) })),
    " ".concat(loc("vehicle/armor/impact_angle"), loc("vehicleDetails/°", { val = round(viewingAngle) })),
    " ".concat(loc("vehicle/armor/effective_thickness"), loc("vehicleDetails/millimeter", { val = effectiveThickness })),
    partDebug,
  ], true)
}

return {
  getArmorClassLocName
  getArmorPartDesc
}
