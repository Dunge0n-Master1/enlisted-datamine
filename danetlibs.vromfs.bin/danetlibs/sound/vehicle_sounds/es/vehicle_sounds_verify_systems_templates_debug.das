options no_aot
require ecs
require ecs.verify_common
require ecs.verify_macro
require vehicle
require CollRes
require soundEvent
require EnlistedShip


[req_template] // vehicle_phys_sound_state (vehicle_phys_sound_state.das)
struct VehiclePhysSoundState
  sound_control__shouldPlay : bool
  vehicle_net_phys : VehiclePhysActor
  vehicle_sound_state__isOnGround : bool
  vehicle_sound_state__slip : float
  vehicle_sound_speed : float
  vehicle_sound_state__prevSoundShockSummary : float
  vehicle_sound_state__deltaShock : float
  vehicle_sound_state__noiseReductionTimer : float
  vehicle_sound_state__noiseReduction : float
  collres : CollisionResource
  transform : float3x4
  isAlive : bool


[req_template] // vehicle_brakes_sound (vehicle_brakes_sound.das)
struct VehicleBrakesSound
  sound_control__shouldPlay : bool
  vehicle_net_phys : VehiclePhysActor
  vehicle_sound_state__isOnGround : bool
  vehicle_brakes_sound__brakes : float
  vehicle_brakes_sound__speedFadeInOut : float2
  sound_event_group : SoundEventGroup
  is_watched_sound : bool
  vehicle_brakes_sound__path : SharedObject
  sound_tags : Object
  transform : float3x4


[req_template] // vehicle_gear_sound (vehicle_gear_sound.das)
struct VehicleGearSound
  sound_control__shouldPlay : bool
  vehicle_net_phys : VehiclePhysActor
  vehicle_gear_sound__gear : int
  vehicle_gear_sound__path : SharedObject
  is_watched_sound : bool
  sound_tags : Object
  transform : float3x4


[req_template] // vehicle_tracks_sound (vehicle_tracks_sound.das)
struct VehicleTracksSound
  sound_control__shouldPlay : bool
  vehicle_tracks_sound__event : SoundEvent
  vehicle_tracks_sound__timer : float
  vehicle_tracks_sound__speedThreshold : float
  vehicle_tracks_sound__speedToTurnMul : float4
  vehicle_sound_speed : float
  vehicle_sound_state__noiseReduction : float
  vehicle_sound_state__slip : float
  is_watched_sound : bool
  vehicle_tracks_sound__path : SharedObject
  sound_tags : Object
  transform : float3x4


[req_template] // vehicle_suspension_sound (vehicle_suspension_sound.das)
struct VehicleSuspensionSound
  sound_control__shouldPlay : bool
  vehicle_net_phys : VehiclePhysActor
  vehicle_suspension_sound__hitToVar : float2
  vehicle_suspension_sound__event : SoundEvent
  vehicle_suspension_sound__hitTime : float
  vehicle_suspension_sound__hitForce : float
  vehicle_sound_state__noiseReduction : float
  vehicle_sound_state__concrete : float
  vehicle_sound_state__water : float
  vehicle_suspension_sound__wheelIdx : int
  vehicle_suspension_sound__waterSurfaceMax : float
  vehicle_suspension_sound__concreteSurfaceMax : float
  vehicle_suspension_sound__path : SharedObject
  sound_tags : Object
  transform : float3x4


[req_template] // vehicle_engine_sound (vehicle_engine_sound.das)
struct VehicleEngineSound
  sound_control__shouldPlay : bool
  vehicle_sound_speed : float
  vehicle_engine_sound_state__rpm : float
  vehicle_engine_sound_state__load : float
  vehicle_engine_sound_state__isStarted : bool
  vehicle_engine_sound__isInited : bool
  vehicle_engine_sound__isStartStopInited : bool
  vehicle_engine_sound__isStarted : bool
  vehicle_engine_sound__shouldStart : bool
  vehicle_engine_sound__path : SharedObject
  vehicle_engine_sound__startPath : SharedObject
  vehicle_engine_sound__stopPath : SharedObject
  sound_tags : Object
  is_watched_sound : bool
  sound_event_group : SoundEventGroup
  transform : float3x4


// vehicle_engine_sound_seats_starter (vehicle_engine_sound_seats_starter.das)
[req_template]
struct VehicleEngineSoundSeatsStarter
  vehicleEngineSoundSeatsStarter : ecs::Tag
  vehicle_engine_sound__shouldStart : bool

[req_template]
struct VehicleWithSeats
  vehicle_seats__seatEids : ecs::EidList


// ship_engine_sound_state (ship_phys_sound_state.das)
[req_template]
struct ShipEngineSoundState
  ship_net_phys : ShipActor
  vehicle_engine_sound_state__rpm : float
  vehicle_engine_sound_state__load : float
  vehicle_engine_sound_state__isStarted : bool


// ship_sound_state (ship_phys_sound_state.das)
[req_template]
struct ShipSoundState
  sound_control__shouldPlay : bool
  ship_net_phys : ShipActor
  vehicle_sound_state__slip : float
  vehicle_sound_speed : float
  vehicle_sound_state__prevSoundShockSummary : float
  vehicle_sound_state__deltaShock : float
  vehicle_sound_state__noiseReductionTimer : float
  vehicle_sound_state__noiseReduction : float
  ship_sound_state__waterTimer : float
  vehicle_sound_state__water : float
  transform : float3x4
