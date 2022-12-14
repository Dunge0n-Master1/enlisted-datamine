module sound_events shared
require ecs

[cpp_event(unicast)]
struct CmdSoundMeleeIrq
  irq : string

[cpp_event(unicast)]
struct CmdStartActionSfx
  pos : float3
  pmid : int
