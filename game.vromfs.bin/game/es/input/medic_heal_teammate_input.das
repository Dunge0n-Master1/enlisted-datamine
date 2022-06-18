require ecs
require DagorInput
require game.es.human.human_use_object_common


[es(tag=gameClient, REQUIRE=hero, REQUIRE_NOT=deadEntity, track=(human_use_object__selectedObject, medic__canHealSelectedSoldier), after=hero_medic_select_damaged_human_es)]
def heal_teammate_input(evt : Event;
                        eid : EntityId;
                        transform : float3x4;
                        human_input__use : int;
                        medic__canHealSelectedSoldier : bool;
                        human_inventory__entityUseEnd : float;
                        human_use_object__thresholdDist : float;
                        human_use_object__selectedObject : EntityId)
  if human_use_object__selectedObject == INVALID_ENTITY_ID || human_inventory__entityUseEnd > 0.0
    return

  if !medic__canHealSelectedSoldier && !(get_bool(human_use_object__selectedObject, "isDowned") ?? false)
    return

  let useInputInProgress = (is_action_active(uint16(human_input__use))
                            ? get_digital_action_state(uint16(human_input__use)).bState
                            : false)

  if useInputInProgress
    human_try_use_object(eid, transform[3],
      human_use_object__thresholdDist, human_use_object__selectedObject)
