from "%enlSqGlob/ui_library.nut" import *

let eventbus = require("eventbus")
let http = require("dagor.http")
let json = require("json")
let serverTime = require("%enlSqGlob/userstats/serverTime.nut")

let { isLoggedIn } = require("%enlSqGlob/login_state.nut")
let { getPlatformId, getLanguageId } = require("%enlist/httpPkg.nut")
let { settings } = require("%enlist/options/onlineSettings.nut")
let { unlockOfferTime } = require("%enlist/unlocks/eventsTaskState.nut")
let { send_counter } = require("statsd")
let { offers } = require("%enlist/meta/profile.nut")
let { curArmyData } = require("%enlist/soldiers/model/state.nut")
let { priorityDiscounts, shopItems } = require("%enlist/shop/shopItems.nut")
let { configs } = require("%enlist/meta/configs.nut")
let { isOffersVisible } = require("%enlist/featureFlags.nut")
let { update_offers } = require("%enlist/meta/clientApi.nut")


const URL = "https://enlisted.net/{0}/events/current/?page=1&platform={1}&target=game"
const UseEventBus = true
const OffersDataRequest = "offers_data_request"
const SEEN_ID = "seen/offersPromo"

let debugActiveOffers = mkWatched(persist, "debugActiveOffers", null)

let isSpecOffersOpened = mkWatched(persist, "isOpened", false)
let allActiveOffers = Watched([])
let curOfferIdx = Watched(0)
let curOffer = Watched(null)


let function updateOffers() {
  update_offers(function(res) {
    // temporary gebug info for QA
    let addedOffers = res?.offers ?? {}
    let removedOffers = res?.removed.offers ?? {}
    if (addedOffers.len() > 0) {
      log($"Add {addedOffers.len()} special offers")
      foreach (offer in addedOffers) {
        let { guid, offerType, shopItemGuid, discountInPercent } = offer
        log($" + {guid} {offerType} {shopItemGuid} {discountInPercent}%")
      }
    }
    if (removedOffers.len() > 0) {
      log($"Removed {removedOffers.len()} special offers")
      foreach (guid in removedOffers)
        log($" - {guid}")
    }
  })
}


let offersSchemes = Computed(function() {
  let res = {}
  foreach (offer in configs.value?.offersSchemes ?? [])
    res[offer.offerType] <- offer

  return res
})

let allOffers = Computed(function() {
  if (!isOffersVisible.value)
    return []

  let oSchemes = offersSchemes.value
  let offersVal = offers.value

  let offerslist = []
  foreach (offer in offersVal.values()) {
    if (offer.hasUsed)
      continue

    let scheme = oSchemes?[offer.offerType]
    if (scheme == null)
      continue

    offerslist.append(offer.__merge({ scheme }))
  }

  return offerslist
})

let function recalcActiveOffers(_ = null) {
  let sItems = shopItems.value
  let time = serverTime.value
  let armyId = curArmyData.value?.guid
  let list = armyId == null ? []
    : allOffers.value
        .map(function(offer) {
          let shopItem = sItems?[offer.shopItemGuid]
          if (shopItem == null)
            return null

          let { armies = [] } = shopItem
          if (armies.len() > 0 && !armies.contains(armyId))
            return null

          return {
            endTime = offer.intervalTs[1]
            widgetTxt = loc(shopItem?.nameLocId ?? "")
            widgetImg = offer.scheme?.baseWidgetImg
            windowImg = offer.scheme?.basePromoImg
            descLocId = offer.scheme?.baseDescLocId
            lifeTime  = offer.scheme.lifeTime
            guid = offer.guid
            shopItem
            discountInPercent = offer.discountInPercent
            offerType = offer.offerType
          }
        })
        .filter(@(offer) offer != null && offer.endTime > time)

  let wasDiscounts = priorityDiscounts.value
  let newDiscounts = {}
  foreach (offer in list)
    newDiscounts[offer.shopItem.guid] <- offer.discountInPercent
  if (!isEqual(wasDiscounts, newDiscounts))
    priorityDiscounts(newDiscounts)

  if (allActiveOffers.value.len() > list.len())
    updateOffers()

  allActiveOffers(list)
}

let nextExpireData = Computed(@() {
  endTime = allActiveOffers.value
    .reduce(@(res, o) res > 0 && o.endTime > res ? res : o.endTime, 0)
})

nextExpireData.subscribe(function(v) {
  let timeLeft = v.endTime - serverTime.value
  if (timeLeft > 0)
    gui_scene.resetTimeout(timeLeft, recalcActiveOffers)
})

foreach (v in [allOffers, curArmyData, shopItems])
  v.subscribe(recalcActiveOffers)

recalcActiveOffers()

curOfferIdx.subscribe(@(idx) curOffer(allActiveOffers.value?[idx]))

let visibleOffersInWindow = Computed(@()
  allActiveOffers.value.filter(@(o) o.offerType != "PREMIUM"))

visibleOffersInWindow.subscribe(function(offersList) {
  let offersCount = offersList.len()
  if (offersCount == 0)
    return curOfferIdx(-1)

  let idx = offersList.findindex(@(offer) offer.guid == curOffer.value?.guid)
  if (idx != null)
    return curOfferIdx(idx)

  let curIdx = curOfferIdx.value
  curOfferIdx(clamp(curIdx, 0, offersCount - 1))
})

let offersByShopItem = Computed(function() {
  let res = {}
  foreach (offer in allActiveOffers.value)
    res[offer.shopItem.guid] <- offer
  return res
})

local offersTimeStart = Computed(@() unlockOfferTime.value.start)
local offersTimeEnd = Computed(@() unlockOfferTime.value.end)

let timeBefore = Computed(@() max(0, offersTimeStart.value - serverTime.value))
let timeLeft = Computed(@() max(0, offersTimeEnd.value - serverTime.value))

let hasSpecialEvent = Computed(@() debugActiveOffers.value
  ?? (timeBefore.value == 0 && timeLeft.value > 0))

let offersData = mkWatched(persist, "offersData", null)
let isRequestInProgress = Watched(false)
let isDataReady = Computed(@() offersData.value != null)

let isUnseen = Computed(@() (settings.value?[SEEN_ID] ?? 0) < offersTimeEnd.value)

let markSeen = @() settings.mutate(function(set) {
  if (offersTimeEnd.value > 0)
    set[SEEN_ID] <- offersTimeEnd.value
})

let offersShortTitle = Computed(@()
  offersData.value?.titleshort ?? loc("offers/commonShortTitle"))

let offersTitle = Computed(@()
  offersData.value?.title ?? loc("offers/commonTitle"))

let offersDescription = Computed(@() offersData.value?.content)

let hasEventData = Computed(@() offersDescription.value != null
  && (offersData.value?.published ?? true))

let offersTags = Computed(function() {
  let { tags = [] } = offersData.value
  return tags.reduce(function(tbl, tag) {
    let pairs = "".join(tag.split(" ")).split(":")
    if (pairs.len() < 1)
      return tbl
    let key = pairs[0]
    let value = pairs?[1]
    if (key not in tbl)
      tbl[key] <- value
    else if (typeof tbl[key] == "array")
      tbl[key].append(value)
    else
      tbl[key] = [tbl[key], value]
    return tbl
  }, {})
})

let headingAndDescription = Computed(function() {
  let list = offersDescription.value ?? []
  return list?[0].t == "image"
    ? {
        heading = list[0]
        description = list.slice(1)
      }
    : {
        heading = null // TODO add default background image
        description = list
      }
})

let function processOffersData(response) {
  isRequestInProgress(false)
  let { status = -1, http_code = 0, body = null } = response
  if (status != http.SUCCESS || http_code < 200 || 300 <= http_code) {
    send_counter("offer_receive_error", 1, { http_code })
    return log($"current offers request error: {status}, {http_code}")
  }

  local result
  try {
    result = json.parse(body?.as_string())?.result
  } catch(e) {
  }

  if (result == null)
    return log("current offers parse error")

  log("current offers successful data request")
  offersData(result)
}

let function requestOffersData() {
  if (isDataReady.value)
    return

  let request = {
    method = "GET"
    url = URL.subst(getLanguageId(), getPlatformId())
  }
  if (UseEventBus)
    request.respEventId <- OffersDataRequest
  else
    request.callback <- processOffersData
  isRequestInProgress(true)
  http.request(request)
}

if (UseEventBus)
  eventbus.subscribe(OffersDataRequest, processOffersData)

if (hasSpecialEvent.value)
  requestOffersData()
hasSpecialEvent.subscribe(@(act) act ? requestOffersData() : null)


isLoggedIn.subscribe(function(logged) {
  if (logged)
    updateOffers()
})

console_register_command(updateOffers, "meta.updateOffers")


console_register_command(@()
  settings.mutate(@(set) SEEN_ID in set ? delete set[SEEN_ID] : null), "meta.resetSeenOffersPromo")

console_register_command(function(val) {
  debugActiveOffers(val)
  console_print("debugActiveOffers:", val)
}, "meta.debugActiveOffers")

console_register_command(function(keyValue) {
  if ((keyValue ?? "") == "")
    offersData.mutate(@(v) "tags" in v ? delete v.tags : null)
  else
    offersData.mutate(@(v) v.tags <- (v?.tags ?? []).append(keyValue))
  console_print("offersData.tags:", offersData.value?.tags)
}, "meta.setActiveOffersTag")

return {
  isSpecOffersOpened
  isRequestInProgress
  isDataReady
  timeLeft
  hasSpecialEvent
  hasEventData
  isUnseen
  markSeen
  offersTitle
  offersShortTitle
  offersDescription
  offersTags
  headingAndDescription

  allActiveOffers
  offersByShopItem
  visibleOffersInWindow
  curOfferIdx
  nextExpireData
}
