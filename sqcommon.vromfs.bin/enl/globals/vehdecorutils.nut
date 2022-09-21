from "%enlSqGlob/library_logs.nut" import *
import "%dngscripts/ecs.nut" as ecs

let { logerr } = require("dagor.debug")
let { fabs } = require("%sqstd/math.nut")
let { format } = require("string")
let { toIntegerSafe, isStringFloat } = require("%sqstd/string.nut")
let { Point3, Point4, TMatrix } = require("dagor.math")

const VERSION = 0
const ZERO_CHAR_CODE = 48
const POINT_CHAR_CODE = 46

let function cutOffRightZeros(str) {
  let dotIdx = str.indexof(".")
  if (dotIdx == null)
    return str

  local idx = str.len()
  while (idx > dotIdx) {
    let last = str[idx - 1]
    if (last != 48 && last != 46)
      break
    idx--
  }

  return str.slice(0, idx)
}

let boolToString = @(v) type(v) != "bool" ? ""
  : v == true ? "1"
  : ""

let floatToString = @(v) type(v) != "float" ? ""
  : fabs(v) < 0.001 ? ""
  : cutOffRightZeros(format("%.3f", v))

let point3ToString = @(v) !(v instanceof Point3) ? ""
  : ",".concat(floatToString(v.x), floatToString(v.y), floatToString(v.z))

let point4ToString = @(v) !(v instanceof Point4) ? ""
  : ",".concat(floatToString(v.x), floatToString(v.y), floatToString(v.z), floatToString(v.w))


let stringToBool = @(str) str == "1" ? true : false

let stringToFloat = @(str) isStringFloat(str) ? str.tofloat() : 0.0

let function stringToPoint3(str) {
  let strData = str.split(",")
  return Point3(stringToFloat(strData?[0] ?? "0"),
    stringToFloat(strData?[1] ?? "0"),
    stringToFloat(strData?[2] ?? "0"))
}

let function stringToPoint4(str) {
  let strData = str.split(",")
  return Point4(stringToFloat(strData?[0] ?? "0"),
    stringToFloat(strData?[1] ?? "0"),
    stringToFloat(strData?[2] ?? "0"),
    stringToFloat(strData?[3] ?? "0"))
}

let matrixToString = @(v) !(v instanceof TMatrix) ? ""
  : "?".concat(point3ToString(v[0]), point3ToString(v[1]), point3ToString(v[2]), point3ToString(v[3]))

let function stringToMatrix(str) {
  let strData = str.split("?")
  let tm = TMatrix()
  for(local i = 0; i < 4; ++i)
    tm.setcol(i, stringToPoint3(strData?[i] ?? ""))
  return tm
}

let decalConfig = [
  { key = "twoSided", valType = "bool", encode = boolToString, decode = stringToBool }
  { key = "dProj0", valType = "Point4", encode = point4ToString, decode = stringToPoint4 }
  { key = "locPos0", valType = "Point3", encode = point3ToString, decode = stringToPoint3 }
  { key = "oppositeMirrored", valType = "bool", encode = boolToString, decode = stringToBool }
  { key = "scale", valType = "float", encode = floatToString, decode = stringToFloat }
  { key = "mirrored", valType = "bool", encode = boolToString, decode = stringToBool }
  { key = "locNorm0", valType = "Point3", encode = point3ToString, decode = stringToPoint3 }
  { key = "vProj0", valType = "Point4", encode = point4ToString, decode = stringToPoint4 }
  { key = "uProj0", valType = "Point4", encode = point4ToString, decode = stringToPoint4 }
  { key = "rotation", valType = "float", encode = floatToString, decode = stringToFloat }
  { key = "uProj1", valType = "Point4", encode = point4ToString, decode = stringToPoint4 }
  { key = "vProj1", valType = "Point4", encode = point4ToString, decode = stringToPoint4 }
  { key = "dProj1", valType = "Point4", encode = point4ToString, decode = stringToPoint4 }
  { key = "locPos1", valType = "Point3", encode = point3ToString, decode = stringToPoint3 }
  { key = "locNorm1", valType = "Point3", encode = point3ToString, decode = stringToPoint3 }
]

let decorConfig = [
  { key = "relativeTm", valType = "TMatrix", encode = matrixToString, decode = stringToMatrix },
  { key = "nodeName", valType = "string", encode = @(v) v, decode = @(v) v },
]

let codecCfgByVer = {
  vehDecal = {
    [0] = decalConfig
  }
  vehDecorator = {
    [0] = decorConfig
  }
}

foreach(key, cfg in codecCfgByVer)
  assert(VERSION in cfg, $"No {key} string convertor with {VERSION} version")


let decalToString = @(decal, cType) "{0}:{1}"
  .subst(VERSION, ";".join(codecCfgByVer[cType][VERSION]
    .map(@(data) data.encode(decal?[data.key]) ?? "")
  ))

let function stringToDecal(decalStr, cType, textureName = "", slot = -1) {
  let baseList = decalStr.split(":")
  if (baseList.len() != 2)
    return logerr($"Wrong decor save format")

  if (cType not in codecCfgByVer)
    return logerr($"No decor string convertor with {cType} type")

  let ver = toIntegerSafe(baseList[0], -1, false)
  if (ver not in codecCfgByVer[cType])
    return logerr($"No decor string convertor with {ver} version")

  let strData = (baseList?[1] ?? "").split(";")
  let decal = {}
  foreach (key, cfg in codecCfgByVer[cType][ver]) {
    let str = strData?[key] ?? ""
    decal[cfg.key] <- cfg.decode(str) ?? str
  }

  return decal.__update({ textureName, slot })
}

let function decalToCompObject(decal) {
  let decalCompObject = ecs.CompObject()
  foreach (key, val in decal)
    decalCompObject[key] <- val

  return decalCompObject
}


let function getTemplateByName(templateName) {
  if (templateName == null)
    return null

  let DB = ecs.g_entity_mgr.getTemplateDB()
  return DB.getTemplateByName(templateName)
}

let function getBaseVehicleSkin(templateName) {
  if (templateName == null)
    return null

  let vehTemplate = getTemplateByName(templateName)
  return vehTemplate == null ? null
    : vehTemplate.getCompValNullable("animchar__objTexReplace")?.getAll()
}

let function getVehSkins(templateName) {
  if (templateName == null)
    return []

  let vehTemplate = getTemplateByName(templateName)
  if (vehTemplate == null)
    return []

  let skinTemplate = getTemplateByName(vehTemplate.getCompValNullable("skin__template"))
  if (vehTemplate == null)
    return []

  let baseSkinId = (getBaseVehicleSkin(templateName) ?? {}).values()?[0]
  return (skinTemplate?.getCompValNullable("skin__objTexReplace").getAll() ?? [])
    .filter(@(s) (s?.objTexReplace ?? {}).values()?[0] != baseSkinId)
}


return {
  decalToString
  stringToDecal
  decalToCompObject

  getTemplateByName
  getBaseVehicleSkin
  getVehSkins
}
