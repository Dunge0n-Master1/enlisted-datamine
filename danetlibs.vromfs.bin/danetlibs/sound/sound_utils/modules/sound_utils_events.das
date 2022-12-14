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

[cpp_event(unicast)]
struct CmdSoundGenIrq
  irq : string

[cpp_event(unicast)]
struct CmdSoundSpecificIrq
  irq : string
  group : uint

//may move this events to single module in daNetGameLibs to share it across all da-net-game projects
[cpp_event(unicast)]
struct EventOnCollision
  vel : float3
  pvel : float3
  pos : float3
  offender : EntityId
  cvel : float3
  dt : float
  damage : float
