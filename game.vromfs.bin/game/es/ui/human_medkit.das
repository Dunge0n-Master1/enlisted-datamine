require ecs
require enlisted.events_enlisted

[es(tag=ui, REQUIRE=hero, no_order)]
def human_medkit_update_need_display_heal_tip(info : ParallelUpdateFrameDelayed;
                                              isDowned : bool;
                                              burning__isBurning : bool;
                                              heal__continuousInput : bool;
                                              hitpoints__hp : float;
                                              hitpoints__maxHp : float;
                                              hitpoints__deathHpThreshold : float;
                                              human_inventory__hpThresholdForHealTip : float;
                                              human_inventory__entityUseEnd : float;
                                              human_inventory__canUseMedkit : bool;
                                              var human_medkit__needDisplayHealTip : bool&)
  let maxHp = !isDowned ? hitpoints__maxHp : -hitpoints__deathHpThreshold
  let needUseMedkitOrRevive = !burning__isBurning && human_inventory__entityUseEnd < info.curTime
  let isHpLessThanThreshold = hitpoints__hp > 0.0 && maxHp > 0.0 && hitpoints__hp / maxHp < human_inventory__hpThresholdForHealTip
  human_medkit__needDisplayHealTip = needUseMedkitOrRevive && human_inventory__canUseMedkit && heal__continuousInput && (isDowned || isHpLessThanThreshold)