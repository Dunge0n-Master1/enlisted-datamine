options no_aot
require ecs
require ecs.verify_common
require ecs.verify_macro
require EnlistedPlane
require soundEvent


[req_template]
struct PlaneSoundsRequiredComponents
  plane_net_phys : PlaneActor
  transform : float3x4
  isAlive : bool
  sound_event_group : SoundEventGroup
  sound_control__shouldPlay : bool
