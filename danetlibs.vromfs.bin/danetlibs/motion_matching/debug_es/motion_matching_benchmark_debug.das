options no_aot
require ecs
require math.base
require DagorConsole
require EnlistedWalkerai
require BehNodes
require DagorDataBlock
require DagorRandom
require Dacoll
require DagorDebug3D
require DagorTime
require daProfiler
require EnlistedCamera

[console_cmd(name="motion_matching.enable_on_base_soldier")]
def enable_optinal_motion_matching()
  query()  <| $ [es(REQUIRE=optionalRequestMotionMatching)] (eid : EntityId)
    addSubTemplate(eid, "motion_matching_animchar_component")

def randXZfloat3(scale : float)
  return (float3(gfrnd(), 0.f, gfrnd()) * 2.0 - float3(1, 0, 1)) * scale

def spawn_dev_soldier(pos : float3; templateName : string; team = 1)
  return createEntity(templateName) <| $(var init : ComponentsInitializer)
    var tm = IDENT_TM
    tm[3] = pos
    set(init, "transform", tm)
    set(init, "team", team)


[es(on_appear)]
def test_target_appear(event : Event; var test_target, test_target_center, test_target_velocity : float3&; transform : float3x4)
  test_target = transform[3]
  test_target_center = transform[3]
  test_target_velocity = float3(0, 0, 2)

[es(on_appear, REQUIRE=animationTestPair)]
def test_pair_appear(event : Event; var first_tester, second_tester : EntityId&; transform : float3x4)
  let right = transform[0]

  first_tester = spawn_dev_soldier(transform[3] + right, "walk_soldier+dev_soldier_tag+animation_tester")
  second_tester = spawn_dev_soldier(transform[3] - right, "walk_soldier+dev_soldier_tag+animation_tester")
  enable_free_camera()

def clamp_point_in_circle(center, point : float3; radius : float)
  let d = center - point
  let dist = length(d)
  let t = dist / radius
  if t > 1.f
    return point + d * (1.f - 1.f / t)
  else
    return point

[es(no_order)]
def tester_target_update(info : ecs::UpdateStageInfoAct;
                         var animation_tester__moveTarget : float3&;
                         test_target : float3)
  animation_tester__moveTarget = test_target

[es(no_order, REQUIRE=animationTestPair)]
def test_pair_update(info : ecs::UpdateStageInfoAct;
                     var transform : float3x4&;
                     first_tester, second_tester : EntityId)

  var firstPos = float3(0)
  var secondPos = float3(0)
  query(first_tester) <| $ [es] (transform : float3x4; var motion_matching__enabled : bool&)
    motion_matching__enabled = false
    firstPos = transform[3]
  query(second_tester) <| $ [es] (transform : float3x4)
    secondPos = transform[3]

  let middle = (firstPos + secondPos) * 0.5f
  transform[3] = middle

  let backward = normalize(cross(secondPos - firstPos, float3(0, 1, 0)))
  find_query() <| $ [es] (camera__active : bool; var transform : float3x4&)
    if !camera__active
      return false
    transform[3] = middle + float3(0, 4, 0) + backward * 2.f
    return true

[es(no_order)]
def test_target_update(info : ecs::UpdateStageInfoAct;
                       transform : float3x4;
                       var test_target, test_target_velocity : float3&;
                       test_target_center : float3)
  let position = transform[3]
  let r = length(test_target_velocity)//radius
  let a = atan2(test_target_velocity.x, test_target_velocity.z)//angle
  let maxDa = PI * 8.f
  let maxDr = 15.f
  let maxVel = 6.f
  let dr = (gfrnd() - 0.5f) * 2.f * maxDr * info.dt
  let da = (gfrnd() - 0.5f) * 2.f * maxDa * info.dt
  var x, y : float
  sincos(a + da, x, y)

  let maxRadius = 20.f
  let innerRadius = 15.f
  let t = saturate((length(test_target_center - position) - innerRadius) / maxRadius)

  test_target_velocity = float3(x, 0.f, y) * min(r + dr, maxVel)
  test_target_velocity = lerp(test_target_velocity, normalize(test_target_center - position) * maxVel, float3(t))
  test_target += test_target_velocity * info.dt

  test_target.y = max(position.y, 0.f)
  test_target = clamp_point_in_circle(test_target_center, test_target, 3.f)

  let color = E3DCOLOR(0xFF00FF00)
  draw_debug_sphere_buffered(test_target, 0.1, color, 12, 10)

[es(no_order, REQUIRE=animationTestPair)]
def test_pair_text_update(info : UpdateStageInfoRenderDebug;
                          first_tester, second_tester : EntityId)

  query(first_tester) <| $ [es] (transform : float3x4)
    add_debug_text_mark(transform[3], "anim tree", -1, 0f, E3DCOLOR(0xFFFFFFFF))
  query(second_tester) <| $ [es] (transform : float3x4; motion_matching__distanceFactor : float)
    add_debug_text_mark(transform[3], "motion matching {motion_matching__distanceFactor}", -1, 0f, E3DCOLOR(0xFFFFFFFF))


[es(no_order, REQUIRE=animationTestPair)]
def test_pair_beh_tree_controll(info : ecs::UpdateStageInfoAct;
                                transform : float3x4;
                                test_target : float3;
                                first_tester, second_tester : EntityId)

  let right = transform[0]
  let firstTarget =  test_target + right
  let secondTarget = test_target - right
  query(first_tester) <| $ [es] (var animation_tester__moveTarget : float3&)
    animation_tester__moveTarget = firstTarget
  query(second_tester) <| $ [es] (var animation_tester__moveTarget : float3&)
    animation_tester__moveTarget = secondTarget


[es(no_order)]
def tester_beh_tree_controll(info : ecs::UpdateStageInfoAct;
                             animation_tester__moveTarget : float3;
                             var beh_tree : BehaviourTree&)
  beh_tree.blackBoard |> get_or_create("wishPos", animation_tester__moveTarget)
  beh_tree.blackBoard |> set("wishPos", animation_tester__moveTarget)
  let color = E3DCOLOR(0xFFFFFF00)
  draw_debug_sphere_buffered(animation_tester__moveTarget, 0.1, color, 12, 10)


[console_cmd(name="motion_matching.spawn_test_pair")]
def spawn_test_pair()
  clear_bots()

  find_query() <| $ [es(REQUIRE=animationTestSpawnArea)] (transform : float3x4)
    createEntity("animation_test_pair") <| $(var init : ComponentsInitializer)
      set(init, "transform", transform)
    return true



[console_cmd(name="motion_matching.spawn_bots")]
def spawn_bots(botCount : int)
  clear_bots()
  set_rnd_seed(61346)
  let curTime = float(get_time_msec()) / 1000.f
  createEntity("animation_test_scope") <| $(var init : ComponentsInitializer)
    set(init, "animation_test__startTime", curTime)

  var cameraTm : float3x4
  var found = false
  query() <| $ [es(REQUIRE=animationTestSpawnArea)] (transform : float3x4)
    let spawnArea = sqrt(float(botCount) + 1.f) * PI * 0.5
    for _i in range(0, botCount)
      spawn_dev_soldier(transform[3] + randXZfloat3(spawnArea), "walk_soldier+dev_soldier_tag+animation_self_tester+motion_matching_animchar_component")
    cameraTm[0] = float3(1, 0, 0)
    cameraTm[1] = float3(0, 1, 0)
    cameraTm[2] = float3(0, 0, 1)
    cameraTm[3] = float3(0, 5, -15) + transform[3]
    found = true
  if found
    set_cam_itm(cameraTm)
    enable_free_camera()


[es(on_appear, REQUIRE=animationTestScope)]
def start_animation_test_sampling(event : Event)
  set_mode(da_profiler_ALL | da_profiler_CONTINUOUS)

[es(on_disappear, REQUIRE=animationTestScope)]
def stop_animation_test_sampling(event : Event)
  request_dump()
  set_mode(da_profiler_ALL)
  clear_bots()

[es(no_order, REQUIRE=animationTestScope)]
def animation_test_timer(info : ecs::UpdateStageInfoAct; eid : EntityId; animation_test__startTime, animation_test__duration : float)
  if animation_test__startTime + animation_test__duration < info.curTime
    destroyEntity(eid)

[console_cmd(name="motion_matching.clear_tester")]
def clear_bots()
  query() <| $ [es(REQUIRE=animation_tester__moveTarget)] (eid : EntityId)
    destroyEntity(eid)
  query() <| $ [es(REQUIRE=animationTestPair)] (eid : EntityId)
    destroyEntity(eid)