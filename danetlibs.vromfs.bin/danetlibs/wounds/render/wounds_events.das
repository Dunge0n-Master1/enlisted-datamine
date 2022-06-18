module wounds_events shared

require ecs
require EnlistedDm

[event(unicast, routing=ROUTING_SERVER_TO_CLIENT)]
struct CmdRestoreEntityHp
  restoreHp : float

[cpp_event(unicast)]
struct EventEntityDied
  victim : EntityId
  offender : EntityId
  damageType : int
  gunPropsId : int
  shellId : int
  collNodeId : int
  victimTeam : int
  offenderTeam : int

[cpp_event(broadcast)]
struct EventOnEntityHit
  victim : ecs::EntityId
  offender : ecs::EntityId
  damageDesc : DamageDesc
  hitResult : HitResult