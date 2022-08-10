module events_enlisted shared
require ecs
require EnlistedWalkerai
require common_shooter.events_common_shooter
require enlisted.game.es.medic_common

[cpp_event(broadcast)]
struct ParallelUpdateFrameDelayed
  curTime : float
  dt : float

[event(broadcast)]
struct EventRequestedAircraftShootAllBombs
  aircraftEid : EntityId

[event(broadcast)]
struct EventOnChangeSpawnTeams {}

[event(broadcast)]
struct EventResolveSlotAttachDeps
  attachTo : EntityId

[event(unicast)]
struct CmdFinishPlacePlaceableItem
  tm : float3x4
  newTemplate : string
  itemEid : EntityId
  vehicleEid : EntityId
  vehicleNodeId : int

[event(unicast)]
struct faceGenInfoUpdated {}

[event(unicast)]
struct faceGenSaveInfo
  initialSave : bool

[cpp_event(unicast)]
struct RequestSquadOrder
  orderType : SquadOrder
  orderPosition : float3
  orderUseEntity : ecs::EntityId

[cpp_event(unicast)]
struct RequestSquadMateOrder
  orderType : SquadMateOrder
  orderPosition : float3
  orderUseEntity : ecs::EntityId

[cpp_event(unicast)]
struct RequestSquadFormation
  spread : SquadFormationSpread

[event(unicast, routing=ROUTING_CLIENT_TO_SERVER)]
struct RequestSquadBehaviour
  behaviour : int

[event(unicast, routing=ROUTING_CLIENT_TO_SERVER)]
struct EventDigRequest
  pos : float3

[event(unicast)]
struct RqContextCommand{}

[event(unicast)]
struct RqCancelContextCommand
  include_personal_orders : bool

[cpp_event(unicast)]
struct CmdSelectBuildingType
  data : ecs::Object // index : int

[event(unicast)]
struct EventTryBuildFortification {}

[event(unicast)]
struct EventRecreateBuildPreview {}

[event(unicast)]
struct EventRecreateBuildIcons {}

[event(unicast)]
struct EventApplyCustomAnimcharVars {}

[event(unicast, routing=ROUTING_CLIENT_CONTROLLED_ENTITY_TO_SERVER)]
struct CmdBuildFortification
  builderGunEid : ecs::EntityId
  tm : float3x4
  boxMin : float3
  boxMax : float3

[event(unicast, routing=ROUTING_CLIENT_CONTROLLED_ENTITY_TO_SERVER)]
struct CmdStartPlacePlaceableItem
  itemEid : EntityId
  tm : float3x4
  vehicleEid : EntityId
  vehicleNodeId : int

[event(unicast, routing=ROUTING_CLIENT_CONTROLLED_ENTITY_TO_SERVER)]
struct EventSetBuildingTarget
  target : EntityId

[event(unicast, routing=ROUTING_CLIENT_CONTROLLED_ENTITY_TO_SERVER)]
struct EventDismantleBuilding
  target : EntityId

[event(unicast)]
struct EventOnDestroyBuilding {}

[event(unicast)]
struct EventEngineerBuildingBroken
  offender : EntityId

[cpp_event(unicast)]
struct CmdWallposterPreview
  enable : bool
  wallPosterId : int

[cpp_event(unicast)]
struct CmdWallposterPlace {}

[cpp_event(unicast)]
struct WallposterRequestPlace
  wallPosterId : int
  wallPostersCurCount : int
  tm : float3x4
  bmin : float3
  bmax : float3

[event(unicast)]
struct OnScoringKillBySquadMember
  victim : EntityId
  offender : EntityId

[event(unicast)]
struct EventOnPlayerWipedOutInfantrySquad {}

[event(broadcast)]
struct EventTeamWon
  team : int

[event(broadcast)]
struct EventTeamLost
  team : int

[event(broadcast, routing=ROUTING_SERVER_TO_CLIENT)]
struct EventTeamLowScore
  teamId : int

[event(broadcast, routing=ROUTING_SERVER_TO_CLIENT)]
struct EventTeamLoseHalfScore
  teamId : int

[event(unicast)]
struct EventPlayerSquadFinishedCapturing {}

[event(unicast)]
struct EventOnBarbwireDamageAward {}

[event(unicast)]
struct EventOnPlayerMineVehicleKill {}

[event(unicast)]
struct EventOnPlayerMineInfantryKill {}

[event(unicast)]
struct EventOnCapzoneFortificationAward {}

[event(unicast, routing=ROUTING_CLIENT_TO_SERVER)]
struct CmdHumanHoorayRequest {}

[event(unicast, routing=ROUTING_CLIENT_TO_SERVER)]
struct CmdBlinkMarker {}

[event(unicast, routing=ROUTING_CLIENT_CONTROLLED_ENTITY_TO_SERVER)]
struct RequestForgiveFriendlyFire
  player : EntityId

[event(unicast)]
struct OnFriendlyFire
  offender : EntityId
  gunPropsId : int

[event(unicast)]
struct OnTeamKill
  offender : EntityId
  gunPropsId : int

[event(broadcast, routing=ROUTING_SERVER_TO_CLIENT)]
struct EventKillReport
  victim : EntityId
  victimTeam : int
  victimPlayer : EntityId
  victimName : string
  victimRank : int
  isVictimVehicle : bool
  scoreId : string
  killer : EntityId
  killerTeam : int
  killerPlayer : EntityId
  killerName : string
  killerRank : int
  isKillerVehicle : bool
  isHeadshot : bool
  damageType : int
  gunName : string

[event(unicast)]
struct CmdSwitchSquad {}

[event(unicast, routing=ROUTING_SERVER_TO_CLIENT)]
struct CmdResupplyVehicle {}

[event(unicast, routing=ROUTING_CLIENT_CONTROLLED_ENTITY_TO_SERVER)]
struct RequestNextRespawnEntity
  memberEid : EntityId

[event(unicast)]
struct RqPersonalContextCommand{}

[event(unicast)]
struct RqCancelPersonalContextCommand{}

[event(unicast, routing=ROUTING_CLIENT_TO_SERVER)]
struct RequestPersonalSquadMateOrder
  orderType : int
  orderPosition : float3
  orderUseEntity : ecs::EntityId

[event(unicast)]
struct EventAwardZoneCapturers {}

[event(unicast)]
struct EventForceCapture
  team : int

[event(unicast)]
struct EventBombSiteExplosion {}

[event(unicast)]
struct EventBombSitePlanting
  bombSiteOperator : EntityId

[event(unicast)]
struct EventBombSitePlanted
  bombSiteOperator : EntityId

[event(unicast)]
struct EventBombSiteDefusing
  bombSiteOperator : EntityId

[event(unicast)]
struct EventBombSiteDefused
  bombSiteOperator : EntityId

[event(unicast)]
struct EventPlayerSquadHelpedToDestroyPoint {}

[event(unicast, routing=ROUTING_CLIENT_CONTROLLED_ENTITY_TO_SERVER)]
struct CmdVoteToKick
  voteYes : bool
  accused : EntityId

[event(unicast)]
struct CmdOpenArtilleryMap {}

[event(unicast)]
struct CmdCloseArtilleryMap {}

[event(unicast)]
struct CmdShowArtilleryCooldownHint {}

[event(unicast)]
struct RequestOpenArtilleryMap {}

[event(unicast)]
struct RequestCloseArtilleryMap {}

[event(unicast)]
struct EventArtilleryMapPosSelected
  pos : float3
  typeIndex : int
  posEnd : float3

[event(unicast, routing=ROUTING_CLIENT_CONTROLLED_ENTITY_TO_SERVER)]
struct RequestArtilleryStrikeAtPos
  owner : EntityId
  pos : float3
  typeIndex : int
  posEnd : float3

[event(unicast)]
struct CmdStartArtilleryStrikeAtPos
  owner : EntityId
  pos : float3
  typeIndex : int
  posEnd : float3

[event(unicast, routing=ROUTING_CLIENT_TO_SERVER)]
struct RequestArtilleryOverOrder
  active : bool
  targetPos : float3
  typeIndex : int
  posEnd : float3

[event(unicast)]
struct CmdSpawnSquad
  team : int
  possessed : ecs::EntityId
  squadId : int
  memberId : int
  respawnGroupId : int

[event(broadcast)]
struct EventFirstPlayerConnected
  time : float

[event(broadcast)]
struct EventFirstPlayerSpawned
  time : float

[event(unicast)]
struct EventPlayerProfileChanged {}

[event(unicast)]
struct RequestCheckTeamSpawnDefeat {}

[event(unicast, routing=ROUTING_SERVER_TO_CLIENT)]
struct EventCapZoneEnter
  visitor : EntityId

[event(unicast, routing=ROUTING_SERVER_TO_CLIENT)]
struct EventCapZoneLeave
  visitor : EntityId

[event(broadcast, routing=ROUTING_SERVER_TO_CLIENT)]
struct EventZoneCaptured
  zone : EntityId
  team : int

[event(broadcast, routing=ROUTING_SERVER_TO_CLIENT)]
struct EventZoneIsAboutToBeCaptured
  zone : EntityId
  team : int

[event(unicast)]
struct EventEntityAboutToDeactivate {}

[event(broadcast)]
struct EventZoneDeactivated
  zone : EntityId
  team : int

[event(broadcast, routing=ROUTING_SERVER_TO_CLIENT)]
struct EventZoneDecaptured
  zone : EntityId
  team : int

[event(broadcast, routing=ROUTING_SERVER_TO_CLIENT)]
struct CmdDig
  diggerEid : EntityId
  pos : float3
  radius : float
  depth : float
  matId : int

[event(broadcast)]
struct CmdTerraBrush
  pos : float3
  radius : float
  alt : float
  clearMode : bool
  eraseGrass : bool

[event(broadcast)]
struct CmdTerraUpdateRender
  hmapBoxMin : float3
  hmapBoxMax : float3
  egrasBase : int
  egrasNum  : int

[event(broadcast)]
struct CmdTerraBrushUndo {}

[event(broadcast)]
struct CmdTerraBrushRedo {}

[event(broadcast)]
struct CmdRIToolAddSelected
  tm : float3x4
  name : string
  bsph : float4
  action : string
  kind : int

[event(broadcast)]
struct CmdRIToolClearSelected {}

[event(broadcast)]
struct CmdRIToolRemoveRendInst
  tm : float3x4
  name : string
  eid : EntityId

[event(broadcast)]
struct CmdRIToolUnbakeRendInst
  tm : float3x4
  name : string
  eid : EntityId

[event(broadcast)]
struct CmdRIToolEnbakeRendInst
  tm : float3x4
  name : string
  eid : EntityId

[event(broadcast)]
struct CmdRIToolRebakeRendInst
  tm : float3x4
  name : string
  eid : EntityId

[event(broadcast)]
struct CmdRIToolCreateRendInst
  tpl : string
  tm : float3x4
  name : string
  eid : EntityId

[event(broadcast)]
struct CmdRIToolRestoreRendInst {}

[event(unicast)]
struct EventEditorEntityMoved {}

[event(broadcast)]
struct EventBombCraterPartTerraformed
  partPos : float3
  partRadius : float

[event(broadcast)]
struct EventBombCraterTerraformed
  pos : float3
  outerRadius : float
  availablePartsMask : uint64
  partsGridWidth : int

[event(broadcast)]
struct CmdUpdateBombCraterRemovableRiList {}

[event(broadcast)]
struct CmdStartNarrator
  phrase : string
  replace : bool

[event(broadcast, routing=ROUTING_SERVER_TO_CLIENT)]
struct CmdTeamStartNarrator
  team : int
  phrase : string
  replace : bool

[event(unicast, routing=ROUTING_CLIENT_TO_SERVER)]
struct CmdNextBuildingType {}

[event(unicast, routing=ROUTING_SERVER_TO_CLIENT)]
struct EventOnDig
  canTerraformCheckResult : int

[event(unicast, routing=ROUTING_CLIENT_TO_SERVER)]
struct CmdStopInteractBomb
  operatorEid : EntityId

[event(unicast, routing=ROUTING_CLIENT_TO_SERVER)]
struct CmdRequestAmmoBoxMarker {}

[event(unicast, routing=ROUTING_CLIENT_TO_SERVER)]
struct CmdRequestRallyPointMarker {}

[event(unicast, routing=ROUTING_CLIENT_TO_SERVER)]
struct RequestSquadChangeLeader
  eid : EntityId

[event(unicast)]
struct CmdSwitchSquadLeader
  eid : EntityId

[event(unicast, routing=ROUTING_CLIENT_TO_SERVER)]
struct EventRepairFortificationStart
  target : EntityId

[event(unicast)]
struct EventRepairFortificationFinish {}

[event(unicast, routing=ROUTING_CLIENT_TO_SERVER)]
struct EventRepairFortificationStop {}

[event(unicast)]
struct EventAdditiveBuildingRepaired {}

[event(unicast)]
struct InitCapzoneRadius {}

[event(unicast)]
struct CmdExplodeTntBlocks {}

[event(unicast, routing=ROUTING_SERVER_TO_CLIENT)]
struct EventActivateRadioMode
  isActive : bool

[cpp_event(unicast)]
struct CmdTutorialHint
  data : ecs::Object

[event(unicast)]
struct CmdHeroSpeech
  phrase : string

[event(unicast)]
struct EventUpdatedItemContainer {}

[event(unicast)]
struct NextReplayTarget
  delta : int

[event(unicast)]
struct SetReplayTarget {}

[event(broadcast, routing=ROUTING_SERVER_TO_CLIENT)]
struct CmdSpawnCharredArea
  pos : float3
  normal : float3

[event(unicast, routing=ROUTING_SERVER_TO_CLIENT)]
struct VoteKickResult
  kicked : bool

[event(unicast, routing=ROUTING_CLIENT_TO_SERVER)]
struct CmdFlaskUse {}

[event(unicast, routing=ROUTING_CLIENT_TO_SERVER)]
struct CmdFlaskUseCancel {}

[event(unicast, routing=ROUTING_CLIENT_CONTROLLED_ENTITY_TO_SERVER)]
struct HumanUseItemRequest
  item : EntityId
  target : EntityId

[event(unicast)]
struct EventSoldierRecreateOnDie {}

[event(unicast)]
struct RequestSwitchBinocular
  choosePrevGunSlot : bool

[event(unicast, routing=ROUTING_CLIENT_CONTROLLED_ENTITY_TO_SERVER)]
struct CmdSwitchBinocular
  choosePrevGunSlot : bool

[event(unicast)]
struct CmdSwitchBinocularCockpit
  enabled : bool

[cpp_event(broadcast)]
struct EventSquadMembersStats
  data : Object

[event(broadcast, routing=ROUTING_SERVER_TO_CLIENT, net_liable=ignore)]
struct EventGunGameNewLeader
  oldLeaderPlayerEid : EntityId
  newLeaderPlayerEid : EntityId

[event(broadcast, routing=ROUTING_SERVER_TO_CLIENT, net_liable=ignore)]
struct EventGunGameLevelReached
  playerEid : EntityId
  level : int
