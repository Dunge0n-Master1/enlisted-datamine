module player_events shared
require ecs
require EnlistedNet

[event(unicast)]
struct CheckAndReportNoHero {}

[event(unicast, routing=ROUTING_CLIENT_CONTROLLED_ENTITY_TO_SERVER)]
struct RespawnRequestCommon{}

[event(unicast)]
struct FinalizePlayerCreation
  matchingTeam : int
  clientFlags : uint16
  reconnected : bool

[event(unicast)]
struct EventOnPlayerConnected
  wishTeam : int
  reconnected : bool
  canSpawnEntity : bool

[cpp_event(broadcast)]
struct EventOnClientConnected
  connid : int
  matching : uint64
  userName : das_string
  groupId : int64
  clientFlags : uint16
  platformUserId : das_string
  platform : das_string
  matchingTeam : int
  appId : int

[cpp_event(broadcast)]
struct EventOnClientDisconnected
  connid : int
  cause : DisconnectionCause

[event(unicast)]
struct CmdSpawnEntityForPlayer
  team : int
  possessed : ecs::EntityId

[event(unicast)]
struct EventPlayerPlace
  team_id : int
  player_place : int
  total_places : int
  killer_player : ecs::EntityId

[event(broadcast)]
struct EventOnPlayerSpawned
  player_eid : EntityId
  pos_spawn : float3
  no_battles_played : int

[event(unicast)]
struct CmdPossessEntity
  possessedEid : EntityId
