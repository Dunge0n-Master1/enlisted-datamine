module turret_input_common shared

require ecs
require math.base
require DagorMath
require DagorMathUtils
require DagorInput
require math.ang
require EnlistedCamera
require common_shooter.es.weapon.turret_common

def calc_aim_pos(aim_angles : float2)
  let camTm = get_TMatrix(get_cur_cam_entity(), "transform")
  let camPos = camTm != null ? (*camTm)[3] : float3()
  return camPos + angles_to_dir(aim_angles) * AIM_DISTANCE

def apply_turret_input(turret_control__gunEids : EidList;
                       aim : AnalogStickAction;
                       zoomToggle : DigitalAction;
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

      turret_input__isZoom = turret__canZoom && (zoomToggle.bActive && zoomToggle.bState || zoom.bActive && zoom.bState)

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

def stop_weapons(turret_control__gunEids : EidList; trigger : int)
  for gunEid in turret_control__gunEids
    query(gunEid) <| $ [es(REQUIRE=resolvedTurret)] (turret__triggerGroup : int; var turret_input__shootFlag : bool&)
      if turret__triggerGroup == trigger
        turret_input__shootFlag = false


def release_weapon(turret_control__gunEids : EidList; state : bool; trigger : int; salvo_size : int)
  if salvo_size == 0
    return
  var indexInSalvo = 0
  var isFired = false
  for gunEid in turret_control__gunEids
    query(gunEid) <| $ [es(REQUIRE=resolvedTurret)] (turret__triggerGroup : int; gun__ammo : int; var turret_input__shootFlag : bool&)
      if turret__triggerGroup == trigger
        turret_input__shootFlag = state
        isFired ||= turret_input__shootFlag && gun__ammo > 0
        indexInSalvo = (indexInSalvo + 1) % salvo_size
    if isFired && indexInSalvo == 0
      break
