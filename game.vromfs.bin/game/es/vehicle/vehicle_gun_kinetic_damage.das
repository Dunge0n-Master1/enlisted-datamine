require ecs
require ecs.common
require ecs.safe

[es(tag=server, on_appear, before=turret_control_create_guns_es)]
def vehicle_init_gun_kinetic_damage_mult(evt : Event;
                                         turrets__kineticDamageMult : float;
                                         [[shared_comp]] turret_control__turretInfo : Array;
                                         var turretsInitialComponents : Array&)
  let numTurrets = length(turret_control__turretInfo)

  for comps in turretsInitialComponents
    assume object = (comps as Object)
    if object != null
      (*object) |> set("gun__kineticDamageMult", turrets__kineticDamageMult)
  let numUnitedComps = numTurrets - length(turretsInitialComponents)
  for _i in range(numUnitedComps)
    push_to_array(turretsInitialComponents) <| $(var object : Object)
      object |> set("gun__kineticDamageMult", turrets__kineticDamageMult)
