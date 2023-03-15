module native_events shared
require ecs
require RendInst


[cpp_event(unicast, with_scheme)]
struct CmdApplyDamage
  offender : EntityId
  damageType : int
  shellId : int
  gunPropsId : int
  actionPropsId : int
  collNodeId : int
  deltaHp : float
  blockingDeltaHp : float
  stoppingPower : float
  hitPos : float3
  hitDir : float3
  hitNorm : float3
  dmgMult : float
  armorMult : float
  armorPenetration : float


[cpp_event(unicast, with_scheme)]
struct EventMeleeAttackHit
  pos : float3
  power : float
  targetEid : EntityId


[cpp_event(unicast, with_scheme)]
struct CmdUpdateHitpoints
  time : float


[cpp_event(unicast, with_scheme)]
struct CmdAddDefaultEntitiesInNetScopeForPlayer {}

[cpp_event(unicast, with_scheme, routing=ROUTING_CLIENT_CONTROLLED_ENTITY_TO_SERVER)]
struct RequestCamSwitch
  isTpsView : bool

[event(unicast, with_scheme, routing=ROUTING_SERVER_TO_CLIENT)]
struct SetLocalPlayerMsg {}

[cpp_event(unicast, with_scheme)]
struct EventOnSelectWeap
  curr_gun_slot_id : int

[cpp_event(unicast, with_scheme)]
struct GainVehicleVelocity
  vehicleEid : EntityId

[cpp_event(unicast, with_scheme)]
struct PossessTargetByPlayer
  target : EntityId

// this is like UpdateStageInfoAct, but is also sent in level loading as well
[cpp_event(broadcast, with_scheme)]
struct UpdateStageGameLogic
  dt : float
  curTime : float

[cpp_event(broadcast, with_scheme)]
struct EventGameSessionFinished
  disconnected : bool

[cpp_event(broadcast, with_scheme)]
struct EventGameSessionStarted {}

[cpp_event(broadcast, with_scheme)]
struct EventSessionFinished {}

[cpp_event(unicast, with_scheme)]
struct EventUseItem
  item : EntityId
  target : EntityId

[cpp_event(broadcast, with_scheme)]
struct ChangeServerRoute
  currentIsUnresponsive : bool

[cpp_event(broadcast, with_scheme)]
struct ServerCreatePlayersEntities {}

[cpp_event(broadcast, with_scheme)]
struct BloodPuddlesLeakDecalEvent
  pos : float3
  normal : float3
  size : float
  ri_desc_handle : riex_handle_t
  hit_pos : float3
  projective : bool

[cpp_event(broadcast, with_scheme)]
struct BloodPuddlesSplashDecalEvent
  pos : float3
  normal : float3
  size : float
  ri_desc_handle : riex_handle_t
  hit_pos : float3
  projective : bool

[cpp_event(broadcast, with_scheme)]
struct BloodPuddlesSprayDecalEvent
  pos : float3
  normal : float3
  size : float
  ri_desc_handle : riex_handle_t
  hit_pos : float3
  projective : bool

[cpp_event(broadcast, with_scheme)]
struct BloodPuddlesSplashEmmiterEvent
  start_pos : float3
  target_pos : float3
  normal : float3
  dir : float3
  size : float
  ri_desc_handle : riex_handle_t

[cpp_event(unicast, with_scheme)]
struct EventMeleeAction
  actorEid : EntityId
  propsId : int

[cpp_event(unicast, with_scheme)]
struct CmdStartSecAnim
  startTime : float

[cpp_event(unicast, with_scheme)]
struct CmdStopSecAnim
  immediately : bool

[cpp_event(broadcast, with_scheme)]
struct EventAnyEntityResurrected
  eid : EntityId

[cpp_event(broadcast, with_scheme, cpp_gen=false)]
struct EventRendinstsLoaded {}

[cpp_event(unicast, with_scheme, cpp_gen=false)]
struct CmdDestroyRendinst
  userData : int
  destroyEntity : bool

[cpp_event(unicast, with_scheme, routing=ROUTING_SERVER_TO_CLIENT)]
struct CmdHeroLogEvent
  event : string
  text : string
  sound : string
  ttl : int

[cpp_event(broadcast, with_scheme)]
struct EventTickrateChanged
  oldTickrate : int
  newTickrate : int
