from "%enlSqGlob/ui_library.nut" import *

let { fontHeading1, fontHeading2, fontBody } = require("%enlSqGlob/ui/fontsStyle.nut")
let { bigPadding, titleTxtColor, defTxtColor, maxContentWidth, accentTitleTxtColor, commonBtnHeight
} = require("%enlSqGlob/ui/viewConst.nut")
let { shopItemContentArrayCtor } = require("%enlist/shop/armyShopState.nut")
let closeBtnBase = require("%ui/components/closeBtn.nut")
let { mkHeaderFlag, primeFlagStyle } = require("%enlSqGlob/ui/mkHeaderFlag.nut")
let { premiumImage } = require("%enlist/currency/premiumComp.nut")
let { mkCurrencyImg } = require("%enlist/currency/currenciesComp.nut")
let { getClassCfg } = require("%enlSqGlob/ui/soldierClasses.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { getRomanNumeral } = require("%sqstd/math.nut")
let { kindIcon, className } = require("%enlSqGlob/ui/soldiersUiComps.nut")
let sClassesCfg = require("%enlist/soldiers/model/config/sClassesConfig.nut")
let { enlistedGold } = require("%enlist/currency/currenciesList.nut")
let { itemTypeIcon } = require("%enlist/soldiers/components/itemTypesData.nut")
let { getItemName, iconByGameTemplate} = require("%enlSqGlob/ui/itemsInfo.nut")
let { mkColoredGradientY } = require("%enlSqGlob/ui/gradients.nut")
let { safeAreaVerPadding, safeAreaHorPadding } = require("%enlSqGlob/safeArea.nut")
let colorize = require("%ui/components/colorize.nut")
let { allItemTemplates, findItemTemplate
} = require("%enlist/soldiers/model/all_items_templates.nut")
let faComp = require("%ui/components/faComp.nut")
let { mkShopItem } = require("%enlist/soldiers/model/items_list_lib.nut")
let { weapInfoBtn } = require("%enlist/soldiers/components/campaignPromoPkg.nut")
let viewItemScene = require("components/viewItemScene.nut")
let { addScene, removeScene } = require("%enlist/navState.nut")
let { Purchase } = require("%ui/components/textButton.nut")
let openUrl = require("%ui/components/openUrl.nut")


let wndContentWidth = fsh(120)
const WND_UID = "STARTER_PACK_PROMO"
const ENLISTED_GOLD_BONUS = "300"
let iconSize = hdpxi(40)
let infoBlockPadding = fsh(3)
let smallBlockPadding = fsh(1)
let weaponBlockSize = [hdpx(330), hdpx(110)]


let starterPack = Watched(null)
let crateContent = shopItemContentArrayCtor(starterPack)


let blockHeaderStyle = freeze({ color = accentTitleTxtColor }.__update(fontHeading2))
let defTxtStyle = freeze({ color = titleTxtColor }.__update(fontBody))
let bottomGradient = mkColoredGradientY({colorTop=0x00000000, colorBottom=0xFF000000})

let mkTextArea = @(text, override = {}) {
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  size = [flex(), SIZE_TO_CONTENT]
  text
}.__update(override)


let closeButton = closeBtnBase({
  onClick = @() starterPack(null),
  hplace = ALIGN_RIGHT,
  vplace = ALIGN_TOP
})

let wndHeader = mkHeaderFlag(
  {
    rendObj = ROBJ_TEXT
    hplace = ALIGN_LEFT
    padding = [fsh(2), fsh(3)]
    text = utf8ToUpper(loc("shop/starter_pack"))
  }.__update(fontHeading1),
  primeFlagStyle
)


let headerWndBlock = {
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_VERTICAL
  gap = bigPadding
  children = [
    wndHeader
    @() {
      watch = starterPack
      rendObj = ROBJ_TEXT
      padding = bigPadding
      text = loc(starterPack.value?.nameLocId)
    }.__update(defTxtStyle)
  ]
}


let blockHeader = @(text) mkTextArea(text, blockHeaderStyle)


let currencyText = mkTextArea(loc("enlistedGold", {
  count = colorize(accentTitleTxtColor, ENLISTED_GOLD_BONUS)}), defTxtStyle)
let premiumText = @(days) days <= 0 ? null
  : mkTextArea(loc("premium/days", { days = colorize(accentTitleTxtColor, days)}), defTxtStyle)


let function accountFeatures() {
  return {
    size = flex()
    flow = FLOW_VERTICAL
    gap = smallBlockPadding
    vplace = ALIGN_CENTER
    padding = [0, infoBlockPadding]
    children = [
      {
        size = [flex(), SIZE_TO_CONTENT]
        flow = FLOW_HORIZONTAL
        gap = bigPadding
        children = [
          mkCurrencyImg(enlistedGold, iconSize)
          premiumImage(iconSize)
        ]
      }
      @() {
        watch = starterPack
        size = [flex(), SIZE_TO_CONTENT]
        flow = FLOW_VERTICAL
        gap = bigPadding
        children = [
          currencyText
          premiumText(starterPack.value?.premiumDays ?? 0)
        ]
      }
    ]
  }
}



let mkSClassRow = @(sClass, soldierRareMin, tier) @() {
  watch = sClassesCfg
  flow = FLOW_HORIZONTAL
  gap = bigPadding
  valign = ALIGN_CENTER
  children = [
    kindIcon(sClassesCfg.value?[sClass].kind ?? sClass, defTxtStyle.fontSize,
      soldierRareMin, defTxtStyle.color)
    className(sClass).__update(defTxtStyle)
    {
      rendObj = ROBJ_TEXT
      text = tier
    }.__update(defTxtStyle)
  ]
}


let function mkSoldierInfo(crate) {
  if (crate == null)
    return null
  let { armyId = null, content = null } = crate
  let { soldierClasses = [], itemsAmount = {}, soldierRareMin = 0 } = content
  let minAmount = itemsAmount?.x ?? 0
  if (soldierClasses.len() <= 0 || minAmount <= 0)
    return null
  let sClasses = soldierClasses.reduce(function(res, sClass) {
    let { locId = "" } = getClassCfg(sClass)
    if (locId != "")
      res.append({
        sClass = sClass
        sortLoc = loc(locId)
      })
    return res
  }, [])
    .sort(@(a, b) a.sortLoc <=> b.sortLoc)
    .map(@(s) s.sClass)
  let { soldierTierMin = 0, soldierTierMax = 0} = content
  let tiersText = soldierTierMin == soldierTierMax ? getRomanNumeral(soldierTierMin)
    : $"{getRomanNumeral(soldierTierMin)}-{getRomanNumeral(soldierTierMax)}"
  return {
    size = flex()
    flow = FLOW_VERTICAL
    gap = smallBlockPadding
    padding = [0, infoBlockPadding]
    children = soldierClasses.len() <= 0 ? null : [
      blockHeader(loc($"{armyId}/full"))
      {
        flow = FLOW_VERTICAL
        children = sClasses.map(@(sClass) mkSClassRow(sClass, soldierRareMin, tiersText))
      }
    ]
  }
}


let mkItemRow = @(item) {
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_HORIZONTAL
  gap = bigPadding
  valign = ALIGN_CENTER
  children = [
    itemTypeIcon(item?.itemtype, item?.itemsubtype)
    {
      rendObj = ROBJ_TEXT
      text = getItemName(item)
    }.__update(defTxtStyle)
  ]
}


let itemsInfo = @(crate) (crate == null || (crate?.content.items ?? {}).len() == 0) ? null
  : function() {
  let { armyId = null, content = null } = crate
  let { items = {} } = content
  let children = items.keys().reduce(function(res, val) {
      let item = findItemTemplate(allItemTemplates, armyId, val)
      if (item != null && item?.tier == null)
        res.append(mkItemRow(item))
      return res
    }, [])
  return {
    watch = allItemTemplates
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    gap = smallBlockPadding
    padding = [0, infoBlockPadding]
    children = [
      blockHeader(loc("starterPack/eachArmy"))
      {
        size = [flex(), SIZE_TO_CONTENT]
        flow = FLOW_VERTICAL
        gap = bigPadding
        children
      }
    ]
  }
}

let featuresGap = {
  size = [hdpx(1), flex()]
  rendObj = ROBJ_SOLID
  color = 0xCCFFFFFF
}

let featuresBlock = @() {
  watch = crateContent
  size = [flex(), hdpx(180)]
  flow = FLOW_HORIZONTAL
  gap = featuresGap
  children = [accountFeatures]
    .extend(crateContent.value.map(mkSoldierInfo))
    .append(itemsInfo(crateContent.value?[0]))
}

let cratePlusSign = faComp("plus", {
  color = defTxtStyle.color
  fontSize = defTxtStyle.fontSize
})

let mkCrateWeapon = @(crate) function() {
  let { armyId = null, content = {} } = crate
  let { items = {} } = content
  let weapons = items.keys().reduce(function(res, val) {
    let item = findItemTemplate(allItemTemplates, armyId, val)
    if (item?.tier != null)
      res.append(item.__merge({ itemId = val }))
    return res
  }, [])
  return {
    watch = allItemTemplates
    size = [weaponBlockSize[0], SIZE_TO_CONTENT]
    flow = FLOW_HORIZONTAL
    gap = {
      padding = bigPadding
      vplace = ALIGN_CENTER
      children = cratePlusSign
    }
    children = weapons.map(function(w) {
      let itemToView = mkShopItem(w.itemId, w, armyId)
      let icon = iconByGameTemplate(w.gametemplate, {
        width = weaponBlockSize[0]/1.5
        height = weaponBlockSize[1]
      })
      return {
        size = [flex(), SIZE_TO_CONTENT]
        flow = FLOW_VERTICAL
        gap = bigPadding
        halign = ALIGN_CENTER
        children = [
          watchElemState(@(sf){
            rendObj = ROBJ_BOX
            size = weaponBlockSize
            behavior = Behaviors.Button
            onClick = function() {
              viewItemScene(itemToView)
            }
            borderWidth = hdpx(1)
            halign = ALIGN_CENTER
            valign = ALIGN_CENTER
            fillColor = sf & S_HOVER ? 0x00333333 : 0xFF000000
            borderColor = sf & S_HOVER ? titleTxtColor : defTxtColor
            children = [
              icon
              weapInfoBtn(sf)
            ]
          })
          {
            rendObj = ROBJ_TEXTAREA
            behavior = Behaviors.TextArea
            size = [flex(), SIZE_TO_CONTENT]
            text = getItemName(w)
            halign = ALIGN_CENTER
          }.__update(defTxtStyle)
        ]
      }
    })
  }
}

let weaponsPlusSign = faComp("plus", {
  color = accentTitleTxtColor
  fontSize = fontHeading1.fontSize
  pos = [0, weaponBlockSize[1]/2 - fontHeading1.fontSize / 2]
  padding = [0, smallBlockPadding]
})

let function weaponsBlock() {
  let hasNoItem = crateContent.value.findvalue(@(v) (v?.content.items.len() ?? 0) > 0) == null
  return {
    watch = crateContent
    flow = FLOW_HORIZONTAL
    gap = weaponsPlusSign
    children = hasNoItem ? null : crateContent.value.map(mkCrateWeapon)
  }
}


let function purchaseButton() {
  let url = starterPack.value?.url ?? ""
  return {
    watch = starterPack
    hplace = ALIGN_RIGHT
    vplace = ALIGN_BOTTOM
    children = Purchase(loc("starterPack/purchase"), @() openUrl(url), {
      style = { size = [SIZE_TO_CONTENT, commonBtnHeight] }
      isEnabled = url != ""
    })
  }
}


let bottomWndBlock = {
  size = [wndContentWidth, fsh(60)]
  vplace = ALIGN_BOTTOM
  children = [
    {
      size = flex()
      flow = FLOW_VERTICAL
      gap = fsh(6)
      children = [
        headerWndBlock
        featuresBlock
        weaponsBlock
      ]
    }
    purchaseButton
  ]
}


let wndContent = {
  size = flex()
  halign = ALIGN_CENTER
  maxWidth = maxContentWidth
  children = [
    @() {
      watch = starterPack
      rendObj = ROBJ_IMAGE
      size = [wndContentWidth, flex()]
      image = Picture(starterPack.value?.image ?? "ui/gameImage/premium_bg.avif")
      imageValign = ALIGN_TOP
      keepAspect = true
    }
    {
      size = [wndContentWidth, fsh(80)]
      rendObj = ROBJ_IMAGE
      image = bottomGradient
      vplace = ALIGN_BOTTOM
    }
    @() {
      watch = [safeAreaVerPadding, safeAreaHorPadding]
      size = flex()
      padding = [max(safeAreaVerPadding.value, fsh(2)), max(safeAreaHorPadding.value, fsh(2))]
      margin = [0, 0, hdpx(40), 0]
      vplace = ALIGN_BOTTOM
      halign = ALIGN_CENTER
      children = [
        bottomWndBlock
        closeButton
      ]
    }
  ]
}


let scene = {
  size = flex()
  key = WND_UID
  rendObj = ROBJ_SOLID
  color = 0xFF000000
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  onClick = @() null
  children = wndContent
}


starterPack.subscribe(@(v) v != null ? addScene(scene) : removeScene(scene))


return starterPack



