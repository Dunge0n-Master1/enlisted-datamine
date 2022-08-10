options no_aot
require ecs
require app
require common_shooter.events_common_shooter
require DagorConsole
require DagorMath
require DagorDebug3D
require Dacoll
require Gun
require DaWeapons
require EnlistedPhys
require GridCollision
require game.utils.hero
require EnlistedNet
require game.es.server_debug_common
require daslib/safe_addr
require game.es.net_console_macro

[console_cmd(name="gun.draw_aim")]
def draw_camera_gun_aim()
  let found = find_query() <| $ [es(REQUIRE=cameraAimDebug)] (eid : EntityId)
    destroyEntity(eid)
    return true
  if !found
    createEntity("camera_aim_debug")

[es(tag=render, no_order, REQUIRE=cameraAimDebug)]
def draw_camera_gun_aim_es(evt : UpdateStageInfoRenderDebug)
  find_query() <| $ [es] (transform : float3x4; camera__active : bool)
    if !camera__active
      return false

    let traceDir = transform[2]
    let tracePos = transform[3]

    var len = 4000f
    var norm : float3
    var color = E3DCOLOR(0xFFFFFFFF)

    if traceray_normalized(tracePos, traceDir, len, norm)
      color = E3DCOLOR(0xFF00FF00)

    trace_entities_in_grid(ecs_hash("humans"), tracePos, traceDir, len, INVALID_ENTITY_ID)
    trace_entities_in_grid(ecs_hash("vehicles"), tracePos, traceDir, len, INVALID_ENTITY_ID)
    trace_entities_in_grid(ecs_hash("interactable"), tracePos, traceDir, len, INVALID_ENTITY_ID)

    let pos = tracePos + traceDir * len
    draw_debug_sphere_buffered(pos, 0.25, color, 24, 5)
    return true

def shoot_from_gun(gun_eid : EntityId; gun_tm : float3x4?; start_vel : float)
  let atTime = get_sync_time()
  let gctrl = [[GunControls() shoot=true, wishShoot=true, boltActionMult = 1., timeStep = 0.01]]
  let gunPos = (*gun_tm)[3]
  let gunDir = (*gun_tm)[0]
  let gunVel = start_vel * gunDir
  let gloc = [[GunLocation() gunDir      = gunDir,
                              gunShootDir = gunDir,
                              gunVel      = safe_addr(gunVel),
                              gunPos      = safe_addr(gunPos),
                              visTm       = gun_tm,
                              physTm      = gun_tm]]

  sendEventImmediate(gun_eid, [[CmdGunUpdate atTime=atTime, isForReal=true, seed=phys_time_to_seed(atTime), gctrl=gctrl, gloc=gloc]])

def shoot_from_gun(gun_templ : string; bullet_type_index : int; start_vel : float; tm : float3x4?)
  let finalizeCreation <- @ <| (gunEid : EntityId)
    shoot_from_gun(gunEid, tm, start_vel)

  let templateName = "{gun_templ}+turret_with_several_types_of_shells+gun_ammo_load_debug"
  createEntity(templateName, finalizeCreation) <| $(var init : ComponentsInitializer)
    set(init, "currentBulletId", bullet_type_index)

def get_camera_tm()
  var tm : float3x4
  find_query() <| $ [es] (camera__active : bool; transform : float3x4)
    if !camera__active
      return false
    tm = transform
    let x = tm[0]
    tm[0] = tm[2]
    tm[2] = x
    return true
  return tm

[console_cmd(name="gun.shootFromCam", hint="Shoot a bullet with specified index from gun with given template from the camera in the view direction")]
def gun_shootFromCam(gun_templ : string;
                     bullet_type_index : int = 0;
                     start_vel : float = 50.;
                     dir_x, dir_y, dir_z, x, y, z : float = 0.)
  let dir = float3(dir_x, dir_y, dir_z)
  let pos = float3(x, y, z)
  let up  = float3(0, 1, 0)

  var tmPtr = new [[float3x4()]]
  *tmPtr = get_camera_tm()
  assume tm = *tmPtr
  if length_sq(dir) > 0.0
    tm[0] = normalize(dir)
    tm[2] = cross(tm[0], up)
    tm[1] = cross(tm[2], tm[0])
    tm[3] = pos

  if is_server()
    shoot_from_gun(gun_templ, bullet_type_index, start_vel, tmPtr)
  else
    exec_server_cmd("gun.shootFromCam {gun_templ} {bullet_type_index} {start_vel} {tm[0][0]} {tm[0][1]} {tm[0][2]} {tm[3][0]} {tm[3][1]} {tm[3][2]}")

def gun_shoot_by_aim_trace(eid; gun_templ; bullet_type_index; start_vel)
  query(eid) <| $ [es] (human__aimTm : float3x4)
    var len = 1000.f
    var norm = float3()
    traceray_normalized(human__aimTm[3], human__aimTm[0], len, norm)

    let shootToPos = human__aimTm[3] + human__aimTm[0] * len
    let gunPos     = shootToPos + float3(0.f, 200.f, 0.f)
    let gunDir     = normalize(shootToPos - gunPos)

    var tmPtr = new [[float3x4()]]
    make_tm(dir_to_quat(gunDir), *tmPtr)
    (*tmPtr)[3] = gunPos

    shoot_from_gun(gun_templ, bullet_type_index, start_vel, tmPtr)

[net_console_cmd(name="gun.shoot", hint="Shoot a bullet with specified index from gun with given template from the position of hero's weapon in its shoot direction")]
def gun_shoot(gun_templ : string; bullet_type_index : int; start_vel : float; [[net_hero]] hero_eid : EntityId)
  gun_shoot_by_aim_trace(hero_eid, gun_templ, bullet_type_index, start_vel)