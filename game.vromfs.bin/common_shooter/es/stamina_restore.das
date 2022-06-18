require ecs
require EnlistedHuman
require common_shooter.events_common_shooter


[es]
def stamina_restore(evt : CmdRestoreStamina;
                    var human_net_phys : HumanActor&)
  assume cs = human_net_phys.phys.currentState
  let maxStamina = human_net_phys.phys.maxStamina * cs.maxStaminaMult * cs.staminaBoostMult

  cs.stamina = min(cs.stamina + evt.restoreStamina, maxStamina)