require ecs
require DngHuman
require common_shooter.events_common_shooter


[es]
def stamina_restore(evt : CmdRestoreStamina;
                    human__totalMaxStamina : float;
                    var human_net_phys : HumanActor&)
  assume cs = human_net_phys.phys.currentState
  cs.stamina = min(cs.stamina + evt.restoreStamina, human__totalMaxStamina)