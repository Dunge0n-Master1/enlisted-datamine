let entity_editor = require_optional("entity_editor")

let function initTemplatesGroups(for_debug) {
  if (entity_editor == null)
    return

  let {clear_groups, add_group_require, add_group_variant, add_group_variext, get_ecs_tags} = entity_editor
  clear_groups()

  add_group_variant("Mission respawns", "respbase")
  add_group_variext("Mission respawns", "respbase", "respawnChooser+")
  add_group_variant("Mission respawns", "@spawnMode")

  add_group_variant("Mission objective zones", "capzone")
  add_group_variext("Mission objective zones", "capzone", "+defend_zone_respawnbase")
  add_group_variext("Mission objective zones", "capzone", "+separate_cap_decap_time+lockable_capzone")
  add_group_variant("Mission objective zones", "capzone_area_polygon_point__*")

  add_group_variant("Mission supplies", "resupplyZone")

  add_group_variant("Mission battle area", "battle_area")
  add_group_variant("Mission battle area", "battle_area_polygon_point__*")

  add_group_variext("Mission teams", "teamTag", "+respawn_creators_team")
  add_group_variant("Mission teams", "isTeamsSwitched")
  add_group_variant("Mission teams", "briefing")
  add_group_variant("Mission teams", "activator__activateChoice")
  add_group_variant("Mission teams", "activator__activateBidirectionalChoice")
  add_group_variant("Mission teams", "enemy_attack_marker")

  add_group_require("Aircrafts", "airplane")
  add_group_require("Aircrafts", "vehicle_seats__seats")
  add_group_require("Aircrafts", "transform")
  add_group_require("Aircrafts", "animchar__res")

  add_group_require("Tanks", "isTank")
  add_group_require("Tanks", "vehicle_seats__seats")
  add_group_require("Tanks", "transform")
  add_group_require("Tanks", "animchar__res")

  add_group_require("Other vehicles", "vehicle")
  add_group_require("Other vehicles", "vehicle_seats__seats")
  add_group_require("Other vehicles", "transform")
  add_group_require("Other vehicles", "animchar__res")
  add_group_require("Other vehicles", "!airplane")
  add_group_require("Other vehicles", "!isTank")

  add_group_require("Weapons", "collres__res")
  add_group_require("Weapons", "animchar__res")
  add_group_variext("Weapons", "?item__lootType=gun", "+item_in_world")
  add_group_variext("Weapons", "?item__lootType=magazine", "+item_in_world")
  add_group_variext("Weapons", "?item__weapType=melee", "+item_in_world")

  add_group_require("Equipment", "collres__res")
  add_group_require("Equipment", "animchar__res")
  add_group_require("Equipment", "!gun_attach*")
  add_group_require("Equipment", "!gun__blk")
  add_group_require("Equipment", "!shell__active")
  add_group_require("Equipment", "!?slot_attach__slotName=r_hand")
  add_group_variext("Equipment", "slot_attach*", "+item_in_world")

  add_group_require("Other items", "collres__res")
  add_group_require("Other items", "animchar__res")
  add_group_require("Other items", "!item__weapTemplate")
  add_group_require("Other items", "!slot_attach*")
  add_group_require("Other items", "!?item__lootType=gun")
  add_group_require("Other items", "!?item__lootType=magazine")
  add_group_require("Other items", "!?item__weapType=melee")
  add_group_require("Other items", "!vehicle")
  add_group_variext("Other items", "item__*", "+item_in_world")

  add_group_variext("Soldiers", "human", "+ai_enabled")

  add_group_variant("RendInsts", "@gameRendInstTag")
  add_group_variant("RendInsts", "@unbakedRendInstTag")
  add_group_variant("RendInsts", "scenery_remove__*")
  add_group_variant("RendInsts", "ladder__sceneIndex")

  add_group_variant("Effects", "ri_gpu_object__*")
  add_group_variant("Effects", "gpu_object_placer__*")
  add_group_variant("Effects", "effect__*")
  add_group_variant("Effects", "light__*")
  add_group_variant("Effects", "spot_light__*")
  add_group_variant("Effects", "effect_area__*")
  add_group_variant("Effects", "globe__*")
  add_group_variant("Effects", "tracer_launcher__*")
  add_group_variant("Effects", "sound_effect_2d__path")

  add_group_variant("Level", "level__loaded") // DO NOT REMOVE
  add_group_variant("Level", "water__*")
  add_group_variant("Level", "wind__*")
  add_group_variant("Level", "far_rain__*")
  add_group_variant("Level", "snow__*")
  add_group_variant("Level", "projector__*")
  add_group_variant("Level", "projectors_manager__*")
  add_group_variant("Level", "clouds_hole_tag")
  add_group_variant("Level", "ground_effect__*")
  add_group_variant("Level", "ambient_sound")
  add_group_variant("Level", "@initialCamTag")
  add_group_variant("Level", "respawnCameraForTeam")

  add_group_variant("Shaders", "shader_vars__vars")
  add_group_variant("Shaders", "tonemapper")
  add_group_variant("Shaders", "postfxRoundctrlTag")


  //add_group_require("All fit",    "~fitprev")
  //add_group_require("All unfit", "!~fitprev")
  //
  //add_group_require("All unfit(*)", "!~fitprev")
  //add_group_require("All unfit(*)", "!cockpitEntity")
  //add_group_require("All unfit(*)", "!plane_wreckage")
  //add_group_require("All unfit(*)", "!on_create__spawnActivatedShellBlk")
  //add_group_require("All unfit(*)", "!weaponMod")
  //add_group_require("All unfit(*)", "!gun")
  //add_group_require("All unfit(*)", "!human_sound__*")
  //add_group_require("All unfit(*)", "!ammo_holder__*")
  //add_group_require("All unfit(*)", "!ammo_cluster__*")
  //add_group_require("All unfit(*)", "!ammo_stowage__*")
  //add_group_require("All unfit(*)", "!shell__active")
  //add_group_require("All unfit(*)", "!skin__objTexReplace")

  //if (for_debug) {
  //  add_group_require("All tagged", "~hastags")
  //  add_group_require("All non-tagged", "!~hastags")
  //
  //  add_group_require("All placeable singletons", "~singleton")
  //  add_group_require("All placeable singletons", "transform")
  //
  //  add_group_require("All non-placeable", "!~singleton")
  //  add_group_require("All non-placeable", "!transform")
  //}

  add_group_require("All placeable", "!~singleton")
  add_group_require("All placeable", "transform")
  add_group_require("All singletons", "~singleton")
  add_group_require("All", "")

  if (for_debug) {
    //add_group_require("All nonCreatableObj", "~noncreatable")

    //add_group_require("All AnimChar+CollRes", "animchar__res")
    //add_group_require("All AnimChar+CollRes", "collres__res")
    //add_group_require("All AnimChar", "animchar__res")
    //add_group_require("All CollRes", "collres__res")

    //add_group_require("(incomplete) RendInsts", "!transform")
    //add_group_variant("(incomplete) RendInsts", "ri_extra__name")

    //add_group_require("(incomplete) Items", "item__*")
    //add_group_require("(incomplete) Items", "!vehicle")
    //add_group_variant("(incomplete) Items", "!animchar__res")
    ////add_group_variant("(incomplete) Items", "!collres__res") <-- not always present

    //add_group_require("(incomplete) Vehicles", "vehicle")
    //add_group_variant("(incomplete) Vehicles", "!transform")
    //add_group_variant("(incomplete) Vehicles", "!animchar__res")
  }

  if (for_debug) {
    let tags = get_ecs_tags()
    foreach (tag in tags)
      add_group_require($"({tag})", $"{tag}")
  }
}

return {
  initTemplatesGroups
}
