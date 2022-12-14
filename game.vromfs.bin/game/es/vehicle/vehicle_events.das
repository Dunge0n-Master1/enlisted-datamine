module vehicle_events shared
require ecs
require DagorMath

[cpp_event(unicast)]
struct EventOnPartDamageEffects
  offender : ecs::EntityId
  partId : int
  effects : int
  gunPropsId : int
  shellId : int

[cpp_event(unicast)]
struct EventOnPartKillEffects
  offender : ecs::EntityId
  partId : int
  effects : int
  gunPropsId : int
  shellId : int

[cpp_event(unicast)]
struct CmdVolumetricDamage
  offender : ecs::EntityId
  sph : BSphere3
  damage : float
  isDamageRel : bool
  damageTypeId : int
  damageEffectsMask : int
  seed : int

[cpp_event(unicast)]
struct EventOnVolumetricDamage
  offender : ecs::EntityId
  damageTypeId : int
  damageEffectsMask : int
  damagedParts : ecs::Array
  gunPropsId : int
  shellId : int

[event(unicast, routing=ROUTING_SERVER_TO_CLIENT)]
struct EventOnVehicleDamageEffects
  offender : EntityId
  vehicle : EntityId
  effects : int

[event(unicast, routing=ROUTING_SERVER_TO_CLIENT)]
struct EventOnVehicleDamaged
  offender : EntityId
  vehicle : EntityId
  damage : float
  hp : float
  maxHp : float

[cpp_event(unicast)]
struct EventOnCollisionHit
  collNodeId : int
  dir : float3

[cpp_event(unicast)]
struct EventOnMetaPartDamage
  offender : ecs::EntityId
  metaPartId : int
  damage : float
  hp : float
  maxHp : float

[event(unicast)]
struct CmdUseVehicleOnSpawn
  possessed : ecs::EntityId
  squad : ecs::EntityId
  vehicle : ecs::EntityId
  seatOrderNo : int

[event(unicast)]
struct CmdVehicleSwapSeats
  seatNo1 : int
  seatNo2 : int

[event(unicast)]
struct CmdKillVehicle
  offender : EntityId

[cpp_event(unicast)]
struct CmdExplosionFatal
  offender : ecs::EntityId
  gunPropsId : int
  shellId : int

[cpp_event(unicast)]
struct EventExplosionFatal
  offender : ecs::EntityId
  gunPropsId : int
  shellId : int

[event(unicast)]
struct CmdFireFatal
  offender : ecs::EntityId
  gunPropsId : int
  shellId : int

[event(unicast, routing=ROUTING_SERVER_TO_CLIENT)]
struct EventFireFatal
  offender : ecs::EntityId
  gunPropsId : int
  shellId : int

[cpp_event(unicast)]
struct CmdCrashExplosionFatal
  offender : ecs::EntityId
  crashType : int

[cpp_event(unicast)]
struct EventCrashExplosionFatal
  offender : ecs::EntityId
  crashType : int

[event(unicast)]
struct CmdActivateExtinguisher
  eid : EntityId

[event(unicast)]
struct CmdStopExtinguisher
  eid : EntityId

[cpp_event(unicast)]
struct CmdStopBurn {}

[event(unicast, routing=ROUTING_CLIENT_TO_SERVER)]
struct RequestStartMaintenance
  target : EntityId

[event(unicast, routing=ROUTING_CLIENT_TO_SERVER)]
struct RequestStopMaintenance
  target : EntityId

[event(unicast)]
struct CmdStartMaintenance
  target : EntityId

[event(unicast)]
struct CmdStopMaintenance
  target : EntityId

[event(unicast)]
struct CmdStartRepair
  target : EntityId

[event(unicast)]
struct CmdStopRepair
  target : EntityId

[event(unicast, routing=ROUTING_CLIENT_TO_SERVER)]
struct RequestVehicleChangeSeat
  eid : EntityId
  seat : int

[event(unicast)]
struct CmdVehicleChangeSeat
  eid : EntityId
  seat : int

[event(broadcast)]
struct EventOnStartVehicleChangeSeat
  endTime : float

[event(unicast)]
struct CmdVehiclePlaceSeat
  eid : EntityId
  seat : int

[event(unicast)]
struct CmdVehiclePlaceDriverSeat
  eid : EntityId

[event(unicast)]
struct CmdVehiclePlaceNextSeat
  eid : EntityId

[event(unicast)]
struct CmdSetVehicleShootDir
  dir : float3

[event(unicast, routing=ROUTING_CLIENT_TO_SERVER)]
struct CmdSetGunnerCockpitRequest
  isGunner : bool

[event(unicast)]
struct CmdTurretStartReloading {}

[event(unicast)]
struct NodesVisibilityWasUpdated {}

[cpp_event(unicast)]
struct CmdRestore {}

[event(unicast)]
struct CmdAcquireVehicleSeat
  requester : ecs::EntityId
  seat_no : int

[event(unicast, routing=ROUTING_CLIENT_TO_SERVER)]
struct RequestVehicleSeat
  requester : EntityId
  seat_no : int

[event(unicast)]
struct CmdKickFromVehicle
  eid : EntityId

[event(unicast, routing=ROUTING_CLIENT_TO_SERVER)]
struct RequestKickFromVehicle
  requester : EntityId

[event(unicast, routing=ROUTING_SERVER_TO_CLIENT)]
struct EventEnterVehicle
  incomer : EntityId
  vehicle : EntityId
  seat_no : int
  enter : bool

[event(unicast)]
struct EventOnSeatOwnersChanged {}

[event(unicast)]
struct EventOnVehicleExtinguished
  eid : EntityId
