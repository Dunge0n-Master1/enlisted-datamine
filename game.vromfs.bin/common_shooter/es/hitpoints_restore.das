require ecs
require common_shooter.events_common_shooter

[es(tag=server, REQUIRE=(hitpoints, hitpoints__stoppingPower))]
def hitpoints_restore_es(evt : CmdRestoreEntityHp;
                         hitpoints__maxHp : float;
                         var hitpoints__hp : float&)
  hitpoints__hp = min(max(hitpoints__hp, 0.) + evt.restoreHp, hitpoints__maxHp)
