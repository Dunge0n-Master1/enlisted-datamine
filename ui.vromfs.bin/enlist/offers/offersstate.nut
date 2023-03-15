from "%enlSqGlob/ui_library.nut" import *

let eventbus = require("eventbus")
let http = require("dagor.http")
let json = require("json")
let serverTime = require("%enlSqGlob/userstats/serverTime.nut")
let { get_circuit } = require("app")
let { isLoggedIn } = require("%enlSqGlob/login_state.nut")
let { getPlatformId, getLanguageId } = require("%enlist/httpPkg.nut")
let { settings } = require("%enlist/options/onlineSettings.nut")
let { specialEvents } = require("%enlist/unlocks/eventsTaskState.nut")
let { send_counter } = require("statsd")
let { offers } = require("%enlist/meta/profile.nut")
let { curArmyData } = require("%enlist/soldiers/model/state.nut")
let { priorityDiscounts, shopItems } = require("%enlist/shop/shopItems.nut")
let { configs } = require("%enlist/meta/configs.nut")
let { isOffersVisible } = require("%enlist/featureFlags.nut")
let { update_offers } = require("%enlist/meta/clientApi.nut")


const URL = "https://enlisted.net/{language}/events/event/{id}/?platform={platform}&circuit={circuit}&target=game" //warning disable: -forgot-subst
const UseEventBus = true
const EventDescRequest = "event_desc_request"
const SEEN_ID = "seen/eventPromo"

let isSpecOffersOpened = mkWatched(persist, "isOpened", false)

let eventDescs = mkWatched(persist, "eventDescs", {})
let descRequestedId = Watched(null)

let allActiveOffers = Watched([])
let curOfferIdx = Watched(0)
let curOffer = Watched(null)

let isUnseen = Computed(@() specialEvents.value
  .findindex(@(event) (settings.value?[SEEN_ID] ?? 0) < (event?.start ?? 0)) != null)

let markSeen = @() settings.mutate(@(set)
  set[SEEN_ID] <- specialEvents.value.reduce(@(res, event) max(res, event?.start ?? 0), 0))

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
          let { shopItemGuid } = offer
          let shopItem = sItems?[shopItemGuid]
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
            shopItemGuid
            discountInPercent = offer.discountInPercent
            offerType = offer.offerType
          }
        })
        .filter(@(offer) offer != null && offer.endTime > time)

  let wasDiscounts = priorityDiscounts.value
  let newDiscounts = {}
  foreach (offer in list)
    newDiscounts[offer.shopItemGuid] <- offer.discountInPercent
  if (!isEqual(wasDiscounts, newDiscounts))
    priorityDiscounts(newDiscounts)

  if (allActiveOffers.value.len() > list.len())
    updateOffers()

  allActiveOffers(list)

  let endTime = allActiveOffers.value
    .reduce(@(res, o) res > 0 && o.endTime > res ? res : o.endTime, 0)
  let leftTime = endTime - serverTime.value
  if (leftTime > 0)
    gui_scene.resetTimeout(leftTime, recalcActiveOffers)
}

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
    res[offer.shopItemGuid] <- offer
  return res
})

let eventsData = Computed(@() specialEvents.value.map(function(event, id) {
  let desc = eventDescs.value?[id]
  local {
    title = loc("offers/commonTitle"),
    titleshort = loc("offers/commonShortTitle"),
    imagepromo = null,
    content = null,
    published = desc != null,
    tags = []
  } = desc

  tags = tags.reduce(function(tbl, tag) {
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

  let hasFirstImage = content?[0].t == "image"
  let heading = hasFirstImage ? content[0].v : null // TODO add default heading background image
  let description = hasFirstImage ? content.slice(1) : content
  return event.__merge({
    id
    titleshort
    imagepromo = imagepromo ?? heading // TODO add default widget image
    title
    heading
    description
    published
    tags
  })
}))

let availableEventTime = Watched({})

let function recalcAvailableEvents(_ = null) {
  let curTime = serverTime.value
  let res = {}
  local closestTime = -1
  foreach (id, event in eventsData.value) {
    if (event.start <= curTime && curTime <= event.end)
      res[id] <- true
    if (curTime < event.start && (closestTime == -1 || closestTime > event.start))
      closestTime = event.start
    if (curTime < event.end && (closestTime == -1 || closestTime > event.end))
      closestTime = event.end
  }
  availableEventTime(res)
  if (closestTime > 0)
    gui_scene.resetTimeout(closestTime - curTime, recalcAvailableEvents)
}
eventsData.subscribe(recalcAvailableEvents)
recalcAvailableEvents()

let eventsAvailable = Computed(@() eventsData.value
  .values()
  .filter(@(evt) evt.published && evt.id in availableEventTime.value)
  .sort(@(a, b) b.start <=> a.start || a.end <=> b.end || a.id <=> b.id))

let function processEventDesc(response) {
  let id = descRequestedId.value
  let { status = -1, http_code = 0, body = null } = response
  if (status != http.SUCCESS || http_code < 200 || 300 <= http_code) {
    send_counter("offer_receive_error", 1, { http_code })
    log($"current offers request error: {status}, {http_code}")
    descRequestedId(null)
    eventDescs.mutate(@(data) data[id] <- { published = false })
    return
  }

  local result
  try {
    result = json.parse(body?.as_string())?.result
  } catch(e) {
  }

  if (result == null) {
    log("current offers parse error")
    descRequestedId(null)
    eventDescs.mutate(@(data) data[id] <- { published = false })
    return
  }

  log("current offers successful data request")
  descRequestedId(null)
  eventDescs.mutate(@(data) data[id] <- result)
}

let function requestOffersData(eventId) {
  if (eventId in eventDescs.value || descRequestedId.value != null)
    return

  let request = {
    method = "GET"
    url = URL.subst({
      id = eventId
      language = getLanguageId()
      platform = getPlatformId()
      circuit = get_circuit()
    })
  }
  if (UseEventBus)
    request.respEventId <- EventDescRequest
  else
    request.callback <- processEventDesc
  descRequestedId(eventId)
  http.request(request)
}

if (UseEventBus)
  eventbus.subscribe(EventDescRequest, processEventDesc)

let function eventDescUpdate(_ = null) {
  if (specialEvents.value.len() == 0)
    return

  let eventId = specialEvents.value.findindex(@(_, id) id not in eventDescs.value)
  if (eventId != null)
    requestOffersData(eventId)
}

foreach (w in [eventDescs, specialEvents])
  w.subscribe(eventDescUpdate)

isLoggedIn.subscribe(function(logged) {
  if (logged)
    updateOffers()
})

console_register_command(updateOffers, "meta.updateOffers")

console_register_command(@()
  settings.mutate(@(set) SEEN_ID in set ? delete set[SEEN_ID] : null), "meta.resetSeenOffersPromo")

return {
  isSpecOffersOpened
  isRequestInProgress = Computed(@() descRequestedId.value != null)
  hasSpecialEvent = Computed(@() eventsAvailable.value.len() > 0)
  eventsAvailable

  isUnseen
  markSeen

  allActiveOffers
  offersByShopItem
  visibleOffersInWindow
  curOfferIdx
}
