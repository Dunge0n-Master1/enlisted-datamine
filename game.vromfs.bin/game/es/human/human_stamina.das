require ecs
require HumanPhys
require EnlistedHuman

[es(track=entity_mods__staminaBoostMult, on_appear)]
def entity_stamina_boost_mult_applier(evt : Event;
                                      var human_net_phys : HumanActor;
                                      entity_mods__staminaBoostMult : float)
  human_net_phys.phys.currentState.staminaBoostMult = entity_mods__staminaBoostMult

[es(after=entity_stamina_boost_mult_applier, on_appear, REQUIRE=entity_mods__staminaBoostMult)]
def human_update_stamina_on_spawn(evt : Event;
                                  var human_net_phys : HumanActor)
  human_phys_state_reset_stamina(human_net_phys.phys.currentState, human_net_phys.phys.maxStamina)

[es(tag=server, after=human_phys_es, before=after_net_phys_sync)]
def human_apply_stamina_regen_affect_server(evt : UpdateStageInfoAct; game_effect__attachedTo : EntityId; stamina_regen__amount : float)
  query(game_effect__attachedTo) <| $ [es] (var human_net_phys : HumanActor)
    assume cs = human_net_phys.phys.currentState
    let maxStamina = human_net_phys.phys.maxStamina * cs.maxStaminaMult * cs.staminaBoostMult

    cs.stamina = min(cs.stamina + stamina_regen__amount * evt.dt, maxStamina)

[es(tag=netClient, after=human_phys_es, before=after_net_phys_sync)]
def human_apply_stamina_regen_affect_client(evt : UpdateStageInfoAct; game_effect__attachedTo : EntityId; stamina_regen__amount : float)
  query(game_effect__attachedTo) <| $ [es(REQUIRE=hero)] (var human_net_phys : HumanActor)
    assume cs = human_net_phys.phys.currentState
    let maxStamina = human_net_phys.phys.maxStamina * cs.maxStaminaMult * cs.staminaBoostMult

    cs.stamina = min(cs.stamina + stamina_regen__amount * evt.dt, maxStamina)
