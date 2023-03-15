from "%enlSqGlob/ui_library.nut" import *

let JB = require("%ui/control/gui_buttons.nut")
let closeBtnBase = require("%ui/components/closeBtn.nut")
let {body_txt, sub_txt} = require("%enlSqGlob/ui/fonts_style.nut")
let { Flat } = require("%ui/components/textButton.nut")
let { safeAreaBorders } = require("%enlist/options/safeAreaState.nut")
let { defTxtColor, isWide } = require("%enlSqGlob/ui/viewConst.nut")
let { mkRewardImages, prepareRewards } = require("rewardsPkg.nut")
let { premiumUnlock, premiumStage0Unlock } = require("%enlist/unlocks/taskRewardsState.nut")
let { sceneWithCameraAdd, sceneWithCameraRemove } = require("%enlist/sceneWithCamera.nut")
let { curSelectedItem } = require("%enlist/showState.nut")
let { bpHeader, hugePadding, btnBuyPremiumPass, bpTitle, btnSize, cardCountCircle,
  sizeCard, imageSize, gapCards
} = require("bpPkg.nut")
let { seasonIndex } = require("bpState.nut")
let { elitePassItem, canBuyBattlePass, hasEliteBattlePass, isPurchaseBpInProgress
} = require("eliteBattlePass.nut")
let { makeHorizScroll } = require("%ui/components/scrollbar.nut")
let spinner = require("%ui/components/spinner.nut")({ height = hdpx(70) })
let { curArmy } = require("%enlist/soldiers/model/state.nut")
let buyShopItem = require("%enlist/shop/buyShopItem.nut")
let openUrl = require("%ui/components/openUrl.nut")
let { allItemTemplates } = require("%enlist/soldiers/model/all_items_templates.nut")
let { dynamicSeasonBPIcon } = require("battlePassPkg.nut")

let circuitConf = require("app").get_circuit_conf()
let linkToOpen = circuitConf?.battlePassUrl

let curItem = mkWatched(persist, "curItem", null)
let isOpened = mkWatched(persist, "isOpened", false)

const HIGH_WORTH_REWARD = 3

let localGap = hugePadding * 2
let maxWidth = (sizeCard[0] + 3*gapCards) * (isWide ? 4 : 3) - 3*gapCards
let titleAndDescriptionBlockHeight = hdpx(330)
let cardBlockSize = isWide ? [hdpx(1600), SIZE_TO_CONTENT] : [hdpx(1400), SIZE_TO_CONTENT]

let showingItem = Computed(function() {
  if (curItem.value == null)
    return null
  let reward = curItem.value.reward
  let season = seasonIndex.value
  let weapId = reward?.specialRewards[season][curArmy.value]
  if (weapId != null){
    let { gametemplate = reward.gametemplate } = allItemTemplates.value?[curArmy.value][weapId]
    return reward.__merge({
      isSpecial = true
      gametemplate
    })
  }
  return reward
})

showingItem.subscribe(function(item) {
  if (isOpened.value)
    curSelectedItem(item)
})

hasEliteBattlePass.subscribe(function(v) {
  if (v)
    isOpened(false)
})

let closeButton = closeBtnBase({ onClick = @() isOpened(false) })

let function getUniqRewards(unlock) {
  let items = {}
  let currency = {}
  foreach (stage in unlock?.stages ?? []){
    let { rewards = {}, currencyRewards = {} } = stage
      foreach (idStr, amount in rewards)
        items[idStr] <- (items?[idStr] ?? 0) + amount
    foreach (idStr, amountStr in currencyRewards)
      currency[idStr] <- (currency?[idStr] ?? 0) + amountStr.tointeger()
  }
  return { items, currency }
}


let premItemsAnnouncement = Computed(function() {
  let immidiatelyGet = prepareRewards(getUniqRewards(premiumStage0Unlock.value).items)
  let { items, currency } = getUniqRewards(premiumUnlock.value)
  let receiveLater = prepareRewards(items)
  let currencyBack = prepareRewards(currency)
  let sortedRewards = [
    {locId = "bp/getImmediately", rewards = immidiatelyGet}
    {locId = "bp/additional",
      rewards = receiveLater.filter(@(val) val.reward.worth >= HIGH_WORTH_REWARD)}
    {locId = "bp/goldBack", rewards = currencyBack}
  ]

  return sortedRewards
})

let rewardBlock = @(allRewards) @(){
  hplace = ALIGN_CENTER
  size = [SIZE_TO_CONTENT, flex()]
  children = makeHorizScroll({
    xmbNode = XmbContainer({
      canFocus = @() false
      scrollSpeed = 10.0
      isViewport = true
    })
    gap = gapCards
    flow = FLOW_HORIZONTAL
    vplace = ALIGN_BOTTOM
    children = allRewards.map(function(rewardData){
      if (rewardData == null)
        return null
      let {count, reward} = rewardData
      return {
        flow = FLOW_HORIZONTAL
        halign = ALIGN_CENTER
        children = watchElemState(@(sf){
          watch = curItem
          rendObj = ROBJ_BOX
          size = sizeCard
          behavior = Behaviors.Button
          borderWidth = sf & S_HOVER ? hdpx(1) : 0
          onClick =  @() curItem({ reward = reward })
          children = [
            mkRewardImages(reward, imageSize)
            cardCountCircle(count)
          ]
        })
      }
    })
  },{
    size = [SIZE_TO_CONTENT, flex()]
    hplace = ALIGN_CENTER
    maxWidth
  })
}

let cardBlock = @(txt, val) @(){
  minHeight = hdpx(330)
  padding = [0, gapCards]
  children = [
    {
      rendObj = ROBJ_TEXTAREA
      halign = ALIGN_CENTER
      vplace = ALIGN_TOP
      behavior = Behaviors.TextArea
      size = [flex(), SIZE_TO_CONTENT]
      text = loc(txt)
    }.__update(body_txt)
    rewardBlock(val)
  ]
}

let function cardsBlock(){
  let separateLine = {
    rendObj = ROBJ_SOLID
    size = [hdpx(1), flex()]
    color = defTxtColor
  }
  return {
    watch = premItemsAnnouncement
    size = cardBlockSize
    gap = separateLine
    flow = FLOW_HORIZONTAL
    hplace = ALIGN_CENTER
    halign = ALIGN_CENTER
    valign = ALIGN_TOP
    children = premItemsAnnouncement.value.map(@(val) cardBlock(val.locId, val.rewards))
  }
}

let mkDescription = @(text, params = {}, txtSize = body_txt){
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  size = [hdpx(500), SIZE_TO_CONTENT]
  text
}.__update(txtSize, params)

let function buyEliteBattlePass() {
  if (!canBuyBattlePass.value)
    return
  buyShopItem({ shopItem = elitePassItem.value })
}

let bpPurchaseSpinner = {
  size = btnSize
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = spinner
}

let btnBlock = {
  size = [flex(), hdpx(150)]
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  children = [
    function() {
      let action = linkToOpen != null ? @() openUrl(linkToOpen) : buyEliteBattlePass
      return {
        watch = [canBuyBattlePass, isPurchaseBpInProgress]
        flow = FLOW_HORIZONTAL
        valign = ALIGN_CENTER
        halign = ALIGN_CENTER
        gap = localGap
        size = flex()
        children = [
          !canBuyBattlePass.value ? null
            : isPurchaseBpInProgress.value ? bpPurchaseSpinner
            : btnBuyPremiumPass(loc("bp/Purchase"), action)
          Flat(loc("bp/close"), @() isOpened(false), {
            size = btnSize,
            hotkeys = [[$"^{JB.B}", { description = { skip = true }}]]
          })
        ]}
    }
    mkDescription(loc("bp/moreRewards"),
      {hplace = ALIGN_RIGHT, size =[hdpx(150), SIZE_TO_CONTENT]}, sub_txt)
  ]
}


let eliteBattlePassWnd = @(){
  size = flex()
  watch = [safeAreaBorders, showingItem, isOpened]
  padding = [safeAreaBorders.value[0] + hdpx(30), safeAreaBorders.value[1] + hdpx(25)]
  children = [
    {
      hplace = ALIGN_RIGHT
      margin = [hdpx(150), hdpx(100)]
      children = dynamicSeasonBPIcon(hdpx(220))
    }
    {
      size = flex()
      flow = FLOW_VERTICAL
      hplace = ALIGN_CENTER
      valign = ALIGN_BOTTOM
      children = [
        bpHeader(showingItem.value, closeButton, !isOpened.value)
        {
          size = [flex(), titleAndDescriptionBlockHeight]
          gap = localGap
          flow = FLOW_VERTICAL
          children = [
            bpTitle(true, hdpx(100))
            mkDescription(loc("bp/description"))
          ]
        }
        cardsBlock
        btnBlock
      ]
    }
  ]
}

let function open() {
  sceneWithCameraAdd(eliteBattlePassWnd, "battle_pass")
  curSelectedItem(null)
  curItem(null)
}

let function close() {
  sceneWithCameraRemove(eliteBattlePassWnd)
  curSelectedItem(null)
  curItem(null)
}

if (isOpened.value)
  open()

isOpened.subscribe(@ (v) v ? open() : close())


console_register_command(@() isOpened(true), "ui.battlepassWindow")

return @() isOpened(true)
