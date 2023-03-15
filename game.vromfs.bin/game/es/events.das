//ATTENTION!
//this file should decrease in size, move old/new events to events_game.das
//shouldDecreaseSize, allowedSizeIncrease = 0
module events shared
require ecs
require EnlistedNet
require Dacoll

[cpp_event(unicast)]
struct EventEntityCreated {}

[cpp_event(unicast)]
struct EventEntityRecreated {}

[cpp_event(unicast)]
struct EventEntityDestroyed {}

[cpp_event(unicast)]
struct EventComponentsDisappear {}

[cpp_event(unicast)]
struct EventComponentsAppear {}

[cpp_event(broadcast)]
struct EventHeroChanged
  eid : ecs::EntityId

[event(unicast)]
struct EventOnDownedThreshold {}

[event(broadcast)]
struct EventAnyEntityDowned
  victim : EntityId
  offender : EntityId

[cpp_event(unicast)]
struct CmdTeleportEntity
  newTm : float3x4
  hard : bool

[cpp_event(unicast)]
struct CmdSetCameraTarget
  target : EntityId

[event(unicast)]
struct EventOnVehiclePartTypeDamaged
  partType : string
  isDestroyed : bool

[cpp_event(unicast)]
struct EventOnRepaired
  eid : EntityId

[cpp_event(unicast)]
struct EventRiExtraDestroyed
  offenderEid : ecs::EntityId

[cpp_event(unicast)]
struct EventOnLootPickup
  itemEid : ecs::EntityId

[event(unicast)]
struct CmdInventoryPickup
  itemEid : ecs::EntityId
  usefulOnly : bool

[cpp_event(unicast)]
struct EventOnLootDrop
  itemEid : ecs::EntityId

[event(unicast)]
struct EventOnLootUse
  itemEid : ecs::EntityId

[cpp_event(unicast)]
struct EventOnProjectileHit
  hitPos : float3
  norm : float3
  shellId : int
  physMatId : int
  collNodeId : int
  projectileEid : EntityId

[event(unicast)]
struct CmdHumanHitTagging
  powerMult : float

[cpp_event(unicast)]
struct CmdUse
  requesterEid : EntityId

[cpp_event(unicast)]
struct HumanUseObjectRequest
  objectEid : EntityId

[cpp_event(unicast)]
struct CmdChangePlayerPerk
  perkName : string
  active : bool

[event(unicast)]
struct CmdKill
  offender : EntityId
  damageType : uint16
  gunPropsId : int
  shellId : int

[event(unicast)]
struct EventOnLootItemUsed
  target : ecs::EntityId

[cpp_event(unicast)]
struct CmdPostPhysUpdate
  tick : int
  dt : float
  isForReal : bool

[cpp_event(unicast)]
struct CmdPostPhysUpdateRemoteShadow
  tick : int
  dt : float

[cpp_event(unicast)]
struct EventCutPart
  offender : ecs::EntityId
  partNo : int

[event(unicast)]
struct EventOnDeviceShoot {}

[cpp_event(unicast)]
struct CmdEquipItemDirect
  itemEid : ecs::EntityId
  slot : string
  allowReorderSlots : bool
  dropPrevItem : bool

[cpp_event(unicast)]
struct CmdEquipItemEntity
  slot : string
  name : string

[cpp_event(unicast)]
struct EventOnEquipmentUnequiped
  equipmentEid : EntityId

[cpp_event(broadcast)]
struct CmdInitPolyBattleAreas {}

[cpp_event(unicast)]
struct EventOnCollision
  vel : float3
  pvel : float3
  pos : float3
  offender : EntityId
  cvel : float3
  dt : float
  damage : float

[cpp_event(unicast)]
struct EventOnModsChanged {}

[cpp_event(unicast)]
struct CmdBodyCleanup
  time : float

[event(unicast)]
struct EventOnItemStartUse
  target : EntityId

[cpp_event(unicast)]
struct CmdChatMessage//mode="team",text="",qmsg=null
  data : Object

[cpp_event(unicast)]
struct CmdEquipItem
  itemEid : EntityId
  slotName : string

[event(unicast)]
struct CmdWeapModToggle
  slotId : int

[cpp_event(unicast)]
struct CmdTeleportTo
  newTm : float3x4
  speed : float

[cpp_event(unicast)]
struct CmdRumble
  eventName : string
  duration : int

[cpp_event(unicast)]
struct CmdScaledRumble
  eventMinName : string
  eventMaxName : string
  scale : float

[cpp_event(unicast)]
struct EventInterruptItemUse {}

[cpp_event(unicast)]
struct CmdLoadAmmo
  ammoNum : int

[event(unicast)]
struct CmdUseVehicle
  requester : ecs::EntityId
  seat_no : int

[cpp_event(unicast)]
struct EventShellExplosionShockWave
  position : float3
  dmg_radius : float
  dmg_hp : float

[cpp_event(broadcast)]
struct EventShellExplosionDebug
  pos : float3
  splashExplosiveRadius : float
  splashInnerRadius : float
  splashOuterRadius : float
  splashDamage : float
  shatterRadius : float
  shatterCount : int
  shatterDamage : float

[cpp_event(unicast)]
struct EventShellExplosionDamageDebug
  dist : float
  damageToParts : float
  splashMaxDamage : float
  splashDamage : float
  shatterSingleDamage : float
  shatterDamage : float

[event(broadcast)]
struct ProjectileFlyShockWave
  position : float3
  prev_position : float3
  caliber : float

[cpp_event(broadcast)]
struct ProjectileHitShake
  position : float3
  damage : float

[event(broadcast)]
struct CmdShakeCamera
  position : float3
  max_distance : float
  wish_shake : float
  smooth : float

[cpp_event(broadcast)]
struct EventVehicleEarthTremor
  position : float3
  mass : float
  speed : float

[cpp_event(broadcast)]
struct UpdateStageUpdateInput
  curTime : float
  dt : float

[cpp_event(broadcast)]
struct EventUserLoggedIn
  user_id : int64

[cpp_event(unicast)]
struct EventSqChatMessage
  qmsg : ecs::Object

[cpp_event(unicast)]
struct EventOnEntityReset {}

[event(broadcast)]
struct CmdAddCameraTrauma
  addTrauma : float
  maxTrauma : float

[event(broadcast)]
struct CmdAddCameraTraumaByDistance
  position : float3
  maxDistance : float
  addTrauma : float
  maxTrauma : float

[event(broadcast)]
struct CmdCameraPunch
  angles : float3

[event(broadcast)]
struct CmdCameraPunchByDir
  localDir : float3

[cpp_event(unicast)]
struct EventOnPhysImpulse
  atTime : float
  nodeId : int
  pos : float3
  dir : float3

[cpp_event(unicast)]
struct EventFlashExploded
  pos : float3
  tinnitusRad : float2
  flashRad : float2
  tinnitusPower : float2
  flashPower : float2
  flashDistExp : float
  tinnitusDistExp : float
  ignoreEid : EntityId

[cpp_event(unicast)]
struct ProjectileHitInvulnerableNotification
  hitPos : float3
  hitDir : float3

[cpp_event(unicast)]
struct EventOnEntityTeleported
  newtm : float3x4
  prevtm : float3x4

[event(unicast)]
struct CmdUseUsefulBox
  requesterEid : EntityId

[event(unicast, routing=ROUTING_SERVER_TO_CLIENT, net_liable=ignore)]
struct CmdUsefulBoxCompleteUse {}

[cpp_event(unicast)]
struct EventRIGenExtraRequested {}

[event(unicast)]
struct OnFlamethrowerFriendlyFire
  offender : EntityId
  gunPropsId : int

[cpp_event(broadcast)]
struct CmdAddInitialEntitiesInNetScope
  connid : int

[cpp_event(broadcast)]
struct CmdAddDefaultEntitiesInNetScope
  connid : int
  viewPos : float3
  viewFwd : float3

[event(unicast, routing=ROUTING_SERVER_TO_CLIENT)]
struct CmdServerLoadAmmo
  ammoNum : int