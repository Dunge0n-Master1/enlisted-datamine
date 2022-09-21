require ecs
require PhysVars
require AnimV20
require game.es.device_state_common
require DagorSystem

[es(on_appear, before=anim_phys_init_es)]
def init_device_anim_vars(evt : Event;
                          var phys_vars : PhysVars;
                          var device_anim__stateVarId : int&;
                          var device_anim__progressVarId : int&;
                          var device_anim__states : ecs::IntList)
  device_anim__stateVarId = registerVar(phys_vars, "device_state", 0.f);
  device_anim__progressVarId = registerVar(phys_vars, "device_progress", 0.f);

  var stateNo = 0
  if length(device_anim__states) < 5
    logerr("Wrong length of device_anim__states: {length(device_anim__states)}. Should be at least 5.")
    return
  for anim_state in [[string[5] "device_disabled"; "device_prepare"; "device_use"; "device_fire"; "device_post"]]
    device_anim__states[stateNo++] = animV20_get_enum_value_by_name(anim_state)

[es(tag=render, on_appear, before=anim_phys_init_es)]
def device_anim_fpv_init(evt : Event; var device_anim__isFpvVarId : int&; var phys_vars : PhysVars)
  device_anim__isFpvVarId = registerVar(phys_vars, "is_fpv", 0.0)
