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
  query(game_effect__attachedTo) <| $ [es] (human__totalMaxStamina : float; human_stamina_regen_affect__mult : float = 1.0; var human_net_phys : HumanActor)
    assume cs = human_net_phys.phys.currentState
    cs.stamina = min(cs.stamina + stamina_regen__amount * human_stamina_regen_affect__mult * evt.dt, human__totalMaxStamina)

[es(tag=netClient, after=human_phys_es, before=after_net_phys_sync)]
def human_apply_stamina_regen_affect_client(evt : UpdateStageInfoAct; game_effect__attachedTo : EntityId; stamina_regen__amount : float)
  query(game_effect__attachedTo) <| $ [es(REQUIRE=hero)] (human__totalMaxStamina : float; human_stamina_regen_affect__mult : float = 1.0; var human_net_phys : HumanActor)
    assume cs = human_net_phys.phys.currentState
    cs.stamina = min(cs.stamina + stamina_regen__amount * human_stamina_regen_affect__mult * evt.dt, human__totalMaxStamina)

[es(on_appear, track=(human_net_phys__maxStamina, human_net_phys__maxStaminaMult, human_net_phys__staminaBoostMult))]
def human_update_total_max_stamina(evt : Event;
                                   human_net_phys__maxStamina : float;
                                   human_net_phys__maxStaminaMult : float;
                                   human_net_phys__staminaBoostMult : float;
                                   var human__totalMaxStamina : float&)
  human__totalMaxStamina = human_net_phys__maxStamina * human_net_phys__maxStaminaMult * human_net_phys__staminaBoostMult
