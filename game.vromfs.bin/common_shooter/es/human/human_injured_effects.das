require ecs
require EnlistedHuman
require DagorMath
require HumanPhys

[es(after=(human_weight_influence_server_es, human_weight_influence_client_es), before=human_phys_es)]
def human_injured_speed_reducer(info : UpdateStageInfoAct; var human_net_phys : HumanActor&;
                                hitpoints__hp, hitpoints__maxHp : float;
                                injured_effects__hitpointsThreshold, injured_effects__hitpointsMin, injured_effects__speedMinMult : float)
  let hpRatio = hitpoints__hp / hitpoints__maxHp
  let maxSpeedMult = cvt(hpRatio, injured_effects__hitpointsMin, injured_effects__hitpointsThreshold, injured_effects__speedMinMult, 1f)
  human_net_phys.phys.currentState.moveSpeedMult = max(human_net_phys.phys.currentState.moveSpeedMult, maxSpeedMult)

[es(before=human_phys_es)]
def human_injured_sprint_disable(info : UpdateStageInfoAct; var human_net_phys : HumanActor&;
                                 hitpoints__hp, hitpoints__maxHp : float;
                                 injured_effects__sprintHitpointsThreshold : float)
  let hpRatio = hitpoints__hp / hitpoints__maxHp
  human_phys_state_set_block_sprint(human_net_phys.phys.currentState, hpRatio < injured_effects__sprintHitpointsThreshold)

