from "%enlSqGlob/ui_library.nut" import *
import "%dngscripts/ecs.nut" as ecs

let JB = require("%ui/control/gui_buttons.nut")
let colorize = require("%ui/components/colorize.nut")
let checkbox = require("%ui/components/checkbox.nut")
let spinner = require("%ui/components/spinner.nut")
let { startswith } = require("string")
let { showMsgbox } = require("%enlist/components/msgbox.nut")
let { sub_txt, body_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let { txt, noteTextArea } = require("%enlSqGlob/ui/defcomps.nut")
let { SaveVehicleDecals } = require("vehicle_decals")
let { ceil } = require("%sqstd/math.nut")
let { safeAreaBorders } = require("%enlist/options/safeAreaState.nut")
let { selectVehParams, viewVehicle } = require("vehiclesListState.nut")
let { hasPremium } = require("%enlist/currency/premium.nut")
let { Bordered } = require("%ui/components/textButton.nut")
let { currenciesList } = require("%enlist/currency/currencies.nut")
let { currencyBtn } = require("%enlist/currency/currenciesComp.nut")
let { purchaseMsgBox } = require("%enlist/currency/purchaseMsgBox.nut")
let { makeVertScroll, thinStyle } = require("%ui/components/scrollbar.nut")
let {
  mkDecorSlot, mkDecorIcon, mkBlockHeader, mkCustGroup, slotSize, mkSkinIcon,
  mkFlipBtn, mkSelectBox, mkButton, closeActionIcon, scaleRotationHint,
  slotBigSize, slotNormalColor
} = require("customizePkg.nut")
let {
  sceneWithCameraAdd, sceneWithCameraRemove
} = require("%enlist/sceneWithCamera.nut")
let {
  customizationParams, lastOpenedGroupName, getDecorBelongText,
  curDecorCfgByType, viewVehCustSchemes, customizationSort,
  selectedCamouflage, applyDecorator, availVehDecorByTypeId,
  buyDecorator, curCamouflageId, getOwnedCamouflage, viewVehCamouflage,
  selectedDecorator, startUsingDecal, stopUsingDecal,
  mirrorDecal, twoSideDecal, viewVehDecorByType,
  cropSkinName, closeDecoratorsList, isPurchasing
} = require("customizeState.nut")
let {
  getBaseVehicleSkin, getVehSkins, decalToString
} = require("%enlSqGlob/vehDecorUtils.nut")
let {
  bigPadding, tinyOffset, smallOffset, smallPadding, accentTitleTxtColor,
  defBgColor
} = require("%enlSqGlob/ui/viewConst.nut")
let {
  onDecalMouseMove, onDecalMouseWheel, applyUsingDecal
} = require("decorViewer.nut")
let { closeDmViewerMode } = require("dmViewer.nut")


enum SIDE_PARAMS {
  ONE_SIDE = "DecalSingleSide"
  TWO_SIDE = "DecalTwoSided"
  TWO_SIDE_MIRRORED = "DecalTwoSidedMirr"
}

let sideParams = [
  SIDE_PARAMS.ONE_SIDE,
  SIDE_PARAMS.TWO_SIDE,
  SIDE_PARAMS.TWO_SIDE_MIRRORED
]

let isMirrorMode = mkWatched(persist, "isMirrorMode", false)
let twoSideIdx = mkWatched(persist, "twoSideIdx", 0)

const SLOTS_IN_ROW = 4

let iconSpaceWidth = SLOTS_IN_ROW * slotSize[0] + (SLOTS_IN_ROW - 1) * bigPadding

let purchSpinner = spinner({ height = hdpx(80) }).__update({
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
})

let function mkCamouflage(cParams, gametemplate, camouflage) {
  let { id = null } = camouflage
  let { curCustType = "", curSlotIdx = -1 } = cParams
  let isSelected = curCustType == "vehCamouflage" && curSlotIdx == 0
  let skin = getVehSkins(gametemplate).findvalue(@(s) s.id == id)
  let {
    locId = null, objTexReplace = (getBaseVehicleSkin(gametemplate) ?? {})
  } = skin
  local skinId = cropSkinName((objTexReplace).values()?[0])
  let skinLocId = locId ?? ($"skin/{skinId ?? "baseSkinName"}")
  let decorator = skinId == null ? null : { cfg = { guid = skinId }}
  return {
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    gap = bigPadding
    padding = bigPadding
    children = [
      {
        size = [flex(), SIZE_TO_CONTENT]
        flow = FLOW_VERTICAL
        children = [
          mkBlockHeader(loc("vehCamouflageHeader"))
          noteTextArea(loc(skinLocId)).__update({
            size = [flex(), SIZE_TO_CONTENT]
            margin = [0, smallPadding]
            color = accentTitleTxtColor
          }.__update(sub_txt))
        ]
      }
      mkDecorSlot(decorator, isSelected, false, function() {
        if (!isPurchasing.value)
          customizationParams({
            curCustType = "vehCamouflage"
            curSlotIdx = 0
          })
      })
    ]
  }
}

let mkCustomize = kwarg(
  function(decorators, scheme, slotParams, decoratorsCfg, hasPrem) {
    let { curCustType = "", curSlotIdx = -1 } = slotParams
    let { custType = "", slotsNum = 0, premSlotsNum = 0 } = scheme
    let total = slotsNum + premSlotsNum
    let available = hasPrem ? total : slotsNum
    let rows = ceil(total.tofloat() / SLOTS_IN_ROW)
    return total == 0 ? null
      : {
          flow = FLOW_VERTICAL
          gap = bigPadding
          padding = bigPadding
          children = [mkBlockHeader(loc($"{custType}Header"))]
            .extend(array(rows).map(@(_row, rowIdx) {
              flow = FLOW_HORIZONTAL
              gap = bigPadding
              children = array(SLOTS_IN_ROW).map(function(_column, columnIdx) {
                let sIdx = rowIdx * SLOTS_IN_ROW + columnIdx
                let isSelected = curCustType == custType && curSlotIdx == sIdx
                let hasLocked = sIdx >= available
                let decorator = decorators.findvalue(@(d) d.slotIdx == sIdx)
                let onClick = function() {
                  if (isPurchasing.value)
                    return

                  selectedCamouflage(null)
                  customizationParams({
                    curCustType = custType
                    curSlotIdx = sIdx
                  })
                }
                local onRemove = null
                if (decorator != null) {
                  let { cType, vehGuid, slotIdx } = decorator
                  onRemove = function() {
                    if (decorator.cfg.guid in decoratorsCfg)
                      return applyDecorator("", vehGuid, cType, "", slotIdx)

                    showMsgbox({
                      text = "{0}\n\n{1}".subst(
                        getDecorBelongText(decorator.cfg.belongId),
                        loc("decorator/removeWarning")
                      )
                      buttons = [
                        {
                          text = loc("Yes"), isCurrent = true,
                          action = @() applyDecorator("", vehGuid, cType, "", slotIdx)
                        }
                        { text = loc("Cancel"), isCancel = true }
                      ]
                    })
                  }
                }

                return sIdx >= total ? null
                  : mkDecorSlot(decorator, isSelected, hasLocked, onClick, onRemove)
              })
            }))
        }
  })

let curAvailCamouflages = Computed(function() {
  let { gametemplate = null, isEvent = false, isPremium = false } = viewVehicle.value
  if (gametemplate == null)
    return []

  let availCamouflage = availVehDecorByTypeId.value?.vehCamouflage ?? {}
  let tplWithoutCountry = gametemplate.slice((gametemplate.indexof("_") ?? -1) + 1)
  let vehSkins = getVehSkins(gametemplate)
  return !isEvent && !isPremium ? vehSkins
    : vehSkins.filter(@(skinData) skinData.id in availCamouflage
        || startswith(skinData.id, tplWithoutCountry))
})

let function customizeSlotsUi() {
  let decorCfgByType = curDecorCfgByType.value
  let { gametemplate = null } = viewVehicle.value
  let { vehDecal = null } = viewVehCustSchemes.value
  let slotParams = customizationParams.value
  let decorators = viewVehDecorByType.value
  let camouflage = viewVehCamouflage.value
  let availVehSkins = curAvailCamouflages.value

  let camouflageSlot = availVehSkins.len() > 0 && gametemplate != null
    ? mkCamouflage(slotParams, gametemplate, camouflage)
    : null

  return {
    watch = [
      viewVehCustSchemes, customizationParams, viewVehDecorByType,
      viewVehCamouflage, viewVehicle, hasPremium, curAvailCamouflages,
      curDecorCfgByType
    ]
    size = [SIZE_TO_CONTENT, flex()]
    flow = FLOW_VERTICAL
    gap = tinyOffset
    children = [
      { size = flex() }
      camouflageSlot
      /*mkCustomize({ // decorators temporarily hidden
        decorators = decorators?.vehDecorator ?? {}
        scheme = vehDecorator
        slotParams
        decoratorsCfg = decorCfgByType?.vehDecorator ?? {}
        hasPrem = hasPremium.value
      })*/
      mkCustomize({
        decorators = decorators?.vehDecal ?? {}
        scheme = vehDecal
        slotParams
        decoratorsCfg = decorCfgByType?.vehDecal ?? {}
        hasPrem = hasPremium.value
      })
      { size = flex() }
      Bordered(loc("BackBtn"),
        @() selectVehParams.mutate(@(v) v.isCustomMode = false),
        {
          margin = bigPadding
          hotkeys = [[ $"^{JB.B} | Esc", { description = loc("BackBtn") }]]
        })
    ]
  }
}

let wrapParams = {
  width = iconSpaceWidth
  hGap = bigPadding
  vGap = bigPadding
}

let emptyList = {
  rendObj = ROBJ_WORLD_BLUR_PANEL
  size = [flex(), SIZE_TO_CONTENT]
  padding = bigPadding
  halign = ALIGN_CENTER
  color = defBgColor
  children = txt(loc("msg/listIsEmpty")).__update(sub_txt)
}

let function mkGroupIcons(groupIconsList, vehGuid, curCustType,
  curSlotIdx, currencies, ownDecorators, onlyOwnedVal
) {
  let children = []
  foreach (iconCfg in groupIconsList) {
    let cfg = clone iconCfg
    let { guid } = cfg
    let freeDecorators = (ownDecorators?[guid] ?? {})
      .filter(@(d) d.id == guid
        && (d.vehGuid == "" || d.vehGuid == vehGuid )
        && (d.slotIdx == -1 || d.slotIdx == curSlotIdx))

    if (freeDecorators.len() == 0 && onlyOwnedVal)
      continue

    let onClick = curCustType == "vehDecal"
      ? @() startUsingDecal(curSlotIdx, cfg)
      : @() null
    children.append(mkDecorIcon({
      cfg, currencies, onClick, availableCount = freeDecorators.len()
    }))
  }

  return children.len() == 0 ? emptyList
    : {
        size = [flex(), SIZE_TO_CONTENT]
        children = wrap(children, wrapParams)
      }
}

let mkCustomizeList = @(groupName, hasOpened, onClick, groupIcons = null) {
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_VERTICAL
  gap = bigPadding
  children = [
    mkCustGroup(groupName, hasOpened, onClick)
    groupIcons
  ]
}

let mkCustomizationList = @(curCustType, content, onlyOwned = null) {
  size = [SIZE_TO_CONTENT, flex()]
  padding = [smallOffset,bigPadding,0,bigPadding]
  children = {
    key = $"{curCustType}_customization"
    size = [SIZE_TO_CONTENT, flex()]
    flow = FLOW_VERTICAL
    gap = bigPadding
    children = [
      {
        rendObj = ROBJ_SOLID
        size = [iconSpaceWidth, SIZE_TO_CONTENT]
        flow = FLOW_HORIZONTAL
        gap = smallOffset
        padding = smallPadding
        valign = ALIGN_CENTER
        color = slotNormalColor
        children = [
          mkBlockHeader(loc($"{curCustType}ChooseHeader"))
          { size = flex() }
          onlyOwned == null ? null
            : checkbox(onlyOwned, { text = loc("onlyAvailable") }.__update(sub_txt), {
                setValue = @(_) onlyOwned(!onlyOwned.value)
                textOnTheLeft = true
              })
          mkButton({
            icon = closeActionIcon
            onClick = function() {
              selectedCamouflage(null)
              closeDecoratorsList()
            }
            descLocId = "Close"
            hotkey = "Esc"
            gpadHotkey = "J:B"
            override = {
              size = [hdpx(36), hdpx(36)]
              padding = smallPadding
            }
          })
        ]
      }
    ].append(makeVertScroll(content, { styling = thinStyle }))
    transform = {}
    animations = [{
      prop = AnimProp.translate, from = [iconSpaceWidth, 0], to = [0, 0],
      play = true, duration = 0.5, easing = OutCubic
    }]
  }
}

let mkDecoratorsList = @(curCustType, curSlotIdx, onlyOwned) function() {
  let res = {
    watch = [
      curDecorCfgByType, lastOpenedGroupName, viewVehicle,
      currenciesList, availVehDecorByTypeId, onlyOwned
    ]
  }

  let vehGuid = viewVehicle.value?.guid
  let ownDecorators = availVehDecorByTypeId.value?[curCustType] ?? {}
  let currencies = currenciesList.value
  let custCfg = curDecorCfgByType.value?[curCustType] ?? {}
  if (custCfg.len() == 0)
    return res

  let groupsList = custCfg
    .reduce(@(r, v) v.subType == "" ? r : r.__merge({ [v.subType] = true }), {})
    .keys()
    .sort(@(a, b) a <=> b)

  let openedGroup = lastOpenedGroupName.value
  let groupIconsList = custCfg.values()
    .filter(@(cfg) cfg.subType == openedGroup)
    .sort(customizationSort)

  let onlyOwnedVal = onlyOwned.value
  let content = groupsList.len() == 0 ? null
    : {
        size = [flex(), SIZE_TO_CONTENT]
        flow = FLOW_VERTICAL
        gap = bigPadding
        children = groupsList.map(function(groupName) {
          let hasOpened = openedGroup == groupName
          let groupIcons = hasOpened
            ? mkGroupIcons(groupIconsList, vehGuid, curCustType, curSlotIdx,
                currencies, ownDecorators, onlyOwnedVal)
            : null
          let onGroupClick = @() lastOpenedGroupName(hasOpened ? "" : groupName)
          return mkCustomizeList(groupName, hasOpened, onGroupClick, groupIcons)
        })
      }
  return res.__update(mkCustomizationList(curCustType, content, onlyOwned))
}

let function applyCamouflageImpl(guid, vehGuid, cType, slot) {
  applyDecorator(guid, vehGuid, cType, "", slot, function(res) {
    if (res?.error == null)
      selectedCamouflage(null)
  })
}

let function chooseSkin(skinData, vehGuid, ownCamouflages = {}) {
  if (skinData == null)
    return applyCamouflageImpl("", vehGuid, "vehCamouflage", 0)

  let ownCamouflage = getOwnedCamouflage(ownCamouflages, skinData.id, vehGuid)
  selectedCamouflage(skinData.__merge({ hasOwned = ownCamouflage != null }))
  if (ownCamouflage != null)
    applyCamouflageImpl(ownCamouflage.guid, vehGuid, "vehCamouflage", 0)
}

let camouflageListUi = function() {
  let res = { watch = [
    viewVehicle, curCamouflageId, curDecorCfgByType, availVehDecorByTypeId,
    currenciesList, curAvailCamouflages
  ]}

  let currencies = currenciesList.value
  let custCfg = curDecorCfgByType.value?.vehCamouflage ?? {}
  if (custCfg.len() == 0)
    return res

  let camouflageId = curCamouflageId.value
  let ownCamouflages = availVehDecorByTypeId.value?.vehCamouflage ?? {}
  let { guid, gametemplate } = viewVehicle.value
  let availVehSkins = curAvailCamouflages.value

  let skinsList = []
  foreach (skinData in availVehSkins) {
    let { id = null } = skinData
    let cfg = custCfg?[id]
    if (cfg == null)
      continue

    let hasOwned = getOwnedCamouflage(ownCamouflages, id, guid) != null
    skinsList.append(skinData.__merge({ cfg, hasOwned }))
  }

  let skinsObjects = skinsList
    .sort(@(a, b) (a?.cfg.buyData.price ?? 0) <= 0 <=> (b?.cfg.buyData.price ?? 0) <= 0
      || (a?.cfg.buyData.price ?? 0) <=> (b?.cfg.buyData.price ?? 0)
      || a.id <=> b.id)
    .map(function(skinData) {
      let { id, hasOwned } = skinData
      let isSelected = camouflageId == id
      return mkSkinIcon(skinData, isSelected, hasOwned, currencies,
        @() chooseSkin(skinData, guid, ownCamouflages))
    })

  let baseSkinData = {
    objTexReplace = getBaseVehicleSkin(gametemplate)
  }
  let skinsBlock = {
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    gap = bigPadding
    children = skinsObjects.len() == 0 ? null
      : [
          mkSkinIcon(baseSkinData, camouflageId == null, true, currencies,
            @() chooseSkin(null, guid))
        ].extend(skinsObjects)
  }
  return res.__update(mkCustomizationList("vehCamouflage", skinsBlock))
}

let function purchaseBtnUi() {
  let res = {
    watch = [viewVehicle, selectedCamouflage]
  }
  let {
    cfg = null, hasOwned = false, objTexReplace = {}, locId = null
  } = selectedCamouflage.value
  if (cfg == null || hasOwned)
    return res

  let { cType, guid, buyData } = cfg
  let { price = 0, currencyId = "" } = buyData
  let skinId = cropSkinName((objTexReplace).values()?[0])
  let skinTxt = loc(locId ?? ($"skin/{skinId ?? "baseSkinName"}"))
  let hasAlternativeTxt = price == 0 || currencyId == ""
  return res.__update({
    hplace = ALIGN_RIGHT
    children = hasAlternativeTxt
      ? {
          rendObj = ROBJ_SOLID
          padding = bigPadding
          color = defBgColor
          children = noteTextArea(loc("alternativeCamouflageReceivingWay"))
            .__update({
              size = [hdpx(560), SIZE_TO_CONTENT]
              halign = ALIGN_CENTER
              color = accentTitleTxtColor
            }.__update(body_txt))
        }
      : currencyBtn({
          btnText = loc("btn/buy")
          currencyId
          price
          cb = @() purchaseMsgBox({
            price
            currencyId
            description = "{0}\n{1}".subst(
              loc("buyCamouflageConfirm"),
              colorize(accentTitleTxtColor, skinTxt)
            )
            purchase = @() buyDecorator(cType, guid, price, function(r) {
              if (r?.error == null) {
                let vehGuid = viewVehicle.value?.guid
                let camouflageGuid = (r?.vehDecorators ?? {}).keys()?[0]
                if (vehGuid != null && camouflageGuid != null)
                  applyCamouflageImpl(camouflageGuid, vehGuid, cType, 0)
              }
            })
            alwaysShowCancel = true
            srcComponent = "buy_camouflage"
          })
          style = ({
            margin = bigPadding
            hotkeys = [["^J:Y", { description = { skip = true }}]]
          })
        })
  })
}

let filterOnlyOwned = Watched(false)
let function customizeListUi() {
  let { curCustType = "", curSlotIdx = -1 } = customizationParams.value
  return {
    watch = customizationParams
    size = [SIZE_TO_CONTENT, flex()]
    flow = FLOW_VERTICAL
    halign = ALIGN_RIGHT
    hplace = ALIGN_RIGHT
    children = [
      curCustType == "" ? null
        : curCustType == "vehCamouflage" ? camouflageListUi
        : mkDecoratorsList(curCustType, curSlotIdx, filterOnlyOwned)
      purchaseBtnUi
    ]
  }
}

let mkUseDecalBlock = kwarg(@(applyCb, cancelModeCb, padding) {
  size = flex()
  flow = FLOW_HORIZONTAL
  gap = smallOffset
  padding
  margin = bigPadding
  behavior = [Behaviors.MenuCameraControl, Behaviors.Button]
  onClick = applyCb
  eventPassThrough = true
  halign = ALIGN_CENTER
  valign = ALIGN_BOTTOM
  children = [
    {
      hotkeys = [[
        $"^J:LB", @() onDecalMouseWheel({ shiftKey = true, button = -2 })
      ]]
    }
    {
      hotkeys = [[
        $"^J:RB", @() onDecalMouseWheel({ shiftKey = true, button = 2 })
      ]]
    }
    {
      hotkeys = [[
        $"^J:LT", @() onDecalMouseWheel({ altKey = true, button = -2 })
      ]]
    }
    {
      hotkeys = [[
        $"^J:RT", @() onDecalMouseWheel({ altKey = true, button = 2 })
      ]]
    }
    scaleRotationHint
    mkFlipBtn(isMirrorMode)
    mkSelectBox(sideParams, twoSideIdx, ["S", "T", "M"], "J:X")
    mkButton({
      icon = closeActionIcon
      onClick = cancelModeCb
      descLocId = "Close"
      hotkey = "Esc"
      gpadHotkey = "J:B"
      hasHotkeyHint = true
    })
  ]
})

isMirrorMode.subscribe(@(v) mirrorDecal(v))
twoSideIdx.subscribe(function(v) {
  if (sideParams[v] == SIDE_PARAMS.ONE_SIDE)
    twoSideDecal(false, false)
  else if (sideParams[v] == SIDE_PARAMS.TWO_SIDE)
    twoSideDecal(true, false)
  else if (sideParams[v] == SIDE_PARAMS.TWO_SIDE_MIRRORED)
    twoSideDecal(true, true)
})

let customizeScene = {
  size = flex()
  children = function() {
    let mouseMoveCb = selectedDecorator.value != null
      ? onDecalMouseMove
      : null
    let mouseWheelCb = selectedDecorator.value != null
      ? onDecalMouseWheel
      : null
    let isDecoration = mouseMoveCb != null
    return {
      watch = [safeAreaBorders, selectedDecorator, isPurchasing]
      size = flex()
      padding = isDecoration ? null : safeAreaBorders.value
      behavior = isDecoration
        ? Behaviors.TrackMouse
        : Behaviors.MenuCameraControl
      onMouseMove = mouseMoveCb
      onMouseWheel = mouseWheelCb
      children = selectedDecorator.value != null
        ? mkUseDecalBlock({
            applyCb = applyUsingDecal
            cancelModeCb = stopUsingDecal
            padding = safeAreaBorders.value
          })
        : [
            customizeSlotsUi
            isPurchasing.value ? purchSpinner : null
            customizeListUi
          ]
    }
  }
}

let function openPurchaseDecoratorBox(decoratorCfg, applyCb) {
  let { guid, buyData, cType } = decoratorCfg
  let { price, currencyId } = buyData
  if (price == null || currencyId == "")
    return

  purchaseMsgBox({
    price
    currencyId
    description = "{0}\n{1}".subst(
      loc($"{cType}BuyConfirm"),
      colorize(accentTitleTxtColor, loc($"decals/{guid}"))
    )
    productView = mkDecorIcon({
      cfg = decoratorCfg, override = { size = slotBigSize }
    })
    purchase = @() buyDecorator(cType, guid, price, function(res) {
      if (res?.error != null)
        return

      let decals = (res?.vehDecorators ?? {})
      let decal = decals.findvalue(@(d) d.id == guid && d.vehGuid == "")
      if (decal != null)
        applyCb(decal.guid)
    })
    alwaysShowCancel = true
    srcComponent = $"buy_{cType}"
  })
}

let function onSaveVehicleDecals(evt, _eid, _comp) {
  let vehGuid = viewVehicle.value?.guid
  let decoratorCfg = selectedDecorator.value
  let { guid = null, cType = null } = decoratorCfg
  let { curSlotIdx = -1 } = customizationParams.value

  stopUsingDecal()
  if (guid == null || curSlotIdx == -1)
    return

  let decalsData = (evt?[0]?.getAll() ?? [])
    .findvalue(@(d) d.slot == curSlotIdx)
  if (decalsData == null)
    return

  let freeDecorators = (availVehDecorByTypeId.value?[cType][guid] ?? {})
    .filter(@(d) d.id == guid
      && (d.vehGuid == "" || d.vehGuid == vehGuid )
      && (d.slotIdx == -1 || d.slotIdx == curSlotIdx))

  let freeDecorator = freeDecorators
    .findvalue(@(d) d.vehGuid == vehGuid) ?? freeDecorators.values()?[0]

  let applyCb = function(decGuid) {
    closeDecoratorsList()
    let decalString = decalToString(decalsData)
    if (decalString != null)
      applyDecorator(decGuid, vehGuid, cType, decalString, curSlotIdx)
  }
  if (freeDecorator != null)
    return applyCb(freeDecorator.guid)

  let { price = 0 } = decoratorCfg.buyData
  if (price <= 0)
    return showMsgbox({ text = loc("alternativeDecalReceivingWay") })

  openPurchaseDecoratorBox(decoratorCfg, applyCb)
}

ecs.register_es("decal_es", {
  [SaveVehicleDecals] = onSaveVehicleDecals
}, {}, {tags = "server"})

let function open() {
  closeDmViewerMode()
  customizationParams(null)
  selectedCamouflage(null)
  sceneWithCameraAdd(customizeScene, "vehicles")
}

let function close() {
  sceneWithCameraRemove(customizeScene)
  selectedCamouflage(null)
}

if (selectVehParams.value?.isCustomMode ?? false)
  open()

selectVehParams.subscribe(function(v) {
  if (v?.isCustomMode ?? false)
    open()
  else
    close()
})
