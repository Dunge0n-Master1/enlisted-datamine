require ecs
require DngHuman
require game.es.events

[es]
def human_weapon_hold_breath(evt : CmdPostPhysUpdate;
                             human_hold_breath__startLevel : float = 1.0;
                             human_hold_breath__holdBreathDrain : float = 0.33;
                             human_hold_breath__restoreBreath : float = 0.2;
                             entity_mods__breathRestoreMult : float = 1.0;
                             entity_mods__holdBreathDrainMult : float = 1.0;
                             isDowned : bool = false;
                             var human_hold_breath__isAvailable : bool&;
                             var human_net_phys : HumanActor&)
  assume currentState = human_net_phys.phys.currentState
  assume appliedCT = human_net_phys.phys.appliedCT
  let stoppedHoldBreath = (currentState.breathShortness >= 1.0
    || (!is_hold_breath(currentState) && currentState.breathShortness > 1.0 - human_hold_breath__startLevel))
  let isAiming = (human_phys_state_can_aim(currentState)
    && is_control_bit_set(appliedCT, HumanPhysControlType HCT_AIM)
    && currentState.weapEquipState.curState != HUWeaponEquipState EES_DOWN
    && !human_phys_state_get_isClimbing(currentState)
    && !isDowned)

  human_hold_breath__isAvailable = isAiming && !stoppedHoldBreath

  currentState |> set_is_hold_breath(appliedCT |> is_control_bit_set(HumanPhysControlType HCT_SPRINT) && human_hold_breath__isAvailable)
  if is_hold_breath(currentState)
    currentState.breathShortness += evt.dt * human_hold_breath__holdBreathDrain * entity_mods__holdBreathDrainMult
  else
    currentState.breathShortness -= evt.dt * human_hold_breath__restoreBreath * entity_mods__breathRestoreMult

  currentState.breathShortness = saturate(currentState.breathShortness)
