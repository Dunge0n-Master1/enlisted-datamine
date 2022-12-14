options no_aot
require ecs
require ecs.verify_common
require ecs.verify_macro
require vehicle
require CollRes
require soundEvent
require vehicle_sounds_net.modules.vehicle_sounds_net_events


[req_template] // vehicle_sound_update_vars
struct VehiclePhysSoundState
  sound_control__shouldPlay : bool
  vehicle_net_phys : VehiclePhysActor
  vehicle_sound_vars__isOnGround : bool
  vehicle_sound_vars__slip : float
  vehicle_sound_vars__speed : float
  vehicle_sound_vars__prevSoundShockSummary : float
  vehicle_sound_vars__deltaShock : float
  vehicle_sound_vars__noiseReductionTimer : float
  vehicle_sound_vars__noiseReduction : float
  vehicle_sound_vars__noiseReductionDecayPeriod : float
  vehicle_sound_vars__noiseDeltaShockThreshold : float
  vehicle_sound_vars__noiseSpeedThreshold : float
  collres : CollisionResource
  transform : float3x4
  isAlive : bool


[req_template] // vehicle_brakes_sound
struct VehicleBrakesSound
  sound_control__shouldPlay : bool
  vehicle_net_phys : VehiclePhysActor
  vehicle_sound_vars__isOnGround : bool
  vehicle_brakes_sound__brakes : float
  vehicle_brakes_sound__brakesStart : float
  vehicle_brakes_sound__speedFadeInOut : float2
  sound_event_group : SoundEventGroup
  is_watched_sound : bool
  vehicle_brakes_sound__path : SharedObject
  sound_tags : Object
  transform : float3x4


[req_template] // vehicle_gear_sound
struct VehicleGearSound
  sound_control__shouldPlay : bool
  vehicle_net_phys : VehiclePhysActor
  vehicle_gear_sound__gear : int
  vehicle_gear_sound__path : SharedObject
  is_watched_sound : bool
  sound_tags : Object
  transform : float3x4


[req_template] // vehicle_tracks_sound
struct VehicleTracksSound
  sound_control__shouldPlay : bool
  vehicle_tracks_sound__event : SoundEvent
  vehicle_tracks_sound__timer : float
  vehicle_tracks_sound__speedThreshold : float
  vehicle_tracks_sound__speedToTurnMul : float4
  vehicle_sound_vars__speed : float
  vehicle_sound_vars__noiseReduction : float
  vehicle_sound_vars__slip : float
  is_watched_sound : bool
  vehicle_tracks_sound__path : SharedObject
  sound_tags : Object
  transform : float3x4


[req_template] // vehicle_suspension_hit_sound
struct VehicleSuspensionHitSound
  sound_control__shouldPlay : bool
  vehicle_net_phys : VehiclePhysActor
  vehicle_suspension_sound__hitToVar : float2
  vehicle_suspension_sound__event : SoundEvent
  vehicle_suspension_sound__hitTime : float
  vehicle_suspension_sound__hitForce : float
  vehicle_sound_vars__noiseReduction : float
  vehicle_suspension_sound__path : SharedObject
  sound_tags : Object
  transform : float3x4


[req_template] // vehicle_suspension_sound_update_surface
struct VehicleSoundUpdateSurface
  sound_control__shouldPlay : bool
  vehicle_net_phys : VehiclePhysActor
  vehicle_sound_vars__concrete : float
  vehicle_sound_vars__water : float
  vehicle_sound_update_surface__wheelIdx : int
  vehicle_sound_update_surface__waterSurfaceMax : float
  vehicle_sound_update_surface__concreteSurfaceMax : float
  transform : float3x4


[req_template] // vehicle_engine_sound
struct VehicleEngineSound
  sound_control__shouldPlay : bool
  vehicle_sound_vars__speed : float
  vehicle_engine_sound_vars__rpm : float
  vehicle_engine_sound_vars__load : float
  vehicle_engine_sound_vars__isStarted : bool
  vehicle_engine_sound__isInited : bool
  vehicle_engine_sound__isStartStopInited : bool
  vehicle_engine_sound__isStarted : bool
  vehicle_engine_sound__rpmMul : float
  vehicle_engine_sound__path : SharedObject
  vehicle_engine_sound__startPath : SharedObject
  vehicle_engine_sound__stopPath : SharedObject
  sound_tags : Object
  is_watched_sound : bool
  sound_event_group : SoundEventGroup
  transform : float3x4


[req_template]
struct VehicleWithSeats
  vehicle_seats__seatEids : ecs::EidList

[req_template]
struct HumanVoiceEffectFallcry
  human_voice_effect_fallcry__enabled : bool

[es(on_event=VerifyEcsTemplates)]
def vehicle_sounds_verify_ecs_templates(evt : Event)
  // vehicle_horn_toggle
  req_template({{
    "sound_control__shouldPlay" => ecs_type_hash(type<bool>);
    "vehicle_horn_sound__endTime" => ecs_type_hash(type<float>);
    "vehicle_horn_sound__note" => ecs_type_hash(type<int>);
    "vehicle_horn_sound__path" => ecs_type_hash(type<SharedObject>);
    "sound_tags" => ecs_type_hash(type<Object>);
    "sound_event_group" => ecs_type_hash(type<SoundEventGroup>);
    "is_watched_sound" => ecs_type_hash(type<bool>);
    "transform" => ecs_type_hash(type<float3x4>)
  }})
  req_unique_event_handler("CmdVehicleSoundHorn")
