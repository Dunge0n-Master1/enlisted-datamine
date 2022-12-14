require ecs
require ecs.common
require math
require math.base
require math.ang
require DagorMathUtils
require game.utils.hero
require EnlistedHuman
require HumanPhys


[es(REQUIRE=hero, tag=input, after=human_input_es, before=before_net_phys_sync)]
def lock_camera_on_downed_es(info : UpdateStageInfoAct;
                             var human_net_phys : HumanActor;
                             var human_input__aimAngle : float2&;
                             downedMaxAngles : float2;
                             downedMaxAnglesExtension : float2;
                             isDowned : bool)
  if !isDowned
    return

  var lookAngles = dir_to_angles(human_net_phys.phys.producedCT.wishLookDir)
  var shootAngles = dir_to_angles(human_net_phys.phys.producedCT.wishShootDir)

  let bodyOrientDir = human_net_phys.phys.currentState.bodyOrientDir
  let bodyDir = float3(bodyOrientDir.x, 0.0, bodyOrientDir.y)

  let smoothClampTimeCoef = 15.0
  let lookAnglesClamped = clamp_angles_by_dir(lookAngles, downedMaxAngles, bodyDir)
  lookAngles = lookAngles + angle_diff(lookAngles, lookAnglesClamped) * clamp(info.dt * smoothClampTimeCoef, 0.0, 1.0)
  lookAngles = clamp_angles_by_dir(lookAngles, downedMaxAngles + downedMaxAnglesExtension, bodyDir)
  shootAngles = clamp_angles_by_dir(shootAngles, downedMaxAngles, bodyDir)

  human_net_phys.phys.producedCT |> human_control_state_set_wish_look_dir(angles_to_dir(lookAngles))
  human_net_phys.phys.producedCT |> human_control_state_set_wish_shoot_dir(angles_to_dir(shootAngles))
  human_net_phys.phys.producedCT |> human_control_state_set_walk_dir(bodyOrientDir)
  human_input__aimAngle = lookAngles
