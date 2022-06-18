require ecs
require AnimV20
require EnlistedDm
require DagorShaders
require MaterialRecreate

[es(tag=render, on_appear, REQUIRE=cockpit)]
def init_cockpit_material_es(evt : Event;
                             var animchar_render : AnimcharRendComponent&)
  let cockpitVarId = get_shader_variable_id("simplified_vehicle_cockpit_render", false)
  recreate_material(animchar_render) <| $(mat)
    mat |> set_int_param(cockpitVarId, 1)