let { soldierKinds } = require("soldierClasses.nut")

let autoSoldierIcons = {}
foreach (sKind, sKindCfg in soldierKinds) {
  let { icon, iconsByRare = null } = sKindCfg
  autoSoldierIcons[sKind] <- $"ui/uiskin/{icon}"
  autoSoldierIcons[$"{sKind}_veteran"] <- $"ui/uiskin/{iconsByRare?.top() ?? icon}"
}

return freeze(autoSoldierIcons.__update({
  soldier_tier1 = "ui/uiskin/research/soldier_tier1.svg"
  soldier_tier2 = "ui/uiskin/research/soldier_tier2.svg"
  soldier_tier3 = "ui/uiskin/research/soldier_tier3.svg"
  soldier_tier4 = "ui/uiskin/research/soldier_tier4.svg"
  soldier_tier5 = "ui/uiskin/research/soldier_tier5.svg"
  soldier_tier6 = "ui/uiskin/research/soldier_tier6.svg"
  squad_icon = "ui/uiskin/research/squad_icon.svg"
  squad_size = "ui/uiskin/research/squad_size.svg"
  reserve_upgrade_icon = "ui/uiskin/research/reserve_upgrade_icon.svg"
  squad_xp_boost_icon = "ui/uiskin/research/squad_xp_boost_icon.svg"
  building_unlock_1_icon = "ui/uiskin/building_aaa.svg"
  building_unlock_2_icon = "ui/uiskin/building_at.svg"
  building_unlock_3_icon = "ui/uiskin/building_mg_nest.svg"
  building_unlock_4_icon = "ui/uiskin/building_ampulomet.svg"
  building_unlock_5_icon = "ui/uiskin/building_machine_gun.svg"
  inventory_upgrade_icon = "ui/uiskin/research/inventory_upgrade_icon.svg"
  class_xp_boost_icon = "ui/uiskin/research/class_xp_boost_icon.svg"
  side_slot_upgrade_icon = "ui/uiskin/pistol.svg"
  secondary_slot_upgrade_icon = "ui/uiskin/research/secondary_weap_slot_upgrade_icon.svg"
  backpack_slot_upgrade_icon = "ui/uiskin/research/inventory_upgrade_icon.svg"
  veteran_perk_icon = "ui/uiskin/research/veteran_perk_icon.svg"
  weapon_parts_boost_icon = "ui/uiskin/research/weapon_parts_boost_icon.svg"
  weapon_upgrade_cost_icon = "ui/uiskin/research/weapon_upgrade_cost_icon.svg"
  artillery_upgrade_icon = "ui/uiskin/radio.svg"
  artillery_type_unlock_1_icon = "ui/uiskin/grenade_smoke_icon.svg"
  artillery_type_unlock_2_icon = "ui/uiskin/marker_bomb.svg"
  artillery_type_unlock_3_icon = "ui/uiskin/marker_bomb.svg"
  artillery_type_unlock_4_icon = "ui/uiskin/marker_bomb.svg"
  artillery_type_unlock_5_icon = "ui/uiskin/marker_bomb.svg"
  artillery_type_unlock_6_icon = "ui/uiskin/marker_bomb.svg"
  artillery_type_unlock_7_icon = "ui/uiskin/marker_bomb.svg"
  artillery_type_unlock_8_icon = "ui/uiskin/marker_bomb.svg"
  artillery_type_unlock_9_icon = "ui/uiskin/marker_bomb.svg"
  artillery_type_unlock_10_icon = "ui/uiskin/marker_bomb.svg"
  artillery_type_unlock_11_icon = "ui/uiskin/marker_bomb.svg"
  artillery_type_unlock_12_icon = "ui/uiskin/marker_bomb.svg"
  artillery_type_unlock_13_icon = "ui/uiskin/marker_bomb.svg"

  squad_usa = "ui/uiskin/squad_usa_default.svg"
  squad_ussr ="ui/uiskin/squad_ussr_default.svg"
  squad_germany ="ui/uiskin/squad_germany_default.svg"
  squad_japan ="ui/uiskin/squad_japan_default.svg"
}))