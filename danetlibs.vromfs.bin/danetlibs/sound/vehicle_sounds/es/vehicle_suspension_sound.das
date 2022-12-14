require ecs
require math.base
require DagorMath
require CollRes
require Dacoll
require PhysMat
require vehicle
require soundEvent
require soundProps
require sound_utils.modules.sound_player_common
require sound_utils_net.modules.sound_utils_net_events


[es(tag=sound, after=vehicle_sound_update_vars)]
def vehicle_suspension_hit_sound(info : ParallelUpdateFrameDelayed;
                                 sound_control__shouldPlay : bool;
                                 vehicle_net_phys : VehiclePhysActor;
                                 vehicle_suspension_sound__hitToVar : float2;
                                 var vehicle_suspension_sound__event : SoundEvent&;
                                 var vehicle_suspension_sound__hitTime : float&;
                                 var vehicle_suspension_sound__hitForce : float&;
                                 vehicle_sound_vars__noiseReduction : float;
                                 [[shared_comp]] vehicle_suspension_sound__path : Object;
                                 sound_tags : Object;
                                 transform : float3x4)
  var total = 0.
  if sound_control__shouldPlay
    for idx in range(int(vehicle_net_phys.phys.currentState.wheelCount))
      let wheel = vehicle_phys_get_wheel(vehicle_net_phys.phys, idx)
      if wheel != null
        total += cvt(abs((*wheel).velocity), vehicle_suspension_sound__hitToVar.x, vehicle_suspension_sound__hitToVar.y, 0., 1.)
    total *= vehicle_sound_vars__noiseReduction
  sound_player_common::play_parameterized(vehicle_suspension_sound__event, total, vehicle_suspension_sound__hitForce, "force", transform[3], vehicle_suspension_sound__path, sound_tags, true, info.curTime, vehicle_suspension_sound__hitTime)


[es(tag=sound, on_event=ParallelUpdateFrameDelayed, after=vehicle_sound_update_vars)]
def vehicle_suspension_sound_update_surface(evt : Event;
                                            sound_control__shouldPlay : bool;
                                            vehicle_net_phys : VehiclePhysActor;
                                            var vehicle_sound_vars__concrete : float&;
                                            var vehicle_sound_vars__water : float&;
                                            var vehicle_sound_update_surface__wheelIdx : int&;
                                            var vehicle_sound_update_surface__waterSurfaceMax : float&;
                                            var vehicle_sound_update_surface__concreteSurfaceMax : float&;
                                            transform : float3x4)
  if !sound_control__shouldPlay || int(vehicle_net_phys.phys.currentState.wheelCount) <= 0 || vehicle_sound_update_surface__wheelIdx >= int(vehicle_net_phys.phys.currentState.wheelCount)
    vehicle_sound_vars__concrete = 0.
    vehicle_sound_vars__water = 0.
    vehicle_sound_update_surface__concreteSurfaceMax = 0.
    vehicle_sound_update_surface__waterSurfaceMax = 0.
    vehicle_sound_update_surface__wheelIdx = 0
  else
    let wheel = vehicle_phys_get_wheel(vehicle_net_phys.phys, vehicle_sound_update_surface__wheelIdx)
    if wheel != null
      let wpos = transform * float3((*wheel).pos)

      var waterLevel = 0.
      if traceht_water(wpos, waterLevel)
        vehicle_sound_update_surface__waterSurfaceMax = max(vehicle_sound_update_surface__waterSurfaceMax, waterLevel - wpos.y)

      if (*wheel).lastMatId != PHYSMAT_INVALID
        vehicle_physmat_sound_get_props((*wheel).lastMatId) <| $(props : SoundVehiclePhysMatProps)
          vehicle_sound_update_surface__concreteSurfaceMax = max(vehicle_sound_update_surface__concreteSurfaceMax, props.concrete)

      vehicle_sound_update_surface__wheelIdx += max(1, int(vehicle_net_phys.phys.currentState.wheelCount) / 32)
      if vehicle_sound_update_surface__wheelIdx >= int(vehicle_net_phys.phys.currentState.wheelCount)
        vehicle_sound_update_surface__wheelIdx = 0
        vehicle_sound_vars__concrete = vehicle_sound_update_surface__concreteSurfaceMax
        vehicle_sound_vars__water = vehicle_sound_update_surface__waterSurfaceMax
        vehicle_sound_update_surface__concreteSurfaceMax = 0.
        vehicle_sound_update_surface__waterSurfaceMax = 0.
