require ecs
require vehicle

[es(on_appear)]
def apply_vehicle_phys_mods(evt : Event;
                            var vehicle_net_phys : VehiclePhysActor;
                            vehicle_mods__extraMass : float;
                            vehicle_mods__maxMomentMult : float;
                            vehicle_mods__maxBrakeForceMult : float;
                            vehicle_mods__trackFricSideLinMult : float;
                            vehicle_mods__trackFrontalStaticFrictionMult : float;
                            vehicle_mods__trackFrontalSlidingFrictionMult : float;
                            vehicle_mods__trackSideRotMinSpdMult : float;
                            vehicle_mods__trackSideRotMaxSpdMult : float;
                            vehicle_mods__trackSideRotMinFricMult : float;
                            vehicle_mods__trackSideRotMaxFricMult : float;
                            vehicle_mods__suspensionDampeningMult : float;
                            vehicle_mods__suspensionRestingMult : float;
                            vehicle_mods__suspensionMinLimitMult : float;
                            vehicle_mods__suspensionMaxLimitMult : float)
  assume phys = vehicle_net_phys.phys

  vehicle_phys_add_extra_mass(phys, vehicle_mods__extraMass)

  phys.maxMoment *= vehicle_mods__maxMomentMult

  phys.maxBrakeForce *= vehicle_mods__maxBrakeForceMult

  phys.trackFricSideLin   *= vehicle_mods__trackFricSideLinMult
  phys.trackFricFrontal.x *= vehicle_mods__trackFrontalStaticFrictionMult
  phys.trackFricFrontal.y *= vehicle_mods__trackFrontalSlidingFrictionMult

  phys.trackFricSideRot.x *= vehicle_mods__trackSideRotMinSpdMult
  phys.trackFricSideRot.y *= vehicle_mods__trackSideRotMaxSpdMult
  phys.trackFricSideRot.z *= vehicle_mods__trackSideRotMinFricMult
  phys.trackFricSideRot.w *= vehicle_mods__trackSideRotMaxFricMult

  vehicle_phys_apply_dampening_mult(phys, vehicle_mods__suspensionDampeningMult)
  vehicle_phys_apply_suspension_resting_mult(phys, vehicle_mods__suspensionRestingMult)
  vehicle_phys_apply_suspension_min_limit_mult(phys, vehicle_mods__suspensionMinLimitMult)
  vehicle_phys_apply_suspension_max_limit_mult(phys, vehicle_mods__suspensionMaxLimitMult)
