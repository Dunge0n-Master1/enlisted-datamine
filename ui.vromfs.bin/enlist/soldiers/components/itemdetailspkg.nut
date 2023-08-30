from "%enlSqGlob/ui_library.nut" import *

let { fontSub } = require("%enlSqGlob/ui/fontsStyle.nut")
let { doesLocTextExist } = require("dagor.localize")
let { fabs } = require("math")
let { msgHighlightedTxtColor } = require("%enlSqGlob/ui/viewConst.nut")
let { smallPadding, bigPadding, inventoryItemDetailsWidth, brightAccentColor, defTxtColor,
  titleTxtColor, defItemBlur, defBdColor, midPadding
} = require("%enlSqGlob/ui/designConst.nut")
let { floatToStringRounded } = require("%sqstd/string.nut")
let { round_by_value } = require("%sqstd/math.nut")
let colorize = require("%ui/components/colorize.nut")
let { getWeaponData, getVehicleData, applyUpgrades
} = require("%enlist/soldiers/model/collectWeaponData.nut")
let upgrades = require("%enlist/soldiers/model/config/upgradesConfig.nut")
let { levelBlock } = require("%enlSqGlob/ui/soldiersUiComps.nut")
let { withTooltip, normalTooltipTop } = require("%ui/style/cursors.nut")
let { mkUpgradeWatch, mkSpecsWatch } = require("%enlist/vehicles/physSpecs.nut")
let { getItemDetails, VEHICLE_DETAILS, ARMOR_ORDER, getArmaments, getItemDesc
} = require("%enlSqGlob/ui/itemsInfo.nut")

const MAX_STATS_COUNT = 3 // max count of shown stats changes in upgrades
const GOOD_COLOR = 0xFF3DB613
const BAD_COLOR = 0xFFFF5522
const BASE_COLOR = 0xFFC6C7DC
const VALUE_COLOR = 0xFFCFD0E3
const DARK_COLOR = 0xFF3E413F

let RANGE_SIZE = [inventoryItemDetailsWidth - midPadding * 2, hdpx(8)]

let blur = @(override = {}) {
  size = SIZE_TO_CONTENT
  rendObj = ROBJ_WORLD_BLUR
  color = defItemBlur
  padding = bigPadding
  flow = FLOW_HORIZONTAL
}.__update(override)

let mkText = @(text) {
  rendObj = ROBJ_TEXT
  color = BASE_COLOR
  text
}

let mkTextArea = @(text, size = SIZE_TO_CONTENT, halign = ALIGN_LEFT) {
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  color = BASE_COLOR
  halign
  size
  text
}

let mkTextRow = @(header, value) {
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_HORIZONTAL
  gap = smallPadding
  children = [
    mkTextArea(header, [flex(), SIZE_TO_CONTENT])
    mkTextArea(value)
  ]
}

let vertFrame = { rendObj = ROBJ_SOLID, size = [hdpx(1), flex()], color = defBdColor }

let function armamentRowTitle(gun) {
  let gunCount = gun.count <= 1 || gun.count == gun.gun__maxAmmo
    ? ""
    : loc("common/amountShort", { count = gun.count })
  let gunLocId = gun?.gun__locName
  if (gunLocId == null)
      return null
  let gunName = loc($"guns/{gunLocId}")
  let text = $"{gunName} {gunCount}"
  return mkTextArea(text, [flex(), SIZE_TO_CONTENT])
}

let armamentRowRounds = @(gun)
  mkTextArea("{0} {1}".subst(colorize(titleTxtColor, gun["gun__maxAmmo"]), loc("itemDetails/count")),
    SIZE_TO_CONTENT, ALIGN_RIGHT)

let getValueColor = @(val, baseVal, isPositive = true)
  fabs(val - baseVal) < 0.001 * fabs(val + baseVal) ? BASE_COLOR
    : val > baseVal == isPositive ? GOOD_COLOR
    : BAD_COLOR

let function armamentRowCtor(val, _itemData, setup, _itemBase) {
  let reducedGuns = getArmaments(val)
  let hasArmament = reducedGuns != null
  return {
    size = [flex(), SIZE_TO_CONTENT]
    flow = hasArmament ? FLOW_VERTICAL : FLOW_HORIZONTAL
    gap = smallPadding
    children = [
      {
        rendObj = ROBJ_TEXT
        text = loc($"itemDetails/{setup.key}")
        color = defTxtColor
      }
      hasArmament
        ? {
            rendObj = ROBJ_BOX
            size = [flex(), SIZE_TO_CONTENT]
            flow = FLOW_VERTICAL
            borderColor = defBdColor
            borderWidth = [hdpx(1), 0]
            padding = [hdpx(4), 0]
            gap = smallPadding
            children = reducedGuns.map(@(gun){
              size = [flex(), SIZE_TO_CONTENT]
              flow = FLOW_HORIZONTAL
              gap = smallPadding
              children = [
                armamentRowTitle(gun)
                armamentRowRounds(gun)
              ]
            })
          }
        : {
            size = [flex(), SIZE_TO_CONTENT]
            rendObj = ROBJ_TEXT
            text = loc("itemDetails/weaponsNotInstalled")
            halign = ALIGN_RIGHT
          }
    ]
  }
}

let flexGap = {
  size = flex()
  halign = ALIGN_CENTER
  children = vertFrame
}

let halfGap = { size = flex(0.5) }

let function armorRowCtor(tbl, _itemData, setup, _itemBase) {
  let { mult = 1, measure = "", precision = 1 } = setup
  let measureLoc = measure != "" ? loc($"itemDetails/{measure}") : null
  let tblHeader = loc($"itemDetails/{setup.key}", {
    measure = measureLoc
  })
  let columns = ARMOR_ORDER
    .filter(@(key) key in tbl)
    .map(function(key) {
      local val = tbl[key] * mult
      let valColor = colorize(titleTxtColor, floatToStringRounded(val, precision))
      return {
        halign = ALIGN_CENTER
        flow = FLOW_VERTICAL
        padding = [smallPadding, 0]
        children = [
          {
            rendObj = ROBJ_TEXT
            text = loc($"itemDetails/armor__{key}")
            color = defTxtColor
          }
          mkTextArea(valColor)
        ]
      }
    })
  let columnsToShow = columns.reduce(function(res, v, idx) {
    let gap = idx == columns.len() - 1 ? halfGap : flexGap
    res.append(v, gap)
    return res
  }, [halfGap])
  return {
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    gap = smallPadding
    children = [
      mkTextArea(tblHeader, [flex(), SIZE_TO_CONTENT])
      {
        rendObj = ROBJ_BOX
        size = [flex(), SIZE_TO_CONTENT]
        borderWidth = hdpx(1)
        flow = FLOW_HORIZONTAL
        borderColor = defBdColor
        children = columnsToShow
      }
    ]
  }
}

let gunFiringModeNamesShortDesc  = function(val, _itemData, _setup, _itemBase) {
  if (val.len() == 0)
    return null
  return {
    size = [flex(),SIZE_TO_CONTENT]
    flow = FLOW_HORIZONTAL
    valign = ALIGN_TOP
    halign = ALIGN_LEFT
    gap = hdpx(3)
    children = [
      {
        valign = ALIGN_TOP
        halign = ALIGN_LEFT
        children = mkText(loc("itemDetails/gun__firingModeNames"))
      }
      {
        flow = FLOW_VERTICAL
        valign = ALIGN_TOP
        halign = ALIGN_RIGHT
        children = val.map(@(name) mkText(loc($"firing_mode/{name}")))
      }
    ]
  }
}

let itemDetailsConstructors = @(isFull) {
  "bullets" : @(val, itemData, _setup, _itemBase) val <= 0 ? null
    : mkTextRow(loc("itemDetails/bullets"),
        loc(itemData?.magazine_type ?? "magazine_type/default",
          { count = val, countColored = colorize(titleTxtColor, val) }))
  "gun__firingModeNames" : isFull ? @(val, _itemData, _setup, _itemBase) val.len() == 0 ? null
      : mkTextRow(loc("itemDetails/gun__firingModeNames"),
          ", ".join(val.map(@(name) loc($"firing_mode/{name}"))))
    : gunFiringModeNamesShortDesc
  "splashDamage" :  @(val, _itemData, _setup, _itemBase) mkTextRow(loc("itemDetails/splashDamage", { from = val.radius.x, to = val.radius.y }),
    loc("itemDetails/splashDamage/damage", { to = val.damage }))
}

let VEHICLE_DETAILS_CONSTRUCTORS = {
  "armament" : armamentRowCtor
  "armor__body" : armorRowCtor
  "armor__turret" : armorRowCtor
  "engine__horsePowers" : function(val, itemData, setup, itemBase) {
    if (val <= 0)
      return null
    let { precision = 1, baseKey, key } = setup
    let baseVal = round_by_value(itemBase?[key] ?? val, precision).tointeger()
    val = round_by_value(val, precision).tointeger()
    return mkTextRow(loc("itemDetails/enginePower"), loc("itemDetails/enginePowerValues", {
      val = colorize(getValueColor(val, baseVal), val)
      rpm = colorize(titleTxtColor, itemData?[baseKey])
    }))
  }
}

local function mkRange(val, range, key) {
  val = clamp(val, range[0], range[1])
  local progressWidth = val == 0 ? 0 : RANGE_SIZE[0] * val / range[1]
  return {
    key
    rendObj = ROBJ_SOLID
    size = RANGE_SIZE
    color = DARK_COLOR
    children = {
      rendObj = ROBJ_SOLID
      size = [progressWidth, flex()]
      color = brightAccentColor
      transform = { pivot = [0, 0]}
      animations = [
        { prop = AnimProp.scale, from = [0, 1], to = [0, 1], duration = 0.1, play = true }
        { prop = AnimProp.scale, from = [0, 1], to = [1, 1], duration = 0.2, play = true, delay = 0.1 }
      ]
    }
  }
}

let function mkFullLine (key, valText, measure, val, range, animKey) {
  let headerTitle = loc($"itemDetails/{key}", measure == "" ? {} : {
    measure = loc($"itemDetails/{measure}")
  })
  return {
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    children = [
      {
        size = [flex(), SIZE_TO_CONTENT]
        flow = FLOW_HORIZONTAL
        gap = smallPadding
        children = [
          mkTextArea(headerTitle, [flex(), SIZE_TO_CONTENT])
          mkTextArea(valText, SIZE_TO_CONTENT, ALIGN_RIGHT)
        ]
      }
      range != null ? mkRange(val, range, animKey) : null
    ]
  }
}

local function mkDetailsLine(val, setup, itemBase, animKey) {
  local {
    key, mult = 1, measure = "", altLimit = 0.0, altMeasure = "",
    precision = 1, isPositive = true, range = null
  } = setup

  local baseVal = itemBase[key]
  if (type(baseVal) != "array")
    baseVal = [baseVal]
  if (type(val) != "array")
    val = [val]

  let colors = val.map(@(v, idx)
    getValueColor(v, baseVal?[idx] ?? baseVal.top(), isPositive))
  if (altLimit != 0.0 && val.top() >= altLimit)
    measure = altMeasure
  else
    val = (clone val).map(@(v) v * mult)

  let valColorList = val.map(@(v, idx)
    colorize(colors[idx], floatToStringRounded(v, precision)))
  let valColored = "-".join(valColorList)
  let topVal = round_by_value(val.top(), precision).tointeger()
  let valText = valColored
  return mkFullLine(key, valText, measure, topVal, range, animKey)
}

let function mkDetailsTable(tbl, setup, baseVal = 1.0) {
  let { key, mult = 1, measure = "", altMeasure = "", precision = 1 } = setup
  if (mult == 0 || baseVal == 0)
    return null
  let measureLoc = measure != "" ? loc($"itemDetails/{measure}") : null
  let altMeasureLoc = altMeasure != "" ? loc($"itemDetails/{altMeasure}") : null
  let tblHeader = loc($"itemDetails/{key}", {
    measure = measureLoc
    altMeasure = altMeasureLoc
  })
  let columns = tbl.values()
    .filter(@(p) (p?.x ?? 0) != 0 || (p?.y ?? 0) != 0)
    .sort(@(a, b) (a?.y ?? 0) <=> (b?.y ?? 0))
    .map(function(col) {
      let ref = col?.y ?? 0
      let refColored = colorize(BASE_COLOR, ref)
      local val = (col?.x ?? 0) * baseVal * mult
      let valColored = colorize(BASE_COLOR, floatToStringRounded(val, precision))
      return {
        size = [flex(), SIZE_TO_CONTENT]
        halign = ALIGN_CENTER
        flow = FLOW_VERTICAL
        padding = [smallPadding, 0]
        children = [
          mkTextArea(refColored)
          mkTextArea(valColored)
        ]
      }
    })
    .insert(0, measureLoc == null && altMeasureLoc == null ? null : {
      halign = ALIGN_CENTER
      flow = FLOW_VERTICAL
      padding = [smallPadding, midPadding]
      children = [
        measureLoc == null ? null : mkTextArea(measureLoc)
        altMeasureLoc == null ? null : mkTextArea(altMeasureLoc)
      ]
    })
  return columns.len() <= 0 ? null : {
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    gap = smallPadding
    children = [
      mkTextArea(tblHeader, [flex(), SIZE_TO_CONTENT])
      {
        rendObj = ROBJ_BOX
        size = [flex(), SIZE_TO_CONTENT]
        borderWidth = hdpx(1)
        borderColor = defBdColor
        flow = FLOW_HORIZONTAL
        gap = vertFrame
        children = columns
      }
    ]
  }
}

let function mkDetails(detailsList, constructors, item) {
  let { upgradesId = null, upgradeIdx = 0, gametemplate = null, itemtype = null } = item
  if (gametemplate == null)
    return null

  let itemData = itemtype == "vehicle"
    ? getVehicleData(gametemplate)
    : getWeaponData(gametemplate)
  if (itemData == null)
    return null

  let upgradesCurWatch = mkUpgradeWatch(upgrades, upgradesId, upgradeIdx)
  let upgradesBaseWatch = mkUpgradeWatch(upgrades,upgradesId, 0)
  let specsWatch = mkSpecsWatch(upgradesCurWatch, item)

  return function() {
    let res = { watch = [upgradesCurWatch, upgradesBaseWatch, specsWatch] }
    itemData.__update(specsWatch.value)
    let itemBase = applyUpgrades(itemData, upgradesBaseWatch.value)
    let upgradedData = applyUpgrades(itemData, upgradesCurWatch.value)
    let children = detailsList
      .map(function(setup) {
        let val = upgradedData?[setup.key]
        let animKey = $"{gametemplate}_{setup.key}"
        return val == null || val == 0 ? null
          : setup.key in constructors ? constructors[setup.key](val, itemData, setup, itemBase)
          : type(val) == "table" ? mkDetailsTable(val, setup, upgradedData?[setup?.baseKey] ?? 1.0)
          : mkDetailsLine(val, setup, itemBase, animKey)
      })
      .filter(@(v) v != null)
    return children.len() == 0
      ? res
      : res.__update({
          size = [flex(), SIZE_TO_CONTENT]
          children = {
            size = [flex(), SIZE_TO_CONTENT]
            gap = smallPadding
            flow = FLOW_VERTICAL
            children = children
          }
        })
  }
}

let UPGRADES_LIST = [
  // items
  { key = "gun__shotFreq", measure = "percent" }
  { key = "gun__kineticDamageMult", measure = "percent" }
  { key = "recoilVertBonus", measure = "percent", isPositive = false, locId = "itemDetails/recoilAmountVert" }
  { key = "recoilHorBonus", measure = "percent", isPositive = false, locId = "itemDetails/recoilAmountHor" }
  { key = "gun_spread__maxDeltaAngle", measure = "percent", isPositive = false }
  { key = "gun__reloadTime", measure = "percent", isPositive = false }
  { key = "flamethrower__maxFlameLength", measure = "percent", locId = "itemDetails/maxFlameLength" }
  { key = "flamethrower__streamDamagePerSecond", measure = "percent", locId = "itemDetails/streamDamagePerSecond" }
  // vehicles
  { key = "braking_force", measure = "percent" }
  { key = "engine_power", measure = "percent" }
  { key = "suspension_dampening", measure = "percent" }
  { key = "suspension_resting", measure = "percent" }
  { key = "suspension_min_limit", measure = "percent" }
  { key = "suspension_max_limit", measure = "percent" }
  { key = "turret_hor_speed", measure = "percent" }
  { key = "turret_ver_speed", measure = "percent" }
  // keys for tank upgrades from WT
  { key = "mulMaxDeltaAngle", measure = "percent" }
  { key = "mulMaxDeltaAngleVertical", measure = "percent" }
  { key = "mulFrontalStaticFriction", measure = "percent" }
  { key = "mulFrontalSlidingFriction", measure = "percent" }
  { key = "mulSideRotMinSpd", measure = "percent" }
  { key = "mulSideRotMaxSpd", measure = "percent" }
  { key = "mulSideRotMinFric", measure = "percent" }
  { key = "mulSideRotMaxFric", measure = "percent" }
  { key = "mulSuspensionDampeningMoment", measure = "percent" }
  { key = "mulSuspensionMinLimit", measure = "percent" }
  { key = "mulSuspensionMaxLimit", measure = "percent" }
  { key = "mulHorsePowers", measure = "percent" }
  { key = "mulMaxBrakeForce", measure = "percent" }
  { key = "mulTransmissionEfficiency", measure = "percent" }
  { key = "mulSpeedYaw", measure = "percent" }
  // keys for aircraft upgrades from WT
  { key = "mulCdminFusel", measure = "percent" }
  { key = "mulCdminTail", measure = "percent" }
  { key = "mulCdmin", measure = "percent" }
  { key = "mulOswEffNumber", measure = "percent" }
  { key = "damageReceivedMult", measure = "percent" }
  { key = "mulMass", measure = "percent", isPositive = false, mult = -1 }
  { key = "cutProbabilityMult", measure = "percent" }
  { key = "radiatorEffMul", measure = "percent" }
  { key = "mulCompressorMaxP", measure = "percent" }
]
  .map(@(u) { locId = $"itemDetails/upgrade/{u.key}" }.__update(u))

local function prepareValue(val, setup) {
  if (val == null)
    return null
  let { mult = 1, precision = 1 } = setup
  val *= mult
  return fabs(val) < precision ? null : val
}

local function formatValue(val, setup, showValue) {
  val = prepareValue(val, setup)
  if (val == null)
    return null
  if (!showValue)
    return { val = "..." }
  let { locId, measure = "", precision = 1, isPositive = true } = setup
  let rounded = floatToStringRounded(val, precision)
  let fullValue = "{0}{1}".subst(val > 0 ? $"+{rounded}" : rounded,
    measure == "" ? "" : loc($"itemDetails/{measure}", { val = val.tointeger() }))
  let color = val > 0 == isPositive ? GOOD_COLOR : BAD_COLOR
  return {
    title = loc(locId)
    val = colorize(color, fullValue)
  }
}

let countUpgradeStats = @(upgrade)
  UPGRADES_LIST.reduce(@(sum, setup) prepareValue(upgrade?[setup.key], setup) != null ? sum + 1 : sum, 0)

let function mkUpgradeStatsList(upgrade, limit = 0) {
  let list = []
  for (local order = 0, count = 0;
    order < UPGRADES_LIST.len() && (limit <= 0 || count <= limit);
    ++order
  ) {
    let setup = UPGRADES_LIST[order]
    let showValue = limit <= 0 || count < limit
    let formated = formatValue(upgrade?[setup.key], setup, showValue)
    if (formated != null) {
      list.append(formated)
      ++count
    }
  }
  return list
}

let mkUpgradesStatsComp = @(list, isAvailable = false) {
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_VERTICAL
  children = list.map(@(row) {
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_HORIZONTAL
    gap = bigPadding
    children = [
      {
        rendObj = ROBJ_TEXTAREA
        size = [flex(), SIZE_TO_CONTENT]
        behavior = Behaviors.TextArea
        text = row?.title
        color = isAvailable ? BASE_COLOR : defTxtColor
      }.__update(fontSub)
      {
        rendObj = ROBJ_TEXTAREA
        text = row.val
        behavior = Behaviors.TextArea
        color = isAvailable ? BASE_COLOR : defTxtColor
      }.__update(fontSub)
    ]
  })
}

let mkUpgradeStatsTooltip = @(header, list) {
  rendObj = ROBJ_WORLD_BLUR_PANEL
  fillColor = Color(30, 30, 30, 160)
  size = SIZE_TO_CONTENT
  children = {
    rendObj = ROBJ_FRAME
    size = [inventoryItemDetailsWidth, SIZE_TO_CONTENT]
    color =  Color(50, 50, 50, 20)
    borderWidth = hdpx(1)
    padding = fsh(1)
    children = {
      size = [flex(), SIZE_TO_CONTENT]
      flow = FLOW_VERTICAL
      gap = smallPadding
      children = [
        header
        mkUpgradesStatsComp(mkUpgradeStatsList(list))
      ]
    }
  }
}

let function mkUpgradeGroup(groupId, level, idx, upgrade, isFull) {
  if ((upgrade?.len() ?? 0) == 0)
    return null
  let list = mkUpgradeStatsList(upgrade, MAX_STATS_COUNT)

  if (list.len() <= 0)
    return null

  let upgradeHeader = {
    valign = ALIGN_TOP
    flow = FLOW_HORIZONTAL
    size = [flex(), SIZE_TO_CONTENT]
    gap = smallPadding
    children = [
      mkTextArea(loc($"itemDetails/group/{groupId}_{idx}"), [flex(), SIZE_TO_CONTENT])
      levelBlock({ curLevel = level + idx }).__update({pos = [0, 4]})
    ]
  }

  local upgradeStats
  if (isFull) {
    let descLocId = $"itemDetails/group/{groupId}_{idx}/desc"
    if (doesLocTextExist(descLocId)) {
      upgradeStats = {
        size = [flex(), SIZE_TO_CONTENT]
        gap = { size = flex() }
        children = mkTextArea(loc(descLocId), [flex(), SIZE_TO_CONTENT])
      }
    } else {
      upgradeStats = mkUpgradesStatsComp(list)
      if (countUpgradeStats(upgrade) > MAX_STATS_COUNT)
        upgradeStats = withTooltip(upgradeStats.__update({ cursor = normalTooltipTop }),
          @() mkUpgradeStatsTooltip(upgradeHeader, upgrade))
    }
  }

  return {
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    children = [
      upgradeHeader
      upgradeStats
    ]
  }
}

let calcBonus = @(prevWd, curWd, key)
  !(key in curWd) || (prevWd?[key] ?? 0) == 0 ? 0
    : curWd[key].tofloat() / prevWd[key] - 1.0

let function prepareUpgrades(curUpgrades, prevUpgrades, itemData) {
  let res = clone (curUpgrades ?? {})
  foreach (key, value in prevUpgrades)
    res[key] <- (res?[key] ?? 0) - value

  if ("gun__recoilAmount" in itemData) {
    let prevWd = applyUpgrades(itemData, prevUpgrades)
    let curWd = applyUpgrades(itemData, curUpgrades)
    let recoilVertBonus = 100 * calcBonus(prevWd, curWd, "recoilAmountVert")
    if (fabs(recoilVertBonus) >= 1)
      res.recoilVertBonus <- recoilVertBonus
    let recoilHorBonus = 100 * calcBonus(prevWd, curWd, "recoilAmountHor")
    if (fabs(recoilHorBonus) >= 1)
      res.recoilHorBonus <- recoilHorBonus
  }

  return res
}

let function mkUpgrades(item, isFull = true) {
  let { upgradesId = null, upgradeIdx = 0, gametemplate = null, tier = 0 } = item
  if (upgradesId == null || gametemplate == null)
    return null

  local children = []
  let itemData = getWeaponData(gametemplate)
  let allUpgrades = upgrades.value?[upgradesId] ?? []
  let curUpgrades = prepareUpgrades(allUpgrades?[upgradeIdx], allUpgrades?[0] ?? {}, itemData)
  let availableUpgrades = mkUpgradeStatsList(curUpgrades, MAX_STATS_COUNT)
  if (availableUpgrades.len() > 0) {
    local curStats = mkUpgradesStatsComp(availableUpgrades, true)
    if (countUpgradeStats(curUpgrades) > MAX_STATS_COUNT) {
      let basicHeader = {
        rendObj = ROBJ_TEXT
        text = loc("itemDetails/label/basicValues")
        color = titleTxtColor
      }
      curStats = withTooltip(curStats.__update({ cursor = normalTooltipTop }),
        @() mkUpgradeStatsTooltip(basicHeader, curUpgrades))
    }
    children.append(curStats)
  }

  let pendingUpgrades = []
  for (local idx = upgradeIdx + 1; idx < allUpgrades.len(); ++idx) {
    let diff = prepareUpgrades(allUpgrades[idx], allUpgrades?[idx-1] ?? {}, itemData)
    let upgradeGroup = mkUpgradeGroup(upgradesId, tier - upgradeIdx + 1, idx, diff, isFull)
    if (upgradeGroup != null)
      pendingUpgrades.append(upgradeGroup)
  }
  if (pendingUpgrades.len() > 0)
    children = children.append({
      rendObj = ROBJ_TEXT
      text = loc("itemDetails/label/pendingUpgrades")
      color = msgHighlightedTxtColor
    }).extend(pendingUpgrades)

  return children.len() == 0 ? null : {
    size = [flex(), SIZE_TO_CONTENT]
    children = {
      size = [flex(), SIZE_TO_CONTENT]
      gap = isFull ? smallPadding : 0
      flow = FLOW_VERTICAL
      children = children
    }
  }
}

let function diffUpgrades(item, nextIdx = null) {
  let { upgradesId = null, upgradeIdx = 0, gametemplate = null } = item
  if (upgradesId == null || gametemplate == null)
    return null
  let itemData = getWeaponData(gametemplate)
  let allUpgrades = upgrades.value?[upgradesId] ?? []
  let curUpgrades = prepareUpgrades(allUpgrades?[nextIdx ?? (upgradeIdx + 1)], allUpgrades?[upgradeIdx], itemData)
  return mkUpgradeStatsList(curUpgrades)
}

let function mkItemDescription(item) {
  let text = getItemDesc(item)
  return text == "" ? null : {
    size = [flex(), SIZE_TO_CONTENT]
    padding = smallPadding
    rendObj = ROBJ_TEXTAREA
    behavior = Behaviors.TextArea
    text
    color = defTxtColor
  }.__update(fontSub)
}

let mkItemDetails = @(item, isFull)
  mkDetails(getItemDetails(isFull), itemDetailsConstructors(isFull), item)

let mkVehicleDetails = @(vehicle)
  mkDetails(VEHICLE_DETAILS, VEHICLE_DETAILS_CONSTRUCTORS, vehicle)

return {
  mkItemDescription
  mkItemDetails
  mkVehicleDetails
  mkUpgrades
  diffUpgrades
  BASE_COLOR
  blur
  mkUpgradesStatsComp
}
