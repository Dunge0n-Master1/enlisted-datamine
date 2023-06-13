require ecs
require math.base
require HumanPhys
require DngHuman
require game.es.events
require enlisted.events_enlisted

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

def breath_shortness_block_stamina_restoration(var human_net_phys : HumanActor&)
  assume currentState = human_net_phys.phys.currentState
  if currentState.breathShortness > 0.
    currentState.restoreStaminaMult = 0.0

[es(tag=netClient, REQUIRE=hero, after=entity_restore_stamina_mult_applier_es, before=before_net_phys_sync)]
def breath_shortness_block_stamina_restoration_local(info : ParallelUpdateFrameDelayed;
                                                     var human_net_phys : HumanActor&)
  breath_shortness_block_stamina_restoration(human_net_phys)

[es(tag=server, after=entity_restore_stamina_mult_applier_es, before=before_net_phys_sync)]
def breath_shortness_block_stamina_restoration_server(info : ParallelUpdateFrameDelayed;
                                                      var human_net_phys : HumanActor&)
  breath_shortness_block_stamina_restoration(human_net_phys)
