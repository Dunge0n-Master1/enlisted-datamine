require ecs
require ecs.common
require game.es.events
require common_shooter.es.human.human_parachute_common



[es(tag=server)]
def human_parachute_create_canopy(evt : CmdEquipItemDirect;
                                  eid : EntityId)
  query(evt.itemEid) <| $ [es] (parachute_backpack__canopyTemplate : string;
                                var parachute_backpack__canopyEid : EntityId&)
    if parachute_backpack__canopyTemplate != "" && !parachute_backpack__canopyEid
      parachute_backpack__canopyEid = parachute_create_for_eid(eid, parachute_backpack__canopyTemplate)


[es(tag=server, REQUIRE=eid)]
def human_parachute_unequip_backpack(evt : EventOnEquipmentUnequiped)
  let equipmentEid = evt.equipmentEid
  query(equipmentEid) <| $ [es] (var parachute_backpack__canopyEid : EntityId&)
    destroyEntity(parachute_backpack__canopyEid)
    parachute_backpack__canopyEid = INVALID_ENTITY_ID
