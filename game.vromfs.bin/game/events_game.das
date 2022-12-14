module events_game shared
require ecs
require RendInst
require DagorMath
require rapidjson
require danetlibs.native_dasevents.main.native_events public
require danetlibs.route_prober.main.net_events public


[event(unicast, routing=ROUTING_SERVER_TO_CLIENT)]
struct EventEntityDied
  victim : EntityId
  offender : EntityId
  damageType : int
  gunPropsId : int
  shellId : int
  collNodeId : int
  victimTeam : int
  offenderTeam : int

[event(broadcast, routing=ROUTING_SERVER_TO_CLIENT)]
struct EventAnyEntityDied
  victim : EntityId
  offender : EntityId
  offenderPlayer : EntityId
  victimPlayer : EntityId
  damageType : int
  gunPropsId : int
  shellId : int
  collNodeId : int
  victimTeam : int
  offenderTeam : int

[cpp_event(broadcast)]
struct EventEntityManagerBeforeClear {}

[event(unicast)]
struct EventLutSwitcherAliveState {}

[event(unicast)]
struct CmdSetMarkMain {}

[event(unicast)]
struct CmdSetMarkEnemy {}

[event(broadcast)]
struct CmdClearAllAttachedUserPoint
  target : ecs::EntityId
  team : int

[event(unicast)]
struct CmdCollisionDamage
  damage : float
  pos : float3
  offender : ecs::EntityId

[event(unicast, routing=ROUTING_SERVER_TO_CLIENT)]
struct EventEntityResurrected {}

[event(unicast, routing=ROUTING_SERVER_TO_CLIENT)]
struct EventEntityRevived {}

[event(broadcast, routing=ROUTING_SERVER_TO_CLIENT)]
struct CmdLogEvent
  event : string
  text : string
  sound : string
  ttl : int
  data : ecs::Object const?

[event(broadcast)]
struct CmdShowHint
  event : string
  text : string
  hotkey : string
  unique : string
  ttl : float

[event(unicast, routing=ROUTING_SERVER_TO_CLIENT)]
struct CmdHumanQuickChatSpeech
  phraseIdx : int
  time : float

[event(unicast, routing=ROUTING_CLIENT_CONTROLLED_ENTITY_TO_SERVER)]
struct EventSpectateTarget
  target_eid : EntityId

[cpp_event(unicast)]
struct EventAnimIrq
  irqType : int

[event(unicast)]
struct GameEffectStateChanged // note: can be resended on recreate
  attachedTo : EntityId
  activated : bool

[event(unicast, routing=ROUTING_SERVER_TO_CLIENT)]
struct EnableSpectatorForTarget
  player : EntityId

[event(unicast, routing=ROUTING_SERVER_TO_CLIENT)]
struct EnableSpectatorForPlayer
  target : EntityId// if invalid, the target will be decided on the client side

[cpp_event(unicast)]
struct CmdRendinstDamage
  handle : riex_handle_t
  damage : float
  pos : float3
  impulse : float3
  time : float

[event(unicast)]
struct CmdRendinstBulletHole
  handle : riex_handle_t
  pos : float3
  norm : float3
  pmid : int

[event(unicast, routing=ROUTING_CLIENT_CONTROLLED_ENTITY_TO_SERVER)]
struct RequestRendinstDamage
  handle : riex_handle_t
  damage : float
  pos : float3
  impulse : float3
  time : float

[event(unicast, routing=ROUTING_CLIENT_CONTROLLED_ENTITY_TO_SERVER)]
struct RequestRendinstEntityDamage
  eid : EntityId
  damage : float
  pos : float3
  impulse : float3
  time : float

[cpp_event(broadcast)]
struct EventRendinstDestroyed // server
  riexHandle : riex_handle_t
  riTm : float3x4
  riBBox : BBox3

[event(unicast)]
struct EventPlayerOnLootUse
  entityToUse : EntityId

[event(broadcast, routing=ROUTING_SERVER_TO_CLIENT)]
struct EventTeamRoundResult
  team : int
  isWon : bool

[event(unicast)]
struct CmdSwitchCamera {}

[event(unicast)]
struct CmdSwitchCameraByEntity
  index : int
  camNamesEid : ecs::EntityId

[event(unicast)]
struct CmdSwitchCameraByIndex
  index : int

[event(unicast)]
struct CmdTryToSwitchCameraInVehicle {}

[event(broadcast)]
struct EventTeamMemberJoined
  eid : ecs::EntityId
  team : int

[event(broadcast)]
struct EventTeamMemberLeave
  eid : ecs::EntityId
  team : int

[event(unicast)]
struct CmdWeapSwitchSight
  toNext : bool

[event(unicast, routing=ROUTING_SERVER_TO_CLIENT)]
struct PossessHero // Possess/unposses entity
  possess : bool

[cpp_event(unicast)]
struct CmdUpdateRemoteShadow
  tick : int
  dt : float

[cpp_event(unicast)]
struct CmdSetSimplifiedPhys
  is_simplified : bool

[event(unicast)]
struct CmdPushPhys
  vel : float3
  push_immunity : float

[event(unicast)]
struct CmdVehiclePushPhys
  energyScaledDir : float3
  arm : float3
  duration : float

[event(unicast)]
struct EventPlayerPossessedEntityDied
  victimEid : EntityId
  killerEid : EntityId
  deathDesc_damageTypeId : uint16
  victimPlayerEid : EntityId
  killerPlayerEid : EntityId

[event(broadcast)]
struct ReplaySetTpsCamera {}

[event(broadcast)]
struct ReplaySetFreeTpsCamera {}

[event(broadcast)]
struct ReplaySetFpsCamera {}

[event(unicast)]
struct ReplaySetCamera {}

[cpp_event(unicast)]
struct CmdApplyRagdollParameters
  cur_time : float

[event(unicast)]
struct EventOnItemGenerated {}

[cpp_event(broadcast)]
struct EventGameObjectsCreated
  game_objects : EntityId

[event(unicast)]
struct EventEntityActivate
  activate : bool

[cpp_event(broadcast)]
struct EventOnConnectedToServer {}

[cpp_event(broadcast)]
struct EventOnNetworkDestroyed
  last_client_dc : int // DisconnectionCause

[cpp_event(broadcast)]
struct DynamicQualityChangeEvent
  name : string

[cpp_event(broadcast)]
struct EventOnWriteReplayMetaInfo
  replayMeta : JsonDocument

[event(unicast)]
struct CmdGetUserstats {}

[event(unicast, routing=ROUTING_CLIENT_CONTROLLED_ENTITY_TO_SERVER)]
struct RequestSuicide {}

[event(broadcast)]
struct EventZoneStartCapture
  eid : EntityId
  team : int

[event(broadcast)]
struct EventZoneStartDecapture
  eid : EntityId
  team : int

[event(unicast)]
struct EventZoneUnlock {}

[event(unicast)]
struct EventOnUsefulBoxSuccessfulUse
  requester : EntityId

[event(unicast, routing=ROUTING_SERVER_TO_CLIENT)]
struct RunActionCmd
  id : int
  overridePropsId : int
  overrideTime : float
  overrideAt : float
  actionPeriod : float
  progress : float
  timeMult : float

[event(unicast, routing=ROUTING_SERVER_TO_CLIENT)]
struct AFKShowDisconnectWarning {}

[event(unicast, routing=ROUTING_SERVER_TO_CLIENT)]
struct AFKShowWarning {}
