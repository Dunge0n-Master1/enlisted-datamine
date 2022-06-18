from "%enlSqGlob/ui_library.nut" import *
import "%dngscripts/ecs.nut" as ecs

let colorize = require("%ui/components/colorize.nut")
let { hasPremium } = require("%enlist/currency/premium.nut")
let { getLinkedArmyName } = require("%enlSqGlob/ui/metalink.nut")
let { hasVehicleCustomization } = require("%enlist/featureFlags.nut")
let { endswith } = require("string")
let { configs } = require("%enlSqGlob/configs/configs.nut")
let { vehDecorators } = require("%enlist/meta/profile.nut")
let { viewVehicle } = require("vehiclesListState.nut")
let { add_veh_decorators, apply_decorator, buy_veh_decorator
} = require("%enlist/meta/clientApi.nut")
let { setDecalSlot, setDecalName, setDecalMirrored, setDecalTwoSide,
  vehTargetEid, applyDecalsToVehicle
} = require("decorViewer.nut")
let { curArmyData } = require("%enlist/soldiers/model/state.nut")
let {
  getBaseVehicleSkin, getVehSkins, stringToDecal, decalToCompObject
} = require("%enlSqGlob/vehDecorUtils.nut")
let { accentTitleTxtColor } = require("%enlSqGlob/ui/viewConst.nut")
let {
  allItemTemplates, findItemTemplate
} = require("%enlist/soldiers/model/all_items_templates.nut")


let customizationParams = Watched(null)
let lastOpenedGroupName = Watched("")

let selectedCamouflage = Watched(null)
let selectedDecorator = Watched(null)

let isPurchasing = Watched(false)


let viewVehCustSchemes = Computed(function() {
  if (!hasVehicleCustomization.value)
    return null

  let vehicle = viewVehicle.value
  if (vehicle == null)
    return null

  let { itemsubtype } = vehicle
  let armyId = getLinkedArmyName(vehicle)
  let {
    vehDecal = null, vehDecorator = null, reqArmies = []
  } = (configs.value?.vehCustSchemes ?? {})?[itemsubtype]

  if (vehDecal == null && vehDecorator == null)
    return null

  return reqArmies.len() > 0 && !reqArmies.contains(armyId)
    ? null
    : { vehDecal, vehDecorator }
})


let vehDecorBelongCfg = Computed(function() {
  return configs.value?.vehDecorBelongCfg ?? {}
})

let vehCustomizationCfg = Computed(function() {
  return (configs.value?.vehCustomizationCfg ?? {})
    .map(@(cTypeData) cTypeData.map(@(cfg, guid) { guid }.__update(cfg)))
})

let availVehDecorByTypeId = Computed(function() {
  let res = {}
  foreach (guid, vehDecorator in vehDecorators.value) {
    let { cType, id } = vehDecorator
    if (cType not in res)
      res[cType] <- {}
    if (id not in res[cType])
      res[cType][id] <- {}

    res[cType][id][guid] <- vehDecorator
  }
  return res
})

let customizationSort = @(a, b) (a?.weight ?? 0) <=> (b?.weight ?? 0) || a.guid <=> b.guid


let getOwnedCamouflage = @(typeDecorators, id, vehGuid)
  (typeDecorators?[id] ?? {}).values()
    .findvalue(@(d) d.vehGuid == "" || d.vehGuid == vehGuid)

let forcedCustomization = Computed(function() {
  let res = {}
  let {
    objTexReplace = null, animchar__objTexSet = null
  } = selectedCamouflage.value
  if (objTexReplace != null)
    res.__update({
      vehCamouflage = objTexReplace
      objTexSet = animchar__objTexSet
    })

  return res
})

let hasNoBelongToHidden = @(belongData)
  belongData.findvalue(@(belong) belong.len() > 0) != null

let hasBelongByArmy = @(armyBelong, armyId)
  armyBelong.len() == 0 || (armyBelong?[armyId] ?? false)

let hasBelongByCountry = @(countryBelong, countryId)
  countryBelong.len() == 0 || (countryBelong?[countryId] ?? false)

let hasBelongByType = @(vehTypeBelong, vehType)
  vehTypeBelong.len() == 0 || (vehTypeBelong?[vehType] ?? false)

let function getDecorBelongText(belongId) {
  let belongCfg = vehDecorBelongCfg.value?[belongId] ?? {}
  let armyBelong = (belongCfg?.byArmy ?? {}).keys()
  let countryBelong = (belongCfg?.byCountry ?? {}).keys()
  let vehTypeBelong = (belongCfg?.byVehType ?? {}).keys()
  let belongData = {
    armyies = ", ".join(armyBelong
      .map(@(v) colorize(accentTitleTxtColor, loc($"{v}/full"))))
    countries = ", ".join(countryBelong
      .map(@(v) colorize(accentTitleTxtColor, loc($"country/{v}"))))
    vehTypes = ", ".join(vehTypeBelong
      .map(@(v) colorize(accentTitleTxtColor, loc($"vehType/{v}"))))
  }

  let res = "\n".join(belongData.map(function(txt, key) {
    let keyText = loc($"decorator/belong/{key}")
    return txt == "" ? null : $"{keyText}: {txt}"
  }).values().filter(@(v) v != null))
  return res == "" ? ""
    : "{0}\n{1}".subst(loc("decorator/conditions"), res)
}

let curDecorCfgByType = Computed(function() {
  let vehicle = viewVehicle.value
  if (vehicle == null)
    return null

  let armyId = getLinkedArmyName(vehicle)
  let { basetpl = null, itemsubtype = null } = vehicle
  let template = findItemTemplate(allItemTemplates, armyId, basetpl)
  let { guid = "" } = curArmyData.value
  let { country = "" } = template
  let belongCfg = vehDecorBelongCfg.value
  let res = vehCustomizationCfg.value.map(@(decData, decType) decType == "vehCamouflage"
    ? decData
    : decData.filter(function(decor) {
        let { belongId = "" } = decor
        if (belongId == "")
          return true

        let belongData = belongCfg?[belongId] ?? {}
        return hasNoBelongToHidden(belongData)
          && hasBelongByArmy(belongData?.byArmy ?? {}, guid)
          && hasBelongByCountry(belongData?.byCountry ?? {}, country)
          && hasBelongByType(belongData?.byVehType ?? {}, itemsubtype)
      }))
  return res
})

let viewVehDecorByType = Computed(function() {
  let { guid = "" } = viewVehicle.value
  let decoratorsCfg = vehCustomizationCfg.value
  return availVehDecorByTypeId.value
    .map(function(cTypeData) {
      let res = {}
      foreach (idData in cTypeData)
        foreach (dGuid, decorator in idData)
          if (decorator.vehGuid == guid) {
            let cfg = decoratorsCfg?[decorator.cType][decorator.id]
            res[dGuid] <- decorator.__merge({ cfg })
          }
      return res
    })
})

let viewVehCamouflage = Computed(@()
  (viewVehDecorByType.value?.vehCamouflage ?? {}).values()?[0])

let viewVehDecorators = Computed(function() {
  let res = { vehCamouflage = null }
  let { gametemplate = "" } = viewVehicle.value
  if (gametemplate == "")
    return res

  let { vehCamouflage = {} } = viewVehDecorByType.value
  foreach (skin in vehCamouflage) {
    let camouflageData = getVehSkins(gametemplate).findvalue(@(s) s.id == skin.id)
    if (camouflageData != null) {
      res.vehCamouflage <- camouflageData.objTexReplace
      res.objTexSet <- camouflageData?.animchar__objTexSet
      break
    }
  }

  return res.__update(forcedCustomization.value)
})

let curCamouflageId = Computed(@()
  selectedCamouflage.value?.id ?? viewVehCamouflage.value?.id)

let function startUsingDecal(slot, cfg) {
  setDecalSlot(slot)
  setDecalName(cfg.guid)
  selectedDecorator(cfg)
}

let function mirrorDecal(isMirrored) {
  setDecalMirrored(isMirrored)
}

let function twoSideDecal(isTwoSided, isMirrored) {
  setDecalTwoSide(isTwoSided, isMirrored)
}

let function applyDecorator(guid, vehGuid, cType, details, slot, cb = null) {
  if (isPurchasing.value)
    return

  isPurchasing(true)
  apply_decorator(guid, vehGuid, cType, details, slot, function(res) {
    isPurchasing(false)
    cb?(res)
  })
}

let function buyDecorator(cType, id, cost, cb = null) {
  if (isPurchasing.value)
    return

  isPurchasing(true)
  buy_veh_decorator(cType, id, cost, function(res) {
    isPurchasing(false)
    cb?(res)
  })
}

let closeDecoratorsList = @() customizationParams(null)

let viewVehDecalData = keepref(Computed(function() {
  let vehicleGuid = viewVehicle.value?.guid ?? ""
  let targetEid = vehTargetEid.value ?? -1
  if (vehicleGuid == "" || targetEid < 0)
    return null

  let hasPrem = hasPremium.value
  let { slotsNum = 0, premSlotsNum = 0 } = viewVehCustSchemes.value?.vehDecal ?? {}
  let avaiSlots = hasPrem ? slotsNum + premSlotsNum : slotsNum
  if (avaiSlots <= 0)
    return null

  let decalCompArray = ecs.CompArray()
  foreach (decalsById in availVehDecorByTypeId.value?.vehDecal ?? {}) {
    foreach (decal in decalsById) {
      let { vehGuid, slotIdx, id, details } = decal
      if (vehGuid != vehicleGuid || slotIdx >= avaiSlots)
        continue

      let decalData = stringToDecal(details, id, slotIdx)
      if (decalData != null)
        decalCompArray.append(decalToCompObject(decalData))
    }
  }

  return { targetEid, decalCompArray }
}))

let function updateViewVehDecals(_ = null) {
  let decals = viewVehDecalData.value
  if (decals != null)
    applyDecalsToVehicle(decals)
}

viewVehDecalData.subscribe(updateViewVehDecals)

let function stopUsingDecal() {
  selectedDecorator(null)
  setDecalSlot(-1)
  setDecalName("")
  updateViewVehDecals()
}

let cropSkinName = @(skinName)
  skinName == null || !endswith(skinName, "*")
    ? skinName
    : skinName.slice(0, skinName.len() - 1)

console_register_command(@(cType, id) add_veh_decorators(cType, id), "meta.addVehCustomizator")

return {
  closeDecoratorsList
  customizationParams
  lastOpenedGroupName
  selectedCamouflage

  selectedDecorator
  startUsingDecal
  isPurchasing
  mirrorDecal
  twoSideDecal
  stopUsingDecal

  viewVehDecorators
  vehCustomizationCfg
  vehDecorBelongCfg
  customizationSort
  viewVehCustSchemes
  getVehSkins
  getBaseVehicleSkin
  getOwnedCamouflage
  cropSkinName
  viewVehCamouflage
  curCamouflageId

  availVehDecorByTypeId
  curDecorCfgByType
  getDecorBelongText
  viewVehDecorByType
  applyDecorator
  buyDecorator
}
