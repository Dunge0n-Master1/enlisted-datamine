require ecs
require game.es.input.input_events

[es(before=human_anim_es, after=human_common_input_action_triggered_es)]
def weap_disable_melee_es(evt : EventDaInputActionTriggered;
                          var human_input__wishMelee : bool&;
                          human_weap__currentGunEid : EntityId)
  human_input__wishMelee &&= !has(human_weap__currentGunEid, "disableMelee")