require ecs
require game.es.events
require DngDm

[es(on_event=RequestSuicide, tag=server, REQUIRE=hitpoints)]
def human_suicide_es(evt : Event;
                     eid : EntityId;
                     var hitpoints__downedKillChanceBase : float&)
  hitpoints__downedKillChanceBase = 1f
  sendEvent(eid, [[CmdKill offender=eid, damageType=uint16(int(DamageType DM_MELEE)), gunPropsId=-1, shellId=-1]])
