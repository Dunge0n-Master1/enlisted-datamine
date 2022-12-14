from "%enlSqGlob/ui_library.nut" import *
import "%dngscripts/ecs.nut" as ecs
let { Point2 } = require("dagor.math")
let {
  viewVehicle, selectVehParams, CAN_USE
} = require("%enlist/vehicles/vehiclesListState.nut")
let {
  getVehicleData, applyUpgrades
} = require("%enlist/soldiers/model/collectWeaponData.nut")
let upgrades = require("%enlist/soldiers/model/config/upgradesConfig.nut")
let { mkUpgradeWatch, mkSpecsWatch } = require("%enlist/vehicles/physSpecs.nut")
let {
  getArmorClassLocName, getArmorPartDesc
} = require("%enlist/vehicles/dmViewerArmor.nut")
let { getXrayPartDesc } = require("%enlist/vehicles/dmViewerXray.nut")
let { isInQueue } = require("%enlist/state/queueState.nut")
let { isInBattleState } = require("%enlSqGlob/inBattleState.nut")
let cursors = require("%ui/style/cursors.nut")
let tooltipBox = require("%ui/style/tooltipBox.nut")
let colorize = require("%ui/components/colorize.nut")
let {
  bigPadding, defPanelBgColorVer_1, listCtors, defBgColor, hoverBgColor
} = require("%enlSqGlob/ui/viewConst.nut")
let { Flat } = require("%ui/components/textButton.nut")
let { blur } = require("%enlist/soldiers/components/itemDetailsPkg.nut")
let { viewVehCustSchemes } = require("%enlist/vehicles/customizeState.nut")
let faComp = require("%ui/components/faComp.nut")
let { mkHotkey } = require("%ui/components/uiHotkeysHint.nut")

enum MODE {
  VIEW_NONE = 0
  VIEW_ARMOR = 1
  VIEW_XRAY = 2
}

let mods = [
  MODE.VIEW_NONE,
  MODE.VIEW_ARMOR,
  MODE.VIEW_XRAY
]

let curViewModeIdx = Watched(0)

let function mkCustomizeButton(curVehicle) {
  let { guid = "" } = curVehicle
  let { flags = 0 } = curVehicle.status
  return flags != CAN_USE && guid == "" ? null
    : Flat(loc("customizeVehicle"),
        @() selectVehParams.mutate(@(v) v.isCustomMode = true),
        {
          hotkeys = [[ "^J:X" ]]
          padding = [0, sh(9)]
          margin = 0
        })
}

let isDebugMode = mkWatched(persist, "isDebugMode", false)
let debugTextColor = Color(255, 128, 0)
let listTxtColor = listCtors.txtColor

let dmViewerTarget = Watched(ecs.INVALID_ENTITY_ID)
let dmViewerMode = Watched(MODE.VIEW_NONE)

let partName = Watched("")
let armorParams = Watched({
  thickness = 0.0
  normalAngle = 0.0
  viewingAngle = 0.0
})

let canUseDmViewer = @(vehicle) vehicle?.itemsubtype == "tank"

let isDmViewerEnabled = Computed(@() dmViewerMode.value != MODE.VIEW_NONE && dmViewerTarget.value != ecs.INVALID_ENTITY_ID)

let dmBlkPath = Computed(function() {
  if (!isDmViewerEnabled.value || (viewVehicle.value?.gametemplate ?? "") == "")
    return ""
  let template = ecs.g_entity_mgr.getTemplateDB().getTemplateByName(viewVehicle.value.gametemplate)
  return template?.getCompValNullable("damage_model__blk") ?? ""
})

let vehicleUpgradedData = Computed(function() {
  if (viewVehicle.value == null || dmViewerMode.value == MODE.VIEW_NONE)
    return null
  let { upgradesId = null, upgradeIdx = 0, gametemplate = null } = viewVehicle.value
  let itemData = gametemplate != null ? getVehicleData(gametemplate) : null
  if (itemData == null)
    return null
  let upgradesCurWatch = mkUpgradeWatch(upgrades, upgradesId, upgradeIdx)
  let specsWatch = mkSpecsWatch(upgradesCurWatch, viewVehicle.value)
  itemData.__update(specsWatch.value)
  return applyUpgrades(itemData, upgradesCurWatch.value)
})

let cacheArmorClass = {}
let cacheXrayDesc = {}

let function resetCache(...) {
  cacheArmorClass.clear()
  cacheXrayDesc.clear()
}
dmBlkPath.subscribe(resetCache)
vehicleUpgradedData.subscribe(resetCache)

let partDebug = Computed(@() isDebugMode.value ? colorize(debugTextColor, $"DEBUG: {partName.value}") : null)

let tooltipTextArmor = Computed(function() {
  if (dmBlkPath.value == "" || partName.value == "")
    return null
  if (cacheArmorClass?[partName.value] == null)
    cacheArmorClass[partName.value] <- getArmorClassLocName(dmBlkPath.value, partName.value)
  return getArmorPartDesc(cacheArmorClass[partName.value], armorParams.value, partDebug.value)
})

let tooltipTextXray = Computed(function() {
  if (dmBlkPath.value == "" || partName.value == "")
    return null
  if (cacheXrayDesc?[partName.value] == null)
    cacheXrayDesc[partName.value] <- getXrayPartDesc(viewVehicle.value, vehicleUpgradedData.value,
      dmBlkPath.value, partName.value, partDebug.value)
  return cacheXrayDesc[partName.value]
})

let mkTooltipComp = @(text) tooltipBox({
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  maxWidth = hdpx(800)
  fontSize = hdpx(20)
  color = Color(160,160,160)
  text
})

let updateTooltip = @(text) cursors.setTooltip(text != null ? mkTooltipComp(text) : null)

let function updateTooltipSubscriptions(...) {
  tooltipTextArmor.unsubscribe(updateTooltip)
  tooltipTextXray.unsubscribe(updateTooltip)
  updateTooltip(null)
  if (dmViewerTarget.value != ecs.INVALID_ENTITY_ID) {
    if (dmViewerMode.value == MODE.VIEW_ARMOR)
      tooltipTextArmor.subscribe(updateTooltip)
    else if (dmViewerMode.value == MODE.VIEW_XRAY)
      tooltipTextXray.subscribe(updateTooltip)
  }
}

dmViewerTarget.subscribe(updateTooltipSubscriptions)
dmViewerMode.subscribe(updateTooltipSubscriptions)

ecs.register_es("armor_analyzer", {
    [[ "onInit", "onChange" ]] = function(_eid, comp) {
      dmViewerTarget.update(comp["armor_analyzer__target"])
      dmViewerMode.update(comp["armor_analyzer__mode"])
      partName.update(comp["armor_analyzer__partName"])
      armorParams.mutate(function(p) {
        p.thickness    = comp["armor_analyzer__thickness"]
        p.normalAngle  = comp["armor_analyzer__normalAngle"]
        p.viewingAngle = comp["armor_analyzer__angle"]
      })
    },
  },
  {
    comps_track = [
      ["armor_analyzer__target", ecs.TYPE_EID],
      ["armor_analyzer__mode", ecs.TYPE_INT],
      ["armor_analyzer__partName", ecs.TYPE_STRING, ""],
      ["armor_analyzer__thickness", ecs.TYPE_FLOAT, 0.0],
      ["armor_analyzer__normalAngle", ecs.TYPE_FLOAT, 0.0],
      ["armor_analyzer__angle", ecs.TYPE_FLOAT, 0.0],
    ],
  }
)

let setDmViewerTargetQuery = ecs.SqQuery("setDmViewerTargetQuery",
  { comps_rw = [ "armor_analyzer__target" ]})

let function setDmViewerTarget(targetEid) {
  setDmViewerTargetQuery.perform(function(_eid, comp) {
    comp["armor_analyzer__target"] = targetEid
  })
}

let setDmViewerModeQuery = ecs.SqQuery("setDmViewerModeQuery",
  { comps_rw = [ "armor_analyzer__mode" ] })

let function setDmViewerMode(mode) {
  setDmViewerModeQuery.perform(function(_eid, comp) {
    comp["armor_analyzer__mode"] = mode
  })
}

let setDmViewerScreenPosQuery = ecs.SqQuery("setDmViewerScreenPosQuery",
  { comps_rw = [ "armor_analyzer__screenPos" ] })

let function onDmViewerMouseMove(mouseEvent) {
  setDmViewerScreenPosQuery.perform(function(_eid, comp) {
    comp["armor_analyzer__screenPos"] = Point2(mouseEvent.screenX, mouseEvent.screenY)
  })
}

curViewModeIdx.subscribe(@(v) setDmViewerMode(v))

let modeTabs = [{
    id = MODE.VIEW_ARMOR
    locId = "vehicle/inspect/mode/armor"
    tooltipLocId = "vehicle/inspect/mode/armor/tooltip"
  }, {
    id = MODE.VIEW_XRAY
    locId = "vehicle/inspect/mode/xray"
    tooltipLocId = "vehicle/inspect/mode/xray/tooltip"
  }]

let eyeButtonBlock = watchElemState(@(sf) {
  rendObj = ROBJ_SOLID
  behavior = Behaviors.Button
  size = [SIZE_TO_CONTENT, flex()]
  valign = ALIGN_CENTER
  padding = [0, hdpx(10)]
  onClick = @() setDmViewerMode(MODE.VIEW_NONE)
  onHover = @(on) cursors.setTooltip(on ? loc("vehicle/inspect/mode/off/tooltip") : null)
  color = sf & S_HOVER ? hoverBgColor
    : dmViewerMode.value == 0 ? defPanelBgColorVer_1
    : defBgColor
  children = faComp("eye-slash", {
    fontSize = hdpx(30)
    color = listTxtColor(sf)
  })
})

let function changeViewMods(idx) {
  let newIdx = curViewModeIdx.value + idx
  if (newIdx >= 0 && newIdx < mods.len())
    curViewModeIdx(newIdx)
}

let dmViewerPanelUi = @() canUseDmViewer(viewVehicle.value) ? {
    watch = [ viewVehicle, isDebugMode, dmBlkPath ]
    size = SIZE_TO_CONTENT
    vplace = ALIGN_BOTTOM
    flow = FLOW_VERTICAL
    gap = bigPadding
    children = [
      !isDebugMode.value || dmBlkPath.value == ""
        ? null
        : {
            rendObj = ROBJ_TEXTAREA
            behavior = Behaviors.TextArea
            hplace = ALIGN_CENTER
            color = debugTextColor
            fontSize = hdpx(20)
            text = $"DEBUG: Damage Model: {dmBlkPath.value}"
          }
      @() blur({
        watch = [viewVehCustSchemes, dmViewerMode]
        hplace = ALIGN_CENTER
        padding = bigPadding
        flow = FLOW_VERTICAL
        halign = ALIGN_CENTER
        gap = bigPadding
        children = [
          viewVehCustSchemes.value != null
            ? mkCustomizeButton(viewVehicle.value)
            : null
          {
            flow = FLOW_HORIZONTAL
            valign = ALIGN_CENTER
            children = [
              mkHotkey("^J:LB", @() changeViewMods(-1))
              eyeButtonBlock
              {
                hplace = ALIGN_CENTER
                flow = FLOW_HORIZONTAL
                children = modeTabs.map(function(v) {
                  let id = v.id
                  let isCurrent = dmViewerMode.value == id
                  return Flat(loc(v.locId), @() setDmViewerMode(id), {
                    margin = 0
                    minWidth = hdpx(130)
                    style = { BgNormal = isCurrent ? defPanelBgColorVer_1 : defBgColor }
                    onHover = @(on) cursors.setTooltip(on ? loc(v.tooltipLocId) : null)
                  })
                })
              }
              mkHotkey("^J:RB", @() changeViewMods(1))
            ]
          }
        ]
      })
    ]
  }
  : {
      watch = [viewVehCustSchemes, viewVehicle]
      vplace = ALIGN_BOTTOM
      children = viewVehCustSchemes.value != null
        ? mkCustomizeButton(viewVehicle.value)
        : null
    }

let closeDmViewerMode = @() setDmViewerMode(MODE.VIEW_NONE)

viewVehicle.subscribe(function(vehicle) {
  if (!canUseDmViewer(vehicle))
    closeDmViewerMode()
})
isInQueue.subscribe(function(val) {
  if (!val) // Probably connecting to battle
    closeDmViewerMode()
})
isInBattleState.subscribe(function(val) {
  if (val) // Connected to battle
    closeDmViewerMode()
})

console_register_command(function () {
    resetCache()
    isDebugMode.update(!isDebugMode.value)
  }, "dmViewer.toggleDebugMode")

return {
  isDmViewerEnabled
  setDmViewerTarget
  dmViewerPanelUi
  onDmViewerMouseMove
  closeDmViewerMode
}
