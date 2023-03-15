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

[event(unicast)]
struct CmdRequestPlayNetSound
  name : string

[event(unicast)]
struct CmdRequestPlayNetSoundPos
  name : string
  pos : float3
