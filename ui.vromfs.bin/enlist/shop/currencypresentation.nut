from "%enlSqGlob/ui_library.nut" import *

let { logerr } = require("dagor.debug")
let { mainSectionId } = require("%enlist/mainMenu/sectionsState.nut")

let ticketGroups = {}

let ticketGroupsSorted = [
  {
    id   = "weapon"
    icon = "!ui/uiskin/currency/weapon_order_cards.svg"
    desc = "items/weapon_order_all/desc"
    name = "items/weapon_order"
    hasTutorial = true
    isShownIfEmpty = true
    isInteractive = true
    expandedInShop = true
  }
  {
    id   = "soldier"
    icon = "!ui/uiskin/currency/soldier_order_cards.svg"
    desc =  "items/soldier_order_all/desc"
    name = "items/soldier_order"
    hasTutorial = true
    isShownIfEmpty = true
    isInteractive = true
    expandedInShop = true
  }
  {
    id   = "twitch"
    icon = "!ui/uiskin/currency/twitch_drop_big.svg"
    desc  = "items/twitch_drop_2021_event_pistol_order/desc"
    name = "items/twitch_drop_2021_event_pistol_order"
    hasTutorial = true
    isShownIfEmpty = false
    isInteractive = true
  }
  {
    id   = "research"
    icon = "!ui/uiskin/currency/squad_respec.svg"
    desc = "research/change_research_order/desc"
    name = "research/change_research_order"
    isShownIfEmpty = false
    isInteractive = false
  }
  {
    id   = "soldiers"
    icon = "!ui/uiskin/currency/soldier_levelup.svg"
    desc = "items/soldier_levelup_order/desc"
    name = "items/soldier_levelup_order"
    isShownIfEmpty = false
    isInteractive = false
  }
  {
    id   = "items"
    icon = "!ui/uiskin/currency/item_upgrade.svg"
    desc = "items/upgrade_order/desc"
    name = "items/upgrade_order"
    isShownIfEmpty = false
    isInteractive = false
  }
  {
    id   = "soldierCustomize"
    icon = "!ui/uiskin/currency/soldier_appearance.svg"
    desc = "items/soldier_appearance_change_order/desc"
    name = "items/soldier_appearance_change_order"
    isShownIfEmpty = false
    isInteractive = false
  }
  {
    id   = "vehicle"
    icon = "!ui/uiskin/currency/vehicle_with_skin.svg"
    desc = "items/vehicle_with_skin_order_gold/desc"
    name = "items/vehicle_with_skin_order_gold"
    isShownIfEmpty = false
    isInteractive = true
  }
  {
    id   = "temporarily_and_uniq"
    icon = "!ui/uiskin/currency/uniq_order_cards.svg"
    desc = "items/temporarily_and_uniq/desc"
    name = "items/temporarily_and_uniq"
    isShownIfEmpty = false
    isInteractive = true
    showInSection = [mainSectionId, "SHOP"]
  }
]

ticketGroupsSorted.each(function(group, idx) {
  group.order <- idx
  ticketGroups[group.id] <- group
})

let DEFAULT_CURRENCY = {
  order = 0
  group = ticketGroups.twitch
  color = Color(60,60,60)
  icon  = "!ui/uiskin/currency/twitch_drop.svg"
}

let currencyPresentation = freeze({
  weapon_order = {
    order = 0
    color = Color(182,107,61)
    group = ticketGroups.weapon
    icon = "!ui/uiskin/currency/weapon_order.svg"
    isAlwaysVisible = true
  }
  weapon_order_silver = {
    order = 1
    group = ticketGroups.weapon
    color = Color(117,123,129)
    icon = "!ui/uiskin/currency/weapon_order_silver.svg"
    isAlwaysVisible = true
  }
  weapon_order_gold = {
    order = 2
    group = ticketGroups.weapon
    color = Color(188,150,78)
    icon = "!ui/uiskin/currency/weapon_order_gold.svg"
    isAlwaysVisible = true
  }
  soldier_order = {
    order = 0
    group = ticketGroups.soldier
    color = Color(182,107,61)
    icon = "!ui/uiskin/currency/soldier_order.svg"
    isAlwaysVisible = true
  }
  soldier_order_silver = {
    order = 1
    group = ticketGroups.soldier
    color = Color(117,123,129)
    icon = "!ui/uiskin/currency/soldier_order_silver.svg"
    isAlwaysVisible = true
  }
  soldier_order_gold = {
    order = 2
    group = ticketGroups.soldier
    color = Color(188,150,78)
    icon = "!ui/uiskin/currency/soldier_order_gold.svg"
    isAlwaysVisible = true
  }
  twitch_drop_2021_obt_pistol_order = {
    order = 3
    group = ticketGroups.temporarily_and_uniq
    color = Color(180,180,180)
    icon  = "!ui/uiskin/currency/twitch_drop.svg"
    hideIfZero = true
  }
  twitch_drop_2021_event_pistol_order = {
    order = 3
    group = ticketGroups.temporarily_and_uniq
    color = Color(180,180,180)
    icon  = "!ui/uiskin/currency/twitch_drop.svg"
    hideIfZero = true
  }
  twitch_drop_2021_berlin_pistol_order = {
    order = 3
    group = ticketGroups.temporarily_and_uniq
    color = Color(180,180,180)
    icon  = "!ui/uiskin/currency/twitch_drop.svg"
    hideIfZero = true
  }
  twitch_drop_2021_tunisia_pistol_order = {
    order = 3
    group = ticketGroups.temporarily_and_uniq
    color = Color(180,180,180)
    icon  = "!ui/uiskin/currency/twitch_drop.svg"
    hideIfZero = true
  }
  twitch_drop_2021_winter_order = {
    order = 3
    group = ticketGroups.temporarily_and_uniq
    color = Color(180,180,180)
    icon  = "!ui/uiskin/currency/twitch_drop.svg"
    hideIfZero = true
  }
  twitch_drop_2022_stalingrad_order = {
    order = 3
    group = ticketGroups.temporarily_and_uniq
    color = Color(180,180,180)
    icon  = "!ui/uiskin/currency/twitch_drop.svg"
    hideIfZero = true
  }
  research_change_order = {
    order = 0
    group = ticketGroups.research
    color = Color(150,188,78)
    icon = "!ui/uiskin/currency/squad_respec.svg"
    sections = { RESEARCHES = true }
  }
  soldier_levelup_order = {
    order = 0
    group = ticketGroups.soldiers
    color = Color(188,150,78)
    icon = "!ui/uiskin/currency/soldier_levelup.svg"
  }
  item_upgrade_order = {
    order = 0
    group = ticketGroups.items
    color = Color(188,150,78)
    icon = "!ui/uiskin/currency/item_upgrade.svg"
  }
  vehicle_upgrade_order = {
    order = 0
    group = ticketGroups.items
    color = Color(188,150,78)
    icon = "!ui/uiskin/currency/vehicle_upgrade.svg"
  }
  callname_change_order = {
    order = 0
    group = ticketGroups.soldierCustomize
    color = Color(188,150,78)
    icon = "!ui/uiskin/currency/soldier_name_change.svg"
    hideIfZero = true
  }
  appearance_change_order = {
    order = 0
    group = ticketGroups.soldierCustomize
    color = Color(188,150,78)
    icon = "!ui/uiskin/currency/soldier_appearance.svg"
    hideIfZero = true
  }
  vehicle_with_skin_order_gold = {
    order = 1
    group = ticketGroups.temporarily_and_uniq
    color = Color(188,150,78)
    icon = "!ui/uiskin/currency/vehicle_with_skin.svg"
  }
  marathon_2021_summer_order = {
    order = 0
    group = ticketGroups.temporarily_and_uniq
    color = Color(180,180,180)
    icon  = "!ui/uiskin/currency/event_order.svg"
    hideIfZero = true
  }
  victory_day_event_order = {
    order = 0
    group = ticketGroups.temporarily_and_uniq
    color = Color(180,180,180)
    icon  = "!ui/uiskin/currency/event_order.svg"
    hideIfZero = true
  }
  marathon_2022_summer_event_order = {
    order = 0
    group = ticketGroups.temporarily_and_uniq
    color = Color(180,180,180)
    icon  = "!ui/uiskin/currency/event_order.svg"
    hideIfZero = true
  }
  pacific_event_2022_order = {
    order = 0
    group = ticketGroups.temporarily_and_uniq
    color = Color(180,180,180)
    icon  = "!ui/uiskin/currency/event_order.svg"
    hideIfZero = true
  }
  twitch_drop_2022_pacific_weapon_order = {
    order = 3
    group = ticketGroups.temporarily_and_uniq
    color = Color(180,180,180)
    icon  = "!ui/uiskin/currency/twitch_drop_weapon_order.svg"
    hideIfZero = true
  }
  twitch_drop_2022_pacific_axis_hero_order = {
    order = 3
    group = ticketGroups.temporarily_and_uniq
    color = Color(180,180,180)
    icon  = "!ui/uiskin/currency/twitch_drop_soldier_order.svg"
    hideIfZero = true
  }
  twitch_drop_2022_pacific_allies_tank_order = {
    order = 3
    group = ticketGroups.temporarily_and_uniq
    color = Color(180,180,180)
    icon  = "!ui/uiskin/currency/twitch_drop_tank_order.svg"
    hideIfZero = true
  }
  sea_predator_reward_order = {
    order = 1
    group = ticketGroups.temporarily_and_uniq
    color = Color(180,180,180)
    icon  = "!ui/uiskin/currency/random_reward_order.svg"
    hideIfZero = true
  }
  sea_predator_decal_order = {
    order = 0
    group = ticketGroups.temporarily_and_uniq
    color = Color(180,180,180)
    icon  = "!ui/uiskin/currency/decal_order_event.svg"
    hideIfZero = true
  }
  armory_event_order = {
    order = 0
    group = ticketGroups.temporarily_and_uniq
    color = Color(180,180,180)
    icon  = "!ui/uiskin/currency/event_order.svg"
    hideIfZero = true
  }
  xmas_event_order = {
    order = 0
    group = ticketGroups.temporarily_and_uniq
    color = Color(180,180,180)
    icon  = "!ui/uiskin/currency/event_order.svg"
    hideIfZero = true
  }
  heavy_weapons_event_order = {
    order = 0
    group = ticketGroups.temporarily_and_uniq
    color = Color(180,180,180)
    icon  = "!ui/uiskin/currency/event_order.svg"
    hideIfZero = true
  }

})

let function getCurrencyPresentation(key) {
  if (key in currencyPresentation)
    return currencyPresentation[key]

  logerr($"Unknown currency {key}")
  return DEFAULT_CURRENCY
}

return {
  currencyPresentation
  getCurrencyPresentation
  ticketGroups
}
