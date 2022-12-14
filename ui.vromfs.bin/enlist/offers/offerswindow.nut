from "%enlSqGlob/ui_library.nut" import *

let JB = require("%ui/control/gui_buttons.nut")
let viewShopItemsScene = require("%enlist/shop/viewShopItemsScene.nut")
let buySquadWindow = require("%enlist/shop/buySquadWindow.nut")
let mkCountdownTimer = require("%enlSqGlob/ui/mkCountdownTimer.nut")
let activatePremiumBttn = require("%enlist/shop/activatePremiumBtn.nut")
let buyShopItem = require("%enlist/shop/buyShopItem.nut")
let { txt } = require("%enlSqGlob/ui/defcomps.nut")
let { secondsToHoursLoc } = require("%ui/helpers/time.nut")
let { sub_txt, body_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let { safeAreaBorders } = require("%enlist/options/safeAreaState.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { Bordered, FAButton, Purchase } = require("%ui/components/textButton.nut")
let { mkHeaderFlag, primeFlagStyle } = require("%enlSqGlob/ui/mkHeaderFlag.nut")
let { visibleOffersInWindow, curOfferIdx, isSpecOffersOpened } = require("offersState.nut")
let {
  sceneWithCameraAdd, sceneWithCameraRemove
} = require("%enlist/sceneWithCamera.nut")
let {
  smallPadding, bigPadding, hoverBgColor, defBgColor, activeTxtColor,
  defTxtColor, fadedTxtColor
} = require("%enlSqGlob/ui/viewConst.nut")
let {
  mkShopItemView, mkShopItemPriceLine, mkProductView
} = require("%enlist/shop/shopPkg.nut")
let { shopItemContentCtor } = require("%enlist/shop/armyShopState.nut")
let { allItemTemplates } = require("%enlist/soldiers/model/all_items_templates.nut")
let { squadsCfgById } = require("%enlist/soldiers/model/config/squadsConfig.nut")
let { campaignsByArmy, squadsByArmies } = require("%enlist/meta/profile.nut")


let specOfferWidth = hdpx(700)
let shopItemHeight = hdpx(400)

let function btnBlockUi() {
  let pageIdx = curOfferIdx.value
  let totalPages = visibleOffersInWindow.value.len()
  let canPrev = pageIdx > 0
  let canNext = pageIdx < totalPages - 1
  return {
    watch = [visibleOffersInWindow, curOfferIdx]
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    children = [
      totalPages < 2 ? null
        : FAButton("arrow-left", @() curOfferIdx(pageIdx - 1), {
            key = $"prevOffer_{canPrev}"
            isEnabled = canPrev
            hotkeys = canPrev ? [["^J:LB", { description = loc("Prev offer") }]] : null
          })
      totalPages < 2 ? null
        : FAButton("arrow-right", @() curOfferIdx(pageIdx + 1), {
            key = $"nextOffer_{canNext}"
            isEnabled = canNext
            hotkeys = canNext ? [["^J:RB", { description = loc("Next offer") }]] : null
          })
    ]
  }
}

let function mkShopItemSquads(squads, shopItem) {
  if (squads.len() == 0)
    return null

  return function() {
    let campaigns = campaignsByArmy.value
    let squadsCfg = squadsCfgById.value
    let children = squads.map(function(squad) {
      let { armyId, id } = squad
      let squadCfg = squadsCfg?[armyId][id]
        if (squadCfg == null)
          return null

      let campaign = loc(campaigns?[armyId].title ?? "")
      let name = loc(squadCfg.nameLocId)
      return watchElemState(@(sf) {
        rendObj = sf & S_HOVER ? ROBJ_SOLID : null
        size = [flex(), SIZE_TO_CONTENT]
        flow = FLOW_HORIZONTAL
        gap = bigPadding
        padding = [smallPadding, bigPadding]
        color = defBgColor
        behavior = Behaviors.Button
        onClick = @() buySquadWindow({
          shopItem
          productView = mkProductView(shopItem, allItemTemplates)
          armyId
          squadId = id
          isBuyDisabled = true
        })
        children = [
          txt({
            text = loc("listWithDot", { text = $"{campaign} {name}" })
            color = sf & S_HOVER ? activeTxtColor : defTxtColor
          }).__update(sub_txt)
          txt({
            text = loc("btn/view")
            color = sf & S_HOVER ? defTxtColor : fadedTxtColor
          }).__update(sub_txt)
        ]
      })
    })

    return {
      watch = [campaignsByArmy, squadsCfgById]
      size = [flex(), SIZE_TO_CONTENT]
      flow = FLOW_VERTICAL
      padding = [smallPadding, 0]
      children
    }
  }
}

let mkOfferDesc = @(descLocId, params = {}) descLocId == "" ? null
  : {
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      size = [flex(), SIZE_TO_CONTENT]
      color = activeTxtColor
      text = loc(descLocId, params)
    }.__update(sub_txt)

let function mkOfferShopItem(personalOffer, ownSquads) {
  let { shopItem = null, descLocId = "" } = personalOffer
  if (shopItem == null)
    return null

  let squads = (shopItem?.squads ?? [])
    .filter(@(squad) (ownSquads?[squad.armyId] ?? {})
      .findvalue(@(s) s.squadId == squad.id) == null)
  let crateContent = shopItemContentCtor(shopItem)
  let squadBlock = mkShopItemSquads(squads, shopItem)
  let descBlock = {
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    padding = bigPadding
    gap = bigPadding
    children = [
      mkOfferDesc(descLocId)
      squads.len() == 0 ? null
        : {
            size = [flex(), SIZE_TO_CONTENT]
            flow = FLOW_VERTICAL
            children = [
              mkOfferDesc("offer/squadAnnounce", { count = squads.len() })
              squadBlock
            ]
          }
    ]
  }
  return {
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    gap = smallPadding
    children = [
      {
        size = [flex(), shopItemHeight]
        children = mkShopItemView({
          shopItem
          crateContent
          onCrateViewCb = @() viewShopItemsScene(shopItem)
        })
      }
      mkShopItemPriceLine(shopItem, personalOffer)
      descBlock
      {
        size = [flex(), fsh(3)]
        children = [
          Bordered(loc("Close"), @() isSpecOffersOpened(false), {
            hotkeys = [[$"^{JB.B} | Esc", { description = loc("Close") } ]]
          })
          Purchase(loc("btn/buy"),
            @() buyShopItem({
              shopItem
              activatePremiumBttn
              productView = mkProductView(shopItem, allItemTemplates)
              pOfferGuid = personalOffer?.guid
            }),
            { hplace = ALIGN_RIGHT }
          )
        ]
      }
    ]
  }
}

let timerStyle = {
  padding = [0, bigPadding]
  hplace = ALIGN_RIGHT
}

let mkOfferLifetimeInfo = @(lifeTime) {
  rendObj = ROBJ_TEXT
  text = loc("specialOfferInfo", { timeInfo = secondsToHoursLoc(lifeTime) })
  margin = smallPadding
  color = defTxtColor
}.__update(sub_txt)

let function curOfferUi() {
  let offer = visibleOffersInWindow.value?[curOfferIdx.value]
  let ownSquads = squadsByArmies.value
  return {
    watch = [visibleOffersInWindow, curOfferIdx, squadsByArmies]
    size = [fsh(130), flex()]
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    children = offer == null ? null
      : {
          rendObj = ROBJ_SOLID
          size = [specOfferWidth, SIZE_TO_CONTENT]
          flow = FLOW_VERTICAL
          color = defBgColor
          children = [
            { size = [flex(), bigPadding] }
            {
              size = [flex(), SIZE_TO_CONTENT]
              valign = ALIGN_CENTER
              children = [
                mkHeaderFlag({
                  rendObj = ROBJ_TEXT
                  text = utf8ToUpper(loc("specialOfferHeader"))
                  padding = [fsh(2), fsh(3)]
                }.__update(body_txt), primeFlagStyle)
                {
                  size = [flex(), SIZE_TO_CONTENT]
                  flow = FLOW_VERTICAL
                  halign = ALIGN_RIGHT
                  children = [
                    mkCountdownTimer({
                      timestamp = offer.endTime
                      override = timerStyle
                    })
                    mkOfferLifetimeInfo(offer.lifeTime)
                  ]
                }
              ]
            }
            {
              size = [flex(), SIZE_TO_CONTENT]
              padding = bigPadding
              children = mkOfferShopItem(offer, ownSquads)
            }
          ]
        }
  }
}

let offerWindow = @() {
  watch = safeAreaBorders
  rendObj = ROBJ_WORLD_BLUR
  size = flex()
  flow = FLOW_VERTICAL
  padding = safeAreaBorders.value
  halign = ALIGN_CENTER
  color = hoverBgColor
  children = [
    curOfferUi
    btnBlockUi
  ]
}

let function open() {
  sceneWithCameraAdd(offerWindow, "researches")
}

let function close() {
  sceneWithCameraRemove(offerWindow)
}

if (isSpecOffersOpened.value)
  open()

visibleOffersInWindow.subscribe(function(list) {
  if (list.len() == 0)
    isSpecOffersOpened(false)
})
isSpecOffersOpened.subscribe(@(v) v ? open() : close())

return function(specOffer) {
  curOfferIdx(visibleOffersInWindow.value.indexof(specOffer) ?? 0)
  isSpecOffersOpened(true)
}
