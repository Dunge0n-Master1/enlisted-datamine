from "%enlSqGlob/ui_library.nut" import *

let colorize = require("%ui/components/colorize.nut")
let faComp = require("%ui/components/faComp.nut")
let premiumWnd = require("%enlist/currency/premiumWnd.nut")
let tooltipBox = require("%ui/style/tooltipBox.nut")
let iconByGameTemplate = require("%enlSqGlob/ui/icon3dByGameTemplate.nut")
let { setTooltip } = require("%ui/style/cursors.nut")
let { sub_txt, body_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let { txt } = require("%enlSqGlob/ui/defcomps.nut")
let { showMsgbox } = require("%enlist/components/msgbox.nut")
let { mkCurrency } = require("%enlist/currency/currenciesComp.nut")
let { FAButton } = require("%ui/components/textButton.nut")
let {
  defBgColor, activeBgColor, defTxtColor, accentTitleTxtColor,
  activeTxtColor, smallPadding, bigPadding, titleTxtColor, tinyOffset,
  bonusColor, warningColor
} = require("%enlSqGlob/ui/viewConst.nut")
let {
  BdActive, BdHover, BdNormal, BgHover, BgNormal, TextHover, TextNormal
} = require("%ui/components/textButton.style.nut")
let { cropSkinName } = require("customizeState.nut")
let { mkImageCompByDargKey } = require("%ui/components/gamepadImgByKey.nut")
let { isGamepad } = require("%ui/control/active_controls.nut")
let { decal_preprocess_tex_name } = require("vehicle_decals")


let SKIN_ICON_SIZE = hdpx(40)
let TXT_ICON_SIZE = hdpx(36)
let TXT_SMALL_SIZE = hdpx(16)


let slotSize = [hdpx(100), hdpx(100)]
let slotBigSize = [hdpx(180), hdpx(180)]
let skinSize = [flex(), hdpx(50)]
let arrowIconSize = [hdpx(30), hdpx(30)]

let slotNormalColor = Color(40,40,40,160)
let slotActiveColor = Color(45,40,35,160)
let borderNormalColor = Color(80,80,80,200)
let borderHoverColor = Color(120,120,120,200)
let borderActiveColor = Color(180,180,180,200)
let slotTxtNormalColor = Color(95,95,95,200)
let slotTxtHoverColor = borderActiveColor


let slotColor = @(sf, isSelected = false) isSelected ? slotActiveColor
  : sf & S_HOVER ? slotActiveColor
  : slotNormalColor

let slotBorderColor = @(sf, isSelected = false) isSelected ? borderActiveColor
  : sf & S_HOVER ? borderHoverColor
  : borderNormalColor

let slotTxtColor = @(sf, isSelected = false) isSelected ? slotTxtHoverColor
  : sf & S_HOVER ? slotTxtHoverColor
  : slotTxtNormalColor

let btnBorderColor = @(sf) sf & S_ACTIVE ? BdActive
  : sf & S_HOVER ? BdHover
  : BdNormal

let btnFillColor = @(sf) sf & S_ACTIVE ? BgNormal
  : sf & S_HOVER ? BgHover
  : BgNormal

let btnTxtColor = @(sf) sf & S_ACTIVE ? accentTitleTxtColor
  : sf & S_HOVER ? TextHover
  : TextNormal

let txtColor = @(sf, isSelected = false) isSelected ? titleTxtColor
  : sf & S_HOVER ? activeTxtColor
  : defTxtColor

let mkTextarea = @(text, override = {}) {
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  color = defTxtColor
  text
}.__update(override)

let mkSkinImage = @(img, sf, isSelected) {
  rendObj = ROBJ_VECTOR_CANVAS
  size = [SKIN_ICON_SIZE, SKIN_ICON_SIZE]
  fillColor = 0
  commands = [
    [ VECTOR_WIDTH, hdpx(2) ],
    [ VECTOR_ELLIPSE, 50, 50, 52, 52 ]
  ]
  color = slotBorderColor(sf, isSelected)
  children = {
    rendObj = ROBJ_MASK
    size = flex()
    image = Picture("ui/uiskin/skin_mask.png")
    children = {
      rendObj = ROBJ_IMAGE
      size = flex()
      image = Picture(img)
    }
  }
}

let defDecorSize = hdpx(95)

let function mkDecorImage(cfg, override = {}) {
  let { guid = "" } = cfg
  if (guid == "")
    return null

  let iconSize = override?.iconSize ?? defDecorSize
  let decorImg = iconByGameTemplate(guid, {
    width = iconSize
    height = iconSize
  })

  return decorImg == null ? decorImg : decorImg.__update(override)
}

let mkDecalImage = @(cfg, override = {}) {
  rendObj = ROBJ_IMAGE
  size = flex()
  margin = bigPadding
  keepAspect = true
  image = Picture($"{decal_preprocess_tex_name(cfg.guid)}*")
}.__update(override)

let animFrame = {
  rendObj = ROBJ_BOX
  size = flex()
  borderWidth = hdpx(2)
  borderColor = activeBgColor
  animations = [{
    prop = AnimProp.opacity, from = 0, to = 1, easing = CosineFull,
    duration = 1, play = true, loop = true
  }]
}

let mkBlockHeader = @(txt) {
  rendObj = ROBJ_TEXT
  color = activeTxtColor
  padding = [0, smallPadding]
  text = txt
}.__update(sub_txt)

let mkCurrencyView = @(currencies, currencyId, price) mkCurrency({
  currency = currencies.findvalue(@(c) c.id == currencyId)
  price
  iconSize = hdpx(20)
})

let mkLockedIcon = @(sf, isSelected, fontSize = TXT_SMALL_SIZE)
  faComp("lock", { fontSize, color = slotTxtColor(sf, isSelected) })

let mkApplyIcon = @(sf, isSelected)
  faComp("plus", {
    fontSize = hdpx(TXT_ICON_SIZE)
    color = slotTxtColor(sf, isSelected)
  })

let mkSlotBox = @(sf, isSelected = false) {
  rendObj = ROBJ_BOX
  borderWidth = hdpx(1)
  size = flex()
  borderColor = slotBorderColor(sf, isSelected)
  fillColor = slotColor(sf, isSelected)
}

let showNeedPremiumBox = @() showMsgbox({
  text = loc("reqPremiumToUseDecorSlot")
  buttons = [
    { text = loc("Ok") }
    { text = loc("btn/buy"), action = premiumWnd }
  ]
})

let mkLockedSlotPrice = @(sf, hasPrice, currencies, currencyId, price) {
  rendObj = ROBJ_SOLID
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_HORIZONTAL
  gap = { size = flex() }
  margin  = hdpx(2)
  padding = smallPadding
  vplace = ALIGN_BOTTOM
  valign = ALIGN_CENTER
  color = defBgColor
  children = [
    mkLockedIcon(sf, false, TXT_SMALL_SIZE)
    hasPrice ? mkCurrencyView(currencies, currencyId, price) : null
  ]
}

let function mkDecorSlot(decorator, isSelected, hasLocked, onClick,
  onRemove = null, buyData = null, currencies = null
) {
  let { cType = "" } = decorator?.cfg
  let iconCtor = cType == "vehDecorator" ? mkDecorImage : mkDecalImage
  let { price = 0, currencyId = "" } = buyData
  let hasPrice = currencies != null && price > 0 && currencyId != ""
  return watchElemState(@(sf) {
    rendObj = ROBJ_WORLD_BLUR_PANEL
    size = slotSize
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    behavior = Behaviors.Button
    onClick = hasLocked ? showNeedPremiumBox : onClick
    children = [
      mkSlotBox(sf, isSelected)
      hasLocked && decorator == null ? mkLockedIcon(sf, isSelected, hdpx(TXT_ICON_SIZE))
        : hasLocked && decorator != null ? iconCtor(decorator.cfg, {
            key = $"decal_{decorator.cfg.guid}"
            picSaturate = 0.0
            opacity = 0.3
          })
        : decorator == null ? mkApplyIcon(sf, isSelected)
        : iconCtor(decorator.cfg)
      hasPrice ? mkLockedSlotPrice(sf, hasPrice, currencies, currencyId, price) : null
      isSelected ? animFrame : null
      onRemove == null ? null
        : FAButton("times", onRemove, {
            stopMouse = true
            hplace = ALIGN_LEFT
            vplace = ALIGN_TOP
            style = { TextHover = titleTxtColor }
          })
    ]
  })
}

let mkDecorIcon = kwarg(function(cfg,
  availableCount = 0, currencies = null, onClick = null, override = {}
) {
  let iconSize = override?.size[0]
  let { cType = null, buyData = null } = cfg
  let { price = 0, currencyId = "" } = buyData
  let hasPrice = availableCount == 0 && currencies != null
    && price > 0 && currencyId != ""
  let countObject = availableCount == 0 ? null
    : txt({
        text = availableCount
        padding = smallPadding
        hplace = ALIGN_RIGHT
        vplace = ALIGN_TOP
        color = accentTitleTxtColor
      }).__update(sub_txt)
  let locTypeId = cType == "vehDecorator" ? "decorators" : "decals"
  return watchElemState(@(sf) {
    rendObj = ROBJ_WORLD_BLUR_PANEL
    size = slotSize
    valign = ALIGN_BOTTOM
    behavior = onClick != null ? Behaviors.Button : null
    onClick
    onHover = @(on) setTooltip(on
      ? tooltipBox(txt(loc($"{locTypeId}/{cfg?.guid}")))
      : null)
    children = [
      mkSlotBox(sf)
      cType == "vehDecorator"
        ? mkDecorImage(cfg, { iconSize })
        : mkDecalImage(cfg)
      countObject ?? mkLockedSlotPrice(sf, hasPrice, currencies, currencyId, price)
    ]
  }.__update(override))
})

let function mkSkinIcon(skinData, isSelected, hasOwned, currencies, onClick) {
  let { cfg = null, locId = null } = skinData
  let { price = 0, currencyId = "" } = cfg?.buyData
  let currencyObject = !hasOwned && price > 0 && currencyId != ""
    ? mkCurrencyView(currencies, currencyId, price)
    : null
  let skinImg = (skinData?.objTexReplace ?? {}).values()?[0]
  let skinLocId = cfg != null ? (skinImg ?? "baseSkinName") : "baseSkinName"
  let group = ElemGroup()
  return watchElemState(@(sf) {
    rendObj = ROBJ_WORLD_BLUR_PANEL
    size = skinSize
    behavior = Behaviors.Button
    group
    onClick
    children = [
      mkSlotBox(sf, isSelected)
      {
        size = flex()
        flow = FLOW_HORIZONTAL
        gap = bigPadding
        padding = [0, bigPadding]
        valign = ALIGN_CENTER
        children = [
          skinImg != null ? mkSkinImage(skinImg, sf, isSelected) : null
          hasOwned ? null : mkLockedIcon(sf, isSelected, TXT_SMALL_SIZE)
          {
            rendObj = ROBJ_TEXT
            size = [flex(), SIZE_TO_CONTENT]
            group
            text = loc(locId ?? $"skin/{cropSkinName(skinLocId)}")
            color = txtColor(sf, isSelected)
            scrollOnHover = true
            behavior = Behaviors.Marquee
          }.__update(sub_txt)
          currencyObject
        ]
      }
    ]
  })
}

let function mkCustGroup(groupName, hasOpened, onClick, availCount, limit, count) {
  local limitTxtObj = null
  if (limit > 0) {
    let limitColor = count < limit ? bonusColor : warningColor
    limitTxtObj = mkTextarea(colorize(limitColor, $"{count}/{limit}"), {
      size = [flex(), SIZE_TO_CONTENT]
      halign = ALIGN_RIGHT
      margin = [0, smallPadding]
    })
  }
  return watchElemState(@(sf) {
    rendObj = ROBJ_WORLD_BLUR_PANEL
    size = [flex(), SIZE_TO_CONTENT]
    behavior = Behaviors.Button
    onClick
    children = [
      mkSlotBox(sf, hasOpened)
      {
        size = [flex(), SIZE_TO_CONTENT]
        flow = FLOW_HORIZONTAL
        padding = [smallPadding, 0]
        valign = ALIGN_CENTER
        children = [
          {
            size = arrowIconSize
            halign = ALIGN_CENTER
            valign = ALIGN_CENTER
            children = faComp(hasOpened ? "angle-down" : "angle-right", { fontSize = hdpx(20) })
          }
          txt({
            text = loc($"decals/category/{groupName}")
            color = txtColor(sf, hasOpened)
          }).__update(sub_txt)
          availCount <= 0 ? null
            : txt({
                text = loc("shop/item/count", { count = availCount, itemName = "" })
                color = accentTitleTxtColor
                margin = [0, smallPadding]
              }).__update(sub_txt)
          limitTxtObj
        ]
      }
    ]
  })
}

let iconSize = hdpxi(36)
let btnSize = [hdpx(64), hdpx(64)]

let flipActionIcon = $"!ui/skin#actions/flip_action_icon.svg:{iconSize}:{iconSize}:K"
let closeActionIcon = $"!ui/skin#actions/close_action_icon.svg:{iconSize}:{iconSize}:K"
let twoSideIcons = [
  $"!ui/skin#actions/single_icon.svg:{iconSize}:{iconSize}:K",
  $"!ui/skin#actions/two_side.svg:{iconSize}:{iconSize}:K",
  $"!ui/skin#actions/two_side_mirror.svg:{iconSize}:{iconSize}:K"
]

let selectedLine = {
  rendObj = ROBJ_SOLID
  size = [flex(), smallPadding]
  pos = [0, 2 * smallPadding]
  margin = [0, hdpx(1)]
  vplace = ALIGN_BOTTOM
  color = BgHover
}

let mkBtnImage = @(img, override = {}) {
  rendObj = ROBJ_IMAGE
  size = flex()
  image = Picture(img)
}.__update(override)

let hotkeyViewOverride = {
  color = accentTitleTxtColor
}.__update(body_txt)

let mkButton = kwarg(@(
  icon, onClick, gpadHotkey, hotkey, hasHotkeyHint = false,
  descLocId = "", override = {}
)
  watchElemState(@(sf) {
    rendObj = ROBJ_BOX
    size = btnSize
    padding = tinyOffset
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    behavior = Behaviors.Button
    borderColor = btnBorderColor(sf)
    fillColor = btnFillColor(sf)
    onClick
    onHover = descLocId == "" ? null
      : @(on) setTooltip(on ? tooltipBox(txt(loc(descLocId))) : null)
    hotkeys = [[ $"^{gpadHotkey} | {hotkey}", onClick, loc(descLocId) ]]
    children = [
      mkBtnImage(icon, { color = btnTxtColor(sf) })
      !hasHotkeyHint ? null
        : @() {
            watch = isGamepad
            pos = [0, -hdpx(50)]
            children = isGamepad.value
              ? mkImageCompByDargKey(gpadHotkey)
              : txt(hotkey).__update(hotkeyViewOverride)
          }
    ]
  }.__update(override))
)

let mkFlipBtn = @(checkWatch)
  mkButton({
    icon = flipActionIcon
    onClick = @() checkWatch(!checkWatch.value)
    descLocId = "hintDecalFlip"
    hasHotkeyHint = true
    hotkey = "F"
    gpadHotkey = "J:Y"
  })

let mkSelectBox = @(sideParams, twoSideIdx, hotkeys, gpadHotkey)
  function() {
    let sideIdx = twoSideIdx.value
    return {
      watch = [twoSideIdx, isGamepad]
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      children = [
        {
          flow = FLOW_HORIZONTAL
          gap = smallPadding
          children = sideParams.map(@(p, idx) watchElemState(function(sf) {
            let hotkey = hotkeys?[idx]
            return {
              rendObj = ROBJ_BOX
              borderWidth = hdpx(1)
              size = btnSize
              halign = ALIGN_CENTER
              valign = ALIGN_CENTER
              behavior = Behaviors.Button
              onClick = @() twoSideIdx(idx)
              onHover = @(on) setTooltip(on ? tooltipBox(txt(loc($"hint{p}"))) : null)
              hotkeys = hotkey == null ? null : [[ $"^{hotkey}", @() twoSideIdx(idx) ]]
              borderColor = btnBorderColor(sf)
              fillColor = btnFillColor(sf)
              children = [
                mkBtnImage(twoSideIcons?[idx], {
                  color = btnTxtColor(sf)
                  margin = tinyOffset
                })
                idx == sideIdx ? selectedLine : null
                hotkey == null || isGamepad.value ? null
                  : txt(hotkey).__update(hotkeyViewOverride, { pos = [0, -hdpx(50)] })
              ]
            }
          }))
        }
        gpadHotkey == null || !isGamepad.value ? null
          : {
              pos = [0, -hdpx(50)]
              children = mkImageCompByDargKey(gpadHotkey)
              hotkeys = [[ $"^{gpadHotkey}",
                @() twoSideIdx((twoSideIdx.value + 1) % sideParams.len()),
                loc("switchDecalSideParam") ]]
            }
      ]
    }
  }

let mkDecorHints = @(children) {
  size = [hdpx(400), btnSize[1]]
  flow = FLOW_VERTICAL
  padding = [smallPadding, bigPadding]
  valign = ALIGN_CENTER
  rendObj = ROBJ_SOLID
  color = defBgColor
  children
}

let decorRotationHint = @() {
  watch = isGamepad
  size = [flex(), SIZE_TO_CONTENT]
  valign = ALIGN_CENTER
  flow = FLOW_HORIZONTAL
  gap = smallPadding
  children = [
    {
      size = [pw(55), SIZE_TO_CONTENT]
      halign = isGamepad.value ? ALIGN_CENTER : ALIGN_RIGHT
      flow = FLOW_HORIZONTAL
      gap = smallPadding
      children = isGamepad.value
        ? [
            mkImageCompByDargKey("J:LT")
            mkImageCompByDargKey("J:RT")
          ]
        : mkTextarea(loc("vehDecorRotationHintLeft"))
    }
    mkTextarea(loc("vehDecorRotationHintRight"), { color = accentTitleTxtColor })
  ]
}

let decorScaleHint = @() {
  watch = isGamepad
  size = [flex(), SIZE_TO_CONTENT]
  valign = ALIGN_CENTER
  flow = FLOW_HORIZONTAL
  gap = smallPadding
  children = [
    {
      size = [pw(55), SIZE_TO_CONTENT]
      halign = isGamepad.value ? ALIGN_CENTER : ALIGN_RIGHT
      flow = FLOW_HORIZONTAL
      gap = smallPadding
      children = isGamepad.value
        ? [
            mkImageCompByDargKey("J:LB")
            mkImageCompByDargKey("J:RB")
          ]
        : mkTextarea(loc("vehDecorScaleHintLeft"))
    }
    mkTextarea(loc("vehDecorScaleHintRight"), { color = accentTitleTxtColor })
  ]
}

return {
  mkDecorSlot
  mkDecorIcon
  mkSkinIcon
  mkBlockHeader
  mkCustGroup
  mkFlipBtn
  mkButton
  mkSelectBox
  slotSize
  slotBigSize
  closeActionIcon
  mkDecorHints
  decorScaleHint
  decorRotationHint
  slotNormalColor
  mkDecalImage
  mkDecorImage
}
