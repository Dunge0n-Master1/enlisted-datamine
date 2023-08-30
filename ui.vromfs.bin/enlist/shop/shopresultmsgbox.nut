from "%enlSqGlob/ui_library.nut" import *

let msgbox = require("%enlist/components/msgbox.nut")
let { lastReceivedServerTime } = require("%enlSqGlob/userstats/serverTimeUpdate.nut")
let { fontBody, fontHeading2, fontHeading1 } = require("%enlSqGlob/ui/fontsStyle.nut")
let { settings, onlineSettingUpdated } = require("%enlist/options/onlineSettings.nut")
let { purchasesExt } = require("%enlist/meta/profile.nut")
let { txt, noteTextArea } = require("%enlSqGlob/ui/defcomps.nut")
let { activeTxtColor, gap, bigPadding, accentTitleTxtColor
} = require("%enlSqGlob/ui/viewConst.nut")
let { shopItems } = require("%enlist/shop/shopItems.nut")
let { mkShopItemView } = require("shopPkg.nut")
let { borderColor } = require("%ui/style/colors.nut")
let { isLoggedIn } = require("%enlSqGlob/login_state.nut")


const SEEN_ID = "seen/purchasesExt"
const SEEN_PERIOD_IN_SEC = 86400

let seen = Computed(@() settings.value?[SEEN_ID])
let nameColor  = accentTitleTxtColor

let unseenPurchasesExt = keepref(Computed(function() {
  if (!onlineSettingUpdated.value || !isLoggedIn.value)
    return {}

  let time = lastReceivedServerTime.value
  if (time <= 0)
    return {}

  let sItems = shopItems.value
  let seenPurchasesExt = seen.value
  return purchasesExt.value
    .filter(@(p) time - p.lastTimestamp <= SEEN_PERIOD_IN_SEC)
    .map(@(purchaseInfo, guid) {
      guid
      amount = purchaseInfo.amount - (seenPurchasesExt?[guid] ?? 0)
    })
    .values()
    .filter(@(p) p.amount > 0)
    .map(function(p) {
      let shopItem = sItems.findvalue(@(item) item?.purchaseGuid == p.guid)
      let nameText = loc(shopItem?.nameLocId) ?? ""
      return p.__merge({ shopItem, nameText })})
    .filter(@(p) p.shopItem != null
      && !(p.shopItem?.isHidden ?? false)
      && !(p.shopItem?.isShowDebugOnly ?? false)
      && p.nameText != "")
}))

let function markSeen(purchases) {
  settings.mutate(function(set) {
    let saved = (clone (set?[SEEN_ID] ?? {}))
      .__update( purchases.map(@(v) v.amount) )
    set[SEEN_ID] <- saved
  })
}

let function resetSeen() {
  settings.mutate(@(v) delete v[SEEN_ID])
}

let function mkShopItemSingleResult(purchase) {
  let { amount, shopItem } = purchase
  return {
    flow = FLOW_HORIZONTAL
    valign = ALIGN_BOTTOM
    bigPadding
    children = [
      {
        rendObj = ROBJ_SOLID
        size = [fsh(50), fsh(25)]
        padding = hdpx(1)
        color = borderColor(0, false)
        clipChildren = true
        children = mkShopItemView({ shopItem })
      }
      amount <= 1 ? null
        : txt({
            text = $"x{amount}"
            padding = bigPadding
          }.__update(fontHeading1))
    ]
  }
}

let mkShopItemMultiResult = @(purchases)
  purchases.map(function(purchase) {
    let { amount, nameText } = purchase
    return {
      flow = FLOW_HORIZONTAL
      gap
      children = [
        txt({
          text = nameText
          color = nameColor
        }.__update(fontBody))
        amount <= 0 ? null
          : txt({
              text = $" x{amount}"
              color = activeTxtColor
            }.__update(fontBody))
      ]
    }
  })

let mkPurchasesView = @(purchases) {
  flow = FLOW_VERTICAL
  hplace = ALIGN_CENTER
  children = purchases.len() == 1
    ? mkShopItemSingleResult(purchases[0])
    : mkShopItemMultiResult(purchases)
}

let function checkReqPurchasesMsgbox(purchases) {
  if (purchases.len() == 0)
    return

  msgbox.showMessageWithContent({
    uid = "unseen_ext_purchases_result"
    content = {
      flow = FLOW_VERTICAL
      size = [fsh(110), SIZE_TO_CONTENT]
      halign = ALIGN_CENTER
      gap = hdpx(40)
      children = [
        noteTextArea(loc("youHaveReceived")).__update({
          color = activeTxtColor
          halign = ALIGN_CENTER
        }, fontHeading2)
        mkPurchasesView(purchases)
        noteTextArea(loc("thanksForPurchases")).__update({
          color = activeTxtColor
          halign = ALIGN_CENTER
        }, fontBody)
      ]
    }
    buttons = [{
      text = loc("Ok")
      isCurrent = true
      isCancel = true
      action = function() {
        markSeen(purchasesExt.value)
      }
    }]
  })
}

unseenPurchasesExt.subscribe(checkReqPurchasesMsgbox)
checkReqPurchasesMsgbox(unseenPurchasesExt.value)

console_register_command(resetSeen, "meta.resetSeenPurchasesExt")
