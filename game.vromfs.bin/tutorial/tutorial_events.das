module tutorial_events shared
require ecs

[event(unicast)]
struct CmdTutorialTargetDamaged
  weaponType : string

[event(unicast)]
struct CmdTutorialDamageVehiclePart
  partId : int
  damageMask : int
