from "%enlSqGlob/ui_library.nut" import *

let { getSoldierItemSlots } = require("state.nut")
let { allItemTemplates } = require("all_items_templates.nut")
let { campItemsByLink } = require("%enlist/meta/profile.nut")

let equalIgnore = { ctime = true, guid = true, guids = true, count = true, links = true, linkedItems = true }
let function countParamsToCompare(item) {
  local res = item.len()
  foreach (key, _ in equalIgnore)
    if (key in item)
      res--
  return res
}

let function getLinkedItemsData(guid) {
  let res = {}
  foreach (data in getSoldierItemSlots(guid, campItemsByLink.value)) {
    let tpl = data.item?.basetpl
    if (!(data.slotType in res))
      res[data.slotType] <- {}
    res[data.slotType][data.slotId ?? -1] <- tpl
  }
  return res
}

let function mergeItems(item1, item2) {
  if (countParamsToCompare(item1) != countParamsToCompare(item2))
    return null
  foreach (key, val in item1)
    if (!equalIgnore?[key]
        && (!(key in item2) || !isEqual(val, item2[key])))
      return null

  local linkedItems = null
  if (item1?.equipScheme) {
    linkedItems = item1?.linkedItems ?? getLinkedItemsData(item1.guid)
    if (!isEqual(linkedItems, getLinkedItemsData(item2.guid)))
      return null
  }

  let guids = "guids" in item1 ? item1.guids : [item1?.guid]
  guids.append(item2?.guid)
  return item1.__merge({
    count = (item1?.count ?? 1) + (item2?.count ?? 1)
    guids = guids
    linkedItems = linkedItems
  })
}

let itemWeights = {
  // vehicle
  vehicle = 81,
  // explosives and mines
  explosion_pack = 80, grenade = 79, impact_grenade = 78, incendiary_grenade = 77, molotov = 76,
  lunge_mine = 75, tnt_block_exploder = 74, smoke_grenade = 73, antipersonnel_mine = 72, antitank_mine = 71
  // special
  flamethrower = 62, mortar = 61,
  // heavy
  launcher = 54, grenade_launcher = 53, infantry_launcher = 52, antitank_rifle = 51,
  // assault
  mgun = 46, assault_rifle = 45, assault_rifle_stl = 44, semiauto = 43, carbine_tanker = 42, submgun = 41,
  carbine_pistol = 40,
  // rifle and shotgun
  rifle_grenade_launcher = 37, shotgun = 36, boltaction_noscope = 34,
  carbine = 33, semiauto_sniper = 32, boltaction = 31,
  // pistol
  sideweapon = 29, flaregun = 28,
  // melee and equipment
  flask_usable = 19, binoculars_usable = 18, backpack = 17, radio = 16, melee = 15,
  bayonet = 14, scope = 13, medic_medkits = 12, medkits = 11, repair_kit = 10
  // soldier
  soldier = 4,
  //booster
  booster = 3,
  // ticket
  ticket = 2
}

local function prepareItems(items, objByGuid = {}) {
  items = items
    .map(function(item) {
      if (typeof item == "string")
        return objByGuid?[item]
      if ("guid" in item)
        return objByGuid?[item.guid]
      return item
    })
    .filter(@(v) v != null)
    .sort(@(a, b) (a?.basetpl ?? "") <=> (b?.basetpl ?? ""))

  let res = []
  foreach (item in items) {
    local isMerged = false
    let tpl = item?.basetpl
    for(local i = res.len() - 1; i >= 0; i--) {
      let tgtItem = res[i]
      if (tgtItem?.basetpl != tpl)
        break
      let merged = mergeItems(tgtItem, item)
      if (!merged)
        continue
      res[i] = merged
      isMerged = true
      break
    }
    if (!isMerged)
      res.append(item)
  }

  return res
}

let mkShopItem = @(templateId, template, armyId)
  template.__merge({ guid = "", basetpl = templateId, isShopItem = true, links = { [armyId] = "army"} })

let function addShopItems(items, armyId, templateFilter = @(_templateId, _template) true) {
  let usedTemplates = {}
  foreach (item in items)
    if (item?.basetpl)
      usedTemplates[item.basetpl] <- true

  foreach (templateId, template in (allItemTemplates.value?[armyId] ?? {})) {
    if (usedTemplates?[templateId]
        || (template?.isZeroHidden ?? false)
        || (("armies" in template) && template.armies.indexof(armyId) == null)
        || !templateFilter(templateId, template))
      continue

    items.append(mkShopItem(templateId, template, armyId))
  }
}

let itemsSort = @(item1, item2) (item1?.guid != null) <=> (item2?.guid != null)
  || (item1?.isShopItem ?? false) <=> (item2?.isShopItem ?? false)
  || (itemWeights?[item1?.itemtype] ?? 0) <=> (itemWeights?[item2?.itemtype] ?? 0)
  || ((item1?.tier ?? 0) - (item1?.upgradeIdx ?? 0)) <=> ((item2?.tier ?? 0) - (item2?.upgradeIdx ?? 0))
  || (item2?.itemsubtype ?? "") <=> (item1?.itemsubtype ?? "")
  || (item1?.gametemplate ?? "") <=> (item2?.gametemplate ?? "")
  || (item1?.tier ?? 0) <=> (item2?.tier ?? 0)

let preferenceSort = @(a, b) (b?.tier ?? 0) <=> (a?.tier ?? 0)
  || (itemWeights?[b?.itemtype] ?? 0) <=> (itemWeights?[a?.itemtype] ?? 0)
  || (a?.basetpl ?? "") <=> (b?.basetpl ?? "")

let function findItemByGuid(items, guid) {
  foreach (it in items)
    if ("guids" in it ? it.guids.indexof(guid) != null : it?.guid == guid)
      return it
  return null
}

let function putToStackTop(items, topItem) {
  let guid = topItem?.guid
  if (guid == null)
    return
  let item = findItemByGuid(items, guid)
  if (!("guids" in item) || item?.guid == guid)
    return

  item.guid <- guid
  if ("links" in topItem)
    item.links <- topItem.links
  item.guids.sort(@(a, b) (b == guid) <=> (a == guid))
}

return {
  itemWeights
  prepareItems
  mkShopItem
  addShopItems
  itemsSort
  preferenceSort
  findItemByGuid
  putToStackTop
}