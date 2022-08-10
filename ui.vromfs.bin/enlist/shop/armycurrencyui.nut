from "%enlSqGlob/ui_library.nut" import *

let { bigPadding, warningColor, bonusColor } = require("%enlSqGlob/ui/viewConst.nut")
let { mkCurrencyOverall, mkCurrencyImage } = require("currencyComp.nut")
let { setCurSection, curSection } = require("%enlist/mainMenu/sectionsState.nut")
let { txt } = require("%enlSqGlob/ui/defcomps.nut")
let {
  viewArmyCurrency, realCurrencies, viewCurrencies
} = require("armyShopState.nut")
let {
  currencyPresentation, ticketGroups, getCurrencyPresentation
} = require("currencyPresentation.nut")


let openShop = @() setCurSection("SHOP")
let isInShop = Computed(@() curSection.value == "SHOP")

let ADDING_ORDER_SIZE = [hdpx(20), hdpx(20)]

local diffAnimCounter = 0
let function mkDiffCurrency(curr, idx, onFinish) {
  let delay = idx * 0.6
  let duration = 1
  let isPositive = curr.count > 0
  return {
    key = $"{curr.currTpl}_{diffAnimCounter}"
    pos = [pw(curr.offset), SIZE_TO_CONTENT]
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    opacity = 0
    children = [
      txt({
        text = isPositive ? $"+{curr.count}" : $"{curr.count}"
        color = isPositive ? bonusColor : warningColor
      })
      mkCurrencyImage(getCurrencyPresentation(curr.currTpl).icon, ADDING_ORDER_SIZE)
    ]
    transform = {}
    animations = [
      { prop = AnimProp.opacity, from = 0.2, to = 1, duration = 0.4,
        play = true, easing = InOutCubic, delay }
      { prop = AnimProp.opacity, from = 1, to = 1, duration = 0.4,
        play = true, easing = InOutCubic, delay = delay + 0.4, onFinish }
      { prop = AnimProp.opacity, from = 1, to = 0.2, duration = 0.2,
        play = true, easing = InOutCubic, delay = delay + 0.8 }
      { prop = AnimProp.translate, from = [0,hdpx(60)], to = [0,0],
        play = true, easing = OutQuart, duration, delay }
    ]
  }
}

let function getSortedCards(armyCurrency) {
  let sortedCards = []
  ticketGroups.map(function(groupContent, groupName) {
    let showInCurrentSection = groupContent?.showInSection.contains(curSection.value) ?? true
    if (showInCurrentSection){
      let cardsTable = {
        groupOrder = groupContent.order
        cards = {}
        type = groupName
        showIfZero = groupContent.isShownIfEmpty
        isInteractive = groupContent.isInteractive
      }
      currencyPresentation.each(function(value, key) {
        if (value.group == groupContent) {
          armyCurrency.each(function(val, k) {
            if (key == k)
              cardsTable.cards[k] <- val
          })
          if (key not in cardsTable.cards && !(value?.hideIfZero ?? false))
            cardsTable.cards[key] <- 0
        }
      })
      if (cardsTable.cards.findindex(@(v) v > 0) != null || cardsTable.showIfZero)
        sortedCards.append(cardsTable)
    }
  })

  return sortedCards.sort(@(a,b) a.groupOrder <=> b.groupOrder)
}

let function mkCurrenciesDiffAnim(realCurr, sectionCurr, viewCurrWatch) {
  let viewCurr = viewCurrWatch.value ?? {}
  if (isEqual(realCurr, viewCurr))
    return null

  let sortedCards = getSortedCards(sectionCurr)
  let diff = []
  foreach (currTpl, count in realCurr) {
    let viewCount = viewCurr?[currTpl] ?? 0
    if (currTpl not in sectionCurr)
      viewCurr[currTpl] <- count
    else if (viewCount != count) {
      let orderNumber = sortedCards.findindex(@(v) currTpl in v.cards) ?? 0
      diff.append({
        currTpl
        count = count - viewCount
        offset = sortedCards.len() == 0 ? 0 : 100 * orderNumber / sortedCards.len() + 10
      })
    }
  }
  viewCurrWatch(viewCurr)

  if (diff.len() == 0)
    return null

  diff.sort(@(a, b) a.offset <=> b.offset)
  diffAnimCounter++
  return diff.map(@(curr, idx) mkDiffCurrency(curr, idx, @()
    viewCurrWatch(viewCurrWatch.value.__merge({
      [curr.currTpl] = realCurr?[curr.currTpl] ?? 0
    }))
  ))
}

let mkArmyCurrency = @(armyCurrency, isShop)
  getSortedCards(armyCurrency).map(@(value)
    mkCurrencyOverall(value.type,
      value.cards,
      value.isInteractive ? openShop : null,
      value,
      isShop))

let sectionCurrency = Computed(function() {
  let currencies = viewCurrencies.value
  let armyCurrency = viewArmyCurrency.value
  let curSectionId = curSection.value
  return armyCurrency.__merge(currencyPresentation
    .filter(@(c, key) ((c?.isAlwaysVisible ?? false) || curSectionId in c?.sections)
      && key not in armyCurrency)
    .map(@(_, key) currencies?[key] ?? 0))
})

let currencyUi = {
  size = [SIZE_TO_CONTENT, flex()]
  minHeight = SIZE_TO_CONTENT
  children = [
    @() {
      watch = [sectionCurrency, isInShop]
      size = [SIZE_TO_CONTENT, flex()]
      minHeight = SIZE_TO_CONTENT
      flow = FLOW_HORIZONTAL
      gap = bigPadding
      children = mkArmyCurrency(sectionCurrency.value, isInShop.value)
    }
    @() {
      // I deliberately didn't subscribe to <sectionCurrency> and <viewCurrencies>
      // this block should be updated only after <realCurrencies> change
      watch = realCurrencies
      size = flex()
      valign = ALIGN_CENTER
      children = mkCurrenciesDiffAnim(realCurrencies.value, sectionCurrency.value, viewCurrencies)
    }
  ]
}

return currencyUi
