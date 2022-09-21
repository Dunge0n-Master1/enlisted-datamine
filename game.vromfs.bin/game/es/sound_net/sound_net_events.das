module sound_net_events shared
require ecs

[event(unicast, routing=ROUTING_SERVER_TO_CLIENT)]
struct CmdPlayLootSoundForEnemy
  hash : uint
  time : float

[event(unicast, routing=ROUTING_SERVER_TO_CLIENT)]
struct CmdPlayLootSound
  hash : uint
  time : float

[event(unicast, routing=ROUTING_SERVER_TO_CLIENT)]
struct CmdVehicleSoundHorn
  enable : bool
  end : float

[event(unicast, routing=ROUTING_SERVER_TO_CLIENT)]
struct CmdHumanSpeechForAnySpecificPlayer
  phraseIdx : int
  time : float

[event(unicast, routing=ROUTING_SERVER_TO_CLIENT)]
struct CmdHumanSpeechForHero
  phraseIdx : int
  time : float

[event(unicast, routing=ROUTING_SERVER_TO_CLIENT)]
struct CmdHumanSpeech
  phraseIdx : int
  time : float

[cpp_event(unicast)]
struct CmdRequestHumanSpeech
  phrase : string
  importance : float

[event(unicast)]
struct CmdRequestPlayNetSound
  name : string

[event(unicast)]
struct CmdRequestPlayNetSoundPos
  name : string
  pos : float3

[event(unicast, routing=ROUTING_SERVER_TO_CLIENT)]
struct CmdPlayProjectileHitSound
  localHitPos : float3
  localNormal : float3
  caliber : float
  bulletTypeId : int
  nodeId : int
  pierced : bool

[event(unicast, routing=ROUTING_SERVER_TO_CLIENT)]
struct CmdPlayProjectileRicochetSound
  localHitPos : float3
  caliber : float
