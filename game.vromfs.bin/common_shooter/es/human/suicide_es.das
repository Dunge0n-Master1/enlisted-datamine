require ecs
require game.es.events
require EnlistedDm

[es(on_event=RequestSuicide, tag=server, REQUIRE=hitpoints)]
def human_suicide_es(evt : Event;
                     eid : EntityId;
                     hitpoints__deathHpThreshold : float;
                     var hitpoints__downedKillChanceBase : float&;
                     var hitpoints__hp : float&)
  hitpoints__hp = hitpoints__deathHpThreshold
  hitpoints__downedKillChanceBase = 1f
  sendEvent(eid, [[CmdKill damageType=uint16(int(DamageType DM_MELEE))]])
