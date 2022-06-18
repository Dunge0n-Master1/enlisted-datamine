module events_game shared
require ecs
require RendInst
require DagorMath
require rapidjson


[cpp_event(broadcast)]
struct EventEntityManagerBeforeClear {}

[cpp_event(unicast, with_scheme, routing=ROUTING_SERVER_TO_CLIENT)]
struct EventEntityDied
  victim : EntityId
  offender : EntityId
  damageType : int
  gunPropsId : int
  shellId : int
  collNodeId : int
  victimTeam : int
  offenderTeam : int

[cpp_event(broadcast, with_scheme, routing=ROUTING_SERVER_TO_CLIENT)]
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
struct RenderEventBeforeUI
  viewTm : TMatrix
  viewItm : TMatrix
  globtm : mat44f

[cpp_event(broadcast)]
struct RenderEventUI
  viewTm : TMatrix
  viewItm : TMatrix
  globtm : mat44f
  wk : float
  hk : float

[cpp_event(broadcast)]
struct RenderEventAfterUI
  viewTm : TMatrix
  viewItm : TMatrix
  globtm : mat44f
  wk : float
  hk : float

[event(unicast)]
struct EventLutSwitcherAliveState {}

[event(broadcast)]
struct CmdClearAllAttachedUserPoint
  target : ecs::EntityId
  team : int

[event(unicast)]
struct CmdCollisionDamage
  damage : float
  pos : float3
  offender : ecs::EntityId

[cpp_event(unicast, with_scheme)]
struct EventMeleeAttackHit
  pos : float3
  power : float

[cpp_event(unicast, with_scheme)]
struct CmdUpdateHitpoints
  time : float

[event(unicast, routing=ROUTING_SERVER_TO_CLIENT)]
struct EventEntityResurrected {}

[cpp_event(broadcast)]
struct EventAnyEntityResurrected
  eid : EntityId

[event(unicast, routing=ROUTING_SERVER_TO_CLIENT)]
struct EventEntityRevived {}

[event(broadcast, routing=ROUTING_SERVER_TO_CLIENT)]
struct CmdLogEvent
  event : string
  text : string
  sound : string
  ttl : int

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

[cpp_event(unicast, with_scheme)]
struct CmdAddDefaultEntitiesInNetScopeForPlayer {}

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

[cpp_event(unicast)]
struct CmdDestroyRendinst
  user_data : int
  isDynamic : bool

[cpp_event(unicast, with_scheme)]
struct PlayerRequestRespawnInWorld {}

[event(unicast)]
struct EventPlayerOnLootUse
  entityToUse : EntityId

[event(broadcast, routing=ROUTING_SERVER_TO_CLIENT)]
struct EventTeamRoundResult
  team : int
  isWon : bool

[event(broadcast)]
struct EventTeamLost
  team : int

[cpp_event(broadcast, with_scheme)]
struct PlayerStartQuitGameTimer {}

[cpp_event(unicast, with_scheme)]
struct PlayerResetQuitGameTimer {}

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

[cpp_event(unicast, with_scheme, routing=ROUTING_CLIENT_CONTROLLED_ENTITY_TO_SERVER)]
struct RequestCamSwitch
  isTpsView : bool

[event(unicast, with_scheme, routing=ROUTING_SERVER_TO_CLIENT)]
struct SetLocalPlayerMsg {}

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

[cpp_event(unicast, with_scheme)]
struct EventOnSelectWeap
  curr_gun_slot_id : int

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

[cpp_event(unicast, with_scheme)]
struct GainVehicleVelocity
  vehicleEid : EntityId

[cpp_event(unicast, with_scheme)]
struct PossessTargetByPlayer
  target : EntityId

[event(unicast)]
struct EventPlayerPossessedEntityDied
  victimEid : EntityId
  killerEid : EntityId
  deathDesc_damageTypeId : uint16
  victimPlayerEid : EntityId
  killerPlayerEid : EntityId

[event(unicast)]
struct ChangeReplayTarget
  newReplayTarget : EntityId

[event(unicast)]
struct CmdSpawnEntity
  team : int
  tm : float3x4
  reason : string

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

[cpp_event(broadcast, with_scheme)]
struct ChangeServerRoute
  currentIsUnresponsive : bool

[cpp_event(broadcast)]
struct EventOnWriteReplayMetaInfo
  replayMeta : JsonDocument

[event(broadcast)]
struct MatchingRoomExtraParams
  routeEvaluationChance : float

// this is like UpdateStageInfoAct, but is also sent in level loading as well
[cpp_event(broadcast, with_scheme)]
struct UpdateStageGameLogic
  dt : float
  curTime : float

[cpp_event(unicast, with_scheme)]
struct EventMeleeTargetHit
  target : EntityId
  impulse : float3

[cpp_event(broadcast, with_scheme)]
struct EventGameSessionFinished
  disconnected : bool

[cpp_event(broadcast, with_scheme)]
struct EventGameSessionStarted {}

[cpp_event(broadcast, with_scheme)]
struct EventSessionFinished {}

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

[cpp_event(unicast, with_scheme)]
struct EventUseItem
  item : EntityId
  target : EntityId
