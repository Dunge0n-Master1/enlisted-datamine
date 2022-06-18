require ecs
require math
require math.base
require DagorMath


def detect_barrel_roll_r(dt : float; transform : float3x4; var initDir : float3&; horizonDir : float3;
                         var step : int&; var time : float&; var count : int&) : bool
  time += dt
  if ((step > 0 && time > 3.0) || abs(transform[0].y) > 0.4)
    step = 0; time = 0.0

  if (step != 4 && transform[1].y > 0.8)
    step = 1; time = 0.0
    initDir = horizonDir;
  elif (step == 1 && transform[2].y > 0.8)
    step++; time = 0.0
  elif (step == 2 && transform[1].y < -0.8)
    step++; time = 0.0
  elif (step == 3 && transform[2].y < -0.8)
    step++; time = 0.0
  if (step == 4 && transform[1].y > 0.8 && dot(initDir, transform[0]) > 0.7)
    step = 0; time = 0.0
    count++
    return true
  return false


def detect_barrel_roll_l(dt : float; transform : float3x4; var initDir : float3&; horizonDir : float3;
                         var step : int&; var time : float&; var count : int&) : bool
  time += dt
  if ((step > 0 && time > 3.0) || abs(transform[0].y) > 0.4)
    step = 0; time = 0.0

  if (step != 4 && transform[1].y > 0.8)
    step = 1; time = 0.0
    initDir = horizonDir;
  elif (step == 1 && transform[2].y < -0.8)
    step++; time = 0.0
  elif (step == 2 && transform[1].y < -0.8)
    step++; time = 0.0
  elif (step == 3 && transform[2].y > 0.8)
    step++; time = 0.0
  if (step == 4 && transform[1].y > 0.8 && dot(initDir, transform[0]) > 0.7)
    step = 0; time = 0.0
    count++
    return true
  return false


def detect_split(dt : float; transform : float3x4; var initDir : float3&; horizonDir : float3;
                 var step : int&; var time : float&; var count : int&) : bool
  time += dt
  if ((step > 0 && time > 5.0))
    step = 0; time = 0.0

  if (step != 4 && transform[1].y > 0.8 && abs(transform[0].y - 0.1) < 0.25)
    step = 1; time = 0.0
    initDir = horizonDir;
  elif (step == 1 && abs(transform[1].y) < 0.2 && abs(transform[0].y - 0.1) < 0.25 && dot(initDir, transform[0]) > 0.6)
    step++; time = 0.0
  elif (step == 2 && transform[1].y < -0.8 && abs(transform[0].y) < 0.3 && dot(initDir, transform[0]) > 0.6)
    step++; time = 0.0
  elif (step == 3 && transform[0].y < -0.8 && dot(initDir, transform[1]) < -0.7)
    step++; time = 0.0
  if (step == 4 && transform[1].y > 0.8)
    step = 0; time = 0.0
    count++
    return true
  return false


def detect_nesterov(dt : float; transform : float3x4; var initDir : float3&; horizonDir : float3;
                    var step : int&; var time : float&; var count : int&) : bool
  time += dt

  if ((step > 0 && time > 5.0))
    step = 0; time = 0.0

  if (step != 4 && transform[1].y > 0.8 && abs(transform[0].y) < 0.3)
    step = 1; time = 0.0
    initDir = horizonDir;
  elif (step == 1 && abs(transform[0].y) > 0.8 && dot(initDir, transform[1]) < -0.7)
    step++; time = 0.0
  elif (step == 2 && transform[1].y < -0.8 && dot(initDir, transform[0]) < -0.7)
    step++; time = 0.0
  elif (step == 3 && transform[0].y < -0.8 && dot(initDir, transform[1]) > 0.7)
    step++; time = 0.0
  if (step == 4 && transform[1].y > 0.8 && dot(initDir, transform[0]) > 0.7)
    step = 0; time = 0.0
    count++
    return true
  return false


def detect_turn(dt : float; transform : float3x4; var initDir : float3&; horizonDir : float3;
                var step : int&; var time : float&; var count : int&) : bool
  time += dt

  if (step > 0 && time > 8.0)
    step = 0; time = 0.0

  if (step != 5 && transform[1].y > 0.8 && abs(transform[0].y) < 0.3)
    step = 1; time = 0.0
    initDir = horizonDir;
  elif (step == 1 && abs(transform[0].y) < 0.3 && transform[1].y < 0.8 && transform[1].y > -0.2 &&
        abs(dot(initDir, transform[0])) < 0.3)
    step++; time = 0.0
  elif (step == 2 && abs(transform[0].y) < 0.3 && transform[1].y < 0.8 && transform[1].y > -0.2 &&
        dot(initDir, transform[0]) < -0.7)
    step++; time = 0.0
  elif (step == 3 && abs(transform[0].y) < 0.3 && transform[1].y < 0.8 && transform[1].y > -0.2 &&
        abs(dot(initDir, transform[0])) < 0.3)
    step++; time = 0.0
  elif (step == 4 && dot(initDir, transform[0]) > 0.5)
    step++; time = 0.0
  if (step == 5 && transform[1].y > 0.8 && dot(initDir, transform[0]) > 0.7)
    step = 0; time = 0.0
    count++
    return true

  if (step > 1 && transform[1].y > 0.8)
    step = 0; time = 0.0

  return false



[es(no_order)]
def maneuver_detector_es(info : UpdateStageInfoAct; transform : float3x4; plane_view__tas : float;
                         plane_view__operable : bool;
                         var plane_maneuver__barrel_roll_l__init_dir : float3&;
                         var plane_maneuver__barrel_roll_l__step : int&;
                         var plane_maneuver__barrel_roll_l__time : float&;
                         var plane_maneuver__barrel_roll_l__count : int&;
                         var plane_maneuver__barrel_roll_r__init_dir : float3&;
                         var plane_maneuver__barrel_roll_r__step : int&;
                         var plane_maneuver__barrel_roll_r__time : float&;
                         var plane_maneuver__barrel_roll_r__count : int&;
                         var plane_maneuver__split__init_dir : float3&;
                         var plane_maneuver__split__step : int&;
                         var plane_maneuver__split__time : float&;
                         var plane_maneuver__split__count : int&;
                         var plane_maneuver__nesterov__init_dir : float3&;
                         var plane_maneuver__nesterov__step : int&;
                         var plane_maneuver__nesterov__time : float&;
                         var plane_maneuver__nesterov__count : int&;
                         var plane_maneuver__turn__init_dir : float3&;
                         var plane_maneuver__turn__step : int&;
                         var plane_maneuver__turn__time : float&;
                         var plane_maneuver__turn__count : int& /*;
                         var plane_maneuver__oblique_loop__step: int&;
                         var plane_maneuver__oblique_loop__time: float&;
                         var plane_maneuver__oblique_loop__count: int&*/
                         )
  if (!plane_view__operable || plane_view__tas < 25.0)
    return

  if (int(info.curTime * 16.0) == int((info.curTime + info.dt) * 16.0))
    return

  let h = normalize(float3(transform[0].x, 0.0, transform[0].z));

  let dt = 1.0 / 16.0;
  detect_barrel_roll_r(dt, transform, plane_maneuver__barrel_roll_r__init_dir,
      h, plane_maneuver__barrel_roll_r__step,
      plane_maneuver__barrel_roll_r__time, plane_maneuver__barrel_roll_r__count)

  detect_barrel_roll_l(dt, transform, plane_maneuver__barrel_roll_l__init_dir,
      h, plane_maneuver__barrel_roll_l__step,
      plane_maneuver__barrel_roll_l__time, plane_maneuver__barrel_roll_l__count)

  detect_split(dt, transform, plane_maneuver__split__init_dir,
      h, plane_maneuver__split__step,
      plane_maneuver__split__time, plane_maneuver__split__count)

  detect_nesterov(dt, transform, plane_maneuver__nesterov__init_dir,
      h, plane_maneuver__nesterov__step,
      plane_maneuver__nesterov__time, plane_maneuver__nesterov__count)

  detect_turn(dt, transform, plane_maneuver__turn__init_dir,
      h, plane_maneuver__turn__step,
      plane_maneuver__turn__time, plane_maneuver__turn__count)
