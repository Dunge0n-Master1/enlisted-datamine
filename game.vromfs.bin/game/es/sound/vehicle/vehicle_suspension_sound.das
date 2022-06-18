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


[es(tag=sound, after=vehicle_phys_sound_state)]
def vehicle_suspension_sound(info : UpdateStageInfoAct;
                             sound_control__enabled : bool;
                             vehicle_net_phys : VehiclePhysActor;

                             vehicle_suspension_sound__hitToVar : float2;
                             var vehicle_suspension_sound__event : SoundEvent&;
                             var vehicle_suspension_sound__hitTime : float&;
                             var vehicle_suspension_sound__hitForce : float&;
                             vehicle_sound_state__noiseReduction : float;

                             var vehicle_sound_state__surfaceConcrete : float&;
                             var vehicle_sound_state__surfaceWater : float&;

                             var vehicle_suspension_sound__wheelIdx : int&;
                             var vehicle_suspension_sound__waterSurfaceMax : float&;
                             var vehicle_suspension_sound__concreteSurfaceMax : float&;

                             [[shared_comp]] vehicle_suspension_sound__path : Object;

                             sound_tags : Object;
                             transform : float3x4)

  // suspension hit --------------------------
  var total = 0.

  if sound_control__enabled
    for idx in range(int(vehicle_net_phys.phys.currentState.wheelCount))
      let wheel = vehicle_phys_get_wheel(vehicle_net_phys.phys, idx)
      if wheel != null
        total += cvt(abs((*wheel).velocity), vehicle_suspension_sound__hitToVar.x, vehicle_suspension_sound__hitToVar.y, 0., 1.)
    total *= vehicle_sound_state__noiseReduction

  sound_player_common::play_parameterized(vehicle_suspension_sound__event, total, vehicle_suspension_sound__hitForce, "force", transform[3], vehicle_suspension_sound__path, sound_tags, true, info.curTime, vehicle_suspension_sound__hitTime)

  // surface type ----------------------------
  if !sound_control__enabled || int(vehicle_net_phys.phys.currentState.wheelCount) <= 0 || vehicle_suspension_sound__wheelIdx >= int(vehicle_net_phys.phys.currentState.wheelCount)
    vehicle_sound_state__surfaceConcrete = 0.
    vehicle_sound_state__surfaceWater = 0.
    vehicle_suspension_sound__concreteSurfaceMax = 0.
    vehicle_suspension_sound__waterSurfaceMax = 0.
    vehicle_suspension_sound__wheelIdx = 0
    return

  let wheel = vehicle_phys_get_wheel(vehicle_net_phys.phys, vehicle_suspension_sound__wheelIdx)
  if wheel == null
    return
  let wpos = transform * float3((*wheel).pos)

  var waterLevel = 0.
  if traceht_water(wpos, waterLevel)
    vehicle_suspension_sound__waterSurfaceMax = max(vehicle_suspension_sound__waterSurfaceMax, waterLevel - wpos.y)

  let lastMatId = (*wheel).lastMatId
  if lastMatId != PHYSMAT_INVALID
    vehicle_physmat_sound_get_props(lastMatId) <| $(props : SoundVehiclePhysMatProps)
      vehicle_suspension_sound__concreteSurfaceMax = max(vehicle_suspension_sound__concreteSurfaceMax, props.concrete)

  vehicle_suspension_sound__wheelIdx += max(1, int(vehicle_net_phys.phys.currentState.wheelCount) / 32)
  if vehicle_suspension_sound__wheelIdx >= int(vehicle_net_phys.phys.currentState.wheelCount)
    vehicle_suspension_sound__wheelIdx = 0
    vehicle_sound_state__surfaceConcrete = vehicle_suspension_sound__concreteSurfaceMax
    vehicle_sound_state__surfaceWater = vehicle_suspension_sound__waterSurfaceMax
    vehicle_suspension_sound__concreteSurfaceMax = 0.
    vehicle_suspension_sound__waterSurfaceMax = 0.
