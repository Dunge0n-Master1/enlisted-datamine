from "%enlSqGlob/ui_library.nut" import *

let { h0_txt, body_txt, sub_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let { activeTxtColor, lockedSquadBgColor, smallPadding, bigPadding,
  defTxtColor, darkBgColor, accentTitleTxtColor
} = require("%enlSqGlob/ui/viewConst.nut")
let { isGamepad } = require("%ui/control/active_controls.nut")
let { safeAreaBorders } = require("%enlist/options/safeAreaState.nut")
let { mkPerkDesc } = require("components/perksPackage.nut")
let faComp = require("%ui/components/faComp.nut")
let { classIcon, className } = require("%enlSqGlob/ui/soldiersUiComps.nut")
let { mkSquadIcon } = require("%enlSqGlob/ui/squadsUiComps.nut")
let { allItemTemplates, findItemTemplate } = require("model/all_items_templates.nut")
let { iconByGameTemplate, getItemName, getItemDesc } = require("%enlSqGlob/ui/itemsInfo.nut")
let { Bordered } = require("%ui/components/textButton.nut")
let colorize = require("%ui/components/colorize.nut")
let { getClassNameWithGlyph } = require("%enlSqGlob/ui/soldierClasses.nut")
let viewItemScene = require("components/viewItemScene.nut")
let { mkShopItem } = require("%enlist/soldiers/model/items_list_lib.nut")
let perksList = require("%enlist/meta/perks/perksList.nut")
let { perksStatsCfg } = require("%enlist/meta/perks/perksStats.nut")
let { campaignName, btnSizeSmall, btnSizeBig, weapInfoBtn, rewardToScroll
} = require("components/campaignPromoPkg.nut")
let { CAMPAIGN_NONE } = require("%enlist/campaigns/campaignConfig.nut")

let mainBgColor = Color(98, 98, 80)
let localGap = bigPadding * 2
let descBlockMargin = hdpx(100)
let sizeNewWeaponSmall = [btnSizeSmall[0], hdpx(100)]
let sizeNewWeaponBig = [btnSizeBig[0], hdpx(120)]

let mkText = @(txt, style = {}) {
  rendObj = ROBJ_TEXT
  color = defTxtColor
  text = txt
}.__update(body_txt, style)
let squadBigIconSize = [hdpx(100), hdpx(120)]

let soldierClassElement = @(sClass, armyId)
  colorize(activeTxtColor, getClassNameWithGlyph(sClass, armyId))

let newSquadBlock = @(armyId, sClassId){
  flow = FLOW_VERTICAL
  size = [flex(), SIZE_TO_CONTENT]
  valign = ALIGN_CENTER
  gap = bigPadding
  children = [
    mkText(loc("mainmenu/newInfantryClass"),
            { color = accentTitleTxtColor }.__update(sub_txt))
    {
      flow = FLOW_HORIZONTAL
      gap = smallPadding
      valign = ALIGN_CENTER
      children = [
        classIcon(armyId, sClassId, hdpx(30), {
          vplace = ALIGN_BOTTOM, hplace = ALIGN_RIGHT })
        className(sClassId).__update({ color = Color(255, 255,255) }).__update(body_txt)
      ]
    }
  ]
}

let starterPerkBlock = @(armyId, perk) perk == null ? null : {
  flow = FLOW_VERTICAL
  size = [flex(), SIZE_TO_CONTENT]
  valign = ALIGN_CENTER
  gap = bigPadding
  children = [
    {
      rendObj = ROBJ_TEXT
      text = loc("squads/starterPerk")
      color = accentTitleTxtColor
    }.__update(sub_txt)
    @() {
      watch = [perksList, perksStatsCfg]
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      size = [flex(), SIZE_TO_CONTENT]
      text = mkPerkDesc(perksStatsCfg.value, armyId, perksList.value?[perk])
    }.__update(sub_txt)
  ]
}

let mkSquadDescBlock = @(text, style = {}){
  rendObj = ROBJ_TEXTAREA
  maxWidth = hdpx(600)
  behavior = Behaviors.TextArea
  size = [flex(), SIZE_TO_CONTENT]
  color = activeTxtColor
  text
}.__update(sub_txt, style)

let primePerkBlock = @(primeDesc){
  flow = FLOW_VERTICAL
  size = [flex(), SIZE_TO_CONTENT]
  gap = bigPadding
  children = [
    mkSquadDescBlock(loc("squads/primeStarterPerks"), {color = accentTitleTxtColor})
    mkSquadDescBlock(loc(primeDesc))
  ]
}

let function mkClassDescBlock(params = {}){
  let {
    armyId, newClass, newPerk = null, isPrimeSquad = false, isSmall = false, override = {}
  } = params
  let descTxt = loc($"squadPromo/{newClass}/shortDesc")
  let primeDesc = loc($"soldierClass/{newClass}/desc")
  let defStats = loc($"squadPromo/{newClass}/longDesc")
  if (newClass == null)
    return null

  return {
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    vplace = ALIGN_CENTER
    maxWidth = hdpx(600)
    gap = localGap
    children = [
      newSquadBlock(armyId, newClass)
      starterPerkBlock(armyId, newPerk)
      isPrimeSquad && !isSmall ? primePerkBlock(primeDesc)
        : isSmall ? mkSquadDescBlock(descTxt)
        : null
      isSmall ? null : mkSquadDescBlock(defStats)
    ]
  }.__update(override)
}

let function mNewItemBlock(armyId, itemId, size, isSmall = false, idx = 0, scrollPosition = null) {
  let item = findItemTemplate(allItemTemplates, armyId, itemId)
  if (item == null)
    return null
  let gametemplate = item?.gametemplate
  let itemToView = mkShopItem(itemId, item, armyId)
  return gametemplate != null
    ? {
        size = [flex(), SIZE_TO_CONTENT]
        margin = [0, localGap,0,0]
        vplace = ALIGN_BOTTOM
        flow = FLOW_VERTICAL
        gap = bigPadding
        children = [
          {
            size = [flex(), SIZE_TO_CONTENT]
            flow = FLOW_VERTICAL
            gap = bigPadding
            children = [
              idx > 0 ? null : {
                rendObj = ROBJ_TEXT
                color = accentTitleTxtColor
                text = loc(item?.itemtype == "vehicle"
                  ? "mainmenu/newVehicle"
                  : "mainmenu/newWeapon")
              }.__update(sub_txt)
              {
                rendObj = ROBJ_TEXTAREA
                behavior = Behaviors.TextArea
                size = [flex(), SIZE_TO_CONTENT]
                text = getItemName(item)
              }.__update(body_txt)
              isSmall
                ? null
                : mkSquadDescBlock(getItemDesc(item), {color = defTxtColor})
            ]
          }
          watchElemState(@(sf){
            rendObj = ROBJ_BOX
            behavior = Behaviors.Button
            onClick = function() {
              rewardToScroll(scrollPosition)
              viewItemScene(itemToView)
            }
            borderWidth = hdpx(1)
            size
            halign = ALIGN_CENTER
            valign = ALIGN_CENTER
            fillColor = sf & S_HOVER ? mainBgColor : darkBgColor
            borderColor = sf & S_HOVER ? activeTxtColor : defTxtColor
            children = [
              iconByGameTemplate(gametemplate, {
                width = size[0]/1.5
                height = size[1]
              })
              weapInfoBtn(sf)
            ]
          })
        ]
      }
    : null
}

let mkSquadBodyBottomSmall = kwarg(function(armyId, newClass, newPerk, newWeapon, hasReceived,
  nameLocId, titleLocId, unlockInfo, isPrimeSquad = false, campaignGroup = CAMPAIGN_NONE
) {
    return {
      size = [flex(), ph(60)]
      gap = bigPadding
      flow = FLOW_VERTICAL
      vplace = ALIGN_BOTTOM
      valign = ALIGN_TOP
      children = [
        campaignName({
          nameLocId, titleLocId, isPrimeSquad, hasReceived, sClass = newClass, campaignGroup
        })
        {
          flow = FLOW_HORIZONTAL
          size = [flex(), SIZE_TO_CONTENT]
          gap = hdpx(10)
          children = [
            mkClassDescBlock({armyId, newClass, newPerk, isPrimeSquad, isSmall  = true})
            {
              size = [btnSizeSmall[0], SIZE_TO_CONTENT]
              halign = ALIGN_RIGHT
              margin = [0,bigPadding,0,0]
              maxWidth = hdpx(600)
              children = mNewItemBlock(armyId, newWeapon[0], sizeNewWeaponSmall, true, 0,
                unlockInfo.unlockUid)
            }
          ]
        }
      ]
    }
  }
)

let primeDescGap = {
  rendObj = ROBJ_SOLID
  size = [hdpx(1), hdpx(200)]
  color = defTxtColor
}

let function mkSquadBodyBig(squadData, descBlock, buttons) {
  let { armyId, newClass, newPerk, newWeapon, isPrimeSquad = false } = squadData
  return {
    size = flex()
    flow = FLOW_HORIZONTAL
    gap = sh(5)
    children = [
      {
        size = flex()
        children = [
          { size = flex(), maxHeight = ph(45) }
          campaignName(squadData.__merge({ sClass = newClass }))
          descBlock
        ]
      }
      {
        size = [btnSizeBig[0], flex()]
        flow = FLOW_VERTICAL
        hplace = ALIGN_RIGHT
        vplace = ALIGN_BOTTOM
        valign = ALIGN_CENTER
        gap = localGap
        children = [
          { size = [flex(), flex(1.5)] }
          mkClassDescBlock({armyId, newClass, newPerk, isPrimeSquad, override = {gap = localGap}})
          {
            size = [flex(), SIZE_TO_CONTENT]
            flow = FLOW_VERTICAL
            gap = localGap
            children = newWeapon.map(@(weapon, idx)
              mNewItemBlock(armyId, weapon, sizeNewWeaponBig, false, idx))
          }
          { size = flex() }
          buttons
        ]
      }
    ]
  }
}

let horBottomGradient = {
  rendObj = ROBJ_IMAGE
  vplace = ALIGN_BOTTOM
  size = [flex(), ph(40)]
  color = Color(0,0,0)
  image = Picture("!ui/uiskin/R_BG_gradient_hor.svg:{4}:{300}:K?Ac")
}

let verticalRightGradient = {
  rendObj = ROBJ_IMAGE
  hplace = ALIGN_RIGHT
  size = [pw(45), flex()]
  color = Color(0,0,0)
  image = Picture("!ui/uiskin/R_BG_gradient_vert.svg:{500}:{4}:K?Ac")
}


let mkBgImg = @(img, saturate, isSmall) {
  rendObj = ROBJ_IMAGE
  size = flex()
  keepAspect = true
  imageValign = ALIGN_TOP
  imageHalign = ALIGN_LEFT
  image = Picture(img)
  picSaturate = saturate
  children = [
    horBottomGradient
    !isSmall ? verticalRightGradient : null
  ]
}

let mkBackWithImage = @(img, isLocked, isSmall = true) {
  size = flex()
  valign = ALIGN_TOP
  children = img == null ? null : mkBgImg(img, isLocked ? 0.3 : 1, isSmall)
}

let mkUnlockInfo = @(t, override = {}) {
  rendObj = ROBJ_SOLID
  size = [SIZE_TO_CONTENT, btnSizeSmall[1]]
  minWidth = btnSizeSmall[0]
  halign = ALIGN_CENTER
  hplace = ALIGN_CENTER
  valign = ALIGN_CENTER
  color = lockedSquadBgColor
  children = mkText(t, {
    color = activeTxtColor
  })
}.__update(override)

let mkPromoBackBtn = @(cb) cb != null
  ? @() {
      watch = isGamepad
      children = !isGamepad.value
        ? Bordered(loc("squads/back"), cb, {size = btnSizeBig, margin = 0})
        : null
    }
  : null

let mkFullScreenBack = @(bgChildren, bodyChildren) {
  size = flex()
  rendObj = ROBJ_SOLID
  color = Color(0,0,0)
  halign = ALIGN_CENTER
  children = [
    {
      size = flex()
      maxWidth = hdpx(1920)
      children = bgChildren
    }
    @() {
      watch = safeAreaBorders
      size = flex()
      maxWidth = hdpx(1920)
      padding = safeAreaBorders.value.map(@(v) max(v, localGap))
      children = bodyChildren
    }
  ]
}

let mkPromoSquadIcon = @(icon, isLocked) mkSquadIcon(icon, {
  size = squadBigIconSize
  margin = hdpx(20)
  picSaturate = isLocked ? 0.3 : 1
})

let mkDescBlock = @(announceLocId) {
  size = [flex(), SIZE_TO_CONTENT]
  margin = [0,0,descBlockMargin,0]
  vplace = ALIGN_BOTTOM
  children = mkSquadDescBlock(loc(announceLocId))
}

let primeDescTitle = @(titleText, soldierCount, rank,  perksCount, addChild){
  flow = FLOW_HORIZONTAL
  size = [SIZE_TO_CONTENT, hdpx(50)]
  hplace = ALIGN_LEFT
  valign = ALIGN_BOTTOM
  gap = bigPadding
  children = [
    rank != null
      ? faComp("star",{
          fontSize = hdpx(40)
          color = accentTitleTxtColor
        })
      : {
          rendObj = ROBJ_TEXT
          color = accentTitleTxtColor
          text = soldierCount!= null ? soldierCount
            : perksCount != null ? perksCount
            : loc(titleText)
        }.__update(h0_txt)
    addChild
  ]
}

let primeDesc = @(text, soldierClass = null) {
  size = [flex(), hdpx(100)]
  flow = FLOW_VERTICAL
  hplace = ALIGN_CENTER
  children = [
    {
      size = [flex(), SIZE_TO_CONTENT]
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      text
    }
    soldierClass != null
      ? className(soldierClass).__update({ color = Color(255, 255,255) }, sub_txt)
      : null
  ]
}

let function primeDescription(texts, desc = ""){
  let {titleText  = null, rank  = null, perksCount  = null,
    soliderClass = null, soldierCount = null, addChild = null } = texts
  return {
    size = [flex(), SIZE_TO_CONTENT]
    margin = [0, fsh(3)]
    flow = FLOW_VERTICAL
    vplace = ALIGN_CENTER
    halign = ALIGN_CENTER
    gap = bigPadding
    children = [
      primeDescTitle(titleText, soldierCount, rank, perksCount, addChild)
      primeDesc(loc(desc), soliderClass)
    ]
  }
}

let function soldiersCountDesc(classes){
  let countOverall = classes.values().reduce(@(res, count) res + count, 0)
  let children = classes.map(@(count, sClass) {
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    hplace = ALIGN_CENTER
    children = className(sClass, count).__update({ color = Color(255, 255,255) }, sub_txt)
  }).values()

  return {
    size = [flex(), SIZE_TO_CONTENT]
    margin = [0, fsh(3)]
    flow = FLOW_VERTICAL
    halign = ALIGN_CENTER
    vplace = ALIGN_CENTER
    gap = bigPadding
    children = [
      primeDescTitle(null, countOverall, null, null, {
        rendObj = ROBJ_TEXT
        text = loc("squads/soldiers", { count =  countOverall } )
        margin = [hdpx(7),0]
      }.__update(body_txt))
      {
        flow = FLOW_VERTICAL
        gap = smallPadding
        size = [flex(), hdpx(100)]
        children
      }
    ]
  }
}

let function primeDescBlock(squadCfg, addObject = null) {
  let rank = squadCfg.startSoldiers[0].tier
  let perksCount = squadCfg.startSoldiers[0].level - 1
  let { announceLocId, vehicleType = "", battleExpBonus = 0.0 } = squadCfg
  let hasVehicle = vehicleType != ""

  let soldierClasses = squadCfg.startSoldiers.reduce(function(res, soldier){
    let soldierClass = soldier.sClass
    res[soldierClass] <- (res?[soldierClass] ?? 0) + 1
    return res
  }, {})

  return{
    size = [flex(), hdpx(450)]
    maxWidth = hdpx(1000)
    hplace = ALIGN_CENTER
    vplace = ALIGN_BOTTOM
    flow = FLOW_VERTICAL
    gap = hdpx(20)
    children = [
      {
        size = [flex(), SIZE_TO_CONTENT]
        flow = FLOW_HORIZONTAL
        gap = primeDescGap
        children = [
          soldierClasses.len() > 1
            ? soldiersCountDesc(soldierClasses)
            : primeDescription({soldierCount = soldierClasses.values()[0],
                                soliderClass = soldierClasses.keys()[0]},
                                loc("squads/primeSoldiersCount", { count = squadCfg.size }))
          primeDescription({rank}, loc(hasVehicle
            ? "squads/primeMaxRankVehicle"
            : "squads/primeMaxRankInfantry",
            {rank = rank}))
          primeDescription({perksCount, addChild = {
            rendObj = ROBJ_IMAGE
            size = [hdpx(30), hdpx(30)]
            margin = [hdpx(10),0]
            image = Picture($"!ui/uiskin/thumb.svg:{30}:{30}:K")
          }}, loc("squads/primeOptimalPerks"))
          battleExpBonus <= 0.0 ? null : primeDescription({
            titleText = $"+{(100 * battleExpBonus).tointeger()}%",
            addChild = {
              rendObj = ROBJ_TEXT
              text = loc("squads/primeExp")
              margin = [hdpx(7),0]
            }.__update(body_txt)},
            loc("squads/primeMoreExp"))
        ]
      }
      {
        size = [flex(), SIZE_TO_CONTENT]
        flow = FLOW_HORIZONTAL
        children = [
          mkDescBlock(announceLocId)
          addObject
        ]
      }
    ]
  }
}

return {
  mkBackWithImage
  soldierClassElement
  mkUnlockInfo
  mkSquadBodyBottomSmall
  mkDescBlock
  primeDescBlock
  mkFullScreenBack
  mkSquadBodyBig
  mkPromoSquadIcon
  mkPromoBackBtn
}
