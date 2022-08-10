module weapon_sounds_events shared
require ecs

[event(unicast)]
struct CmdPlayProjectileHitSceneSound
  pos : float3
  pmid : int
  caliber : float
  ricochet : float
  exploded : bool
