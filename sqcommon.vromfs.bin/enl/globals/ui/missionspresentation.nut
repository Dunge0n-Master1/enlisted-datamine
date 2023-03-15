// TODO probably presentation should contain only localization and images,
// but game type and army have to be extracted from blk itself

const defImage = "!ui/skin#moveto.svg"

enum MissionType {
  INVASION = 0
  CONFRONTATION = 1
  DESTRUCTION = 2
  ASSAULT = 3
  DOMINATION = 4
  ESCORT = 5
}

let typeToLocId = {
  [MissionType.ASSAULT] = "missionType/assault",
  [MissionType.DOMINATION] = "missionType/domination",
  [MissionType.INVASION] = "missionType/invasion",
  [MissionType.DESTRUCTION] = "missionType/destruction",
  [MissionType.ESCORT] = "missionType/escort",
  [MissionType.CONFRONTATION] = "missionType/confrontation"
}

enum MissionArmy {
  NONE = 0
  ALLIES = 1
  AXIS = 2
}

let function mkMission(cfg, id) {
  let desc = {
    id
    locId = $"lobbies/{id}"
    type = MissionType.INVASION
    army = MissionArmy.NONE
    image = defImage
  }.__update(cfg)
  desc.typeLocId <- typeToLocId?[desc.type] ?? desc.type
  return desc
}

let missions = {
  volokolamsk_city_assault_ussr = {
    image = "ui/volokolamsk_city_02.avif"
    locId = "lobbies/volokolamsk_city_assault_allies"
    type = MissionType.ASSAULT
    army = MissionArmy.ALLIES
  }

  volokolamsk_city_assault = {
    image = "ui/volokolamsk_city_02.avif"
    locId = "lobbies/volokolamsk_city_assault_axis"
    type = MissionType.ASSAULT
    army = MissionArmy.AXIS
  }

  volokolamsk_city_bomb = {
    image = "ui/volokolamsk_city_03.avif"
    locId = "lobbies/volokolamsk_city_bomb"
    type = MissionType.DESTRUCTION
    army = MissionArmy.AXIS
  }

  volokolamsk_city_bomb_ussr = {
    image = "ui/volokolamsk_city_03.avif"
    locId = "lobbies/volokolamsk_city_bomb_allies"
    type = MissionType.DESTRUCTION
    army = MissionArmy.ALLIES
  }

  volokolamsk_city_dom = {
    image = "ui/volokolamsk_city_01.avif"
    locId = "lobbies/volokolamsk_city_dom"
    type = MissionType.DOMINATION
  }

  volokolamsk_farm_dom = {
    image = "ui/volokolamsk_farm_01.avif"
    locId = "lobbies/volokolamsk_farm_dom"
    type = MissionType.DOMINATION
  }

  volokolamsk_forestry_dom = {
    image = "ui/volokolamsk_forestery_03.avif"
    locId = "lobbies/volokolamsk_forestry_dom"
    type = MissionType.DOMINATION
  }

  volokolamsk_forestry_inv_ussr = {
    image = "ui/volokolamsk_forestery_01.avif"
    locId = "lobbies/volokolamsk_forestry_inv_allies"
    army = MissionArmy.ALLIES
  }

  volokolamsk_forestry_inv = {
    image = "ui/volokolamsk_forestery_01.avif"
    locId = "lobbies/volokolamsk_forestry_inv_axis"
    army = MissionArmy.AXIS
  }

  volokolamsk_forestry_inv_counter_ussr = {
    image = "ui/volokolamsk_forestery_02.avif"
    locId = "lobbies/volokolamsk_forestry_inv_counter_allies"
    army = MissionArmy.ALLIES
  }

  volokolamsk_forestry_inv_counter = {
    image = "ui/volokolamsk_forestery_02.avif"
    locId = "lobbies/volokolamsk_forestry_inv_counter_axis"
    army = MissionArmy.AXIS
  }

  volokolamsk_forestry_bomb = {
    image = "ui/volokolamsk_forestery_04.avif"
    locId = "lobbies/volokolamsk_forestry_bomb"
    army = MissionArmy.AXIS
  }

  volokolamsk_forestry_bomb_ussr = {
    image = "ui/volokolamsk_forestery_04.avif"
    locId = "lobbies/volokolamsk_forestry_bomb_allies"
    army = MissionArmy.ALLIES
  }

  volokolamsk_fortification_dom = {
    image = "ui/volokolamsk_fortification_02.avif"
    locId = "lobbies/volokolamsk_fortification_dom"
    type = MissionType.DOMINATION
  }

  volokolamsk_fortification_inv_ussr = {
    image = "ui/volokolamsk_fortification_01.avif"
    locId = "lobbies/volokolamsk_fortification_inv_allies"
    army = MissionArmy.ALLIES
  }

  volokolamsk_fortification_inv = {
    image = "ui/volokolamsk_fortification_01.avif"
    locId = "lobbies/volokolamsk_fortification_inv_axis"
    army = MissionArmy.AXIS
  }

  volokolamsk_grove_dom = {
    image = "ui/volokolamsk_grove_03.avif"
    locId = "lobbies/volokolamsk_grove_dom"
    type = MissionType.DOMINATION
  }

  volokolamsk_grove_inv = {
    image = "ui/volokolamsk_grove_01.avif"
    locId = "lobbies/volokolamsk_grove_inv"
    army = MissionArmy.AXIS
  }

  volokolamsk_grove_inv_ussr = {
    image = "ui/volokolamsk_grove_01.avif"
    locId = "lobbies/volokolamsk_grove_inv_allies"
    army = MissionArmy.ALLIES
  }

  volokolamsk_grove_inv_counter = {
    image = "ui/Volokolamsk_Birch_Grove_Inv_02.avif"
    locId = "lobbies/volokolamsk_grove_inv_counter"
    army = MissionArmy.AXIS
  }

  volokolamsk_grove_inv_counter_ussr = {
    image = "ui/Volokolamsk_Birch_Grove_Inv_02.avif"
    locId = "lobbies/volokolamsk_grove_inv_counter_allies"
    army = MissionArmy.ALLIES
  }

  volokolamsk_grove_conf = {
    image = "ui/volokolamsk_grove_02.avif"
    locId = "lobbies/volokolamsk_grove_conf_axis"
    type = MissionType.CONFRONTATION
  }

  volokolamsk_grove_conf_ussr = {
    image = "ui/volokolamsk_grove_02.avif"
    locId = "lobbies/volokolamsk_grove_conf_allies"
    type = MissionType.CONFRONTATION
  }

  volokolamsk_lake_dom = {
    image = "ui/volokolamsk_lake_03.avif"
    locId = "lobbies/volokolamsk_lake_dom"
    type = MissionType.DOMINATION
  }

  volokolamsk_lake_inv_ussr = {
    image = "ui/volokolamsk_lake_01.avif"
    locId = "lobbies/volokolamsk_lake_inv_allies"
    army = MissionArmy.ALLIES
  }

  volokolamsk_lake_inv = {
    image = "ui/volokolamsk_lake_01.avif"
    locId = "lobbies/volokolamsk_lake_inv_axis"
    army = MissionArmy.AXIS
  }

  volokolamsk_manor_assault_ussr = {
    image = "ui/volokolamsk_manor_02.avif"
    locId = "lobbies/volokolamsk_manor_assault_allies"
    type = MissionType.ASSAULT
    army = MissionArmy.ALLIES
  }

  volokolamsk_manor_assault = {
    image = "ui/volokolamsk_manor_02.avif"
    locId = "lobbies/volokolamsk_manor_assault_axis"
    type = MissionType.ASSAULT
    army = MissionArmy.AXIS
  }

  volokolamsk_manor_dom = {
    image = "ui/volokolamsk_manor_03.avif"
    locId = "lobbies/volokolamsk_manor_dom"
    type = MissionType.DOMINATION
  }

  volokolamsk_monastery_dom = {
    image = "ui/volokolamsk_monastery_03.avif"
    locId = "lobbies/volokolamsk_monastery_dom"
    type = MissionType.DOMINATION
  }

  volokolamsk_monastery_inv_ussr = {
    image = "ui/volokolamsk_monastery_01.avif"
    locId = "lobbies/volokolamsk_monastery_inv_allies"
    army = MissionArmy.ALLIES
  }

  volokolamsk_monastery_inv = {
    image = "ui/volokolamsk_monastery_01.avif"
    locId = "lobbies/volokolamsk_monastery_inv_axis"
    army = MissionArmy.AXIS
  }

  volokolamsk_quarry_inv_ussr = {
    image = "ui/volokolamsk_quarry_1.avif"
    locId = "lobbies/volokolamsk_quarry_inv_allies"
    army = MissionArmy.ALLIES
  }

  volokolamsk_quarry_inv = {
    image = "ui/volokolamsk_quarry_1.avif"
    locId = "lobbies/volokolamsk_quarry_inv_axis"
    army = MissionArmy.AXIS
  }

  volokolamsk_quarry_inv_counter_ussr = {
    image = "ui/volokolamsk_quarry_2.avif"
    locId = "lobbies/volokolamsk_quarry_inv_counter_allies"
    army = MissionArmy.ALLIES
  }

  volokolamsk_quarry_inv_counter = {
    image = "ui/volokolamsk_quarry_2.avif"
    locId = "lobbies/volokolamsk_quarry_inv_counter_axis"
    army = MissionArmy.AXIS
  }

  volokolamsk_river_dom = {
    image = "ui/volokolamsk_river_01.avif"
    locId = "lobbies/volokolamsk_river_dom"
    type = MissionType.DOMINATION
  }

  volokolamsk_village_assault_ussr = {
    image = "ui/volokolamsk_village_02.avif"
    locId = "lobbies/volokolamsk_village_assault_allies"
    type = MissionType.ASSAULT
    army = MissionArmy.ALLIES
  }

  volokolamsk_village_assault = {
    image = "ui/volokolamsk_village_02.avif"
    locId = "lobbies/volokolamsk_village_assault_axis"
    type = MissionType.ASSAULT
    army = MissionArmy.AXIS
  }

  volokolamsk_village_bomb_ussr = {
    image = "ui/volokolamsk_village_02.avif"
    locId = "lobbies/volokolamsk_village_bomb_allies"
    type = MissionType.DESTRUCTION
    army = MissionArmy.ALLIES
  }

  volokolamsk_village_bomb = {
    image = "ui/volokolamsk_village_02.avif"
    locId = "lobbies/volokolamsk_village_bomb_axis"
    type = MissionType.DESTRUCTION
    army = MissionArmy.AXIS
  }

  volokolamsk_village_inv_ussr = {
    image = "ui/volokolamsk_village_01.avif"
    locId = "lobbies/volokolamsk_village_inv_allies"
    army = MissionArmy.ALLIES
  }

  volokolamsk_village_inv = {
    image = "ui/volokolamsk_village_01.avif"
    locId = "lobbies/volokolamsk_village_inv_axis"
    army = MissionArmy.AXIS
  }

  volokolamsk_village_inv_counter = {
    image = "ui/volokolamsk_village_03.avif"
    locId = "lobbies/volokolamsk_village_inv_counter_axis"
    army = MissionArmy.AXIS
  }

  volokolamsk_village_inv_counter_ussr = {
    image = "ui/volokolamsk_village_03.avif"
    locId = "lobbies/volokolamsk_village_inv_counter_allies"
    army = MissionArmy.ALLIES
  }

  volokolamsk_voskhod_inv = {
    image = "ui/volokolamsk_voskhod_inv_01.avif"
    locId = "lobbies/volokolamsk_voskhod_inv_axis"
    army = MissionArmy.AXIS
  }

  volokolamsk_voskhod_inv_ussr = {
    image = "ui/volokolamsk_voskhod_inv_01.avif"
    locId = "lobbies/volokolamsk_voskhod_inv_allies"
    army = MissionArmy.ALLIES
  }

  volokolamsk_voskhod_inv_counter = {
    image = "ui/volokolamsk_voskhod_inv_03.avif"
    locId = "lobbies/volokolamsk_voskhod_inv_counter_axis"
    army = MissionArmy.AXIS
  }

  volokolamsk_voskhod_inv_counter_ussr = {
    image = "ui/volokolamsk_voskhod_inv_03.avif"
    locId = "lobbies/volokolamsk_voskhod_inv_counter_allies"
    army = MissionArmy.ALLIES
  }

  volokolamsk_voskhod_conf = {
    image = "ui/volokolamsk_voskhod_inv_02.avif"
    locId = "lobbies/volokolamsk_voskhod_conf"
    type = MissionType.CONFRONTATION
  }

  volokolamsk_voskhod_conf_ussr = {
    image = "ui/volokolamsk_voskhod_inv_02.avif"
    locId = "lobbies/volokolamsk_voskhod_conf_allies"
    type = MissionType.CONFRONTATION
  }

  normandy_aerodrome_inv = {
    image = "ui/normandy_airfield_01.avif"
    locId = "lobbies/normandy_aerodrome_inv"
    army = MissionArmy.ALLIES
  }

  normandy_aerodrome_inv_axis = {
    image = "ui/normandy_airfield_01.avif"
    locId = "lobbies/normandy_aerodrome_inv_axis"
    army = MissionArmy.AXIS
  }

  normandy_aerodrome_inv_counter = {
    image = "ui/normandy_airfield_03.avif"
    locId = "lobbies/normandy_aerodrome_inv_counter"
    army = MissionArmy.ALLIES
  }

  normandy_aerodrome_inv_counter_axis = {
    image = "ui/normandy_airfield_03.avif"
    locId = "lobbies/normandy_aerodrome_inv_counter_axis"
    army = MissionArmy.AXIS
  }

  normandy_aerodrome_bomb = {
    image = "ui/normandy_airfield_02.avif"
    locId = "lobbies/normandy_aerodrome_bomb"
    type = MissionType.DESTRUCTION
    army = MissionArmy.ALLIES
  }

  normandy_beach_inv = {
    image = "ui/normandy_beach_inv_01.avif"
    locId = "lobbies/normandy_beach_inv"
  }

  normandy_city_dom = {
    image = "ui/normandy_city_dom_01.avif"
    locId = "lobbies/normandy_city_dom"
    type = MissionType.DOMINATION
  }

  normandy_city_inv_allies = {
    image = "ui/normandy_city_dom_03.avif"
    locId = "lobbies/normandy_city_inv_allies"
    army = MissionArmy.ALLIES
  }

  normandy_city_inv = {
    image = "ui/normandy_city_dom_03.avif"
    locId = "lobbies/normandy_city_inv_axis"
    army = MissionArmy.AXIS
  }

  normandy_city_inv_counter_allies = {
    image = "ui/normandy_city_dom_02.avif"
    locId = "lobbies/normandy_city_inv_counter_allies"
    army = MissionArmy.ALLIES
  }

  normandy_city_inv_counter = {
    image = "ui/normandy_city_dom_02.avif"
    locId = "lobbies/normandy_city_inv_counter_axis"
    army = MissionArmy.AXIS
  }

  normandy_coast_city_assault = {
    image = "ui/normandy_coast_city_02.avif"
    locId = "lobbies/normandy_coast_city_assault"
    type = MissionType.ASSAULT
  }

  normandy_coast_city_dom = {
    image = "ui/normandy_coast_city_01.avif"
    locId = "lobbies/normandy_coast_city_dom"
    type = MissionType.DOMINATION
  }

  normandy_coast_city_inv = {
    image = "ui/normandy_coast_city_03.avif"
    locId = "lobbies/normandy_coast_city_inv"
  }

  normandy_coast_farm_dom = {
    image = "ui/normandy_coast_farm_01.avif"
    locId = "lobbies/normandy_coast_farm_dom"
    type = MissionType.DOMINATION
  }

  normandy_coast_ruins_inv = {
    image = "ui/normandy_coast_ruins_02.avif"
    locId = "lobbies/normandy_coast_ruins_inv"
    army = MissionArmy.ALLIES
  }

  normandy_coast_ruins_inv_axis = {
    image = "ui/normandy_coast_ruins_02.avif"
    locId = "lobbies/normandy_coast_ruins_inv_axis"
    army = MissionArmy.AXIS
  }

  normandy_coast_ruins_inv_counter = {
    image = "ui/normandy_coast_ruins_01.avif"
    locId = "lobbies/normandy_coast_ruins_inv_counter_allies"
    army = MissionArmy.ALLIES
  }

  normandy_coast_ruins_inv_counter_axis = {
    image = "ui/normandy_coast_ruins_01.avif"
    locId = "lobbies/normandy_coast_ruins_inv_counter_axis"
    army = MissionArmy.AXIS
  }

  normandy_coast_ruins_dom = {
    image = "ui/normandy_coast_ruins_03.avif"
    locId = "lobbies/normandy_coast_ruins_dom"
    type = MissionType.DOMINATION
  }

  normandy_coast_swamp_dom = {
    image = "ui/normandy_coast_swamp_03.avif"
    locId = "lobbies/normandy_coast_swamp_dom"
    type = MissionType.DOMINATION
  }

  normandy_field_dom = {
    image = "ui/normandy_field_01.avif"
    locId = "lobbies/normandy_field_dom"
    type = MissionType.DOMINATION
  }

  normandy_omer_inv = {
    image = "ui/normandy_urban_omer_01.avif"
    locId = "lobbies/normandy_omer_inv_allies"
    army = MissionArmy.ALLIES
  }

  normandy_omer_inv_axis = {
    image = "ui/normandy_urban_omer_01.avif"
    locId = "lobbies/normandy_omer_inv_axis"
    army = MissionArmy.AXIS
  }

  normandy_omer_inv_counter = {
    image = "ui/normandy_urban_omer_02.avif"
    locId = "lobbies/normandy_omer_inv_counter_allies"
    army = MissionArmy.ALLIES
  }

  normandy_omer_inv_counter_axis = {
    image = "ui/normandy_urban_omer_02.avif"
    locId = "lobbies/normandy_omer_inv_counter_axis"
    army = MissionArmy.AXIS
  }

  normandy_omer_bomb = {
    image = "ui/normandy_urban_omer_02.avif"
    locId = "lobbies/normandy_omer_bomb"
    type = MissionType.DESTRUCTION
    army = MissionArmy.ALLIES
  }

  normandy_omer_bomb_axis = {
    image = "ui/normandy_urban_omer_02.avif"
    locId = "lobbies/normandy_omer_bomb_axis"
    type = MissionType.DESTRUCTION
    army = MissionArmy.AXIS
  }

  normandy_omer_conf = {
    image = "ui/normandy_urban_omer_03.avif"
    locId = "lobbies/normandy_omer_conf_allies"
    type = MissionType.CONFRONTATION
  }

  normandy_omer_conf_axis = {
    image = "ui/normandy_urban_omer_03.avif"
    locId = "lobbies/normandy_omer_conf_axis"
    type = MissionType.CONFRONTATION
  }

  normandy_station_inv = {
    image = "ui/normandy_station_inv_01.avif"
    locId = "lobbies/normandy_station_inv"
    army = MissionArmy.ALLIES
  }

  normandy_station_inv_axis = {
    image = "ui/normandy_station_inv_01.avif"
    locId = "lobbies/normandy_station_inv_axis"
    army = MissionArmy.AXIS
  }

  normandy_station_inv_counter = {
    image = "ui/normandy_station_inv_02.avif"
    locId = "lobbies/normandy_station_inv_counter_allies"
    army = MissionArmy.ALLIES
  }

  normandy_station_inv_counter_axis = {
    image = "ui/normandy_station_inv_02.avif"
    locId = "lobbies/normandy_station_inv_counter_axis"
    army = MissionArmy.AXIS
  }

  normandy_station_conf = {
    image = "ui/normandy_station_inv_03.avif"
    locId = "lobbies/normandy_station_conf"
    type = MissionType.CONFRONTATION
  }

  normandy_station_conf_axis = {
    image = "ui/normandy_station_inv_03.avif"
    locId = "lobbies/normandy_station_conf_axis"
    type = MissionType.CONFRONTATION
  }

  normandy_station_bomb = {
    image = "ui/normandy_station_inv_04.avif"
    locId = "lobbies/normandy_station_bomb"
    type = MissionType.DESTRUCTION
    army = MissionArmy.ALLIES
  }

  normandy_station_bomb_axis = {
    image = "ui/normandy_station_inv_04.avif"
    locId = "lobbies/normandy_station_bomb_axis"
    type = MissionType.DESTRUCTION
    army = MissionArmy.AXIS
  }

  normandy_village_inv = {
    image = "ui/normandy_village_01.avif"
    locId = "lobbies/normandy_village_inv"
    army = MissionArmy.ALLIES
  }

  normandy_village_inv_axis = {
    image = "ui/normandy_village_01.avif"
    locId = "lobbies/normandy_village_inv_axis"
    army = MissionArmy.AXIS
  }

  normandy_village_bomb = {
    image = "ui/normandy_village_04.avif"
    locId = "lobbies/normandy_village_bomb"
    type = MissionType.DESTRUCTION
    army = MissionArmy.ALLIES
  }

  normandy_village_bomb_axis = {
    image = "ui/normandy_village_04.avif"
    locId = "lobbies/normandy_village_bomb_axis"
    type = MissionType.DESTRUCTION
    army = MissionArmy.AXIS
  }

  berlin_chancellery_dom = {
    image = "ui/berlin_chancellery_dom_01.avif"
    locId = "lobbies/berlin_chancellery_dom"
    type = MissionType.DOMINATION
  }

  berlin_chancellery_conf = {
    image = "ui/berlin_chancellery_dom_04.avif"
    locId = "lobbies/berlin_chancellery_conf"
    type = MissionType.CONFRONTATION
  }

  berlin_chancellery_conf_axis = {
    image = "ui/berlin_chancellery_dom_04.avif"
    locId = "lobbies/berlin_chancellery_conf_axis"
    type = MissionType.CONFRONTATION
  }

  berlin_chancellery_inv = {
    image = "ui/berlin_chancellery_dom_05.avif"
    locId = "lobbies/berlin_chancellery_inv"
    army = MissionArmy.ALLIES
  }

  berlin_chancellery_inv_axis = {
    image = "ui/berlin_chancellery_dom_05.avif"
    locId = "lobbies/berlin_chancellery_inv_axis"
    army = MissionArmy.AXIS
  }

  berlin_garden_assault = {
    image = "ui/berlin_garden_inv_02.avif"
    locId = "lobbies/berlin_garden_assault"
    type = MissionType.ASSAULT
  }

  berlin_garden_inv = {
    image = "ui/berlin_garden_inv_01.avif"
    locId = "lobbies/berlin_garden_inv"
  }

  berlin_goering_dom = {
    image = "ui/berlin_goering_dom_02.avif"
    locId = "lobbies/berlin_goering_dom"
    type = MissionType.DOMINATION
  }

  berlin_goering_inv = {
    image = "ui/berlin_goering_dom_01.avif"
    locId = "lobbies/berlin_goering_inv"
  }

  berlin_ministry_inv = {
    image = "ui/berlin_moat_02.avif"
    locId = "lobbies/berlin_ministry_inv"
  }

  berlin_ministry_inv_counter = {
    image = "ui/berlin_opera_inv_03.avif"
    locId = "lobbies/berlin_ministry_inv_counter"
  }

  berlin_ministry_conf = {
    image = "ui/berlin_opera_inv_02.avif"
    locId = "lobbies/berlin_ministry_conf_allies"
    type = MissionType.CONFRONTATION
  }

  berlin_ministry_conf_axis = {
    image = "ui/berlin_opera_inv_02.avif"
    locId = "lobbies/berlin_ministry_conf_axis"
    type = MissionType.CONFRONTATION
  }

  berlin_moat_germany_inv = {
    image = "ui/berlin_moat_01.avif"
    locId = "lobbies/berlin_moat_germany_inv"
  }

  berlin_moat_inv_counter = {
    image = "ui/berlin_moat_02.avif"
    locId = "lobbies/berlin_moat_inv_counter"
  }

  berlin_opera_assault = {
    image = "ui/berlin_opera_inv_02.avif"
    locId = "lobbies/berlin_opera_assault"
    type = MissionType.ASSAULT
  }

  berlin_opera_inv = {
    image = "ui/berlin_opera_inv_01.avif"
    locId = "lobbies/berlin_opera_inv"
  }

  berlin_station_dom = {
    image = "ui/berlin_station_01.avif"
    locId = "lobbies/berlin_station_dom"
    type = MissionType.DOMINATION
  }

  berlin_station_inv = {
    image = "ui/berlin_station_03.avif"
    locId = "lobbies/berlin_station_inv"
  }

  berlin_station_inv_counter = {
    image = "ui/berlin_station_02.avif"
    locId = "lobbies/berlin_station_inv_counter"
  }

  berlin_river_inv = {
    image = "ui/berlin_river_crossing_01.avif"
    locId = "lobbies/berlin_river_inv"
	army = MissionArmy.ALLIES
  }

  berlin_river_inv_axis = {
    image = "ui/berlin_river_crossing_01.avif"
    locId = "lobbies/berlin_river_inv_axis"
	army = MissionArmy.AXIS
  }

  berlin_station_bomb = {
    image = "ui/berlin_station_04.avif"
    locId = "lobbies/berlin_station_bomb"
    type = MissionType.DESTRUCTION
    army = MissionArmy.ALLIES
  }

  berlin_station_bomb_axis = {
    image = "ui/berlin_station_04.avif"
    locId = "lobbies/berlin_station_bomb_axis"
    type = MissionType.DESTRUCTION
    army = MissionArmy.AXIS
  }

  berlin_village_escort_allies = {
    image = "ui/berlin_escort_01.avif"
    locId = "lobbies/berlin_village_escort_allies"
    type = MissionType.ESCORT
    army = MissionArmy.ALLIES
  }

  berlin_village_escort = {
    image = "ui/berlin_escort_01.avif"
    locId = "lobbies/berlin_village_escort_axis"
    type = MissionType.ESCORT
    army = MissionArmy.AXIS
  }

  berlin_railway_escort_allies = {
    image = "ui/berlin_escort_05.avif"
    locId = "lobbies/berlin_railway_escort_allies"
    type = MissionType.ESCORT
    army = MissionArmy.ALLIES
  }

  berlin_railway_escort = {
    image = "ui/berlin_escort_05.avif"
    locId = "lobbies/berlin_railway_escort_axis"
    type = MissionType.ESCORT
    army = MissionArmy.AXIS
  }

  berlin_bridge_escort_allies = {
    image = "ui/berlin_escort_07.avif"
    locId = "lobbies/berlin_bridge_escort_allies"
    type = MissionType.ESCORT
    army = MissionArmy.ALLIES
  }

  berlin_bridge_escort = {
    image = "ui/berlin_escort_07.avif"
    locId = "lobbies/berlin_bridge_escort_axis"
    type = MissionType.ESCORT
    army = MissionArmy.AXIS
  }

  berlin_bridge_inv = {
    image = "ui/berlin_bridge_inv_03.avif"
    locId = "lobbies/berlin_bridge_inv"
    army = MissionArmy.ALLIES
  }

  berlin_bridge_inv_axis = {
    image = "ui/berlin_bridge_inv_03.avif"
    locId = "lobbies/berlin_bridge_inv_axis"
    army = MissionArmy.AXIS
  }

  berlin_railway_conf = {
    image = "ui/berlin_railway_inv_03.avif"
    locId = "lobbies/berlin_railway_conf"
    type = MissionType.CONFRONTATION
  }

    berlin_railway_conf_axis = {
    image = "ui/berlin_railway_inv_03.avif"
    locId = "lobbies/berlin_railway_conf_axis"
    type = MissionType.CONFRONTATION
  }

  berlin_railway_inv = {
    image = "ui/berlin_railway_inv_02.avif"
    locId = "lobbies/berlin_railway_inv"
    army = MissionArmy.ALLIES
  }

  berlin_railway_inv_axis = {
    image = "ui/berlin_railway_inv_02.avif"
    locId = "lobbies/berlin_railway_inv_axis"
    army = MissionArmy.AXIS
  }

  berlin_wilhelm_dom = {
    image = "ui/berlin_wilhelm_01.avif"
    locId = "lobbies/berlin_wilhelm_dom"
    type = MissionType.DOMINATION
  }

  berlin_wilhelm_inv = {
    image = "ui/berlin_wilhelm_02.avif"
    locId = "lobbies/berlin_wilhelm_inv"
  }

  tunisia_city_bomb = {
    image = "ui/tunisia_city_inv_02.avif"
    locId = "lobbies/tunisia_city_bomb_allies"
    type = MissionType.DESTRUCTION
    army = MissionArmy.ALLIES
  }

  tunisia_city_bomb_axis = {
    image = "ui/tunisia_city_inv_02.avif"
    locId = "lobbies/tunisia_city_bomb_axis"
    type = MissionType.DESTRUCTION
    army = MissionArmy.AXIS
  }

  tunisia_city_dom = {
    image = "ui/tunisia_farm_inv_01.avif"
    locId = "lobbies/tunisia_city_dom"
    type = MissionType.DOMINATION
  }

  tunisia_city_conf = {
    image = "ui/tunisia_city_inv_03.avif"
    locId = "lobbies/tunisia_city_conf_allies"
    type = MissionType.CONFRONTATION
  }

  tunisia_city_conf_axis = {
    image = "ui/tunisia_city_inv_03.avif"
    locId = "lobbies/tunisia_city_conf_axis"
    type = MissionType.CONFRONTATION
  }

  tunisia_cave_conf = {
    image = "ui/tunisia_cave_inv_03.avif"
    locId = "lobbies/tunisia_cave_conf"
    type = MissionType.CONFRONTATION
  }

  tunisia_cave_conf_axis = {
    image = "ui/tunisia_cave_inv_03.avif"
    locId = "lobbies/tunisia_cave_conf_axis"
    type = MissionType.CONFRONTATION
  }

  tunisia_cave_inv = {
    image = "ui/tunisia_cave_inv_01.avif"
    locId = "lobbies/tunisia_cave_inv_allies"
    army = MissionArmy.ALLIES
  }

  tunisia_cave_inv_axis = {
    image = "ui/tunisia_cave_inv_01.avif"
    locId = "lobbies/tunisia_cave_inv_axis"
    army = MissionArmy.AXIS
  }

  tunisia_city_inv = {
    image = "ui/tunisia_city_inv_01.avif"
    locId = "lobbies/tunisia_city_inv_allies"
    army = MissionArmy.ALLIES
  }

  tunisia_city_inv_axis = {
    image = "ui/tunisia_city_inv_01.avif"
    locId = "lobbies/tunisia_city_inv_axis"
    army = MissionArmy.AXIS
  }

  tunisia_city_inv_counter = {
    image = "ui/tunisia_city_inv_02.avif"
    locId = "lobbies/tunisia_city_inv_counter"
    army = MissionArmy.ALLIES
  }

  tunisia_city_inv_counter_axis = {
    image = "ui/tunisia_city_inv_02.avif"
    locId = "lobbies/tunisia_city_inv_counter_axis"
    army = MissionArmy.AXIS
  }

  tunisia_farm_bomb = {
    image = "ui/tunisia_farm_inv_03.avif"
    locId = "lobbies/tunisia_farm_bomb_allies"
    type = MissionType.DESTRUCTION
    army = MissionArmy.ALLIES
  }

  tunisia_farm_bomb_axis = {
    image = "ui/tunisia_farm_inv_03.avif"
    locId = "lobbies/tunisia_farm_bomb_axis"
    type = MissionType.DESTRUCTION
    army = MissionArmy.AXIS
  }

  tunisia_farm_inv = {
    image = "ui/tunisia_farm_inv_01.avif"
    locId = "lobbies/tunisia_farm_inv_allies"
    army = MissionArmy.ALLIES
  }

  tunisia_farm_inv_axis = {
    image = "ui/tunisia_farm_inv_01.avif"
    locId = "lobbies/tunisia_farm_inv_axis"
    army = MissionArmy.AXIS
  }

  tunisia_farm_inv_counter = {
    image = "ui/tunisia_farm_inv_02.avif"
    locId = "lobbies/tunisia_farm_inv_counter_allies"
    army = MissionArmy.ALLIES
  }

  tunisia_farm_inv_counter_axis = {
    image = "ui/tunisia_farm_inv_02.avif"
    locId = "lobbies/tunisia_farm_inv_counter_axis"
    army = MissionArmy.AXIS
  }

  tunisia_farm_conf = {
    image = "ui/tunisia_farm_inv_04.avif"
    locId = "lobbies/tunisia_farm_conf"
    type = MissionType.CONFRONTATION
  }

  tunisia_farm_conf_axis = {
    image = "ui/tunisia_farm_inv_04.avif"
    locId = "lobbies/tunisia_farm_conf_axis"
    type = MissionType.CONFRONTATION
  }

  tunisia_fortress_inv = {
    image = "ui/tunisia_fortress_inv_02.avif"
    locId = "lobbies/tunisia_fortress_inv_allies"
    army = MissionArmy.ALLIES
  }

  tunisia_fortress_inv_axis = {
    image = "ui/tunisia_fortress_inv_02.avif"
    locId = "lobbies/tunisia_fortress_inv_axis"
    army = MissionArmy.AXIS
  }

  tunisia_gorge_bomb = {
    image = "ui/tunisia_gorge_inv_01.avif"
    locId = "lobbies/tunisia_gorge_bomb_allies"
    type = MissionType.DESTRUCTION
    army = MissionArmy.ALLIES
  }

  tunisia_gorge_bomb_axis = {
    image = "ui/tunisia_gorge_inv_01.avif"
    locId = "lobbies/tunisia_gorge_bomb_axis"
    type = MissionType.DESTRUCTION
    army = MissionArmy.AXIS
  }

  tunisia_gorge_inv = {
    image = "ui/tunisia_gorge_inv_02.avif"
    locId = "lobbies/tunisia_gorge_inv_allies"
    army = MissionArmy.ALLIES
  }

  tunisia_gorge_inv_axis = {
    image = "ui/tunisia_gorge_inv_02.avif"
    locId = "lobbies/tunisia_gorge_inv_axis"
    army = MissionArmy.AXIS
  }

  tunisia_gorge_inv_counter = {
    image = "ui/tunisia_gorge_inv_03.avif"
    locId = "lobbies/tunisia_gorge_inv_counter_allies"
    army = MissionArmy.ALLIES
  }

  tunisia_gorge_inv_counter_axis = {
    image = "ui/tunisia_gorge_inv_03.avif"
    locId = "lobbies/tunisia_gorge_inv_counter_axis"
    army = MissionArmy.AXIS
  }

  tunisia_oasis_inv = {
    image = "ui/Tunisia_Oasis_Inv_01.avif"
    locId = "lobbies/tunisia_oasis_inv_allies"
    army = MissionArmy.ALLIES
  }

  tunisia_oasis_inv_axis = {
    image = "ui/Tunisia_Oasis_Inv_01.avif"
    locId = "lobbies/tunisia_oasis_inv_axis"
    army = MissionArmy.AXIS
  }

  tunisia_oasis_inv_counter = {
    image = "ui/Tunisia_Oasis_Inv_02.avif"
    locId = "lobbies/tunisia_oasis_inv_counter"
    army = MissionArmy.ALLIES
  }

  tunisia_oasis_inv_counter_axis = {
    image = "ui/Tunisia_Oasis_Inv_02.avif"
    locId = "lobbies/tunisia_oasis_inv_counter_axis"
    army = MissionArmy.AXIS
  }

  tunisia_oasis_dom = {
    image = "ui/Tunisia_Oasis_Inv_03.avif"
    locId = "lobbies/tunisia_oasis_dom"
    type = MissionType.DOMINATION
  }

  stalingrad_gogol_inv = {
    image = "ui/stalingrad_inv_02.avif"
    locId = "lobbies/stalingrad_gogol_inv"
    army = MissionArmy.AXIS
  }

  stalingrad_gogol_inv_allies = {
    image = "ui/stalingrad_inv_02.avif"
    locId = "lobbies/stalingrad_gogol_inv_allies"
    army = MissionArmy.ALLIES
  }

  stalingrad_gogol_inv_counter = {
    image = "ui/stalingrad_inv_11.avif"
    locId = "lobbies/stalingrad_gogol_inv_counter"
    army = MissionArmy.ALLIES
  }

  stalingrad_gogol_inv_counter_axis = {
    image = "ui/stalingrad_inv_11.avif"
    locId = "lobbies/stalingrad_gogol_inv_counter_axis"
    army = MissionArmy.AXIS
  }

  stalingrad_gogol_conf = {
    image = "ui/stalingrad_inv_12.avif"
    locId = "lobbies/stalingrad_gogol_conf_axis"
    type = MissionType.CONFRONTATION
  }

  stalingrad_gogol_conf_allies = {
    image = "ui/stalingrad_inv_12.avif"
    locId = "lobbies/stalingrad_gogol_conf_allies"
    type = MissionType.CONFRONTATION
  }

  stalingrad_univermag_inv = {
    image = "ui/stalingrad_inv_04.avif"
    locId = "lobbies/stalingrad_univermag_inv_allies"
    army = MissionArmy.ALLIES
  }

  stalingrad_univermag_inv_axis = {
    image = "ui/stalingrad_inv_04.avif"
    locId = "lobbies/stalingrad_univermag_inv_axis"
    army = MissionArmy.AXIS
  }

  stalingrad_univermag_conf = {
    image = "ui/stalingrad_inv_06.avif"
    locId = "lobbies/stalingrad_univermag_conf"
    type = MissionType.CONFRONTATION
  }

  stalingrad_univermag_conf_axis = {
    image = "ui/stalingrad_inv_06.avif"
    locId = "lobbies/stalingrad_univermag_conf_axis"
    type = MissionType.CONFRONTATION
  }

  stalingrad_univermag_inv_counter = {
    image = "ui/stalingrad_inv_01.avif"
    locId = "lobbies/stalingrad_univermag_inv_counter_axis"
    army = MissionArmy.AXIS
  }

  stalingrad_univermag_inv_counter_allies = {
    image = "ui/stalingrad_inv_01.avif"
    locId = "lobbies/stalingrad_univermag_inv_counter_allies"
    army = MissionArmy.ALLIES
  }

  stalingrad_communist_inv = {
    image = "ui/stalingrad_inv_09.avif"
    locId = "lobbies/stalingrad_communist_inv"
    army = MissionArmy.AXIS
  }

  stalingrad_communist_inv_allies = {
    image = "ui/stalingrad_inv_09.avif"
    locId = "lobbies/stalingrad_communist_inv_allies"
    army = MissionArmy.ALLIES
  }

  stalingrad_communist_inv_counter = {
    image = "ui/stalingrad_inv_10.avif"
    locId = "lobbies/stalingrad_communist_inv_counter"
    army = MissionArmy.ALLIES
  }

  stalingrad_communist_inv_counter_axis = {
    image = "ui/stalingrad_inv_10.avif"
    locId = "lobbies/stalingrad_communist_inv_counter_axis"
    army = MissionArmy.AXIS
  }

  stalingrad_communist_bomb = {
    image = "ui/stalingrad_inv_03.avif"
    locId = "lobbies/stalingrad_communist_bomb"
    type = MissionType.DESTRUCTION
    army = MissionArmy.AXIS
  }

  stalingrad_communist_bomb_allies = {
    image = "ui/stalingrad_inv_03.avif"
    locId = "lobbies/stalingrad_communist_bomb_allies"
    type = MissionType.DESTRUCTION
    army = MissionArmy.ALLIES
  }

  stalingrad_communist_conf = {
    image = "ui/stalingrad_inv_08.avif"
    locId = "lobbies/stalingrad_communist_conf"
    type = MissionType.CONFRONTATION
  }

  stalingrad_communist_conf_allies = {
    image = "ui/stalingrad_inv_08.avif"
    locId = "lobbies/stalingrad_communist_conf_allies"
    type = MissionType.CONFRONTATION
  }

  stalingrad_entrance_inv = {
    image = "ui/stalingrad_tractor_plant_04.avif"
    locId = "lobbies/stalingrad_entrance_inv"
    army = MissionArmy.AXIS
  }

  stalingrad_entrance_inv_allies = {
    image = "ui/stalingrad_tractor_plant_04.avif"
    locId = "lobbies/stalingrad_entrance_inv_allies"
    army = MissionArmy.ALLIES
  }

  stalingrad_entrance_inv_counter = {
    image = "ui/stalingrad_tractor_plant_07.avif"
    locId = "lobbies/stalingrad_entrance_inv_counter"
    army = MissionArmy.AXIS
  }

  stalingrad_entrance_inv_counter_allies = {
    image = "ui/stalingrad_tractor_plant_07.avif"
    locId = "lobbies/stalingrad_entrance_inv_counter_allies"
    army = MissionArmy.ALLIES
  }

  stalingrad_entrance_conf = {
    image = "ui/stalingrad_tractor_plant_02.avif"
    locId = "lobbies/stalingrad_entrance_conf"
    type = MissionType.CONFRONTATION
    army = MissionArmy.AXIS
  }

  stalingrad_entrance_conf_allies = {
    image = "ui/stalingrad_tractor_plant_02.avif"
    locId = "lobbies/stalingrad_entrance_conf_allies"
    type = MissionType.CONFRONTATION
    army = MissionArmy.ALLIES
  }

  stalingrad_entrance_bomb = {
    image = "ui/stalingrad_tractor_plant_03.avif"
    locId = "lobbies/stalingrad_entrance_bomb"
    type = MissionType.DESTRUCTION
    army = MissionArmy.AXIS
  }

  stalingrad_entrance_bomb_allies = {
    image = "ui/stalingrad_tractor_plant_03.avif"
    locId = "lobbies/stalingrad_entrance_bomb_allies"
    type = MissionType.DESTRUCTION
    army = MissionArmy.ALLIES
  }

  stalingrad_entrance_bomb_counter = {
    image = "ui/stalingrad_tractor_plant_08.avif"
    locId = "lobbies/stalingrad_entrance_bomb_counter"
    type = MissionType.DESTRUCTION
    army = MissionArmy.AXIS
  }

  stalingrad_entrance_bomb_counter_allies = {
    image = "ui/stalingrad_tractor_plant_08.avif"
    locId = "lobbies/stalingrad_entrance_bomb_counter_allies"
    type = MissionType.DESTRUCTION
    army = MissionArmy.ALLIES
  }

  stalingrad_entrance_dom = {
    image = "ui/stalingrad_tractor_plant_01.avif"
    locId = "lobbies/stalingrad_entrance_dom"
    type = MissionType.DOMINATION
  }

  stalingrad_station_dom = {
    image = "ui/stalingrad_inv_05.avif"
    locId = "lobbies/stalingrad_station_dom"
    type = MissionType.DOMINATION
  }

  pacific_gavutu_inv = {
    image = "ui/pacific_gavutu_inv_04.avif"
    locId = "lobbies/pacific_gavutu_inv"
    army = MissionArmy.ALLIES
  }

  pacific_gavutu_inv_axis = {
    image = "ui/pacific_gavutu_inv_04.avif"
    locId = "lobbies/pacific_gavutu_inv_axis"
    army = MissionArmy.AXIS
  }

  pacific_gavutu_inv_counter = {
    image = "ui/pacific_gavutu_inv_03.avif"
    locId = "lobbies/pacific_gavutu_inv_counter"
    army = MissionArmy.ALLIES
  }

  pacific_gavutu_inv_counter_axis = {
    image = "ui/pacific_gavutu_inv_03.avif"
    locId = "lobbies/pacific_gavutu_inv_counter_axis"
    army = MissionArmy.AXIS
  }

  pacific_gavutu_bomb_aerodrome = {
    image = "ui/pacific_gavutu_inv_07.avif"
    locId = "lobbies/pacific_gavutu_bomb_aerodrome"
    type = MissionType.DESTRUCTION
    army = MissionArmy.ALLIES
  }

  pacific_gavutu_bomb = {
    image = "ui/pacific_gavutu_inv_01.avif"
    locId = "lobbies/pacific_gavutu_bomb"
    type = MissionType.DESTRUCTION
    army = MissionArmy.ALLIES
  }

  pacific_gavutu_bomb_axis = {
    image = "ui/pacific_gavutu_inv_01.avif"
    locId = "lobbies/pacific_gavutu_bomb_axis"
    type = MissionType.DESTRUCTION
    army = MissionArmy.AXIS
  }

  pacific_gavutu_conf = {
    image = "ui/pacific_gavutu_inv_02.avif"
    locId = "lobbies/pacific_gavutu_conf"
    type = MissionType.CONFRONTATION
    army = MissionArmy.ALLIES
  }

  pacific_gavutu_conf_axis = {
    image = "ui/pacific_gavutu_inv_02.avif"
    locId = "lobbies/pacific_gavutu_conf_axis"
    type = MissionType.CONFRONTATION
    army = MissionArmy.AXIS
  }

  pacific_gavutu_dom = {
    image = "ui/pacific_gavutu_inv_01.avif"
    locId = "lobbies/pacific_gavutu_dom"
    type = MissionType.DOMINATION
  }

  pacific_guadalcanal_inv = {
    image = "ui/pacific_guadalcanal_inv_08.avif"
    locId = "lobbies/pacific_guadalcanal_inv"
    army = MissionArmy.ALLIES
  }

  pacific_guadalcanal_inv_axis = {
    image = "ui/pacific_guadalcanal_inv_08.avif"
    locId = "lobbies/pacific_guadalcanal_inv_axis"
    army = MissionArmy.AXIS
  }

  pacific_guadalcanal_inv_counter = {
    image = "ui/pacific_guadalcanal_inv_09.avif"
    locId = "lobbies/pacific_guadalcanal_inv_counter"
    army = MissionArmy.ALLIES
  }

  pacific_guadalcanal_inv_counter_axis = {
    image = "ui/pacific_guadalcanal_inv_09.avif"
    locId = "lobbies/pacific_guadalcanal_inv_counter_axis"
    army = MissionArmy.AXIS
  }

  pacific_guadalcanal_conf = {
    image = "ui/pacific_guadalcanal_inv_11.avif"
    locId = "lobbies/pacific_guadalcanal_conf"
    type = MissionType.CONFRONTATION
    army = MissionArmy.ALLIES
  }

  pacific_guadalcanal_conf_axis = {
    image = "ui/pacific_guadalcanal_inv_11.avif"
    locId = "lobbies/pacific_guadalcanal_conf_axis"
    type = MissionType.CONFRONTATION
    army = MissionArmy.AXIS
  }

  pacific_vertical_inv = {
    image = "ui/pacific_guadalcanal_inv_07.avif"
    locId = "lobbies/pacific_vertical_inv"
    army = MissionArmy.ALLIES
  }

  pacific_vertical_inv_counter = {
    image = "ui/pacific_guadalcanal_inv_13.avif"
    locId = "lobbies/pacific_vertical_inv_counter"
    army = MissionArmy.AXIS
  }

  pacific_native_inv = {
    image = "ui/pacific_guadalcanal_inv_06.avif"
    locId = "lobbies/pacific_native_inv"
    army = MissionArmy.ALLIES
  }

  pacific_native_inv_axis = {
    image = "ui/pacific_guadalcanal_inv_06.avif"
    locId = "lobbies/pacific_native_inv_axis"
    army = MissionArmy.AXIS
  }

}
  .map(mkMission)

let getImagesFromMissions = @() missions.values()
  .filter(@(v) v.image != null)
  .map(@(v) v.image)

  let getMissionPresentation = @(id) missions?[id]
  // FIXME better not use overrides by ids; instead all necessary mission types should be described
  ?? missions.reduce(@(res, m)
    id.startswith(m.id) && (res?.id.len() ?? 0) < m.id.len() ? m : res, null)
  ?? mkMission({}, id)

return {
  getMissionPresentation
  getImagesFromMissions
}