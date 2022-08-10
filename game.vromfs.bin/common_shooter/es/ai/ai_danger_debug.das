options no_aot = true
require ecs
require walkerai
require math
require math.base
require DagorMath
require EnlistedWalkerai
require DagorRandom
require strings
require common_shooter.es.ai.ai_danger_common
require game.es.ai.walker_common

// usage:
// enlisted-aot-win32-c-dev.exe "d:\dagor2\enlisted\prog\scripts\game\es\ai\ai_danger_debug.das" D:\dummy.cpp --config aot_config.blk

def print_values(limit = 100; step = 10; hr = true; blk)
  let origin : float2
  let shootDir = float2(1, 0)
  var x = -limit
  if hr
    print(" y\\x ")
    while x <= limit
      print(format("% 4d", x))
      print(x == 0 ? "  " : " ")
      x += step
      print(x == 0 ? " " : "")
    print("\n\n")

  var y = -limit
  while y <= limit
    x = -limit
    if hr
      print(format("% 4d", y))
      print(" ")
    while x <= limit
      let pos = float2(x, y)
      invoke(blk, origin, pos, shootDir)
      if hr && x == 0
        print(" ")
      x += step
      if hr && x == 0
        print(" ")
    print("\n")
    if hr && y == 0
      print("\n")
    y += step
    if hr && y == 0
      print("\n")


def print_alertness_with_params(stance : int)
  let agent_dangers__frustumAngle = 45f
  let frustumMinCos = cos(deg_to_rad(agent_dangers__frustumAngle))
  print_values(100, 10, true) <| $(origin, pos, shootDir : float2)
    let dist = length(pos - origin)
    let frustumCos = dot(normalize(pos - origin), shootDir)
    let inFrustum = frustumCos >= frustumMinCos
    let agent_dangers__maxDangerDist = 90.0
    let alertness = calc_target_alertness(dist, inFrustum, frustumCos, stance, /*is_downed*/false, agent_dangers__maxDangerDist)
    print(format("%1.2f", alertness))
    print(" ")

// [init]
def print_alertness()
  print("Stance stand\n")
  print_alertness_with_params(STANCE_STAND)
  print("Stance crouch\n")
  print_alertness_with_params(STANCE_CROUCH)
  print("Stance crawl\n")
  print_alertness_with_params(STANCE_CRAWL)
  print(" ")

// [init]
def print_traceable_ratio()
  print_danger_or_traceable_ratio(false)

// [init]
def print_danger()
  print_danger_or_traceable_ratio(true)

def print_danger_or_traceable_ratio(printDanger = true)
  let agent_dangers__frustumAngle = 45f
  let frustumMinCos = cos(deg_to_rad(agent_dangers__frustumAngle))
  let atTime = 1000f
  let agent_dangers__maxDangerDist = 90f

  print_values(100, 10, true) <| $(origin, pos, shootDir : float2)
    let dist = length(pos - origin)
    let frustumCos = dot(normalize(pos - origin), shootDir)
    let inFrustum = frustumCos >= frustumMinCos
    let alertness = calc_target_alertness(dist, inFrustum, frustumCos, STANCE_STAND, /*is_downed*/false, agent_dangers__maxDangerDist)
    using <| $(var danger : Danger#)
      danger.distance = dist
      danger.alertness = alertness
      danger.inFrustumTime = inFrustum ? atTime - 1f : -1f
      danger.lastBulletNearbyTime = -1f //atTime - 0.1f
      danger.lastTraceTime = atTime - 100f
      using <| $(var target : Target#)
        target.lastShootTimer = atTime //1000f
        let isAi = false
        var dangerMeter = calc_danger(atTime, agent_dangers__maxDangerDist, danger, target, /*noise*/0.25, isAi)
        if (dangerMeter < 0.73)
          dangerMeter = 0.0
        print(format("%0.2f", printDanger ? dangerMeter : calc_traceable_ratio(atTime, dangerMeter, danger)))
        print(" ")
