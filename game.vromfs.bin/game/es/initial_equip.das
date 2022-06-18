require ecs
require ecs.common
require game.es.events

[es(tag=server)]
def remove_initial_equip_eid_from_list(evt : CmdEquipItemDirect; var human_equipment__initialEquipEids : EidList)
  let idx = human_equipment__initialEquipEids |> find_index(evt.itemEid)
  if idx >= 0
    human_equipment__initialEquipEids |> erase(idx)

[es(tag=server, on_disappear)]
def remove_initial_equip_without_parent(evt : Event; eid : EntityId; human_equipment__initialEquipEids : EidList)
  for equipEid in human_equipment__initialEquipEids
    print("{eid}: cleanup unattached equip {equipEid}")
    destroyEntity(equipEid)
