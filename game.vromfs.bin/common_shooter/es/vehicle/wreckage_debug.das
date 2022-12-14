options no_aot
require ecs
require dm
require DagorConsole
require game.es.events
require game.es.net_console_macro
require daslib/strings_boost

[console_cmd(name="plane_wreckage.create_all")]
def plane_wreckage_create_all()
  ecs::query() <| $ [es(REQUIRE=plane_wreckage)] (eid : EntityId)
    destroyEntity(eid)

  ecs::query() <| $ [es(REQUIRE=airplane, REQUIRE_NOT=plane_wreckage)] (eid : EntityId;
                                                                        damage_model : DamageModel;
                                                                        var plane_wreckage__createdByTemplates : ecs::BoolList;
                                                                        var plane_cutting__cutting : bool&;
                                                                        var plane_cutting__largePartsCut : ecs::BoolList)
    for wreckageCreated in plane_wreckage__createdByTemplates
      wreckageCreated = false

    plane_cutting__cutting = false

    for largePartCut in plane_cutting__largePartsCut
      largePartCut = false

    let tailPartNo = find_part_id_by_name(damage_model, "tail_dm")
    sendEventImmediate(eid, [[EventCutPart offender=INVALID_ENTITY_ID, partNo=tailPartNo]])

    let wingLPartNo = find_part_id_by_name(damage_model, "wing_l_dm")
    sendEventImmediate(eid, [[EventCutPart offender=INVALID_ENTITY_ID, partNo=wingLPartNo]])

    let wingRPartNo = find_part_id_by_name(damage_model, "wing_r_dm")
    sendEventImmediate(eid, [[EventCutPart offender=INVALID_ENTITY_ID, partNo=wingRPartNo]])

[console_processor]
def plane_cut_part_debug_cmd_processor(args : array<string>;
                                       collect : bool;
                                       var hints : ConsoleProcessorHints)
  if !collect
    return false

  let cmd = "plane.cut_part"
  let inputs <- args[0] |> split(" ")

  if length(inputs) >= 2 && inputs[0] == cmd
    query() <| $ [es(REQUIRE=heroVehicle)] (damage_model : DamageModel)
      assume parts = damage_model.dmData.parts
      for part in parts
        let partName = damagePart_getName(part)
        hints |> add_hint("{cmd} {partName}", 0, 1, "")
  return false

[net_console_cmd(name="plane.cut_part")]
def plane_cut_part_debug(part_name : string; [[net_hero]] hero_eid : EntityId)
  let plane = get_Eid(hero_eid, "human_anim__vehicleSelected") ?? INVALID_ENTITY_ID
  query(plane) <| $ [es(REQUIRE=airplane)] (eid : EntityId;
                                            damage_model : DamageModel)
    let partNo = find_part_id_by_name(damage_model, part_name)
    if partNo >= 0
      sendEventImmediate(eid, [[EventCutPart offender=INVALID_ENTITY_ID, partNo=partNo]])
