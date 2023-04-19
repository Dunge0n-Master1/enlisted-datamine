require ecs
require DngHuman
require HumanPhys
require game.es.events


def human_change_slots_visibility(slots; hide_slots; show : bool)
  for slotName in hide_slots
    let slotObj = slots[string(slotName)]
    if slotObj == null
      return

    let slot = get_ecs_object(slotObj)
    let itemEid = get_Eid(slot, "item") ?? INVALID_ENTITY_ID
    query(itemEid) <| $ [es] (var slot_attach__visible : bool&)
      slot_attach__visible = show

[es(REQUIRE=heroSquad, tag=render, track=possessedByPlr)]
def human_bot_unhide_slots_in_scope_es(evt : Event; human_equipment__slots : Object; human__hideSlotsInScope : StringList; possessedByPlr : EntityId)
  if !possessedByPlr
    human_change_slots_visibility(human_equipment__slots, human__hideSlotsInScope, /*show*/true)

[es(REQUIRE=heroSquad, tag=render, on_disappear)]
def human_bot_unhide_slots_on_destroy_es(evt : Event; human_equipment__slots : Object; human__hideSlotsInScope : StringList)
  human_change_slots_visibility(human_equipment__slots, human__hideSlotsInScope, /*show*/true)

[es(REQUIRE=hero, tag=render, after=human_input_es)]
def human_hide_slots_in_scope_es(info : UpdateStageInfoAct;
                                 human_net_phys : HumanActor;
                                 human_weap__currentGunModEids : EidList;
                                 human_equipment__slots : Object;
                                 human__hideSlotsInScope : StringList;
                                 human__isHidingSlotsInScopeEnabled : bool)
  var hasScope = false
  for mod in human_weap__currentGunModEids
    if has(mod, "gunScope")
      hasScope = true
      break

  let zoomPosition = human_net_phys.phys.currentState.zoomPosition
  let isAimZoom = is_control_bit_set(human_net_phys.phys.producedCT, (HumanPhysControlType HCT_ZOOM_VIEW))
  let show = !hasScope || !isAimZoom || zoomPosition < 1.0 || !human__isHidingSlotsInScopeEnabled
  human_change_slots_visibility(human_equipment__slots, human__hideSlotsInScope, show)
