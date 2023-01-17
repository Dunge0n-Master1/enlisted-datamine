from "%enlSqGlob/ui_library.nut" import *

let { sub_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let { doesLocTextExist } = require("dagor.localize")
let { fabs } = require("math")
let { defTxtColor, activeTxtColor, fadedTxtColor, textBgBlurColor, smallPadding, bigPadding,
  msgHighlightedTxtColor, inventoryItemDetailsWidth
} = require("%enlSqGlob/ui/viewConst.nut")
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

let RANGE_SIZE = [hdpx(250), hdpx(3)]

let blur = @(override = {}) {
  size = SIZE_TO_CONTENT
  rendObj = ROBJ_WORLD_BLUR_PANEL
  color = textBgBlurColor
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
  children = [
    {
      rendObj = ROBJ_TEXT
      text = header
      color = BASE_COLOR
    }
    { size = flex() }
    {
      rendObj = ROBJ_TEXTAREA
      text = value
      behavior = Behaviors.TextArea
      color = BASE_COLOR
    }
  ]
}

let vertFrame = { rendObj = ROBJ_SOLID, size = [hdpx(1), flex()], color = fadedTxtColor }

let armamentRowTitle = @(gun) {
  size = [flex(4), SIZE_TO_CONTENT]
  valign = ALIGN_TOP
  flow = FLOW_HORIZONTAL
  gap = smallPadding
  padding = [smallPadding, bigPadding]
  children = [
    {
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      size = [flex(), SIZE_TO_CONTENT]
      text = "gun__locName" in gun ? loc("guns/{0}".subst(gun["gun__locName"])) : loc("unknown")
      color = defTxtColor
    }
    gun.count <= 1 || gun.count == gun.gun__maxAmmo ? null : {
      rendObj = ROBJ_TEXT
      text = loc("common/amountShort", { count = gun.count })
      color = defTxtColor
    }
  ]
}

let armamentRowRounds = @(gun) {
  rendObj = ROBJ_TEXTAREA
  size = [flex(1), SIZE_TO_CONTENT]
  halign = ALIGN_RIGHT
  padding = [smallPadding, bigPadding]
  text = "{0}{1}".subst(colorize(activeTxtColor, gun["gun__maxAmmo"]), loc("itemDetails/count"))
  behavior = Behaviors.TextArea
  color = defTxtColor
}

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
            rendObj = ROBJ_FRAME
            size = [flex(), SIZE_TO_CONTENT]
            flow = FLOW_VERTICAL
            padding = smallPadding
            color = fadedTxtColor
            borderWidth = hdpx(1)
            children = reducedGuns.map(@(gun){
              size = [flex(), SIZE_TO_CONTENT]
              flow = FLOW_HORIZONTAL
              gap = vertFrame
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

let function armorRowCtor(tbl, _itemData, setup, _itemBase) {
  let { mult = 1, measure = "", precision = 1 } = setup
  let columns = ARMOR_ORDER
    .filter(@(key) key in tbl)
    .map(function(key) {
      local val = tbl[key] * mult
      let valColor = colorize(activeTxtColor, floatToStringRounded(val, precision))
      val = round_by_value(val, precision).tointeger()
      return {
        size = [flex(), SIZE_TO_CONTENT]
        halign = ALIGN_CENTER
        flow = FLOW_VERTICAL
        padding = smallPadding
        children = [
          {
            rendObj = ROBJ_TEXT
            text = loc($"itemDetails/armor__{key}")
            color = defTxtColor
          }
          {
            rendObj = ROBJ_TEXTAREA
            text = measure != ""
              ? "{0}{1}".subst(valColor, loc($"itemDetails/{measure}", { val = val }))
              : valColor
            behavior = Behaviors.TextArea
            color = defTxtColor
          }
        ]
      }
    })
  return {
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    gap = smallPadding
    children = [
      {
        rendObj = ROBJ_TEXT
        text = loc($"itemDetails/{setup.key}")
        color = defTxtColor
      }
      {
        rendObj = ROBJ_FRAME
        borderWidth = hdpx(1)
        size = [flex(), SIZE_TO_CONTENT]
        flow = FLOW_HORIZONTAL
        gap = vertFrame
        color = fadedTxtColor
        children = columns
      }
    ]
  }
}

let gunFiringModeNamesShortDesc  = @(val, _itemData, _setup, _itemBase) val.len() == 0 ? null
  : {
      size = [flex(),SIZE_TO_CONTENT]
      flow = FLOW_HORIZONTAL
      valign = ALIGN_TOP
      halign = ALIGN_RIGHT
      gap = hdpx(3)
      children = [
        {
          flow = FLOW_VERTICAL
          valign = ALIGN_TOP
          halign = ALIGN_RIGHT
          children = val.map(@(name) mkText(loc($"firing_mode/{name}")))
        }
        {
          size = [RANGE_SIZE[0], SIZE_TO_CONTENT]
          valign = ALIGN_TOP
          halign = ALIGN_LEFT
          children = mkText(loc("itemDetails/gun__firingModeNames"))
        }
      ]
    }

let itemDetalesConstructors = @(isFull) {
  "bullets" : @(val, itemData, _setup, _itemBase) val <= 0 ? null
    : mkTextRow(loc("itemDetails/bullets"),
        loc(itemData?.magazine_type ?? "magazine_type/default",
          { count = val, countColored = colorize(activeTxtColor, val) }))
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
      rpm = colorize(activeTxtColor, itemData?[baseKey])
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
      color = BASE_COLOR
      transform = { pivot = [0, 0]}
      animations = [
        { prop = AnimProp.scale, from = [0, 1], to = [0, 1], duration = 0.1, play = true }
        { prop = AnimProp.scale, from = [0, 1], to = [1, 1], duration = 0.2, play = true, delay = 0.1 }
      ]
    }
  }
}

let mkShortLine = @(key, valText, val, range, animKey) {
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_HORIZONTAL
  gap = sh(1)
  children = [
    mkTextArea(valText, [flex(), SIZE_TO_CONTENT], ALIGN_RIGHT)
    {
      size = [RANGE_SIZE[0], SIZE_TO_CONTENT]
      flow = FLOW_VERTICAL
      children = [
        mkText(loc($"itemDetails/{key}"))
        range != null ? mkRange(val, range, animKey) : null
      ]
    }
  ]
}

let mkFullLine = @(key, valText, val, range, animKey) {
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_VERTICAL
  children = [
    {
      size = [flex(), SIZE_TO_CONTENT]
      flow = FLOW_HORIZONTAL
      children = [
        mkText(loc($"itemDetails/{key}"))
        { size = flex() }
        mkTextArea(valText)
      ]
    }
    range != null ? mkRange(val, range, animKey) : null
  ]
}

local function mkDetailsLine(val, setup, itemBase, isFull, animKey) {
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
  let valText = !isFull || measure == ""
    ? valColored
    : "{0}{1}".subst(valColored, loc($"itemDetails/{measure}", { val = topVal }))

  return isFull
    ? mkFullLine(key, valText, val.top(), range, animKey)
    : mkShortLine(key, valText, val.top(), range, animKey)
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
      let refColor = colorize(BASE_COLOR, ref)
      local val = (col?.x ?? 0) * baseVal * mult
      let valColor = colorize(BASE_COLOR, floatToStringRounded(val, precision))
      val = round_by_value(val, precision).tointeger()
      return {
        size = [flex(), SIZE_TO_CONTENT]
        halign = ALIGN_CENTER
        flow = FLOW_VERTICAL
        padding = smallPadding
        children = [
          {
            rendObj = ROBJ_TEXTAREA
            text = measure != ""
              ? "{0}{1}".subst(refColor, loc($"itemDetails/{measure}", { val = ref }))
              : refColor
            behavior = Behaviors.TextArea
            color = BASE_COLOR
          }
          {
            rendObj = ROBJ_TEXTAREA
            text = altMeasure != ""
              ? "{0}{1}".subst(valColor, loc($"itemDetails/{altMeasure}", { val = val }))
              : valColor
            behavior = Behaviors.TextArea
            color = BASE_COLOR
          }
        ]
      }
    })
  return columns.len() <= 0 ? null : {
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    gap = smallPadding
    children = [
      {
        rendObj = ROBJ_TEXT
        text = loc($"itemDetails/{key}")
        color = BASE_COLOR
      }
      {
        rendObj = ROBJ_FRAME
        borderWidth = hdpx(1)
        size = [flex(), SIZE_TO_CONTENT]
        flow = FLOW_HORIZONTAL
        gap = vertFrame
        color = BASE_COLOR
        children = columns
      }
    ]
  }
}

let containerFullSize = [inventoryItemDetailsWidth, SIZE_TO_CONTENT]
let containerShortSize = [inventoryItemDetailsWidth * 0.8, SIZE_TO_CONTENT]

let function mkDetails(detailsList, constructors, item, isFull) {
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
        let animKey = $"{gametemplate}_{setup.key}_{isFull}"
        return val == null || val == 0 ? null
          : setup.key in constructors ? constructors[setup.key](val, itemData, setup, itemBase)
          : type(val) == "table" ? mkDetailsTable(val, setup, upgradedData?[setup?.baseKey] ?? 1.0)
          : mkDetailsLine(val, setup, itemBase, isFull, animKey)
      })
      .filter(@(v) v != null)
    return children.len() == 0
      ? res
      : res.__update({
          children = {
            size = isFull ? containerFullSize : containerShortSize
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

local function formatValue(val, setup) {
  val = prepareValue(val, setup)
  if (val == null)
    return null
  let { locId, measure = "", precision = 1, isPositive = true } = setup
  let rounded = floatToStringRounded(val, precision)
  let fullValue = "{0}{1}".subst(val > 0 ? $"+{rounded}" : rounded,
    measure == "" ? "" : loc($"itemDetails/{measure}", { val = val.tointeger() }))
  let color = val > 0 == isPositive ? GOOD_COLOR : BAD_COLOR
  return "{0} {1}".subst(loc(locId), colorize(color, fullValue))
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
    let formated = formatValue(upgrade?[setup.key], setup)
    if (formated != null) {
      list.append(limit <= 0 || count < limit ? formated : "...")
      ++count
    }
  }
  return list
}

let mkUpgradesStatsComp = @(list, isAvailable = false) {
  rendObj = ROBJ_TEXTAREA
  size = [flex(), SIZE_TO_CONTENT]
  text = "\n".join(list)
  behavior = Behaviors.TextArea
  color = isAvailable ? BASE_COLOR : defTxtColor
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
      {
        rendObj = ROBJ_TEXTAREA
        behavior = Behaviors.TextArea
        size = [flex(), SIZE_TO_CONTENT]
        text = loc($"itemDetails/group/{groupId}_{idx}")
        color = BASE_COLOR
      }
      levelBlock({ curLevel = level + idx }).__update({pos = [0, 4]})
    ]
  }

  local upgradeStats
  if (isFull) {
    let descLocId = $"itemDetails/group/{groupId}_{idx}/desc"
    if (doesLocTextExist(descLocId)) {
      upgradeStats = {
        size = [flex(), SIZE_TO_CONTENT]
        gap = smallPadding
        children = {
          rendObj = ROBJ_TEXTAREA
          size = [flex(), SIZE_TO_CONTENT]
          behavior = Behaviors.TextArea
          text = loc(descLocId)
          color = defTxtColor
        }
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
        color = activeTxtColor
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
    children = {
      size = isFull ? containerFullSize : containerShortSize
      gap = isFull ? bigPadding : 0
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
  let descLoc = getItemDesc(item)
  return descLoc == "" ? null : {
    children = {
      size = containerFullSize
      padding = smallPadding
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      text = descLoc
      color = BASE_COLOR
    }.__update(sub_txt)
  }
}

let mkItemDetails = @(item, isFull)
  mkDetails(getItemDetails(isFull), itemDetalesConstructors(isFull), item, isFull)

let mkVehicleDetails = @(vehicle, isFull)
  mkDetails(VEHICLE_DETAILS, VEHICLE_DETAILS_CONSTRUCTORS, vehicle, isFull)

return {
  blur
  mkItemDescription
  mkItemDetails
  mkVehicleDetails
  mkUpgrades
  diffUpgrades
  BASE_COLOR
}
