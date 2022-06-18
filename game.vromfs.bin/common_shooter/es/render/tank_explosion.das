require ecs
require AnimV20
require EnlistedDm
require DagorTexture3D
require MaterialRecreate

[es(tag=render, track=isExploded, REQUIRE=scorchable)]
def tank_explosion_es(evt : Event;
                      isExploded : bool;
                      var animchar_render : AnimcharRendComponent&;
                      var dmg_animchar : DmgAnimChar&)

  if !isExploded
    return
  let burntTankVar = get_shader_variable_id("burnt_tank", false)
  recreate_material(animchar_render) <| $(mat)
    mat |> set_int_param(burntTankVar, 1)
  recreate_material(dmg_animchar.rendComp) <| $(mat)
    mat |> set_int_param(burntTankVar, 1)

