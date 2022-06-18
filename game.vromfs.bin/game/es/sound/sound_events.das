module sound_events shared
require ecs

[cpp_event(unicast)]
struct CmdSoundMeleeIrq
  irq : string

[cpp_event(unicast)]
struct CmdSoundVoicefxIrq
  irq : string
  group : uint

[cpp_event(unicast)]
struct CmdSoundGenIrq
  irq : string

[cpp_event(unicast)]
struct CmdSoundStepIrq
  irq : string
  group : uint

[cpp_event(unicast)]
struct CmdSoundSpecificIrq
  irq : string
  group : uint

[cpp_event(unicast)]
struct CmdStartActionSfx
  pos : float3
  smid : int

[event(unicast)]
struct CmdStartTinnitussSfx
  pos : float3
  power : float
