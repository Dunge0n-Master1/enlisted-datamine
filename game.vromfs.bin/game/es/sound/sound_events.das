module sound_events shared
require ecs

[cpp_event(unicast)]
struct CmdSoundMeleeIrq
  irq : string

[cpp_event(unicast)]
struct CmdSoundStepIrq
  objIdx : int

[cpp_event(unicast)]
struct CmdStartActionSfx
  pos : float3
  smid : int

[event(unicast)]
struct CmdStartTinnitussSfx
  pos : float3
  power : float
