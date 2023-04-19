require ecs
require ecs.safe
require game.es.events

[es(tag=server, on_appear, REQUIRE=(hasParachute, parachuteDeployed))]
def replace_equipment_on_parachute_open(evt : Event; eid : EntityId; human_equipment__slots : Object)
  for it in human_equipment__slots
    let slot = it.key
    let item = (it.value as Object)?.item ?? INVALID_ENTITY_ID
    query(item) <| $ [es] (item__replaceOnParachuteOpen : string; var parachute_backpack__canopyEid : EntityId?)
      if empty(item__replaceOnParachuteOpen)
        return
      let finalizeCreation <- @ <| (itemEid : EntityId)
        sendEventImmediate(eid, [[CmdEquipItemDirect itemEid=itemEid, slot=slot, allowReorderSlots=false, dropPrevItem=true]])
        destroyEntity(item)

      createEntity(item__replaceOnParachuteOpen, finalizeCreation) <| $ [unused_argument(init)] (var init)
        if parachute_backpack__canopyEid != null
          init |> set("parachute_backpack__canopyEid", *parachute_backpack__canopyEid)
          *parachute_backpack__canopyEid = INVALID_ENTITY_ID

[es(tag=server, on_disappear, REQUIRE=(hasParachute, parachuteDeployed))]
def remove_equipment_on_parachute_landing(evt : Event; var human_equipment__slots : Object&)
  for it in human_equipment__slots
    let item = (it.value as Object)?.item ?? INVALID_ENTITY_ID
    if item |> has("item__unequipAfterParachuteLanding")
      var slotObj = it.value as Object
      if slotObj != null
        *slotObj |> set("item", INVALID_ENTITY_ID)
      destroyEntity(item)
