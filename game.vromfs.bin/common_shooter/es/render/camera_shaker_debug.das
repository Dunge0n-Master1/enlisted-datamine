options no_aot
require ecs
require DagorConsole
require common_shooter.es.render.camera_shaker_common

[console_cmd(name="camera.punch")]
def camera_punch_debug(pitch = 0.; yaw = 0.; roll = 0.)
  add_punch(float3(pitch, yaw, roll))

[console_cmd(name="camera.punchDir")]
def camera_punch_dir_debug(x = 0.; y = 0.; z = 0.; pow = 1.)
  add_punch_by_dir(float3(x, y, z) * pow)

[console_cmd(name="camera.shakeSustain")]
def camera_shake_sustain_debug(trauma : float = 1.f)
  query() <| $ [es(REQUIRE_NOT=camera_shaker_debug__enabled)] (eid : EntityId;
                                                               camera__active : bool)
    if camera__active
      addSubTemplate(eid, "camera_shaker_debug") <| $(var init)
        set(init, "camera_shaker_debug__sustainTrauma", trauma)
  query() <| $ [es(REQUIRE=camera_shaker_debug__enabled)] (camera__active : bool;
                                                           var camera_shaker_debug__sustainTrauma : float&)
    if camera__active
      camera_shaker_debug__sustainTrauma = trauma

[console_cmd(name="camera.shake")]
def camera_shake_debug(trauma : float = 1.f)
  add_trauma(trauma, 1.f)

[console_cmd(name="camera.shakeProjectile")]
def camera_shake_debug()
  query() <| $ [es] (transform : float3x4; camera__active : bool)
    if !camera__active
      return
    createEntity("rpzb_gr_4322_phys") <| $(var init : ComponentsInitializer)
      var tm := transform
      tm[0] = -transform[2]
      tm[2] = transform[0]
      tm[3] += transform[2] * 80.f + float3(0.5f, 3.f, 0.f)
      set(init, "transform", tm)
      set(init, "start_vel", -transform[2] * 100.f)
      set(init, "active", true)
      set(init, "shell__shell_id__shell_id", 7)
      set(init, "shell__shell_id__damage_id", 7)
      set(init, "shell__shell_id__ballistics_id", 7)
      set(init, "shell__gun_props_id", 8)

[es(tag=(dev, gameClient), no_order)]
def camera_shake_debug_es(info : UpdateStageInfoAct;
                          camera__active : bool;
                          camera_shaker_debug__sustainTrauma : float)
  let sustainTrauma = camera_shaker_debug__sustainTrauma
  if sustainTrauma > 0. && camera__active
    add_trauma(sustainTrauma, sustainTrauma)
