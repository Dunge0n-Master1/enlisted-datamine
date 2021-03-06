module turret_input_common shared

require ecs
require math.base
require DagorMath
require DagorMathUtils
require DagorInput
require math.ang
require EnlistedCamera

def calc_aim_pos(aim_angles : float2)
  let AIM_DISTANCE = 1000.0
  let camTm = get_TMatrix(get_cur_cam_entity(), "transform")
  let camPos = camTm != null ? (*camTm)[3] : float3()
  return camPos + angles_to_dir(aim_angles) * AIM_DISTANCE

def apply_turret_input(turret_control__gunEids : EidList;
                       aim : AnalogStickAction;
                       zoom : DigitalAction)
  var isFirstAimPosVaild = false
  var firstAimPos = float3()

  for gunEid in turret_control__gunEids
    query(gunEid) <| $ [es(REQUIRE=(resolvedTurret, firstTurretInput))] (turret__canZoom : bool;
                                                                         var turret_input__aimAngles : float2&;
                                                                         var turret_input__aimPos : float3&;
                                                                         var turret_input__firstUpdate : bool&;
                                                                         var turret_input__isZoom : bool&)
      assume aimAngles = turret_input__aimAngles
      assume aimPos = turret_input__aimPos

      if zoom.bActive && turret__canZoom
        turret_input__isZoom = zoom.bState

      if aim.bActive && !turret_input__firstUpdate
        let dx = aim.x * PI
        let dy = aim.y * PI
        aimAngles.x = norm_s_ang(aimAngles.x + dx)
        aimAngles.y = clamp(aimAngles.y + dy, -SAFE_HALF_PI, SAFE_HALF_PI)

        aimPos = calc_aim_pos(aimAngles)

        isFirstAimPosVaild = true
        firstAimPos = aimPos
      elif aim.bActive
        turret_input__firstUpdate = false

  if !isFirstAimPosVaild
    return

  for gunEid in turret_control__gunEids
    query(gunEid) <| $ [es(REQUIRE=resolvedTurret, REQUIRE_NOT=firstTurretInput)] (var turret_input__aimPos : float3&;
                                                                                   var turret_input__firstUpdate : bool&)
      if aim.bActive && !turret_input__firstUpdate
        turret_input__aimPos = firstAimPos
      elif aim.bActive
        turret_input__firstUpdate = false
