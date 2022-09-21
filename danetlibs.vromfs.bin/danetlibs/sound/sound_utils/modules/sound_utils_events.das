module sound_utils_events shared
require ecs

[cpp_event(broadcast)]
struct EventOnSoundBanksValid
  hash : uint
  isValid : bool

[event(unicast)]
struct CmdPlaySound
  hash : uint
  pos : float3
  param : float

[event(unicast)]
struct CmdPlaySoundSimple
  hash : uint

[event(broadcast)]
struct EventOnWeaponSound
  pos : float3
  isLoop : bool
