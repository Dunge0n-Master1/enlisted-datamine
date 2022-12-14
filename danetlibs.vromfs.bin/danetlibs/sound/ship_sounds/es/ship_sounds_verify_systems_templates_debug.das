options no_aot
require ecs
require ecs.verify_common
require ecs.verify_macro
require EnlistedShip


[req_template]
struct ShipEngineSoundUpdateVarsES
  ship_net_phys : ShipActor
  vehicle_engine_sound_vars__rpm : float
  vehicle_engine_sound_vars__load : float
  vehicle_engine_sound_vars__isStarted : bool
  isAlive : bool


[req_template]
struct ShipSoundUpdateVarsES
  sound_control__shouldPlay : bool
  ship_net_phys : ShipActor
  vehicle_sound_vars__slip : float
  vehicle_sound_vars__speed : float
  vehicle_sound_vars__prevSoundShockSummary : float
  vehicle_sound_vars__deltaShock : float
  vehicle_sound_vars__noiseReductionTimer : float
  vehicle_sound_vars__noiseReduction : float
  vehicle_sound_vars__noiseReductionDecayPeriod : float
  vehicle_sound_vars__noiseDeltaShockThreshold : float
  vehicle_sound_vars__noiseSpeedThreshold : float
  ship_sound_vars__waterTimer : float
  vehicle_sound_vars__water : float
  transform : float3x4
