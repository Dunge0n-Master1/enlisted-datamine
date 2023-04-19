from "%enlSqGlob/ui_library.nut" import *

let upgrades = require("%enlist/soldiers/model/config/upgradesConfig.nut")
let colorize = require("%ui/components/colorize.nut")

let { floatToStringRounded } = require("%sqstd/string.nut")
let { round_by_value } = require("%sqstd/math.nut")
let { fabs } = require("math")
let { fontXSmall, fontSmall } = require("%enlSqGlob/ui/fontsStyle.nut")
let { mkUpgradeWatch, mkSpecsWatch } = require("%enlist/vehicles/physSpecs.nut")
let { mkUpgrades } = require("itemDetailsPkg.nut")

let {
  getWeaponData, getVehicleData, applyUpgrades
} = require("%enlist/soldiers/model/collectWeaponData.nut")
let { getItemDesc, getItemDetails } = require("%enlSqGlob/ui/itemsInfo.nut")
let {
  colFull, colPart, smallPadding, midPadding, accentColor, defTxtColor, defBdColor
} = require("%enlSqGlob/ui/designConst.nut")


const GOOD_COLOR  = 0xFF3DB613
const BAD_COLOR   = 0xFFFF5522
const BASE_COLOR  = 0xFFC6C7DC
const VALUE_COLOR = 0xFFF8BD41
const DARK_COLOR  = 0xFF3E413F


let smallTxtStyle = { color = defTxtColor }.__update(fontXSmall)
let defTxtStyle = { color = defTxtColor }.__update(fontSmall)

let itemInfoWidth = colFull(5)


let mkTextArea = @(text, override = {}) {
  size = [flex(), SIZE_TO_CONTENT]
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  text
}.__update(defTxtStyle, override)

let mkText = @(text, override = {}) {
  rendObj = ROBJ_TEXT
  text
}.__update(defTxtStyle, override)


let mkTextRow = @(header, value) {
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_HORIZONTAL
  children = [
    mkText(header)
    mkTextArea(value, { halign = ALIGN_RIGHT })
  ]
}


let function mkRange(val, range, key) {
  val = clamp(val, range[0], range[1])
  let progressRatio = (val - range[0]) / (range[1] - range[0]).tofloat()
  return {
    key
    size = [flex(), smallPadding]
    color = DARK_COLOR
    rendObj = ROBJ_SOLID
    children = {
      rendObj = ROBJ_SOLID
      size = [pw(100 * progressRatio), flex()]
      color = VALUE_COLOR
      transform = { pivot = [0, 0]}
      animations = [
        { prop = AnimProp.scale, from = [0, 1], to = [0, 1], duration = 0.1, play = true }
        { prop = AnimProp.scale, from = [0, 1], to = [1, 1], duration = 0.2, play = true, delay = 0.1 }
      ]
    }
  }
}


let itemDetailsConstructors = {
  ["bullets"] = function(val, itemData, _setup, _itemBase) {
    if (val <= 0)
      return null

    let countColored = colorize(accentColor, val)
    let valueLocId = itemData?.magazine_type ?? "magazine_type/default"
    let valueText = loc(valueLocId, { count = val, countColored })
    return mkTextRow(loc("itemDetails/bullets"), valueText)
  },

  ["gun__firingModeNames"] = function(val, _itemData, _setup, _itemBase) {
    if (val.len() == 0)
      return null

    let valueText = ", ".join(val.map(@(name) loc($"firing_mode/{name}")))
    return mkTextRow(loc("itemDetails/gun__firingModeNames"), valueText)
  },

  ["splashDamage"] = function(val, _itemData, _setup, _itemBase) {
    let keyText = loc("itemDetails/splashDamage", { from = val.radius.x, to = val.radius.y })
    let valueText = loc("itemDetails/splashDamage/damage", { to = val.damage })
    return mkTextRow(keyText, valueText)
  }
}


let getValColor = @(val, baseVal, isPositive = true)
  fabs(val - baseVal) < 0.001 * fabs(val + baseVal) ? BASE_COLOR
    : val > baseVal == isPositive ? GOOD_COLOR
    : BAD_COLOR


local function mkDetailsLine(val, setup, itemBase, animKey) {
  local { measure = "" } = setup
  let {
    key, mult = 1, altLimit = 0.0, altMeasure = "",
    precision = 1, isPositive = true, range = null
  } = setup

  let itemBaseVal = itemBase[key]
  let baseVal = type(itemBaseVal) == "array" ? itemBaseVal : [itemBaseVal]
  val = type(val) == "array" ? val : [val]

  let colors = val.map(@(v, idx) getValColor(v, baseVal?[idx] ?? baseVal.top(), isPositive))
  if (altLimit != 0.0 && val.top() >= altLimit)
    measure = altMeasure
  else
    val = (clone val).map(@(v) v * mult)

  let valColorList = val.map(@(v, idx) colorize(colors[idx], floatToStringRounded(v, precision)))
  let valColored = "-".join(valColorList)
  let topVal = round_by_value(val.top(), precision).tointeger()
  let valText = measure == "" ? valColored
    : "{0}{1}".subst(valColored, loc($"itemDetails/{measure}", { val = topVal }))

  return {
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    children = [
      mkTextRow(loc($"itemDetails/{key}"), valText)
      range != null ? mkRange(val.top(), range, animKey) : null
    ]
  }
}


let columnsGap = {
  size = [hdpx(1), flex()]
  margin = midPadding
  rendObj = ROBJ_SOLID
  color = defBdColor
}

let function mkDetailsTable(tbl, setup, baseVal = 1.0) {
  let { key, mult = 1, measure = "", altMeasure = "", precision = 1 } = setup
  if (mult == 0 || baseVal == 0)
    return null

  let columns = tbl.values()
    .filter(@(p) (p?.x ?? 0) != 0 || (p?.y ?? 0) != 0)
    .sort(@(a, b) (a?.y ?? 0) <=> (b?.y ?? 0))
    .map(function(col) {
      let ref = col?.y ?? 0
      local val = (col?.x ?? 0) * baseVal * mult
      let valText = floatToStringRounded(val, precision)
      val = round_by_value(val, precision).tointeger()
      let measureText = measure != ""
        ? "{0}{1}".subst(ref, loc($"itemDetails/{measure}", { val = ref }))
        : ref
      let altMeasureText = altMeasure != ""
        ? "{0}{1}".subst(valText, loc($"itemDetails/{altMeasure}", { val = val }))
        : valText
      return {
        flow = FLOW_VERTICAL
        halign = ALIGN_CENTER
        padding = [smallPadding, 0]
        children = [
          mkText(measureText, smallTxtStyle)
          mkText(altMeasureText)
        ]
      }
    })

  return columns.len() <= 0 ? null : {
    flow = FLOW_VERTICAL
    gap = -smallPadding
    children = [
      mkText(loc($"itemDetails/{key}"))
      {
        flow = FLOW_HORIZONTAL
        gap = columnsGap
        children = columns
      }
    ]
  }
}


let function mkDetails(details, ctors, item) {
  let { upgradesId = null, upgradeIdx = 0, gametemplate = null, itemtype = null } = item
  if (gametemplate == null)
    return null

  let itemData = (itemtype == "vehicle" ? getVehicleData : getWeaponData)(gametemplate)
  if (itemData == null)
    return null

  let upgradesCurWatch = mkUpgradeWatch(upgrades, upgradesId, upgradeIdx)
  let upgradesBaseWatch = mkUpgradeWatch(upgrades, upgradesId, 0)
  let specsWatch = mkSpecsWatch(upgradesCurWatch, item)

  return function() {
    let res = { watch = [upgradesCurWatch, upgradesBaseWatch, specsWatch] }

    itemData.__update(specsWatch.value)
    let itemBase = applyUpgrades(itemData, upgradesBaseWatch.value)
    let upgradesData = applyUpgrades(itemData, upgradesCurWatch.value)
    return res.__update({
      size = [flex(), SIZE_TO_CONTENT]
      flow = FLOW_VERTICAL
      gap = 5
      children = details.map(function(setup) {
        let { key, baseKey = null } = setup
        let val = upgradesData?[key]
        let animKey = $"{gametemplate}_{key}"
        return val == null || val == 0 ? null
          : key in ctors ? ctors[key](val, itemData, setup, itemBase)
          : type(val) == "table" ? mkDetailsTable(val, setup, upgradesData?[baseKey] ?? 1.0)
          : mkDetailsLine(val, setup, itemBase, animKey)
      })
    })
  }
}


let mkItemDetails = @(item)
  mkDetails(getItemDetails(true), itemDetailsConstructors, item)


let function mkItemDescription(item) {
  let descLoc = getItemDesc(item)
  return descLoc == "" ? null : mkTextArea(descLoc)
}


let function itemInfo(item) {
  let { basetpl = null } = item
  if (basetpl == null)
    return null

  let isVehicle = item?.itemtype == "vehicle"
  return {
    size = [itemInfoWidth, flex()]
    flow = FLOW_VERTICAL
    gap = colPart(0.5)
    children = [
      mkItemDescription(item)
      isVehicle ? null : mkItemDetails(item)
      mkUpgrades(item, itemInfoWidth)
    ]
  }
}

return itemInfo
