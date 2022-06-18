require ecs
require math.base
require HumanPhys
require EnlistedHuman
require game.es.events

require DagorConsole

[es(tag=input, after=human_input_es, before=before_net_phys_sync)]
def check_hold_breath_stamina_therhold_es(evt : UpdateStageUpdateInput;
                                          human_net_phys__minStaminaLevelToHoldBreath : float;
                                          var human_net_phys : HumanActor)
  let stamina = human_net_phys.phys.currentState.stamina
  let maxStamina = human_net_phys.phys.maxStamina
  let staminaLevel = clamp(safediv(stamina, maxStamina), 0., 1.)
  let isSprinting = (int(human_net_phys.phys.currentState.states) & int(StateFlag ST_SPRINT)) != 0
  let isHoldBreath = (is_control_bit_set(human_net_phys.phys.producedCT, HumanPhysControlType HCT_AIM) &&
                      is_control_bit_set(human_net_phys.phys.producedCT, HumanPhysControlType HCT_SPRINT))
  if (staminaLevel < human_net_phys__minStaminaLevelToHoldBreath &&
      isHoldBreath &&
      !isSprinting &&
      !is_hold_breath(human_net_phys.phys.currentState))
    human_control_state_set_control_bit(human_net_phys.phys.producedCT, HumanPhysControlType HCT_SPRINT, false)
    return

[es(after=human_phys_es, before=after_net_phys_sync)]
def drain_stamina_on_breath_hold_es(evt : CmdPostPhysUpdate;
                                    var human_net_phys : HumanActor;
                                    human_net_phys__drainStaminaSpeedOnHoldBreath : float)
  let stamina = human_net_phys.phys.currentState.stamina
  if is_hold_breath(human_net_phys.phys.currentState)
    human_net_phys.phys.currentState.stamina = max(stamina - human_net_phys__drainStaminaSpeedOnHoldBreath * evt.dt, 0.f)
    if human_net_phys.phys.currentState.stamina <= 0.f
      set_is_hold_breath(human_net_phys.phys.currentState, false)
      human_net_phys.phys.currentState.breathShortness = 1.

[es(after=human_phys_es, before=after_net_phys_sync, REQUIRE=drainBreathOnLowStamina)]
def drain_breath_on_low_stamina_hold_es(evt : CmdPostPhysUpdate; var human_net_phys : HumanActor)
  let wasStamina = human_net_phys.phys.previousState.stamina

  assume stamina = human_net_phys.phys.currentState.stamina
  assume breathShortness = human_net_phys.phys.currentState.breathShortness
  if wasStamina > 0. && stamina <= 0. && breathShortness <= 0.
    breathShortness = 1.
    stamina = 0.
