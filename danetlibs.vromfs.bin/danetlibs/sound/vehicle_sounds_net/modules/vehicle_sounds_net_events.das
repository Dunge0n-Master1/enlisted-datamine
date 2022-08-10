module vehicle_sounds_net_events shared
require ecs

[event(unicast, routing=ROUTING_SERVER_TO_CLIENT)]
struct CmdPlayVehicleDamageSound
  hash : uint
  relHp : float
  time : float
